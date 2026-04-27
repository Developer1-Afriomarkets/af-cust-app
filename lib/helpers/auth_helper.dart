import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';

class AuthHelper {
  /// Called after a successful legacy API login response.
  /// (Kept for any remaining legacy paths.)
  setUserData(loginResponse) {
    if (loginResponse.result == true) {
      is_logged_in.$ = true;
      is_logged_in.save();
      access_token.$ = loginResponse.access_token ?? "";
      access_token.save();
      user_id.$ = loginResponse.user?.id ?? 0;
      user_id.save();
      user_name.$ = loginResponse.user?.name ?? "";
      user_name.save();
      user_email.$ = loginResponse.user?.email ?? "";
      user_email.save();
      user_phone.$ = loginResponse.user?.phone ?? "";
      user_phone.save();
      avatar_original.$ = loginResponse.user?.avatar_original ?? "";
      avatar_original.save();
    }
  }

  /// Called after a successful Medusa auth operation (login / register /
  /// session restore).  Updates all SharedValue globals so every screen
  /// correctly sees the user as logged in.
  void setUserDataFromMedusa(AuthResult result) {
    if (!result.success) return;

    is_logged_in.$ = true;
    is_logged_in.save();

    user_name.$ = result.customerName;
    user_name.save();

    user_email.$ = result.customerEmail;
    user_email.save();

    user_phone.$ = result.customerPhone;
    user_phone.save();

    // Medusa customers don't have a legacy int user_id.
    // Store a stable hash so code that reads user_id.$ still works.
    final idStr = result.customerId;
    if (idStr.isNotEmpty) {
      user_id.$ = idStr.hashCode.abs();
      user_id.save();
    }

    // No avatar from Medusa by default; clear any stale value.
    avatar_original.$ = "";
    avatar_original.save();

    // Map explicit Web JWT Bearer strings to universally authorize generic legacy repository calls unconditionally
    access_token.$ = result.token ?? "";
    access_token.save();
  }

  void clearUserData() {
    is_logged_in.$ = false;
    is_logged_in.save();
    access_token.$ = "";
    access_token.save();
    user_id.$ = 0;
    user_id.save();
    user_name.$ = "";
    user_name.save();
    user_email.$ = "";
    user_email.save();
    user_phone.$ = "";
    user_phone.save();
    avatar_original.$ = "";
    avatar_original.save();
  }
}
