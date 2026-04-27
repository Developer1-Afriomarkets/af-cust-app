import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Afriomarkets Design System
/// Palette: Earth-black (#161000), Forest-green (#344F16), Golden-amber (#F8B55B)
/// Typography: Comfortaa (existing)
class MyTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // Core Brand Palette
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color accent_color = Color(0xFF344F16);       // Forest green (primary)
  static const Color soft_accent_color = Color(0xFFE48629);  // Orange (secondary CTAs)
  static const Color splash_screen_color = Color(0xFF161000);// Earth-black
  static const Color secondary_color = Color(0xFFE48629);
  static const Color accent_brown = Color(0xFF371409);
  static const Color golden = Color(0xFFF8B55B);             // Warm amber
  static const Color gold_highlight = Color(0xFFF8B55B);
  static const Color sidebar_bg = Color(0xFF161000);
  static const Color sidebar_item_color = Color(0xFFF8B55B);

  // ═══════════════════════════════════════════════════════════════════════════
  // African Marketplace Palette
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color teal_accent = Color(0xFF3D8B7A);
  static const Color market_green = Color(0xFF048630);
  static const Color market_red = Color(0xFF861B04);
  static const Color market_blue = Color(0xFF043086);
  static const Color market_teal = Color(0xFF04865F);
  static const Color market_amber = Color(0xFF866204);
  static const Color market_purple = Color(0xFF5B2C6F);
  static const Color market_coral = Color(0xFFE74C3C);

  static const List<Color> marketCardColors = [
    Color(0xFF048630), Color(0xFF861B04), Color(0xFF043086),
    Color(0xFF04865F), Color(0xFF866204), Color(0xFF5B2C6F),
    Color(0xFF3D8B7A),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // Light Mode Surface Palette
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  /// Page / scaffold background (light)
  static const Color lightBg = Color(0xFFF7F4EE);     // Warm parchment
  /// Card surface (light)
  static const Color lightCard = Color(0xFFFFFFFF);
  /// Light dividers / borders
  static const Color lightBorder = Color(0xFFE8E2D6);

  // ═══════════════════════════════════════════════════════════════════════════
  // Dark Mode Surface Palette
  // ═══════════════════════════════════════════════════════════════════════════
  /// Page / scaffold background (dark)
  static const Color darkBg = Color(0xFF0E0C00);       // Near-black earth
  /// Card surface (dark)
  static const Color darkCard = Color(0xFF1C1800);     // Rich dark chocolate
  /// Elevated card / bottomsheet background (dark)
  static const Color darkCardElevated = Color(0xFF252000);
  /// Dark dividers / borders
  static const Color darkBorder = Color(0xFF2E2800);

  // ═══════════════════════════════════════════════════════════════════════════
  // Neutral Palette (retained for backward compat)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color light_grey = Color.fromRGBO(239, 239, 239, 1);
  static const Color dark_grey = Color.fromRGBO(112, 112, 112, 1);
  static const Color medium_grey = Color.fromRGBO(132, 132, 132, 1);
  static const Color medium_grey_50 = Color.fromRGBO(132, 132, 132, .5);
  static const Color grey_153 = Color.fromRGBO(153, 153, 153, 1);
  static const Color font_grey = Color.fromRGBO(73, 73, 73, 1);
  static const Color textfield_grey = Color.fromRGBO(209, 209, 209, 1);
  static Color shimmer_base = Colors.grey.shade50;
  static Color shimmer_highlighted = Colors.grey.shade200;

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Typography & Gradients
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle sectionHeading = const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: Color(0xFF1A1400), letterSpacing: -0.3,
  );

  static TextStyle sectionHeadingDark = const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: Color(0xFFF0EAD6), letterSpacing: -0.3,
  );

  static TextStyle sectionLink = const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: golden,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A2D07), Color(0xFF344F16), Color(0xFF3D8B7A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  /// Sidebar / dark header gradient
  static const LinearGradient drawerGradient = LinearGradient(
    colors: [Color(0xFF1A1400), Color(0xFF2A3D0F), Color(0xFF1F2800)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  /// Card overlay for text readability on images
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // AppBar Gradients (used via ShaderMask or Container decoration)
  // ═══════════════════════════════════════════════════════════════════════════
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF1A2D07), Color(0xFF344F16)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient appBarGradientDark = LinearGradient(
    colors: [Color(0xFF0E0C00), Color(0xFF161000)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ThemeData Factories
  // ═══════════════════════════════════════════════════════════════════════════

  /// Full light ThemeData
  static ThemeData lightTheme(TextTheme baseTextTheme) => ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: accent_color,
    colorScheme: const ColorScheme.light(
      primary: accent_color,
      secondary: golden,
      surface: lightCard,
      background: lightBg,
      error: market_red,
      onPrimary: white,
      onSecondary: Color(0xFF1A1400),
      onSurface: font_grey,
      onBackground: font_grey,
    ),
    cardColor: lightCard,
    dividerColor: lightBorder,
    shadowColor: Colors.black.withOpacity(0.05),
    iconTheme: const IconThemeData(color: accent_color),
    appBarTheme: const AppBarTheme(
      backgroundColor: accent_color,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: white, letterSpacing: 0.2,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: accent_color,
      unselectedItemColor: medium_grey,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBorder,
      selectedColor: accent_color,
      labelStyle: const TextStyle(color: font_grey, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: white, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      labelStyle: const TextStyle(color: medium_grey, fontSize: 14),
      border: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBorder),
          borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBorder),
          borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accent_color, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400),
          borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent_color,
        foregroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent_color),
    ),
    textTheme: baseTextTheme,
    extensions: const [_AfriomMarketsThemeExt(isDark: false)],
  );

  /// Full dark ThemeData
  static ThemeData darkTheme(TextTheme baseTextTheme) => ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: golden,
    colorScheme: const ColorScheme.dark(
      primary: golden,
      secondary: accent_color,
      surface: darkCard,
      background: darkBg,
      error: market_coral,
      onPrimary: Color(0xFF1A1400),
      onSecondary: white,
      onSurface: Color(0xFFF0EAD6),
      onBackground: Color(0xFFD6C9A8),
    ),
    cardColor: darkCard,
    dividerColor: darkBorder,
    shadowColor: Colors.black.withOpacity(0.4),
    iconTheme: const IconThemeData(color: golden),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: const Color(0xFFF0EAD6),
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: golden),
      titleTextStyle: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: Color(0xFFF0EAD6), letterSpacing: 0.2,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: golden,
      unselectedItemColor: Color(0xFF6B6040),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCardElevated,
      selectedColor: golden,
      labelStyle: const TextStyle(color: Color(0xFFD6C9A8), fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: Color(0xFF1A1400), fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      labelStyle: const TextStyle(color: Color(0xFF8A7D60), fontSize: 14),
      border: OutlineInputBorder(
          borderSide: const BorderSide(color: darkBorder),
          borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkBorder),
          borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: golden, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: golden,
        foregroundColor: const Color(0xFF1A1400),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: golden),
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: const Color(0xFFD6C9A8),
      displayColor: const Color(0xFFF0EAD6),
    ),
    extensions: const [_AfriomMarketsThemeExt(isDark: true)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Adaptive helpers (use inside widgets via Theme.of(context))
  // ═══════════════════════════════════════════════════════════════════════════

  /// Surface / card color for current brightness
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;

  /// Background / scaffold color for current brightness
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;

  /// Primary text color for current brightness
  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF0EAD6)
          : font_grey;

  /// Secondary / muted text for current brightness
  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8A7D60)
          : medium_grey;

  /// Border color for current brightness
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  /// Accent/brand primary for current brightness (green in light, gold in dark)
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? golden : accent_color;

  /// Whether we are currently in dark mode
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ═══════════════════════════════════════════════════════════════════════════
  // Brand Decorative Components
  // ═══════════════════════════════════════════════════════════════════════════

  /// A premium background container that applies gradients and silhouettes
  /// based on the current theme brightness.
  static Widget brandBackground({required BuildContext context, required Widget child}) {
    final dark = isDark(context);
    return Stack(
      children: [
        // Base Background
        Positioned.fill(
          child: Container(color: background(context)),
        ),
        // Subtle Gradient Overlay
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: dark
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF1A1400), // Earth black
                        Color(0xFF2A3D0F), // Muted forest green
                        Color(0xFF0E0C00), // Near-black deep earth
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        lightBg,
                        const Color(0xFFE8E2D6).withOpacity(0.5),
                        lightBg
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
          ),
        ),
        // African Silhouette Painter
        Positioned.fill(
          child: Opacity(
            opacity: dark ? 0.6 : 0.35,
            child: CustomPaint(
              painter: AfricanSilhouettePainter(
                baseColor: dark ? golden : accent_color,
                opacity: 1.0,
              ),
            ),
          ),
        ),
        // The actual content
        child,
      ],
    );
  }
}

