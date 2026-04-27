import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/wishlist_check_response.dart';
import 'package:afriomarkets_cust_app/data_model/wishlist_delete_response.dart';
import 'package:afriomarkets_cust_app/data_model/wishlist_response.dart';
import 'package:flutter/foundation.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

class WishListRepository {
  Future<WishlistResponse> getUserWishlist() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/wishlists/${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return wishlistResponseFromJson(response.body);
    }, WishlistResponse(wishlist_items: [], success: false, status: 0));
  }

  Future<WishlistDeleteResponse> delete({
    @required int wishlist_id = 0,
  }) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/wishlists/${wishlist_id}");
      final response = await medusaClient.delete(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return wishlistDeleteResponseFromJson(response.body);
    }, WishlistDeleteResponse(result: false, message: "API unavailable"));
  }

  Future<WishListChekResponse> isProductInUserWishList(
      {@required product_id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/wishlists-check-product?product_id=${product_id}&user_id=${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return wishListChekResponseFromJson(response.body);
    }, WishListChekResponse(is_in_wishlist: false, wishlist_id: 0));
  }

  Future<WishListChekResponse> add({@required product_id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/wishlists-add-product?product_id=${product_id}&user_id=${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return wishListChekResponseFromJson(response.body);
    }, WishListChekResponse(is_in_wishlist: false, wishlist_id: 0));
  }

  Future<WishListChekResponse> remove({@required product_id = 0}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/wishlists-remove-product?product_id=${product_id}&user_id=${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return wishListChekResponseFromJson(response.body);
    }, WishListChekResponse(is_in_wishlist: false, wishlist_id: 0));
  }


}
