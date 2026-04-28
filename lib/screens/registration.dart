import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/custom/input_decorations.dart';
import 'package:afriomarkets_cust_app/custom/intl_phone_input.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:afriomarkets_cust_app/addon_config.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:afriomarkets_cust_app/screens/login.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';
import 'package:afriomarkets_cust_app/helpers/auth_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String _register_by = "email";
  String initialCountry = 'NG';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'NG', dialCode: "+234");

  String _phone = "";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  //controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  onPressSignUp() async {
    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var password_confirm = _passwordConfirmController.text.toString();

    if (name == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.registration_screen_name_warning,
          context);
      return;
    } else if (_register_by == 'email' && email == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.registration_screen_email_warning,
          context);
      return;
    } else if (_register_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.registration_screen_phone_warning,
          context);
      return;
    } else if (password == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.registration_screen_password_warning,
          context);
      return;
    } else if (password_confirm == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .registration_screen_password_confirm_warning,
          context);
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .registration_screen_password_length_warning,
          context);
      return;
    } else if (password != password_confirm) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .registration_screen_password_match_warning,
          context);
      return;
    }

    setState(() => _isLoading = true);

    // Split name into first + last for Medusa
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final result = await MedusaAuthService.register(
      firstName: firstName,
      lastName: lastName,
      email: _register_by == 'email' ? email : '$_phone@phone.afriomarkets.com',
      password: password,
      phone: _register_by == 'phone' ? _phone : null,
    );

    setState(() => _isLoading = false);

    if (!result.success) {
      ToastComponent.showDialog(
          result.message ?? 'Registration failed', context);
    } else {
      // Sync Medusa customer into SharedValues so the whole app
      // sees the user as logged in.
      AuthHelper().setUserDataFromMedusa(result);

      if (!mounted) return;
      ToastComponent.showDialog('Account created successfully!', context);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.only(top: 60.0, bottom: 20),
                    child: Container(
                      width: 120,
                      height: 120,
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
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset(
                          'assets/login_registration_form_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.registration_screen_register_sign_up,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
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
                  Container(
                    width: _screen_width * (3 / 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            AppLocalizations.of(context)!
                                .registration_screen_name,
                            style: TextStyle(
                                color: MyTheme.primary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            height: 36,
                            child: TextField(
                              controller: _nameController,
                              autofocus: false,
                              style: TextStyle(
                                  color: MyTheme.primaryText(context)),
                              decoration:
                                  InputDecorations.buildInputDecoration_1(
                                      context,
                                      hint_text: "John Doe"),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            _register_by == "email"
                                ? AppLocalizations.of(context)!
                                    .registration_screen_email
                                : AppLocalizations.of(context)!
                                    .registration_screen_phone,
                            style: TextStyle(
                                color: MyTheme.primary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_register_by == "email")
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
                                    decoration:
                                        InputDecorations.buildInputDecoration_1(
                                            context,
                                            hint_text: "johndoe@example.com"),
                                  ),
                                ),
                                AddonConfig.otp_addon_installed
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _register_by = "phone";
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .registration_screen_or_register_with_phone,
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
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle: TextStyle(
                                        color: MyTheme.primaryText(context)),
                                    textStyle: TextStyle(
                                        color: MyTheme.primaryText(context)),
                                    initialValue: phoneCode,
                                    textFieldController: _phoneNumberController,
                                    formatInput: true,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            signed: true, decimal: true),
                                    inputDecoration: InputDecorations
                                        .buildInputDecoration_phone(context,
                                            hint_text: "01710 333 558"),
                                    onSaved: (PhoneNumber number) {
                                      //print('On Saved: $number');
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _register_by = "email";
                                    });
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .registration_screen_or_register_with_email,
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
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            AppLocalizations.of(context)!
                                .login_screen_password,
                            style: TextStyle(
                                color: MyTheme.primary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 48,
                                child: TextField(
                                  controller: _passwordController,
                                  autofocus: false,
                                  obscureText: _obscurePassword,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  style: TextStyle(color: MyTheme.primaryText(context)),
                                  decoration: InputDecorations.buildInputDecoration_1(context, hint_text: "• • • • • • • •").copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 18, color: MyTheme.secondaryText(context)),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .registration_screen_password_length_recommendation,
                                style: TextStyle(
                                    color: MyTheme.accent_color,
                                    fontStyle: FontStyle.italic),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            AppLocalizations.of(context)!
                                .registration_screen_retype_password,
                            style: TextStyle(
                                color: MyTheme.primary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            height: 48,
                            child: TextField(
                              controller: _passwordConfirmController,
                              autofocus: false,
                              obscureText: _obscureConfirm,
                              enableSuggestions: false,
                              autocorrect: false,
                              style: TextStyle(color: MyTheme.primaryText(context)),
                              decoration: InputDecorations.buildInputDecoration_1(context, hint_text: "• • • • • • • •").copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18, color: MyTheme.secondaryText(context)),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Terms & Privacy
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: _acceptedTerms ? MyTheme.golden : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: _acceptedTerms ? MyTheme.golden : MyTheme.secondaryText(context)),
                                  ),
                                  child: _acceptedTerms ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 11),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(text: 'Terms of Service', style: TextStyle(color: MyTheme.golden, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                                        const TextSpan(text: ' and '),
                                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: MyTheme.golden, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
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
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      AppLocalizations.of(context)!.registration_screen_register_sign_up,
                                      style: TextStyle(color: MyTheme.isDark(context) ? const Color(0xFF1A1400) : Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                              onPressed: _isLoading ? null : () {
                                if (!_acceptedTerms) {
                                  ToastComponent.showDialog('Please accept the Terms of Service and Privacy Policy', context);
                                  return;
                                }
                                onPressSignUp();
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                              child: Text(
                            AppLocalizations.of(context)!
                                .registration_screen_already_have_account,
                             style: TextStyle(
                                 color: MyTheme.secondaryText(context), fontSize: 12),
                           )),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            height: 45,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize:
                                    Size(MediaQuery.of(context).size.width, 50),
                                backgroundColor: Colors.white.withOpacity(0.1),
                                side: BorderSide(color: MyTheme.golden, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12.0))),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .registration_screen_log_in,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return Login();
                                }));
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  )
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
