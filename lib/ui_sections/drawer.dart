import 'package:afriomarkets_cust_app/screens/change_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:afriomarkets_cust_app/screens/profile.dart';
import 'package:afriomarkets_cust_app/screens/order_list.dart';
import 'package:afriomarkets_cust_app/screens/wishlist.dart';

import 'package:afriomarkets_cust_app/screens/login.dart';
import 'package:afriomarkets_cust_app/screens/messenger_list.dart';
import 'package:afriomarkets_cust_app/screens/wallet.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/helpers/auth_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  onTapLogout(context) async {
    AuthHelper().clearUserData();
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Login();
    }));
  }

  /// A subtle horizontal kente-stripe separator
  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              MyTheme.golden.withOpacity(0.4),
              Colors.transparent,
            ]),
          ),
        ),
      );

  /// A premium sidebar menu item
  Widget _menuItem({
    required IconData icon,
    String? assetIcon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFF8B55B),
    Color textColor = const Color(0xFFF0EAD6),
    bool isRed = false,
  }) {
    final ic = isRed ? Colors.redAccent.shade200 : iconColor;
    final tc = isRed ? Colors.redAccent.shade200 : textColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: MyTheme.golden.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            assetIcon != null
                ? Image.asset(assetIcon, height: 18, color: ic)
                : Icon(icon, color: ic, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: tc,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Directionality(
        textDirection:
            app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            // ── Premium Header with gradient silhouette ─────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                  top: safeTop + 24, bottom: 24, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1400),   // Deep earth-black
                    Color(0xFF2A3D0F),   // Forest green midpoint
                    Color(0xFF1F2800),   // Rich dark olive
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // African market silhouette decoration (geometric arcs)
                  Positioned.fill(
                    child: CustomPaint(painter: AfricanSilhouettePainter()),
                  ),
                  // Content
                  is_logged_in.$ == true
                      ? Row(
                          children: [
                            // Avatar with golden glow ring
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: MyTheme.golden.withOpacity(0.45),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    MyTheme.golden.withOpacity(0.2),
                                backgroundImage: (avatar_original.$ != null &&
                                        avatar_original.$
                                            .toString()
                                            .isNotEmpty)
                                    ? NetworkImage(
                                            avatar_original.$
                                                    .toString()
                                                    .startsWith('http')
                                                ? avatar_original.$.toString()
                                                : PathHelper.getImageUrl(
                                                        "${avatar_original.$}") ??
                                                    "")
                                        as ImageProvider
                                    : const AssetImage(
                                        'assets/placeholder.png'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${user_name.$}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user_email.$ != "" && user_email.$ != null
                                        ? "${user_email.$}"
                                        : "${user_phone.$}",
                                    style: TextStyle(
                                      color: MyTheme.golden.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: MyTheme.golden.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: MyTheme.golden.withOpacity(0.4),
                                    width: 1.5),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .main_drawer_not_logged_in,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to sign in',
                                  style: TextStyle(
                                      color: MyTheme.golden.withOpacity(0.75),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),

            // ── Menu Items (scrollable) ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.home_rounded,
                        assetIcon: 'assets/home.png',
                        label: AppLocalizations.of(context)!.main_drawer_home,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Main())),
                      ),
                      _menuItem(
                        icon: Icons.language,
                        assetIcon: 'assets/language.png',
                        label: AppLocalizations.of(context)!
                            .main_drawer_change_language,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChangeLanguage())),
                      ),
                      if (is_logged_in.$ == true) ...[
                        _divider(),
                        _menuItem(
                          icon: Icons.person_rounded,
                          assetIcon: 'assets/profile.png',
                          label: AppLocalizations.of(context)!
                              .main_drawer_profile,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      Profile(show_back_button: true))),
                        ),
                        _menuItem(
                          icon: Icons.receipt_long_rounded,
                          assetIcon: 'assets/order.png',
                          label: AppLocalizations.of(context)!
                              .main_drawer_orders,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      OrderList(from_checkout: false))),
                        ),
                        _menuItem(
                          icon: Icons.favorite_rounded,
                          assetIcon: 'assets/heart.png',
                          label: AppLocalizations.of(context)!
                              .main_drawer_my_wishlist,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Wishlist())),
                        ),
                        _menuItem(
                          icon: Icons.chat_rounded,
                          assetIcon: 'assets/chat.png',
                          label: AppLocalizations.of(context)!
                              .main_drawer_messages,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MessengerList())),
                        ),
                        _menuItem(
                          icon: Icons.account_balance_wallet_rounded,
                          assetIcon: 'assets/wallet.png',
                          label:
                              AppLocalizations.of(context)!.main_drawer_wallet,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Wallet())),
                        ),
                      ],
                      if (is_logged_in.$ == false)
                        _menuItem(
                          icon: Icons.login_rounded,
                          assetIcon: 'assets/login.png',
                          label:
                              AppLocalizations.of(context)!.main_drawer_login,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Login())),
                        ),
                      _divider(),
                      if (is_logged_in.$ == true)
                        _menuItem(
                          icon: Icons.logout_rounded,
                          assetIcon: 'assets/logout.png',
                          label:
                              AppLocalizations.of(context)!.main_drawer_logout,
                          onTap: () => onTapLogout(context),
                          isRed: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer tagline ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'afriomarkets © 2025',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AfricanSilhouettePainter is now exported from my_theme.dart
