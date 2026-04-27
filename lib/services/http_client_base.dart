import 'package:http/http.dart' as http;

/// Abstract base for Medusa HTTP client.
abstract class MedusaHttpClient {
  static final MedusaHttpClient _instance = _create();

  static MedusaHttpClient get instance => _instance;

  http.Client get client;

  /// Creates the platform-specific implementation.
  /// Uses conditional exports/imports pattern or simple factory if possible.
  static MedusaHttpClient _create() {
    // We will use a factory that returns the right implementation.
    // To avoid compilation errors, we use conditional imports in actual files.
    throw UnimplementedError('Use the factory from medusa_http_client_web.dart or medusa_http_client_mobile.dart');
  }

  /// Helper for GET requests
  Future<http.Response> get(Uri url, {Map<String, String>? headers});

  /// Helper for POST requests
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body});

  /// Helper for DELETE requests
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body});
}

MedusaHttpClient createClient() => throw UnimplementedError('Platform-specific implementation not found');
