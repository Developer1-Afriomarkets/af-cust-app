import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

class ToastComponent {
  static const int lengthLong = 1;
  static const int lengthShort = 0;
  static const int bottom = 0;
  static const int center = 1;
  static const int top = 2;

  static showDialog(String? msg, context, {int duration = 0, int gravity = 0}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg ?? "",
          style: TextStyle(color: MyTheme.white),
        ),
        backgroundColor: MyTheme.accent_color,
        duration: duration == lengthLong
            ? const Duration(seconds: 3)
            : const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
