import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/cart.dart';
import 'package:afriomarkets_cust_app/screens/category_list.dart';
import 'package:afriomarkets_cust_app/screens/home.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_main.dart';
import 'package:afriomarkets_cust_app/screens/profile.dart';
import 'package:afriomarkets_cust_app/ui_sections/animated_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class Main extends StatefulWidget {
  Main({Key? key, this.go_back = true}) : super(key: key);

  final bool go_back;

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  var _children = [
    Home(),
    CategoryList(
      is_base_category: true,
    ),
    Home(),
    Cart(has_bottomnav: true),
    Profile()
  ];

  void onTapped(int i) {
    setState(() {
      _currentIndex = i;
    });
  }

  void initState() {
    // TODO: implement initState
    //re appear statusbar in case it was not there in the previous page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.go_back,
      child: Directionality(
        textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: AnimatedSidebarScaffold(
          child: Scaffold(
            extendBody: true,
            body: MyTheme.brandBackground(
              context: context,
              child: _children[_currentIndex],
            ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          //specify the location of the FAB
          floatingActionButton: Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom ==
                0.0, // if the keyboard is open then hide, else show
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () {},
              tooltip: "start FAB",
              child: Container(
                decoration: BoxDecoration(
                  color: MyTheme.surface(context),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: MyTheme.primary(context), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: MyTheme.primary(context).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                margin: EdgeInsets.all(0.0),
                child: IconButton(
                  icon: Image.asset('assets/square_logo.png'),
                  tooltip: 'Action',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return ExplorerMain();
                    }));
                  },
                ),
              ),
              elevation: 0.0,
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                onTap: onTapped,
                currentIndex: _currentIndex,
                backgroundColor: MyTheme.isDark(context) 
                    ? MyTheme.darkCard.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.85),
                selectedItemColor: MyTheme.primary(context),
                unselectedItemColor: MyTheme.secondaryText(context),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/home.png",
                        color: _currentIndex == 0
                            ? MyTheme.primary(context)
                            : MyTheme.secondaryText(context),
                        height: 20,
                      ),
                      label: AppLocalizations.of(context)
                              ?.main_screen_bottom_navigation_home ??
                          "Home"),
                  BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/categories.png",
                        color: _currentIndex == 1
                            ? MyTheme.primary(context)
                            : MyTheme.secondaryText(context),
                        height: 20,
                      ),
                      label: AppLocalizations.of(context)
                              ?.main_screen_bottom_navigation_categories ??
                          "Categories"),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.circle,
                      color: Colors.transparent,
                    ),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/cart.png",
                        color: _currentIndex == 3
                            ? MyTheme.primary(context)
                            : MyTheme.secondaryText(context),
                        height: 20,
                      ),
                      label: AppLocalizations.of(context)
                              ?.main_screen_bottom_navigation_cart ??
                          "Cart"),
                  BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/profile.png",
                        color: _currentIndex == 4
                            ? MyTheme.primary(context)
                            : MyTheme.secondaryText(context),
                        height: 20,
                      ),
                      label: AppLocalizations.of(context)
                              ?.main_screen_bottom_navigation_profile ??
                          "Profile"),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
