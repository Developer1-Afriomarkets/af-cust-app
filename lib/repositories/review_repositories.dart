import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';

import 'package:afriomarkets_cust_app/data_model/review_response.dart';
import 'package:afriomarkets_cust_app/data_model/review_submit_response.dart';

import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

class ReviewRepository {
  Future<ReviewResponse> getReviewResponse(int product_id, {page = 1}) async {
    final response = await medusaClient.get(
      Uri.parse(AppConfig.BASE_URL + "/reviews/product/$product_id"),
    );
    guardJson(response);
    return reviewResponseFromJson(response.body);
  }

  Future<ReviewSubmitResponse> getReviewSubmitResponse(
    int product_id,
    int rating,
    String comment,
  ) async {
    var post_body = jsonEncode({
      "product_id": "${product_id}",
      "user_id": "${user_id.$}",
      "rating": "$rating",
      "comment": "$comment"
    });

    Uri url = Uri.parse("${AppConfig.BASE_URL}/reviews/submit");
    final response = await medusaClient.post(url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
        body: post_body);
    guardJson(response);
    return reviewSubmitResponseFromJson(response.body);
  }
}
