import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

class InputDecorations {
  static InputDecoration buildInputDecoration_1(BuildContext context, {String hint_text = ""}) {
    return InputDecoration(
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.secondaryText(context).withOpacity(0.6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.border(context), width: 1.0),
          borderRadius: const BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.primary(context), width: 1.5),
          borderRadius: const BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        fillColor: MyTheme.surface(context).withOpacity(0.5),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0));
  }

  static InputDecoration buildInputDecoration_phone(BuildContext context, {String hint_text = ""}) {
    return InputDecoration(
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.secondaryText(context).withOpacity(0.6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.border(context), width: 1.0),
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0)),
        ),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.primary(context), width: 1.5),
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0))),
        fillColor: MyTheme.surface(context).withOpacity(0.5),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0));
  }
}

