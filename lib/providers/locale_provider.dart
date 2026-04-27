import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = Locale(app_mobile_language.$, '');
  Locale get locale {
    return _locale = Locale(app_mobile_language.$, '');
  }

  void setLocale(String code) {
    _locale = Locale(code, '');
    notifyListeners();
  }
}
