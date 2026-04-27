import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

import 'package:afriomarkets_cust_app/data_model/refund_request_response.dart';
import 'package:afriomarkets_cust_app/data_model/refund_request_send_response.dart';

class RefundRequestRepository {
  Future<RefundRequestResponse> getRefundRequestListResponse({page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/refund-request/get-list/${user_id.$}?page=$page");
      final response = await medusaClient.get(
        url,
        headers: {
          "App-Language": app_language.$,
          "Authorization": "Bearer ${access_token.$}",
        },
      );
      guardJson(response);
      return refundRequestResponseFromJson(response.body);
    }, RefundRequestResponse(refund_requests: [], success: false, status: 0));
  }

  Future<RefundRequestSendResponse> getRefundRequestSendResponse(
      {required int id, required String reason}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "id": "${id}",
        "user_id": "${user_id.$}",
        "reason": "${reason}",
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/refund-request/send");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
            "Authorization": "Bearer ${access_token.$}",
          },
          body: post_body);
      guardJson(response);
      return refundRequestSendResponseFromJson(response.body);
    }, RefundRequestSendResponse(result: false, message: "API unavailable"));
  }
}
