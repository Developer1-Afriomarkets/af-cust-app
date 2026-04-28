import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

import 'package:afriomarkets_cust_app/social_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/custom/input_decorations.dart';
import 'package:afriomarkets_cust_app/custom/intl_phone_input.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:afriomarkets_cust_app/addon_config.dart';
import 'package:afriomarkets_cust_app/screens/registration.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:afriomarkets_cust_app/screens/password_forget.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';
import 'package:afriomarkets_cust_app/helpers/auth_helper.dart';
import 'package:afriomarkets_cust_app/repositories/auth_repository.dart';

import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "email";
  String initialCountry = 'US';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'US', dialCode: "+1");
  String _phone = "";
  bool _isLoading = false;
  bool _obscurePassword = true;

  //controllers
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  onPressedLogin() async {
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.login_screen_email_warning, context);
      return;
    } else if (_login_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.login_screen_phone_warning, context);
      return;
    } else if (password == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.login_screen_password_warning, context);
      return;
    }

    setState(() => _isLoading = true);

    // Use Medusa auth instead of legacy api/v2
    final result = await MedusaAuthService.login(
      _login_by == 'email' ? email : _phone,
      password,
    );

    setState(() => _isLoading = false);

    if (!result.success) {
      ToastComponent.showDialog(result.message ?? 'Login failed', context);
    } else {
      // Sync Medusa customer into SharedValues so the whole app
      // sees the user as logged in.
      AuthHelper().setUserDataFromMedusa(result);

      if (!mounted) return;
      ToastComponent.showDialog('Welcome back!', context);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }

  onPressedFacebookLogin() async {
    /*
    final facebookLogin = FacebookLogin();
    final facebookLoginResult = await facebookLogin.logIn(['email']);

    // ... (rest of the code commented out)
    
    final token = facebookLoginResult.accessToken.token;

    /// for profile details also use the below code
    Uri url = Uri.parse(
        'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=$token');
    final graphResponse = await http.get(url);
    final profile = json.decode(graphResponse.body);
    //print(profile);
    
    var loginResponse = await AuthRepository().getSocialLoginResponse(
        profile['name'], profile['email'], profile['id'].toString());

    if (loginResponse.result == false) {
      ToastComponent.showDialog(loginResponse.message!, context);
    } else {
      ToastComponent.showDialog(loginResponse.message!, context);
      AuthHelper().setUserData(loginResponse);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
    */
    ToastComponent.showDialog(
        "Facebook login is currently unavailable", context);
  }

  onPressedGoogleLogin() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        // you can add extras if you require
      ],
    );

    _googleSignIn.signIn().then((GoogleSignInAccount? acc) async {
      if (acc == null) return;
      GoogleSignInAuthentication _ = await acc.authentication;
      print(acc.id);
      print(acc.email);
      print(acc.displayName);
      print(acc.photoUrl);

      acc.authentication.then((GoogleSignInAuthentication auth) async {
        print(auth.idToken);
        print(auth.accessToken);

        //---------------------------------------------------
        var loginResponse = await AuthRepository().getSocialLoginResponse(
            acc.displayName ?? "", acc.email, auth.accessToken ?? "");

        if (loginResponse.result == false) {
          ToastComponent.showDialog(loginResponse.message!, context);
        } else {
          ToastComponent.showDialog(loginResponse.message!, context);
          AuthHelper().setUserData(loginResponse);
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main();
          }));
        }

        //-----------------------------------
      });
    });
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
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.main_drawer_login,
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
                            _login_by == "email"
                                ? AppLocalizations.of(context)!
                                    .login_screen_email
                                : AppLocalizations.of(context)!
                                    .login_screen_phone,
                            style: TextStyle(
                                color: MyTheme.primary(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_login_by == "email")
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: 48,
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
                                            _login_by = "phone";
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .login_screen_or_login_with_phone,
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
                                  height: 48,
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
                                      print('On Saved: $number');
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _login_by = "email";
                                    });
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .login_screen_or_login_with_email,
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
                            "Password",
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return PasswordForget();
                                  }));
                                },
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .login_screen_forgot_password,
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
                                      AppLocalizations.of(context)!.login_screen_log_in,
                                      style: TextStyle(color: MyTheme.isDark(context) ? const Color(0xFF1A1400) : Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                              onPressed: _isLoading ? null : () => onPressedLogin(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                              child: Text(
                            AppLocalizations.of(context)!
                                .login_screen_or_create_new_account,
                            style: TextStyle(
                                color: MyTheme.medium_grey, fontSize: 12),
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
                                    .login_screen_sign_up,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return Registration();
                                }));
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: SocialConfig.allow_google_login ||
                              SocialConfig.allow_facebook_login,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Center(
                                child: Text(
                              AppLocalizations.of(context)!
                                  .login_screen_login_with,
                               style: TextStyle(
                                  color: MyTheme.secondaryText(context), fontSize: 14),
                            )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Center(
                            child: Container(
                              width: 120,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Visibility(
                                    visible: SocialConfig.allow_google_login,
                                    child: InkWell(
                                      onTap: () {
                                        onPressedGoogleLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child: Image.asset(
                                            "assets/google_logo.png"),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: SocialConfig.allow_facebook_login,
                                    child: InkWell(
                                      onTap: () {
                                        onPressedFacebookLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child: Image.asset(
                                            "assets/facebook_logo.png"),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: false,
                                    child: InkWell(
                                      onTap: () {
                                        // onPressedTwitterLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child: Image.asset(
                                            "assets/twitter_logo.png"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
