import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';
import 'package:afriomarkets_cust_app/data_model/payment_type_response.dart';
import 'package:afriomarkets_cust_app/data_model/order_create_response.dart';
import 'package:afriomarkets_cust_app/data_model/paypal_url_response.dart';
import 'package:afriomarkets_cust_app/data_model/flutterwave_url_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/data_model/razorpay_payment_success_response.dart';
import 'package:afriomarkets_cust_app/data_model/paystack_payment_success_response.dart';
import 'package:afriomarkets_cust_app/data_model/iyzico_payment_success_response.dart';
import 'package:afriomarkets_cust_app/data_model/bkash_begin_response.dart';
import 'package:afriomarkets_cust_app/data_model/bkash_payment_process_response.dart';
import 'package:afriomarkets_cust_app/data_model/nagad_begin_response.dart';
import 'package:afriomarkets_cust_app/data_model/nagad_payment_process_response.dart';
import 'package:afriomarkets_cust_app/data_model/sslcommerz_begin_response.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

class PaymentRepository {
  static final _emptyOrder =
      OrderCreateResponse(result: false, combined_order_id: 0);

  Future<List<PaymentTypeResponse>> getPaymentResponseList(
      {mode = "", list = "both"}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/payment-types?mode=${mode}&list=${list}");
      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return paymentTypeResponseFromJson(response.body);
    }, []);
  }

  Future<OrderCreateResponse> getOrderCreateResponse(payment_method) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"user_id": "${user_id.$}", "payment_type": "${payment_method}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/order/store");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return orderCreateResponseFromJson(response.body);
    }, _emptyOrder);
  }

  Future<PaypalUrlResponse> getPaypalUrlResponse(
      String payment_type, int combined_order_id, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/paypal/payment/url?payment_type=${payment_type}&combined_order_id=${combined_order_id}&amount=${amount}&user_id=${user_id.$}",
      );
      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return paypalUrlResponseFromJson(response.body);
    }, PaypalUrlResponse(result: false, url: ""));
  }

  Future<FlutterwaveUrlResponse> getFlutterwaveUrlResponse(
      String payment_type, int combined_order_id, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/flutterwave/payment/url?payment_type=${payment_type}&combined_order_id=${combined_order_id}&amount=${amount}&user_id=${user_id.$}");

      final response = await medusaClient.get(url, headers: {
        "App-Language": app_language.$,
      });
      guardJson(response);
      return flutterwaveUrlResponseFromJson(response.body);
    }, FlutterwaveUrlResponse(result: false, url: ""));
  }

  Future<OrderCreateResponse> getOrderCreateResponseFromWallet(
      payment_method, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/payments/pay/wallet");

      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_method}",
        "amount": "${amount}"
      });

      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return orderCreateResponseFromJson(response.body);
    }, _emptyOrder);
  }

  Future<OrderCreateResponse> getOrderCreateResponseFromCod(
      payment_method) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"user_id": "${user_id.$}", "payment_type": "${payment_method}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/payments/pay/cod");

      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}"
          },
          body: post_body);
      guardJson(response);
      return orderCreateResponseFromJson(response.body);
    }, _emptyOrder);
  }

  Future<OrderCreateResponse> getOrderCreateResponseFromManualPayment(
      payment_method) async {
    return safeApiCall(() async {
      var post_body = jsonEncode(
          {"user_id": "${user_id.$}", "payment_type": "${payment_method}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/payments/pay/manual");

      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return orderCreateResponseFromJson(response.body);
    }, _emptyOrder);
  }

  Future<RazorpayPaymentSuccessResponse> getRazorpayPaymentSuccessResponse(
      payment_type,
      double amount,
      int combined_order_id,
      String payment_details) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_type}",
        "combined_order_id": "${combined_order_id}",
        "amount": "${amount}",
        "payment_details": "${payment_details}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/razorpay/success");

      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return razorpayPaymentSuccessResponseFromJson(response.body);
    }, RazorpayPaymentSuccessResponse(result: false));
  }

  Future<PaystackPaymentSuccessResponse> getPaystackPaymentSuccessResponse(
      payment_type,
      double amount,
      int combined_order_id,
      String payment_details) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_type}",
        "combined_order_id": "${combined_order_id}",
        "amount": "${amount}",
        "payment_details": "${payment_details}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/paystack/success");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}"
          },
          body: post_body);
      guardJson(response);
      return paystackPaymentSuccessResponseFromJson(response.body);
    }, PaystackPaymentSuccessResponse(result: false));
  }

  Future<IyzicoPaymentSuccessResponse> getIyzicoPaymentSuccessResponse(
      payment_type,
      double amount,
      int combined_order_id,
      String payment_details) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_type}",
        "combined_order_id": "${combined_order_id}",
        "amount": "${amount}",
        "payment_details": "${payment_details}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/paystack/success");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}"
          },
          body: post_body);
      guardJson(response);
      return iyzicoPaymentSuccessResponseFromJson(response.body);
    }, IyzicoPaymentSuccessResponse(result: false));
  }

  Future<BkashBeginResponse> getBkashBeginResponse(
      String payment_type, int combined_order_id, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/bkash/begin?payment_type=${payment_type}&combined_order_id=${combined_order_id}&amount=${amount}&user_id=${user_id.$}");

      final response = await medusaClient.get(
        url,
        headers: {"Authorization": "Bearer ${access_token.$}"},
      );
      guardJson(response);
      return bkashBeginResponseFromJson(response.body);
    }, BkashBeginResponse(result: false, url: ""));
  }

  Future<BkashPaymentProcessResponse> getBkashPaymentProcessResponse(
      payment_type,
      double amount,
      int combined_order_id,
      String payment_details) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_type}",
        "combined_order_id": "${combined_order_id}",
        "amount": "${amount}",
        "payment_details": "${payment_details}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/bkash/api/process");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return bkashPaymentProcessResponseFromJson(response.body);
    }, BkashPaymentProcessResponse(result: false));
  }

  Future<SslcommerzBeginResponse> getSslcommerzBeginResponse(
      String payment_type, int combined_order_id, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/sslcommerz/begin?payment_type=${payment_type}&combined_order_id=${combined_order_id}&amount=${amount}&user_id=${user_id.$}");

      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$
        },
      );
      guardJson(response);
      return sslcommerzBeginResponseFromJson(response.body);
    }, SslcommerzBeginResponse(result: false, url: ""));
  }

  Future<NagadBeginResponse> getNagadBeginResponse(
      String payment_type, int combined_order_id, double amount) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/nagad/begin?payment_type=${payment_type}&combined_order_id=${combined_order_id}&amount=${amount}&user_id=${user_id.$}");

      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$
        },
      );
      guardJson(response);
      return nagadBeginResponseFromJson(response.body);
    }, NagadBeginResponse(result: false, url: ""));
  }

  Future<NagadPaymentProcessResponse> getNagadPaymentProcessResponse(
      payment_type,
      double amount,
      int combined_order_id,
      String payment_details) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "payment_type": "${payment_type}",
        "combined_order_id": "${combined_order_id}",
        "amount": "${amount}",
        "payment_details": "${payment_details}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/nagad/process");

      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$,
          },
          body: post_body);
      guardJson(response);
      return nagadPaymentProcessResponseFromJson(response.body);
    }, NagadPaymentProcessResponse(result: false));
  }
}
