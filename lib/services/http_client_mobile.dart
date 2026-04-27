import 'package:http/http.dart' as http;
import 'package:afriomarkets_cust_app/services/http_client_base.dart';

class MobileMedusaHttpClient extends MedusaHttpClient {
  @override
  final http.Client client = http.Client();

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return client.get(url, headers: headers);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return client.post(url, headers: headers, body: body);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) {
    return client.delete(url, headers: headers, body: body);
  }
}

MedusaHttpClient createClient() => MobileMedusaHttpClient();
