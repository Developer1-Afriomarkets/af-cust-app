import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/custom/input_decorations.dart';
import 'package:afriomarkets_cust_app/screens/login.dart';
import 'package:afriomarkets_cust_app/repositories/auth_repository.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class Otp extends StatefulWidget {
  Otp({Key? key, this.verify_by = "email", required this.user_id})
      : super(key: key);
  final String verify_by;
  final int user_id;

  @override
  _OtpState createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  //controllers
  TextEditingController _verificationCodeController = TextEditingController();

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
    _verificationCodeController.dispose();
    super.dispose();
  }

  onTapResend() async {
    var resendCodeResponse = await AuthRepository()
        .getResendCodeResponse(widget.user_id, widget.verify_by);

    if (resendCodeResponse.result == false) {
      ToastComponent.showDialog(resendCodeResponse.message ?? "", context);
    } else {
      ToastComponent.showDialog(resendCodeResponse.message ?? "", context);
    }
  }

  onPressConfirm() async {
    var code = _verificationCodeController.text.toString();

    if (code == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.otp_screen_verification_code_warning,
          context);
      return;
    }

    var confirmCodeResponse =
        await AuthRepository().getConfirmCodeResponse(widget.user_id, code);

    if (confirmCodeResponse.result == false) {
      ToastComponent.showDialog(confirmCodeResponse.message ?? "", context);
    } else {
      ToastComponent.showDialog(confirmCodeResponse.message ?? "", context);

      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Login();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    String _verify_by = widget.verify_by; //phone or email
    final _screen_height = MediaQuery.of(context).size.height;
    final _screen_width = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MyTheme.brandBackground(
          context: context,
          child: Stack(
          children: [
            // Container(
            //   width: _screen_width * (3 / 4),
            //   child: Image.asset(
            //       "assets/splash_login_registration_background_image.png"),
            // ),
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
                        border: Border.all(color: MyTheme.golden.withOpacity(0.4), width: 2),
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
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.otp_screen_verify_your} " +
                              (_verify_by == "email"
                                  ? AppLocalizations.of(context)!.otp_screen_email_account
                                  : AppLocalizations.of(context)!.otp_screen_phone_number),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.transparent, MyTheme.golden, Colors.transparent]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                        width: _screen_width * (3 / 4),
                        child: _verify_by == "email"
                            ? Text(
                                AppLocalizations.of(context)!
                                    .otp_screen_enter_verification_code_to_email,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: MyTheme.secondaryText(context), fontSize: 14))
                            : Text(
                                AppLocalizations.of(context)!
                                    .otp_screen_enter_verification_code_to_phone,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: MyTheme.secondaryText(context), fontSize: 14))),
                  ),
                  Container(
                    width: _screen_width * (3 / 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Container(
                                  height: 48,
                                  child: TextField(
                                    controller: _verificationCodeController,
                                    autofocus: false,
                                    style: TextStyle(color: MyTheme.primaryText(context)),
                                    decoration:
                                        InputDecorations.buildInputDecoration_1(context,
                                            hint_text: "A X B 4 J H"),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Container(
                            height: 45,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize:
                                    Size(MediaQuery.of(context).size.width, 50),
                                backgroundColor: MyTheme.golden,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .otp_screen_confirm,
                                style: TextStyle(
                                    color: MyTheme.isDark(context)
                                        ? const Color(0xFF1A1400)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                onPressConfirm();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: InkWell(
                      onTap: () {
                        onTapResend();
                      },
                      child: Text(
                          AppLocalizations.of(context)!.otp_screen_resend_code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: MyTheme.primary(context),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              fontSize: 13)),
                    ),
                  ),
                ],
              )),
            )
          ],
        ),
      ),
      ),
    );
  }
}