/// Theme extension — carries the isDark flag through InheritedWidget tree
class _AfriomMarketsThemeExt extends ThemeExtension<_AfriomMarketsThemeExt> {
  final bool isDark;
  const _AfriomMarketsThemeExt({required this.isDark});

  @override
  ThemeExtension<_AfriomMarketsThemeExt> copyWith({bool? isDark}) =>
      _AfriomMarketsThemeExt(isDark: isDark ?? this.isDark);

  @override
  ThemeExtension<_AfriomMarketsThemeExt> lerp(
          ThemeExtension<_AfriomMarketsThemeExt>? other, double t) =>
      this;
}

/// CustomPainter that draws African-inspired kente arc silhouettes.
/// Reusable across any header / hero section.
class AfricanSilhouettePainter extends CustomPainter {
  final Color baseColor;
  final double opacity;
  const AfricanSilhouettePainter(
      {this.baseColor = const Color(0xFFF8B55B), this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..style = PaintingStyle.stroke;

    // Large sweep — bottom right
    stroke
      ..color = Colors.white.withOpacity(0.05 * opacity)
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width * 1.12, size.height * 1.25),
          radius: size.width * 0.72),
      math.pi, math.pi * 0.6, false, stroke,
    );

    // Medium arc — top left
    stroke
      ..color = baseColor.withOpacity(0.09 * opacity)
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(-size.width * 0.1, -size.height * 0.1),
          radius: size.width * 0.56),
      0, math.pi * 0.65, false, stroke,
    );

    // Small inner accent
    stroke
      ..color = baseColor.withOpacity(0.07 * opacity)
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width * 0.85, -size.height * 0.15),
          radius: size.width * 0.30),
      math.pi * 0.5, math.pi, false, stroke,
    );

    // Kente-stripe bands
    final fill = Paint()..style = PaintingStyle.fill;
    fill.color = baseColor.withOpacity(0.07 * opacity);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.82, size.width, 3), fill);
    fill.color = Colors.white.withOpacity(0.04 * opacity);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.88, size.width, 2), fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
