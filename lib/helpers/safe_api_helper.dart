/// Centralized helper for safely calling legacy API endpoints.
///
/// Many legacy endpoints may return HTML error pages instead of JSON.
/// This helper wraps API calls in try-catch blocks so the app doesn't
/// crash when an endpoint is unavailable or misconfigured.

import 'dart:convert';

/// Checks whether [responseBody] looks like a valid JSON response.
/// Returns false if it starts with '<' (HTML) or fails to decode.
bool isValidJsonResponse(String responseBody) {
  final trimmed = responseBody.trimLeft();
  if (trimmed.isEmpty || trimmed.startsWith('<')) return false;
  try {
    json.decode(trimmed);
    return true;
  } catch (_) {
    return false;
  }
}

/// Safely parses [responseBody] using the provided [fromJson] parser.
/// Returns [fallback] if parsing fails (e.g. HTML error page returned).
T safeParseResponse<T>(
  String responseBody,
  T Function(String) fromJson,
  T fallback,
) {
  try {
    return fromJson(responseBody);
  } catch (e) {
    print('[API Warning] Failed to parse response: $e');
    return fallback;
  }
}

/// Safely executes an entire API call (including the HTTP request).
/// Returns [fallback] if any exception occurs (network, parsing, etc).
Future<T> safeApiCall<T>(
  Future<T> Function() apiCall,
  T fallback,
) async {
  try {
    return await apiCall();
  } catch (e) {
    // Surface the actual error message if caught from guardJson
    print('[API Warning] API call failed: $e');
    return fallback;
  }
}

/// Throws an exception if the response body looks like HTML (starts with '<').
void guardJson(dynamic response) {
  final body = response.body.toString().trim();
  if (body.startsWith('<') || body.toLowerCase().contains('<!doctype')) {
    final snippet = body.length > 200 ? body.substring(0, 200) : body;
    throw Exception(
        'API returned HTML instead of JSON (${response.statusCode}). '
        'Endpoint: ${response.request?.url}. '
        'Snippet: $snippet');
  }
}
