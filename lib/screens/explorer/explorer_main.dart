import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_overview.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_browse.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_more.dart'; // Contains ExplorerDiscover
import 'package:afriomarkets_cust_app/screens/explorer/explorer_immersive_view.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';
import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';

/// The root scaffold for the Explorer Subsystem.
/// Manages the `ExplorerContext` and the bottom navigation between
/// Overview, Browse (Filter), and More.
class ExplorerMain extends StatefulWidget {
  final ExplorerContext? initialContext;

  const ExplorerMain({Key? key, this.initialContext}) : super(key: key);

  @override
  _ExplorerMainState createState() => _ExplorerMainState();
}

class _ExplorerMainState extends State<ExplorerMain> {
  late ExplorerContext _currentContext;
  int _currentIndex = 0;

  // ── Blended AppBar state ─────────────────────────────────────────────────
  // Shared scroll controller: ExplorerOverview feeds scroll offset back here
  // so the outer AppBar can fade between transparent (over hero) and surface.
  final ScrollController _overviewScrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _currentContext = widget.initialContext ?? ExplorerContext();
    _overviewScrollController.addListener(_onOverviewScrolled);
  }

  void _onOverviewScrolled() {
    // Hero is ~46% of screen height. Fade starts at 80px, completes at 220px.
    final ratio = ((_overviewScrollController.offset - 80.0) / 140.0).clamp(0.0, 1.0);
    if ((ratio - _appBarOpacity).abs() > 0.01) {
      setState(() => _appBarOpacity = ratio);
    }
  }

  /// Launches the fullscreen immersive explorer from the Overview hero.
  /// Shows a loading overlay immediately so the user has instant feedback
  /// while states/markets are fetched asynchronously.
  void _launchImmersiveView() async {
    if (!mounted) return;

    // ── Show immediate loading overlay ───────────────────────────────────────
    // The async fetch can take 0.5–2s. Without this the user sees nothing
    // and thinks the gesture didn't register.
    final overlayState = Overlay.of(context);
    late OverlayEntry loadingOverlay;
    loadingOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.75),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                const SizedBox(height: 14),
                const Text(
                  'Preparing Explorer...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlayState.insert(loadingOverlay);

    // ── Fetch data ────────────────────────────────────────────────────────────
    final repo = ExplorerRepository();
    List<dynamic> items;
    ExplorerLevel level;

    try {
      if (_currentContext.isAtStateLevel) {
        items = await repo.getMarketsByState(_currentContext.selectedState!.id);
        level = ExplorerLevel.state;
      } else {
        items = await repo.getStates();
        level = ExplorerLevel.region;
      }
    } catch (e) {
      items = [];
      level = ExplorerLevel.region;
      debugPrint('[ImmersiveView] fetch error: $e');
    }

    loadingOverlay.remove();
    if (!mounted) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations available to explore right now'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: ExplorerImmersiveView(
              initialContext: _currentContext,
              onContextChanged: _onContextChanged,
              items: items,
              level: level,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _overviewScrollController.removeListener(_onOverviewScrolled);
    _overviewScrollController.dispose();
    super.dispose();
  }

  void _onContextChanged(ExplorerContext newContext) {
    setState(() {
      _currentContext = newContext;
      // Reset AppBar opacity when context changes (new hero imagery)
      _appBarOpacity = 0.0;
    });
  }

  Future<List<dynamic>> _fetchModalData() async {
    final repo = ExplorerRepository();
    if (_currentContext.isAtRegionLevel) {
      return await RegionService.fetchRegions();
    }
    if (_currentContext.selectedState != null && _currentContext.selectedMarket != null) {
       return await repo.getMarketsByState(_currentContext.selectedState!.id.toString());
    }
    return await repo.getStates();
  }

  void _showContextSwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        String modalTitle = "Switch State";
        if (_currentContext.isAtRegionLevel) modalTitle = "Switch Region";
        else if (_currentContext.isAtStoreLevel || _currentContext.isAtMarketLevel) modalTitle = "Switch Market";

        return Container(
          decoration: BoxDecoration(
            color: MyTheme.surface(ctx),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: MyTheme.border(ctx), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      modalTitle, 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w800,
                        color: MyTheme.primaryText(ctx),
                        letterSpacing: -0.5,
                      )
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: MyTheme.primaryText(ctx)), 
                      onPressed: () => Navigator.pop(ctx)
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _fetchModalData(),
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                     if (!snapshot.hasData || (snapshot.data as List).isEmpty) return const Center(child: Text("No locations found."));
                     
                     final list = snapshot.data as List;
                     return ListView.builder(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       itemCount: list.length,
                       itemBuilder: (context, index) {
                         final item = list[index];
                         String name = "";
                         Widget? leading;
                         
                         if (item is MedusaRegion) {
                           name = item.name ?? "";
                           leading = Text(item.countries.isNotEmpty ? _flagEmoji(item.countries.first.iso2) : '🌍', style: const TextStyle(fontSize: 20));
                         } else if (item is StateModel) {
                           name = item.stateName;
                           leading = Icon(Icons.location_city, color: MyTheme.primary(context));
                         } else if (item is MarketModel) {
                           name = item.marketName;
                           leading = Icon(Icons.storefront, color: MyTheme.primary(context));
                         } else if (item is Shop) {
                           name = item.name ?? "";
                           leading = Icon(Icons.shopping_bag, color: MyTheme.primary(context));
                         }
                         
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: MyTheme.background(context).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: leading,
                              title: Text(
                                name, 
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: MyTheme.primaryText(context),
                                )
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onTap: () async {
                                Navigator.pop(ctx);
                                if (item is MedusaRegion) {
                                  final countryCode = item.countries.isNotEmpty ? item.countries.first.iso2 : 'ng';
                                  await RegionService.setRegion(item, countryCode);
                                  _onContextChanged(ExplorerContext()); // Reset to region level
                                }
                                else if (item is StateModel) _onContextChanged(_currentContext.withState(item));
                                else if (item is MarketModel) _onContextChanged(ExplorerContext(selectedState: _currentContext.selectedState, selectedMarket: item));
                                else if (item is Shop) _onContextChanged(_currentContext.withStore(item));
                              }
                            ),
                          );
                        }
                      );
                    }
                  )
                )
            ],
          )
        );
      }
    );
  }

  // Country flag emoji helper (copied from RegionPicker for consistency)
  static String _flagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';
    final int firstChar = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondChar = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }

  void _onBottomTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Builds the top AppBar based on the current context.
  PreferredSizeWidget _buildAppBar() {
    String title = RegionService.currentRegionSync?.name ?? "African Markets";
    if (_currentContext.isAtStoreLevel) {
      title = _currentContext.selectedStore?.name ?? title;
    } else if (_currentContext.isAtMarketLevel) {
      title = _currentContext.selectedMarket?.marketName ?? title;
    } else if (_currentContext.isAtStateLevel) {
      title = _currentContext.selectedState?.stateName ?? title;
    }

    // On the Overview tab the AppBar floats over the hero image.
    // It starts fully transparent (icons white) and fades to a surface
    // background as the user scrolls past the hero.
    final bool isOverview = _currentIndex == 0;
    final double bgOpacity = isOverview ? _appBarOpacity : 1.0;
    final Color iconColor = isOverview && _appBarOpacity < 0.45
        ? Colors.white
        : MyTheme.primaryText(context);
    final Color surfaceBg = MyTheme.surface(context).withOpacity(bgOpacity);

    return AppBar(
      systemOverlayStyle: isOverview && _appBarOpacity < 0.45
          ? SystemUiOverlayStyle.light
          : (MyTheme.isDark(context)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      backgroundColor: surfaceBg,
      centerTitle: true,
      elevation: bgOpacity > 0.6 ? 2 : 0,
      shadowColor: Colors.black.withOpacity(0.12),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: iconColor),
        onPressed: () {
          if (!_currentContext.isAtRegionLevel) {
            _onContextChanged(_currentContext.pop());
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: InkWell(
        onTap: _showContextSwitcherModal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
                shadows: isOverview && _appBarOpacity < 0.45
                    ? [const Shadow(color: Colors.black54, blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: iconColor, size: 20),
          ],
        ),
      ),
      // Bottom divider only appears once the surface background is visible
      bottom: bgOpacity > 0.5
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: MyTheme.border(context), height: 1.0),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ExplorerOverview(
          explorerContext: _currentContext,
          onContextChanged: _onContextChanged,
          // Shared scroll controller drives the AppBar opacity blend
          scrollController: _overviewScrollController,
          // Called when user overscrolls downward on the hero
          onImmersiveRequested: _launchImmersiveView,
        );
      case 1:
        return ExplorerBrowse(explorerContext: _currentContext);
      case 2:
      default:
        return ExplorerDiscover(
          explorerContext: _currentContext,
          onContextChanged: _onContextChanged,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Extend body behind AppBar so the hero imagery bleeds under the
      // transparent AppBar on the Overview tab.
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: MyTheme.brandBackground(
        context: context,
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomTapped,
        backgroundColor: MyTheme.surface(context),
        selectedItemColor: MyTheme.primary(context),
        unselectedItemColor: MyTheme.secondaryText(context),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Overview",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(Icons.search_rounded),
            label: "Browse",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: "Discover",
          ),
        ],
      ),
    );
  }
}
