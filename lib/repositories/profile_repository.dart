import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';
import 'package:afriomarkets_cust_app/data_model/profile_counters_response.dart';
import 'package:afriomarkets_cust_app/data_model/profile_update_response.dart';
import 'package:afriomarkets_cust_app/data_model/device_token_update_response.dart';
import 'package:afriomarkets_cust_app/data_model/profile_image_update_response.dart';
import 'package:afriomarkets_cust_app/data_model/phone_email_availability_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

class ProfileRepository {
  Future<ProfileCountersResponse> getProfileCountersResponse() async {
    return safeApiCall(() async {
      Uri url =
          Uri.parse("${AppConfig.BASE_URL}/profile/counters/${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return profileCountersResponseFromJson(response.body);
    }, ProfileCountersResponse());
  }

  Future<ProfileUpdateResponse> getProfileUpdateResponse(
      String name, String password) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"id": "${user_id.$}", "name": "${name}", "password": "$password"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return profileUpdateResponseFromJson(response.body);
    }, ProfileUpdateResponse(result: false, message: "API unavailable"));
  }

  Future<DeviceTokenUpdateResponse> getDeviceTokenUpdateResponse(
      String device_token) async {
    return safeApiCall(() async {
      var post_body =
          jsonEncode({"id": "${user_id.$}", "device_token": "${device_token}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update-device-token");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return deviceTokenUpdateResponseFromJson(response.body);
    }, DeviceTokenUpdateResponse(result: false, message: "API unavailable"));
  }

  Future<ProfileImageUpdateResponse> getProfileImageUpdateResponse(
      String image, String filename) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"id": "${user_id.$}", "image": "${image}", "filename": "$filename"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update-image");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return profileImageUpdateResponseFromJson(response.body);
    }, ProfileImageUpdateResponse(result: false, message: "API unavailable"));
  }

  Future<PhoneEmailAvailabilityResponse>
      getPhoneEmailAvailabilityResponse() async {
    return safeApiCall(() async {
      var post_body = jsonEncode({"user_id": "${user_id.$}"});

      Uri url =
          Uri.parse("${AppConfig.BASE_URL}/profile/check-phone-and-email");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return phoneEmailAvailabilityResponseFromJson(response.body);
    }, PhoneEmailAvailabilityResponse());
  }
}
