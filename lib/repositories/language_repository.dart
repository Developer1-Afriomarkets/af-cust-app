import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/language_list_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class LanguageRepository {
  Future<LanguageListResponse> getLanguageList() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/languages");
      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return languageListResponseFromJson(response.body);
    }, LanguageListResponse(languages: [], success: false, status: 0));
  }
}
