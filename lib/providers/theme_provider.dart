import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode get themeMode {
    if (app_theme_mode.$ == "light") return ThemeMode.light;
    if (app_theme_mode.$ == "dark") return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setThemeMode(String mode) {
    app_theme_mode.$ = mode;
    app_theme_mode.save();
    notifyListeners();
  }
}
