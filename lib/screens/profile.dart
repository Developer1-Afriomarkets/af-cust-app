import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_sections/animated_sidebar.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/screens/wallet.dart';
import 'package:afriomarkets_cust_app/screens/profile_edit.dart';
import 'package:afriomarkets_cust_app/screens/address.dart';
import 'package:afriomarkets_cust_app/screens/order_list.dart';
import 'package:afriomarkets_cust_app/screens/club_point.dart';
import 'package:afriomarkets_cust_app/screens/refund_request.dart';
import 'package:afriomarkets_cust_app/screens/region_picker.dart';
import 'package:afriomarkets_cust_app/repositories/profile_repository.dart';

import 'package:afriomarkets_cust_app/addon_config.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:afriomarkets_cust_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  Profile({Key? key, this.show_back_button = false}) : super(key: key);

  final bool show_back_button;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _mainScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  int _cartCounter = 0;
  String _cartCounterString = "...";
  int _wishlistCounter = 0;
  String _wishlistCounterString = "...";
  int _orderCounter = 0;
  String _orderCounterString = "...";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  fetchAll() {
    fetchCounters();
  }

  fetchCounters() async {
    var profileCountersResponse =
        await ProfileRepository().getProfileCountersResponse();

    _cartCounter = profileCountersResponse.cart_item_count ?? 0;
    _wishlistCounter = profileCountersResponse.wishlist_item_count ?? 0;
    _orderCounter = profileCountersResponse.order_count ?? 0;

    _cartCounterString =
        counterText(_cartCounter.toString(), default_length: 2);
    _wishlistCounterString =
        counterText(_wishlistCounter.toString(), default_length: 2);
    _orderCounterString =
        counterText(_orderCounter.toString(), default_length: 2);

    setState(() {});
  }

  String counterText(String txt, {default_length = 3}) {
    var blank_zeros = default_length == 3 ? "000" : "00";
    var leading_zeros = "";
    if (default_length == 3 && txt.length == 1) {
      leading_zeros = "00";
    } else if (default_length == 3 && txt.length == 2) {
      leading_zeros = "0";
    } else if (default_length == 2 && txt.length == 1) {
      leading_zeros = "0";
    }

    var newtxt = (txt == "") ? blank_zeros : txt;

    // print(txt + " " + default_length.toString());
    // print(newtxt);

    if (default_length > txt.length) {
      newtxt = leading_zeros + newtxt;
    }
    //print(newtxt);

    return newtxt;
  }

  reset() {
    _cartCounter = 0;
    _cartCounterString = "...";
    _wishlistCounter = 0;
    _wishlistCounterString = "...";
    _orderCounter = 0;
    _orderCounterString = "...";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.background(context),
        appBar: buildAppBar(context),
        body: buildBody(context),
      ),
    );
  }

  buildBody(context) {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.profile_screen_please_log_in,
            style: TextStyle(color: MyTheme.secondaryText(context)),
          )));
    } else {
      return RefreshIndicator(
        color: MyTheme.primary(context),
        backgroundColor: MyTheme.surface(context),
        onRefresh: _onPageRefresh,
        displacement: 10,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                buildTopSection(),
                buildCountersRow(),
                const SizedBox(height: 16),
                buildHorizontalMenu(),
                const SizedBox(height: 24),

                // ─── Settings & Preferences ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Settings & Preferences",
                        style: TextStyle(
                            color: MyTheme.primaryText(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      // ─── Appearance ───
                      Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
                        return _buildProfileCard(
                          context,
                          onTap: () => _showThemeDialog(context, themeProvider),
                          icon: app_theme_mode.$ == "dark"
                              ? Icons.dark_mode
                              : app_theme_mode.$ == "light"
                                  ? Icons.light_mode
                                  : Icons.brightness_auto,
                          iconBgColor: const Color(0xFFE48629),
                          title: "Appearance",
                          subtitle: app_theme_mode.$ == "dark"
                              ? "Dark Mode"
                              : app_theme_mode.$ == "light"
                                  ? "Light Mode"
                                  : "System Default",
                        );
                      }),
                      const SizedBox(height: 12),
                      // ─── Region & Currency ───
                      _buildProfileCard(
                        context,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return const RegionPicker();
                          }));
                        },
                        icon: Icons.public,
                        iconBgColor: const Color(0xFF3D8B7A),
                        title: "Region & Currency",
                        subtitle: "Manage your localization settings",
                      ),
                      const SizedBox(height: 12),
                      // ─── Purchase History ───
                      _buildProfileCard(
                        context,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return OrderList();
                          }));
                        },
                        icon: Icons.credit_card_rounded,
                        iconBgColor: Colors.green,
                        title: AppLocalizations.of(context)!.profile_screen_purchase_history,
                        subtitle: "View your past orders",
                      ),
                      // ─── Addons ───
                      if (AddonConfig.club_point_addon_installed) ...[
                        const SizedBox(height: 12),
                        _buildProfileCard(
                          context,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Clubpoint();
                            }));
                          },
                          icon: Icons.monetization_on_outlined,
                          iconBgColor: Colors.orange,
                          title: AppLocalizations.of(context)!.profile_screen_earning_points,
                          subtitle: "Check your rewards",
                        ),
                      ],
                      if (AddonConfig.refund_addon_installed) ...[
                        const SizedBox(height: 12),
                        _buildProfileCard(
                          context,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return RefundRequest();
                            }));
                          },
                          icon: Icons.double_arrow,
                          iconBgColor: Colors.pinkAccent,
                          title: AppLocalizations.of(context)!.profile_screen_refund_requests,
                          subtitle: "Manage your returns",
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 140), // Prevent obstruction by bottom appbar
              ]),
            )
          ],
        ),
      );
    }
  }

  buildHorizontalMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return OrderList();
            }));
          },
          child: Column(
            children: [
              Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: MyTheme.surface(context).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: MyTheme.golden.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: MyTheme.isDark(context) ? MyTheme.golden : Colors.green.shade700,
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_orders,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MyTheme.primaryText(context), fontWeight: FontWeight.w600, fontSize: 11),
                ),
              )
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ProfileEdit();
            })).then((value) {
              onPopped(value);
            });
          },
          child: Column(
            children: [
              Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: MyTheme.surface(context).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: MyTheme.golden.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.person,
                      color: MyTheme.isDark(context) ? MyTheme.golden : Colors.blueAccent.shade700,
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_profile,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MyTheme.primaryText(context), fontWeight: FontWeight.w600, fontSize: 11),
                ),
              )
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Address();
            }));
          },
          child: Column(
            children: [
              Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: MyTheme.surface(context).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: MyTheme.golden.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.location_on,
                      color: MyTheme.isDark(context) ? MyTheme.golden : Colors.amber.shade700,
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_address,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MyTheme.primaryText(context), fontWeight: FontWeight.w600, fontSize: 11),
                ),
              )
            ],
          ),
        ),
        /*InkWell(
          onTap: () {
            ToastComponent.showDialog("Coming soon", context);
          },
          child: Column(
            children: [
              Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: MyTheme.light_grey,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        Icon(Icons.message_outlined, color: Colors.redAccent),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Message",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MyTheme.font_grey, fontWeight: FontWeight.w300),
                ),
              )
            ],
          ),
        ),*/
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, {required VoidCallback onTap, required IconData icon, required Color iconBgColor, required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                  height: 36, width: 36,
                  decoration: BoxDecoration(
                      color: iconBgColor.withOpacity(0.15), shape: BoxShape.circle,
                      border: Border.all(color: iconBgColor.withOpacity(0.3))),
                  child: Icon(icon, color: iconBgColor, size: 18)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: MyTheme.secondaryText(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: MyTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Appearance",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MyTheme.primaryText(context)),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(context, themeProvider, "light", Icons.light_mode, "Light Mode"),
              _buildThemeOption(context, themeProvider, "dark", Icons.dark_mode, "Dark Mode"),
              _buildThemeOption(context, themeProvider, "system", Icons.brightness_auto, "System Default"),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider themeProvider, String value, IconData icon, String label) {
    bool isSelected = app_theme_mode.$ == value;
    return InkWell(
      onTap: () {
        themeProvider.setThemeMode(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? MyTheme.primary(context).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? MyTheme.primary(context) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? MyTheme.primary(context) : MyTheme.secondaryText(context)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MyTheme.primary(context) : MyTheme.primaryText(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: MyTheme.primary(context), size: 20),
          ],
        ),
      ),
    );
  }

  buildCountersRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _cartCounterString,
                style: TextStyle(
                    fontSize: 18,
                    color: MyTheme.primaryText(context),
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_in_your_cart,
                  style: TextStyle(
                    color: MyTheme.secondaryText(context),
                    fontSize: 12,
                  ),
                )),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _wishlistCounterString,
                style: TextStyle(
                    fontSize: 18,
                    color: MyTheme.primaryText(context),
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_in_wishlist,
                  style: TextStyle(
                    color: MyTheme.secondaryText(context),
                    fontSize: 12,
                  ),
                )),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _orderCounterString,
                style: TextStyle(
                    fontSize: 18,
                    color: MyTheme.primaryText(context),
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_in_ordered,
                  style: TextStyle(
                    color: MyTheme.secondaryText(context),
                    fontSize: 12,
                  ),
                )),
          ],
        )
      ],
    );
  }

  buildTopSection() {
    final isDark = MyTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MyTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Decorative circle behind avatar
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
                  ),
                  child: CustomPaint(
                    painter: AfricanSilhouettePainter(
                      baseColor: MyTheme.golden,
                      opacity: 0.4,
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 3),
                  ),
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(100.0)),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: PathHelper.getImageUrlSafe("${avatar_original.$}"),
                        fit: BoxFit.cover,
                      )),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: MyTheme.golden,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Color(0xFF1A1400)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "${user_name.$}",
              style: TextStyle(
                  fontSize: 18,
                  color: MyTheme.primaryText(context),
                  fontWeight: FontWeight.w700),
            ),
            if (user_name.$ != "" && user_name.$ != null)
              Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                        user_email.$.isNotEmpty ? user_email.$ : user_phone.$,
                        style: TextStyle(
                          color: MyTheme.secondaryText(context),
                          fontSize: 13,
                        ),
                      )),
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: MyTheme.primary(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  AppLocalizations.of(context)!.profile_screen_check_balance.toUpperCase(),
                  style: TextStyle(
                      color: isDark ? const Color(0xFF1A1400) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Wallet();
                  }));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return AppBar(
      backgroundColor: isDark ? MyTheme.darkCard : MyTheme.accent_color,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden,
                  opacity: isDark ? 0.3 : 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        child: widget.show_back_button
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    AnimatedSidebarScaffold.of(context)?.toggleMenu();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18.0, horizontal: 0.0),
                    child: Center(
                      child: Image.asset(
                        'assets/hamburger.png',
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      title: Text(
        AppLocalizations.of(context)!.profile_screen_account,
        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
