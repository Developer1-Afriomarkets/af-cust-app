import 'package:shared_value/shared_value.dart';

final SharedValue<bool> is_logged_in = SharedValue(
  value: false,
  key: "is_logged_in",
);

final SharedValue<String> access_token = SharedValue(
  value: "",
  key: "access_token",
);

final SharedValue<int> user_id = SharedValue(
  value: 0,
  key: "user_id",
);

final SharedValue<String> avatar_original = SharedValue(
  value: "",
  key: "avatar_original",
);

final SharedValue<String> user_name = SharedValue(
  value: "",
  key: "user_name",
);

final SharedValue<String> user_email = SharedValue(
  value: "",
  key: "user_email",
);

final SharedValue<String> user_phone = SharedValue(
  value: "",
  key: "user_phone",
);

final SharedValue<String> app_language = SharedValue(
  value: "en",
  key: "app_language",
);

final SharedValue<String> app_mobile_language = SharedValue(
  value: "en",
  key: "app_mobile_language",
);

final SharedValue<bool> app_language_rtl = SharedValue(
  value: false,
  key: "app_language_rtl",
);

final SharedValue<String> current_region_id = SharedValue(
  value: "",
  key: "current_region_id",
);

final SharedValue<String> current_country_code = SharedValue(
  value: "ng",
  key: "current_country_code",
);

/// Persisted Medusa cart ID — survives app restarts.
/// Cleared after a successful cart completion.
final SharedValue<String> medusa_cart_id = SharedValue(
  value: "",
  key: "medusa_cart_id",
);

/// Has the user seen the onboarding screen at least once?
final SharedValue<bool> has_seen_onboarding = SharedValue(
  value: false,
  key: "has_seen_onboarding",
);

/// Comma-separated locally-stored wishlist Medusa product IDs.
final SharedValue<String> local_wishlist_ids = SharedValue(
  value: "",
  key: "local_wishlist_ids",
);

final SharedValue<String> app_theme_mode = SharedValue(
  value: "light",
  key: "app_theme_mode",
);
