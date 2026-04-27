import 'package:afriomarkets_cust_app/services/http_client_base.dart'
    if (dart.library.html) 'package:afriomarkets_cust_app/services/http_client_web.dart'
    if (dart.library.io) 'package:afriomarkets_cust_app/services/http_client_mobile.dart';

/// The platform-aware Medusa HTTP client.
/// On Web, it uses BrowserClient with withCredentials = true.
/// On Mobile, it uses the standard http.Client.
final medusaClient = createClient();
