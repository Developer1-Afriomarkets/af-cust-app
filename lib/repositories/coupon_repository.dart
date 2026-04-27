import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

import 'dart:convert';

import 'package:afriomarkets_cust_app/data_model/coupon_apply_response.dart';
import 'package:afriomarkets_cust_app/data_model/coupon_remove_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class CouponRepository {
  Future<CouponApplyResponse> getCouponApplyResponse(String coupon_code) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"user_id": "${user_id.$}", "coupon_code": "$coupon_code"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/coupon-apply");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return couponApplyResponseFromJson(response.body);
    }, CouponApplyResponse(result: false, message: "API unavailable"));
  }

  Future<CouponRemoveResponse> getCouponRemoveResponse() async {
    return safeApiCall(() async {
      var post_body = jsonEncode({"user_id": "${user_id.$}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/coupon-remove");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return couponRemoveResponseFromJson(response.body);
    }, CouponRemoveResponse(result: false, message: "API unavailable"));
  }
}
