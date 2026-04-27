import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/login_response.dart';
import 'package:afriomarkets_cust_app/data_model/logout_response.dart';
import 'package:afriomarkets_cust_app/data_model/signup_response.dart';
import 'package:afriomarkets_cust_app/data_model/resend_code_response.dart';
import 'package:afriomarkets_cust_app/data_model/confirm_code_response.dart';
import 'package:afriomarkets_cust_app/data_model/password_forget_response.dart';
import 'package:afriomarkets_cust_app/data_model/password_confirm_response.dart';
import 'package:afriomarkets_cust_app/data_model/user_by_token.dart';

import 'dart:convert';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

class AuthRepository {
  Future<LoginResponse> getLoginResponse(String email, String password) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "email": "${email}",
        "password": "$password",
        "identity_matrix": AppConfig.purchase_code
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/login");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return loginResponseFromJson(response.body);
    }, LoginResponse(result: false, message: "API unavailable"));
  }

  Future<LoginResponse> getSocialLoginResponse(
      String name, String email, String provider) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"name": "${name}", "email": "${email}", "provider": "$provider"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/social-login");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return loginResponseFromJson(response.body);
    }, LoginResponse(result: false, message: "API unavailable"));
  }

  Future<LogoutResponse> getLogoutResponse() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/logout");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);

      return logoutResponseFromJson(response.body);
    }, LogoutResponse(result: false, message: "API unavailable"));
  }

  Future<SignupResponse> getSignupResponse(String name, String email_or_phone,
      String password, String passowrd_confirmation, String register_by) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "name": "$name",
        "email_or_phone": "${email_or_phone}",
        "password": "$password",
        "password_confirmation": "${passowrd_confirmation}",
        "register_by": "$register_by"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/signup");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return signupResponseFromJson(response.body);
    }, SignupResponse(result: false, message: "API unavailable"));
  }

  Future<ResendCodeResponse> getResendCodeResponse(
      int user_id, String verify_by) async {
    return safeApiCall(() async {
      var post_body =
          jsonEncode({"user_id": "$user_id", "register_by": "$verify_by"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/resend_code");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return resendCodeResponseFromJson(response.body);
    }, ResendCodeResponse(result: false, message: "API unavailable"));
  }

  Future<ConfirmCodeResponse> getConfirmCodeResponse(
      int user_id, String verification_code) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"user_id": "$user_id", "verification_code": "$verification_code"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/confirm_code");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return confirmCodeResponseFromJson(response.body);
    }, ConfirmCodeResponse(result: false, message: "API unavailable"));
  }

  Future<PasswordForgetResponse> getPasswordForgetResponse(
      String email_or_phone, String send_code_by) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "email_or_phone": "$email_or_phone",
        "send_code_by": "$send_code_by"
      });

      Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/auth/password/forget_request",
      );
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return passwordForgetResponseFromJson(response.body);
    }, PasswordForgetResponse(result: false, message: "API unavailable"));
  }

  Future<PasswordConfirmResponse> getPasswordConfirmResponse(
      String verification_code, String password) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"verification_code": "$verification_code", "password": "$password"});

      Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/auth/password/confirm_reset",
      );
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return passwordConfirmResponseFromJson(response.body);
    }, PasswordConfirmResponse(result: false, message: "API unavailable"));
  }

  Future<ResendCodeResponse> getPasswordResendCodeResponse(
      String email_or_code, String verify_by) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"email_or_code": "$email_or_code", "verify_by": "$verify_by"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/auth/password/resend_code");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return resendCodeResponseFromJson(response.body);
    }, ResendCodeResponse(result: false, message: "API unavailable"));
  }

  Future<UserByTokenResponse> getUserByTokenResponse() async {
    return safeApiCall(() async {
      var post_body = jsonEncode({"access_token": "${access_token.$}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/get-user-by-access_token");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);

      return userByTokenResponseFromJson(response.body);
    }, UserByTokenResponse(result: false));
  }


}
