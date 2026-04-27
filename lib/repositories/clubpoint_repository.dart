import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

import 'package:afriomarkets_cust_app/data_model/clubpoint_response.dart';
import 'package:afriomarkets_cust_app/data_model/clubpoint_to_wallet_response.dart';

class ClubpointRepository {
  Future<ClubpointResponse> getClubPointListResponse({page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/clubpoint/get-list/${user_id.$}?page=$page");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$
        },
      );
      return clubpointResponseFromJson(response.body);
    }, ClubpointResponse(clubpoints: [], success: false, status: 0));
  }

  Future<ClubpointToWalletResponse> getClubpointToWalletResponse(int id) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "id": "${id}",
        "user_id": "${user_id.$}",
      });
      Uri url =
          Uri.parse("${AppConfig.BASE_URL}/clubpoint/convert-into-wallet");
      final response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);

      return clubpointToWalletResponseFromJson(response.body);
    }, ClubpointToWalletResponse(result: false, message: "API unavailable"));
  }
}
