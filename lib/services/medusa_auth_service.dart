import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

/// Medusa v1 customer authentication service.
///
/// Endpoints used:
/// - POST /store/auth          → login (email + password)
/// - DELETE /store/auth        → logout
/// - GET  /store/auth          → check session / get customer
/// - POST /store/customers     → register new customer
/// - GET  /store/customers/me  → get current customer profile
class MedusaAuthService {
  static const String _sessionCookieKey = 'medusa_session_cookie';
  static const String _customerIdKey = 'medusa_customer_id';

  static String get _baseUrl => AppConfig.MEDUSA_BASE_URL;

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ═══════════════════════════════════════════════════════════════════════
  //  Login
  // ═══════════════════════════════════════════════════════════════════════

  static final String _bearerTokenKey = 'medusa_bearer_token';

  /// Authenticate and retrieve a JWT Bearer Token.
  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await medusaClient.post(
        Uri.parse('$_baseUrl/store/auth/token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );
      _guardJson(response);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final token = body['access_token'] as String?;
        if (token != null) {
          await _storeBearerToken(token);
        }

        // Parallel fallback: Fetch session cookie natively to bridge mobile webviews and plugins requiring `connect.sid`
        try {
          final cookieResponse = await medusaClient.post(
            Uri.parse('$_baseUrl/store/auth'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          );
          if (cookieResponse.statusCode == 200) {
            final setCookie = cookieResponse.headers['set-cookie'];
            if (setCookie != null) {
              final extracted = _extractCookieValue(setCookie);
              if (extracted != null) {
                await _storeSessionCookie(extracted);
              }
            }
          }
        } catch (_) {}

        // Fetch customer profile separately because /token doesn't return the full customer
        final profileResult = await getCustomerProfile();
        
        if (profileResult.success && profileResult.customer != null) {
           await _storeCustomerId(profileResult.customer!['id']?.toString() ?? '');
        }

        return AuthResult(
          success: profileResult.success,
          message: profileResult.success ? 'Login successful' : 'Profile sync failed',
          customer: profileResult.customer,
          token: token,
        );
      } else {
        final body = _safeJsonDecode(response.body);
        return AuthResult(
          success: false,
          message: body?['message'] ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Register
  // ═══════════════════════════════════════════════════════════════════════

  /// Create a new customer account, then auto-login.
  static Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await medusaClient.post(
        Uri.parse('$_baseUrl/store/customers'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          if (phone != null && phone.isNotEmpty)
            'phone': phone.replaceAll(RegExp(r'\D'), ''),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto-login after registration
        final loginResult = await login(email, password);
        return AuthResult(
          success: true,
          message: 'Account created successfully',
          customer: loginResult.customer,
        );
      } else {
        final body = _safeJsonDecode(response.body);
        return AuthResult(
          success: false,
          message: body?['message'] ?? 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Session / Profile
  // ═══════════════════════════════════════════════════════════════════════

  /// Check if the user has an active session. Returns customer data if so.
  static Future<AuthResult> getSession() async {
    return await getCustomerProfile();
  }

  /// Get current customer profile (requires active token).
  static Future<AuthResult> getCustomerProfile() async {
    try {
      final headers = await getAuthBearerHeaders();
      if (!headers.containsKey('Authorization')) {
        return AuthResult(success: false, message: 'Not logged in');
      }

      final response = await medusaClient.get(
        Uri.parse('$_baseUrl/store/customers/me'),
        headers: headers,
      );
      _guardJson(response);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult(
          success: true,
          customer: body['customer'] as Map<String, dynamic>?,
        );
      } else {
        await clearSession();
        return AuthResult(success: false, message: 'Failed to load profile');
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error');
    }
  }

  /// Logout — clear local storage.
  static Future<void> logout() async {
    // Medusa tokens are generally stateless (or simply forgotten by dropping the token client-side)
    await clearSession();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Session Storage
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> _storeSessionCookie(String cookieValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionCookieKey, cookieValue);
  }

  static Future<String?> _getSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionCookieKey);
  }

  static Future<void> _storeBearerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bearerTokenKey, token);
  }

  static Future<String?> getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bearerTokenKey);
  }

  static Future<void> _storeCustomerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerIdKey, id);
  }

  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerIdKey);
  }

  /// Returns fully structured HTTP Request headers appending the Bearer token and fallback Cookies.
  static Future<Map<String, String>> getAuthBearerHeaders() async {
    final token = await getBearerToken();
    final cookie = kIsWeb ? null : await _getSessionCookie();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bearerTokenKey);
    await prefs.remove(_sessionCookieKey);
    await prefs.remove(_customerIdKey);
  }

  /// Check if a bearer token is stored.
  static Future<bool> isLoggedIn() async {
    final token = await getBearerToken();
    return token != null && token.isNotEmpty;
  }

  /// Helper to convert a dynamic ID (int or String) to a stable int hash.
  static int stableId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId == null) return 0;
    return rawId.toString().hashCode.abs();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Private helpers
  // ═══════════════════════════════════════════════════════════════════════

  /// Extracts the usable "name=value" part from a Set-Cookie header.
  /// E.g. "connect.sid=s%3A...; Path=/; HttpOnly" → "connect.sid=s%3A..."
  static String? _extractCookieValue(String setCookieHeader) {
    // Multiple cookies can be separated by commas (RFC 2109), so take first.
    final firstCookie = setCookieHeader.split(',').first.trim();
    // The first semicolon-delimited segment is the name=value pair.
    final nameValue = firstCookie.split(';').first.trim();
    if (nameValue.isEmpty) return null;
    return nameValue;
  }

  static void _guardJson(http.Response response) {
    final body = response.body.trim();
    if (body.startsWith('<') || body.toLowerCase().contains('<!doctype')) {
      final snippet = body.length > 200 ? body.substring(0, 200) : body;
      print('[MedusaAuth] HTML Response detected (${response.statusCode}): $snippet');
      throw Exception(
          'Medusa Auth API returned HTML (${response.statusCode}) instead of JSON. '
          'Endpoint: ${response.request?.url}. '
          'Snippet: $snippet');
    }
  }

  static Map<String, dynamic>? _safeJsonDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Result of an authentication operation.
class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? customer;
  final String? token;

  const AuthResult({required this.success, this.message, this.customer, this.token});

  String get customerName {
    if (customer == null) return '';
    final first = customer!['first_name'] ?? '';
    final last = customer!['last_name'] ?? '';
    return '$first $last'.trim();
  }

  String get customerEmail => customer?['email'] ?? '';

  String get customerPhone => customer?['phone'] ?? '';

  String get customerId => customer?['id']?.toString() ?? '';
}

