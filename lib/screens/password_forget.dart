import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/custom/input_decorations.dart';
import 'package:afriomarkets_cust_app/custom/intl_phone_input.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:afriomarkets_cust_app/addon_config.dart';
import 'package:afriomarkets_cust_app/screens/password_otp.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/repositories/auth_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class PasswordForget extends StatefulWidget {
  @override
  _PasswordForgetState createState() => _PasswordForgetState();
}

class _PasswordForgetState extends State<PasswordForget> {
  String _send_code_by = "email"; //phone or email
  String initialCountry = 'US';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'US');
  String _phone = "";

  //controllers
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  onPressSendCode() async {
    var email = _emailController.text.toString();

    if (_send_code_by == 'email' && email == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.password_forget_screen_email_warning,
          context);
      return;
    } else if (_send_code_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.password_forget_screen_phone_warning,
          context);
      return;
    }

    var passwordForgetResponse = await AuthRepository()
        .getPasswordForgetResponse(
            _send_code_by == 'email' ? email : _phone, _send_code_by);

    if (passwordForgetResponse.result == false) {
      ToastComponent.showDialog(passwordForgetResponse.message ?? "", context);
    } else {
      ToastComponent.showDialog(passwordForgetResponse.message ?? "", context);

      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordOtp(
          verify_by: _send_code_by,
          email_or_code: _send_code_by == 'email' ? email : _phone,
        );
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final _screen_width = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MyTheme.brandBackground(
          context: context,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80.0, bottom: 20),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                              color: MyTheme.golden.withOpacity(0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: MyTheme.golden.withOpacity(0.15),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Image.asset(
                            'assets/login_registration_form_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Column(
                        children: [
                          Text(
                            "Forget Password ?",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                MyTheme.golden,
                                Colors.transparent
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: _screen_width * (3 / 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              _send_code_by == "email"
                                  ? AppLocalizations.of(context)!
                                      .password_forget_screen_email
                                  : AppLocalizations.of(context)!
                                      .password_forget_screen_phone,
                              style: TextStyle(
                                  color: MyTheme.primary(context),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (_send_code_by == "email")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 36,
                                    child: TextField(
                                      controller: _emailController,
                                      autofocus: false,
                                      style: TextStyle(
                                          color: MyTheme.primaryText(context)),
                                      decoration: InputDecorations
                                          .buildInputDecoration_1(context,
                                              hint_text: "johndoe@example.com"),
                                    ),
                                  ),
                                  AddonConfig.otp_addon_installed
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _send_code_by = "phone";
                                            });
                                          },
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .password_forget_screen_send_code_via_phone,
                                            style: TextStyle(
                                                color: MyTheme.primary(context),
                                                fontWeight: FontWeight.w600,
                                                fontStyle: FontStyle.italic,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        )
                                      : Container()
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 36,
                                    child: CustomInternationalPhoneNumberInput(
                                      onInputChanged: (PhoneNumber number) {
                                        print(number.phoneNumber);
                                        setState(() {
                                          _phone = number.phoneNumber!;
                                        });
                                      },
                                      onInputValidated: (bool value) {
                                        print(value);
                                      },
                                      selectorConfig: const SelectorConfig(
                                        selectorType:
                                            PhoneInputSelectorType.DIALOG,
                                      ),
                                      ignoreBlank: false,
                                      autoValidateMode:
                                          AutovalidateMode.disabled,
                                      selectorTextStyle: TextStyle(
                                          color: MyTheme.primaryText(context)),
                                      textStyle: TextStyle(
                                          color: MyTheme.primaryText(context)),
                                      initialValue: phoneCode,
                                      textFieldController:
                                          _phoneNumberController,
                                      formatInput: true,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              signed: true, decimal: true),
                                      inputDecoration: InputDecorations
                                          .buildInputDecoration_phone(context,
                                              hint_text: "01710 333 558"),
                                      onSaved: (PhoneNumber number) {
                                        print('On Saved: $number');
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _send_code_by = "email";
                                      });
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .password_forget_screen_send_code_via_email,
                                      style: TextStyle(
                                          color: MyTheme.primary(context),
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                          decoration: TextDecoration.underline),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0),
                            child: Container(
                              height: 45,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size(
                                      MediaQuery.of(context).size.width, 50),
                                  backgroundColor: MyTheme.golden,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12.0))),
                                ),
                                child: Text(
                                  "Send Code",
                                  style: TextStyle(
                                      color: MyTheme.isDark(context)
                                          ? const Color(0xFF1A1400)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  onPressSendCode();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
