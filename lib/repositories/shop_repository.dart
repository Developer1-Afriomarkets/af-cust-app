import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';
import 'package:afriomarkets_cust_app/data_model/shop_details_response.dart';
import 'package:afriomarkets_cust_app/data_model/product_mini_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class ShopRepository {
  static final _emptyMini =
      ProductMiniResponse(products: [], success: false, status: 0);

  Future<ShopResponse> getShops({name = "", page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/shops" + "?page=${page}&name=${name}");

      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return shopResponseFromJson(response.body);
    }, ShopResponse(shops: [], success: false, status: 0));
  }

  Future<ShopDetailsResponse> getShopInfo({id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/shops/details/${id}");
      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return shopDetailsResponseFromJson(response.body);
    }, ShopDetailsResponse(shops: [], success: false, status: 0));
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts({int id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/shops/products/top/" + id.toString());
      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return productMiniResponseFromJson(response.body);
    }, _emptyMini);
  }

  Future<ProductMiniResponse> getNewFromThisSellerProducts({int id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/shops/products/new/" + id.toString());
      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return productMiniResponseFromJson(response.body);
    }, _emptyMini);
  }

  Future<ProductMiniResponse> getfeaturedFromThisSellerProducts(
      {int id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/shops/products/featured/" + id.toString());
      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return productMiniResponseFromJson(response.body);
    }, _emptyMini);
  }
}
