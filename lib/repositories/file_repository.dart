import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'dart:convert';

import 'package:afriomarkets_cust_app/data_model/simple_image_upload_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class FileRepository {
  Future<SimpleImageUploadResponse> getSimpleImageUploadResponse(
      String image, String filename) async {
    return safeApiCall(() async {
      var post_body =
          jsonEncode({"image": "${image}", "filename": "$filename"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/file/image-upload");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return simpleImageUploadResponseFromJson(response.body);
    }, SimpleImageUploadResponse(result: false, path: ""));
  }
}
