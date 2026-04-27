import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/wallet_balance_response.dart';
import 'package:afriomarkets_cust_app/data_model/wallet_recharge_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class WalletRepository {
  Future<WalletBalanceResponse> getBalance() async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/wallet/balance/${user_id.$}");

      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return walletBalanceResponseFromJson(response.body);
    }, WalletBalanceResponse(balance: "0"));
  }

  Future<WalletRechargeResponse> getRechargeList({int page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/wallet/history/${user_id.$}?page=${page}");

      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return walletRechargeResponseFromJson(response.body);
    }, WalletRechargeResponse(recharges: [], success: false, status: 0));
  }
}
