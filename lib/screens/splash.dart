import 'dart:ui';

import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/helpers/auth_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:afriomarkets_cust_app/screens/onboarding.dart';
import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    _initPackageInfo();
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
    });
  }

  /// Restore a persisted Medusa session (if any), then navigate to correct destination.
  Future<Widget> _loadSession() async {
    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 2));

    final sessionResult = await MedusaAuthService.getSession();
    if (sessionResult.success) {
      AuthHelper().setUserDataFromMedusa(sessionResult);
    }

    // First-launch → show onboarding
    if (has_seen_onboarding.$ != true) {
      return OnboardingScreen();
    }
    return Main();
  }

  @override
  Widget build(BuildContext context) {
    return CustomSplashScreen(
      navigateAfterFuture: _loadSession(),
      title: Text(
        "V " + (_packageInfo?.version ?? "Unknown"),
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.white),
      ),
      useLoader: true,
      loadingText: Text(
        AppConfig.copyright_text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      image: Image.asset("assets/splash_screen_logo.png"),
      // Earth-black → dark forest green = logo pops, no green-on-green clash
      gradientBackground: const LinearGradient(
        colors: [Color(0xFF161000), Color(0xFF1C2E08)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      photoSize: 60.0,
      backgroundPhotoSize: 140.0,
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  /// Seconds to navigate after for time based navigation
  final int seconds;

  /// App title, shown in the middle of screen in case of no image available
  final Text title;

  /// Page background color
  final Color backgroundColor;

  /// Style for the laodertext
  final TextStyle styleTextUnderTheLoader;

  /// The page where you want to navigate if you have chosen time based navigation
  final dynamic navigateAfterSeconds;

  /// Main image size
  final double photoSize;

  final double backgroundPhotoSize;

  /// Triggered if the user clicks the screen
  final dynamic onClick;

  /// Loader color
  final Color loaderColor;

  /// Main image mainly used for logos and like that
  final Image? image;

  final Image? backgroundImage;

  /// Loading text, default: "Loading"
  final Text loadingText;

  ///  Background image for the entire screen
  final ImageProvider? imageBackground;

  /// Background gradient for the entire screen
  final Gradient? gradientBackground;

  /// Whether to display a loader or not
  final bool useLoader;

  /// Custom page route if you have a custom transition you want to play
  final dynamic pageRoute;

  /// RouteSettings name for pushing a route with custom name (if left out in MaterialApp route names) to navigator stack (Contribution by Ramis Mustafa)
  final String? routeName;

  /// expects a function that returns a future, when this future is returned it will navigate
  final Future<dynamic>? navigateAfterFuture;

  /// Use one of the provided factory constructors instead of.
  @protected
  CustomSplashScreen({
    this.loaderColor = Colors.black,
    this.navigateAfterFuture,
    this.seconds = 3,
    this.photoSize = 100.0,
    this.backgroundPhotoSize = 100.0,
    this.pageRoute = const RouteSettings(name: "/"),
    this.onClick,
    this.navigateAfterSeconds,
    this.title = const Text(''),
    this.backgroundColor = Colors.white,
    this.styleTextUnderTheLoader = const TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
    this.image,
    this.backgroundImage,
    this.loadingText = const Text(""),
    this.imageBackground,
    this.gradientBackground,
    this.useLoader = true,
    this.routeName,
  });

  factory CustomSplashScreen.timer(
          {required int seconds,
          Color? loaderColor,
          Color? backgroundColor,
          double? photoSize,
          Text? loadingText,
          Image? image,
          Route? pageRoute,
          dynamic onClick,
          dynamic navigateAfterSeconds,
          Text? title,
          TextStyle? styleTextUnderTheLoader,
          ImageProvider? imageBackground,
          Gradient? gradientBackground,
          bool useLoader = true,
          String? routeName}) =>
      CustomSplashScreen(
        loaderColor: loaderColor ?? Colors.black,
        seconds: seconds,
        photoSize: photoSize ?? 100.0,
        loadingText: loadingText ?? const Text(""),
        backgroundColor: backgroundColor ?? Colors.white,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title ?? const Text(''),
        styleTextUnderTheLoader: styleTextUnderTheLoader ??
            const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  factory CustomSplashScreen.network(
          {@required Future<dynamic>? navigateAfterFuture,
          Color? loaderColor,
          Color? backgroundColor,
          double? photoSize,
          double? backgroundPhotoSize,
          Text? loadingText,
          Image? image,
          Route? pageRoute,
          dynamic onClick,
          dynamic navigateAfterSeconds,
          Text? title,
          TextStyle? styleTextUnderTheLoader,
          ImageProvider? imageBackground,
          Gradient? gradientBackground,
          bool useLoader = true,
          String? routeName}) =>
      CustomSplashScreen(
        loaderColor: loaderColor ?? Colors.black,
        navigateAfterFuture: navigateAfterFuture,
        photoSize: photoSize ?? 100.0,
        backgroundPhotoSize: backgroundPhotoSize ?? 100.0,
        loadingText: loadingText ?? const Text(""),
        backgroundColor: backgroundColor ?? Colors.white,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title ?? const Text(''),
        styleTextUnderTheLoader: styleTextUnderTheLoader ??
            const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.routeName != null &&
        widget.routeName is String &&
        widget.routeName!.isNotEmpty &&
        "${widget.routeName![0]}" != "/") {
      throw ArgumentError(
          "widget.routeName must be a String beginning with forward slash (/)");
    }
    if (widget.navigateAfterFuture == null) {
      Timer(Duration(seconds: widget.seconds), () {
        if (!mounted) return;
        if (widget.navigateAfterSeconds is String) {
          // It's fairly safe to assume this is using the in-built material
          // named route component
          Navigator.of(context)
              .pushReplacementNamed(widget.navigateAfterSeconds);
        } else if (widget.navigateAfterSeconds is Widget) {
          Navigator.of(context).pushReplacement(
              widget.pageRoute is Route<dynamic>
                  ? widget.pageRoute as Route<dynamic>
                  : MaterialPageRoute(
                      settings: widget.pageRoute is RouteSettings
                          ? widget.pageRoute as RouteSettings
                          : (widget.routeName != null
                              ? RouteSettings(name: "${widget.routeName}")
                              : null),
                      builder: (BuildContext context) =>
                          widget.navigateAfterSeconds));
        } else {
          throw ArgumentError(
              'widget.navigateAfterSeconds must either be a String or Widget');
        }
      });
    } else {
      widget.navigateAfterFuture?.then((navigateTo) {
        if (!mounted) return;
        if (navigateTo is String) {
          // It's fairly safe to assume this is using the in-built material
          // named route component
          Navigator.of(context).pushReplacementNamed(navigateTo);
        } else if (navigateTo is Widget) {
          Navigator.of(context).pushReplacement(
              widget.pageRoute is Route<dynamic>
                  ? widget.pageRoute as Route<dynamic>
                  : MaterialPageRoute(
                      settings: widget.pageRoute is RouteSettings
                          ? widget.pageRoute as RouteSettings
                          : (widget.routeName != null
                              ? RouteSettings(name: "${widget.routeName}")
                              : null),
                      builder: (BuildContext context) => navigateTo));
        } else {
          throw ArgumentError(
              'widget.navigateAfterFuture must either be a String or Widget');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: InkWell(
          onTap: widget.onClick,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  image: widget.imageBackground == null
                      ? null
                      : DecorationImage(
                          fit: BoxFit.cover,
                          image: widget.imageBackground!,
                        ),
                  gradient: widget.gradientBackground,
                  color: widget.backgroundColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Hero(
                      tag: "backgroundImageInSplash",
                      child: Container(child: widget.backgroundImage),
                    ),
                    radius: widget.backgroundPhotoSize,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 120.0),
                    child: Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 60.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Hero(
                                  tag: "splashscreenImage",
                                  child: Container(child: widget.image),
                                ),
                                radius: widget.photoSize,
                              ),
                            ),
                            widget.title,
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                            ),
                            widget.loadingText
                          ],
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
