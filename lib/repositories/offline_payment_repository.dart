import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'dart:convert';

import 'package:afriomarkets_cust_app/data_model/offline_payment_submit_response.dart';

import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class OfflinePaymentRepository {
  Future<OfflinePaymentSubmitResponse> getOfflinePaymentSubmitResponse(
      {required int order_id,
      required String amount,
      required String name,
      required String trx_id,
      required int photo}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "order_id": "$order_id",
        "amount": "$amount",
        "name": "$name",
        "trx_id": "$trx_id",
        "photo": "$photo",
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/offline/payment/submit");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return offlinePaymentSubmitResponseFromJson(response.body);
    }, OfflinePaymentSubmitResponse(result: false, message: "API unavailable"));
  }
}
