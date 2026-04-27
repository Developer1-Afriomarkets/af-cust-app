import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/brand_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class BrandRepository {
  static final _empty = BrandResponse(brands: [], success: false, status: 0);

  Future<BrandResponse> getFilterPageBrands() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/brands");
      final response = await medusaClient.get(url);
      guardJson(response);
      return brandResponseFromJson(response.body);
    }, BrandResponse(brands: [], success: false, status: 0));
  }

  Future<BrandResponse> getBrands({name = "", page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/brands" + "?page=${page}&name=${name}");
      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return brandResponseFromJson(response.body);
    }, _empty);
  }
}
