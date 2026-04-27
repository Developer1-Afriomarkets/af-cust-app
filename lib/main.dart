import 'package:afriomarkets_cust_app/other_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/splash.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:shared_value/shared_value.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'dart:async';
import 'app_config.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';
import 'package:afriomarkets_cust_app/services/push_notification_service.dart';
import 'package:one_context/one_context.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:afriomarkets_cust_app/providers/locale_provider.dart';
import 'package:afriomarkets_cust_app/providers/theme_provider.dart';
import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';
import 'package:afriomarkets_cust_app/services/navigation_service.dart';
import 'package:afriomarkets_cust_app/services/supabase_service.dart';
import 'lang_config.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  fetch_user() async {
    final result = await MedusaAuthService.getSession();

    if (result.success == true && result.customer != null) {
      final c = result.customer!;
      is_logged_in.$ = true;
      is_logged_in.save();
      user_id.$ = MedusaAuthService.stableId(c['id']);
      user_id.save();
      user_name.$ = '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
      user_name.save();
      user_email.$ = c['email'] ?? "";
      user_email.save();
      user_phone.$ = c['phone'] ?? "";
      user_phone.save();
      avatar_original.$ = ""; // Medusa customer doesn't have avatar by default
      avatar_original.save();
    }
  }

  app_language.load();
  app_mobile_language.load();
  app_language_rtl.load();
  app_theme_mode.load();

  // Supabase and Region initialization
  await SupabaseService.initialize();
  RegionService.detectAndSetRegion();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(
    SharedValue.wrapApp(
      MyApp(),
    ),
  );

  // Perform user session fetching after runApp to ensure SharedValue is initialized
  access_token.load().then((_) {
    fetch_user();
  });
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (OtherConfig.USE_PUSH_NOTIFICATION) {
      Future.delayed(Duration(milliseconds: 100), () async {
        PushNotificationService().initialise();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comfortaaText = GoogleFonts.comfortaaTextTheme(textTheme).copyWith(
      bodyLarge: GoogleFonts.comfortaa(textStyle: textTheme.bodyLarge),
      bodyMedium: GoogleFonts.comfortaa(textStyle: textTheme.bodyMedium, fontSize: 12),
    );
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer2<LocaleProvider, ThemeProvider>(
            builder: (context, localeProvider, themeProvider, snapshot) {
          return MaterialApp(
            builder: OneContext().builder,
            navigatorKey: OneContext().navigator.key,
            title: AppConfig.app_name,
            debugShowCheckedModeBanner: false,
            // Light theme — warm parchment + forest-green
            theme: MyTheme.lightTheme(comfortaaText),
            // Dark theme — earth-black + golden-amber
            darkTheme: MyTheme.darkTheme(comfortaaText),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            locale: localeProvider.locale,
            supportedLocales: LangConfig().supportedLocales(),
            home: Splash(),
            //home: Main(),
          );
        }));
  }
}
