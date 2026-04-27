import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/flash_deal_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class FlashDealRepository {
  Future<FlashDealResponse> getFlashDeals() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/flash-deals");
      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return flashDealResponseFromJson(response.body);
    }, FlashDealResponse(flash_deals: [], success: false, status: 0));
  }
}
