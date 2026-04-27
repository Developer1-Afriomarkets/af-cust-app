import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_overview.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_browse.dart';
import 'package:afriomarkets_cust_app/screens/explorer/explorer_more.dart';
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

  @override
  void initState() {
    super.initState();
    _currentContext = widget.initialContext ?? ExplorerContext();
  }

  void _onContextChanged(ExplorerContext newContext) {
    setState(() {
      _currentContext = newContext;
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

    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: MyTheme.primaryText(context)),
        onPressed: () {
          if (!_currentContext.isAtRegionLevel) {
            // Pop context level instead of navigating back completely
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
                color: MyTheme.primaryText(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: MyTheme.primaryText(context), size: 20),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: MyTheme.border(context),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ExplorerOverview(
          explorerContext: _currentContext,
          onContextChanged: _onContextChanged,
        );
      case 1:
        return ExplorerBrowse(explorerContext: _currentContext);
      case 2:
      default:
        return ExplorerMore(explorerContext: _currentContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: "More",
          ),
        ],
      ),
    );
  }
}
