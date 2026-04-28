import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/seller_details.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/store_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/brand_square_card.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:afriomarkets_cust_app/repositories/brand_repository.dart';
import 'package:afriomarkets_cust_app/repositories/shop_repository.dart';
import 'package:afriomarkets_cust_app/helpers/reg_ex_inpur_formatter.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:afriomarkets_cust_app/repositories/search_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:afriomarkets_cust_app/data_model/search_suggestion_response.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';

class WhichFilter {
  String option_key;
  String name;

  WhichFilter(this.option_key, this.name);

  static List<WhichFilter> getWhichFilterList(BuildContext context) {
    return <WhichFilter>[
      WhichFilter(
          'product', AppLocalizations.of(context)!.filter_screen_product),
      WhichFilter(
          'sellers', AppLocalizations.of(context)!.filter_screen_sellers),
      WhichFilter('brands', AppLocalizations.of(context)!.filter_screen_brands),
    ];
  }
}

class Filter extends StatefulWidget {
  Filter({
    Key? key,
    this.selected_filter = "product",
  }) : super(key: key);

  final String selected_filter;

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final _amountValidator = RegExInputFormatter.withRegex(
      '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$');

  ScrollController _productScrollController = ScrollController();
  ScrollController _brandScrollController = ScrollController();
  ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  late WhichFilter _selectedFilter;
  late String
      _givenSelectedFilterOptionKey; // may be it can come from another page
  var _selectedSort = "";

  List<WhichFilter> _which_filter_list = [];
  late List<DropdownMenuItem<WhichFilter>> _dropdownWhichFilterItems;
  List<dynamic> _selectedCategories = [];
  List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = new TextEditingController();
  final TextEditingController _minPriceController = new TextEditingController();
  final TextEditingController _maxPriceController = new TextEditingController();

  //--------------------
  List<dynamic> _filterBrandList = [];
  bool _filteredBrandsCalled = false;
  List<dynamic> _filterCategoryList = [];
  bool _filteredCategoriesCalled = false;

  List<dynamic> _searchSuggestionList = [];

  //----------------------------------------
  String _searchKey = "";

  List<dynamic> _productList = [];
  bool _isProductInitial = true;
  int _productPage = 1;
  int _totalProductData = 0;
  bool _showProductLoadingContainer = false;

  List<dynamic> _brandList = [];
  bool _isBrandInitial = true;
  int _brandPage = 1;
  int _totalBrandData = 0;
  bool _showBrandLoadingContainer = false;

  List<dynamic> _shopList = [];
  bool _isShopInitial = true;
  int _shopPage = 1;
  int _totalShopData = 0;
  bool _showShopLoadingContainer = false;

  //----------------------------------------

  fetchFilteredBrands() async {
    var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
    _filterBrandList.addAll(filteredBrandResponse.brands);
    _filteredBrandsCalled = true;
    setState(() {});
  }

  fetchFilteredCategories() async {
    var filteredCategoriesResponse =
        await CategoryRepository().getFilterPageCategories();
    _filterCategoryList.addAll(filteredCategoriesResponse.categories);
    _filteredCategoriesCalled = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_which_filter_list.isEmpty) {
      init();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _productScrollController.dispose();
    _brandScrollController.dispose();
    _shopScrollController.dispose();
    super.dispose();
  }

  init() {
    _which_filter_list = WhichFilter.getWhichFilterList(context);
    _givenSelectedFilterOptionKey = widget.selected_filter;

    _dropdownWhichFilterItems =
        buildDropdownWhichFilterItems(_which_filter_list);
    _selectedFilter = _dropdownWhichFilterItems[0].value!;

    for (int x = 0; x < _dropdownWhichFilterItems.length; x++) {
      if (_dropdownWhichFilterItems[x].value!.option_key ==
          _givenSelectedFilterOptionKey) {
        _selectedFilter = _dropdownWhichFilterItems[x].value!;
      }
    }

    fetchFilteredCategories();
    fetchFilteredBrands();

    if (_selectedFilter.option_key == "sellers") {
      fetchShopData();
    } else if (_selectedFilter.option_key == "brands") {
      fetchBrandData();
    } else {
      fetchProductData();
    }

    //set scroll listeners

    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        fetchProductData();
      }
    });

    _brandScrollController.addListener(() {
      if (_brandScrollController.position.pixels ==
          _brandScrollController.position.maxScrollExtent) {
        setState(() {
          _brandPage++;
        });
        _showBrandLoadingContainer = true;
        fetchBrandData();
      }
    });

    _shopScrollController.addListener(() {
      if (_shopScrollController.position.pixels ==
          _shopScrollController.position.maxScrollExtent) {
        setState(() {
          _shopPage++;
        });
        _showShopLoadingContainer = true;
        fetchShopData();
      }
    });
  }

  fetchProductData() async {
    //print("sc:"+_selectedCategories.join(",").toString());
    //print("sb:"+_selectedBrands.join(",").toString());
    var productResponse = await ProductRepository().getFilteredProducts(
        page: _productPage,
        name: _searchKey,
        sort_key: _selectedSort,
        brands: _selectedBrands.join(",").toString(),
        categories: _selectedCategories.join(",").toString(),
        max: _maxPriceController.text.toString(),
        min: _minPriceController.text.toString());

    _productList.addAll(productResponse.products);
    _isProductInitial = false;
    _totalProductData = productResponse.meta?.total ?? 0;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  resetProductList() {
    _productList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  fetchBrandData() async {
    var brandResponse =
        await BrandRepository().getBrands(page: _brandPage, name: _searchKey);
    _brandList.addAll(brandResponse.brands);
    _isBrandInitial = false;
    _totalBrandData = brandResponse.meta?.total ?? 0;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  resetBrandList() {
    _brandList.clear();
    _isBrandInitial = true;
    _totalBrandData = 0;
    _brandPage = 1;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  fetchShopData() async {
    var shopResponse =
        await ShopRepository().getShops(page: _shopPage, name: _searchKey);
    _shopList.addAll(shopResponse.shops);
    _isShopInitial = false;
    _totalShopData = shopResponse.meta?.total ?? 0;
    _showShopLoadingContainer = false;
    //print("_shopPage:" + _shopPage.toString());
    //print("_totalShopData:" + _totalShopData.toString());
    setState(() {});
  }

  reset() {
    _searchSuggestionList.clear();
    setState(() {});
  }

  resetShopList() {
    _shopList.clear();
    _isShopInitial = true;
    _totalShopData = 0;
    _shopPage = 1;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onProductListRefresh() async {
    reset();
    resetProductList();
    fetchProductData();
  }

  Future<void> _onBrandListRefresh() async {
    reset();
    resetBrandList();
    fetchBrandData();
  }

  Future<void> _onShopListRefresh() async {
    reset();
    resetShopList();
    fetchShopData();
  }

  _applyProductFilter() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onSearchSubmit() {
    reset();
    if (_selectedFilter.option_key == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  _onSortChange() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onWhichFilterChange() {
    if (_selectedFilter.option_key == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
      List which_filter_list) {
    List<DropdownMenuItem<WhichFilter>> items = [];
    for (WhichFilter which_filter_item in which_filter_list) {
      items.add(
        DropdownMenuItem(
          value: which_filter_item,
          child: Text(which_filter_item.name),
        ),
      );
    }
    return items;
  }

  Container buildProductLoadingContainer() {
    return Container(
      height: _showProductLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(
          _totalProductData == _productList.length
              ? AppLocalizations.of(context)!.common_no_more_products
              : AppLocalizations.of(context)!.common_loading_more_products,
          style: TextStyle(color: MyTheme.secondaryText(context)),
        ),
      ),
    );
  }

  Container buildBrandLoadingContainer() {
    return Container(
      height: _showBrandLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(
          _totalBrandData == _brandList.length
              ? AppLocalizations.of(context)!.common_no_more_brands
              : AppLocalizations.of(context)!.common_loading_more_brands,
          style: TextStyle(color: MyTheme.secondaryText(context)),
        ),
      ),
    );
  }

  Container buildShopLoadingContainer() {
    return Container(
      height: _showShopLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(
          _totalShopData == _shopList.length
              ? AppLocalizations.of(context)!.common_no_more_shops
              : AppLocalizations.of(context)!.common_loading_more_shops,
          style: TextStyle(color: MyTheme.secondaryText(context)),
        ),
      ),
    );
  }

  //--------------------

  @override
  Widget build(BuildContext context) {
    /*print(_appBar.preferredSize.height.toString()+" Appbar height");
    print(kToolbarHeight.toString()+" kToolbarHeight height");
    print(MediaQuery.of(context).padding.top.toString() +" MediaQuery.of(context).padding.top");*/
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.background(context),
        body: Stack(clipBehavior: Clip.none, children: [
          _selectedFilter.option_key == 'product'
              ? buildProductList()
              : (_selectedFilter.option_key == 'brands'
                  ? buildBrandList()
                  : buildShopList()),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: buildAppBar(context),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: _selectedFilter.option_key == 'product'
                  ? buildProductLoadingContainer()
                  : (_selectedFilter.option_key == 'brands'
                      ? buildBrandLoadingContainer()
                      : buildShopLoadingContainer()))
        ]),
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MyTheme.isDark(context) ? const Color(0xFF1B1B1B) : Colors.white,
              MyTheme.isDark(context) ? const Color(0xFF121212) : Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden,
                  opacity: MyTheme.isDark(context) ? 0.05 : 0.03,
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 8),
                buildTopAppbar(context),
                const SizedBox(height: 8),
                buildBottomAppBar(context)
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomAppBar(BuildContext context) {
    final int activeCount = _selectedCategories.length + _selectedBrands.length +
        (_minPriceController.text.isNotEmpty || _maxPriceController.text.isNotEmpty ? 1 : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pill type tabs ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: _which_filter_list.map((f) {
              final active = _selectedFilter.option_key == f.option_key;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = _dropdownWhichFilterItems
                      .firstWhere((d) => d.value!.option_key == f.option_key).value!);
                  _onWhichFilterChange();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: active ? LinearGradient(colors: [MyTheme.market_red, MyTheme.secondary_color]) : null,
                    color: active ? null : MyTheme.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? Colors.transparent : MyTheme.border(context)),
                    boxShadow: active ? [BoxShadow(color: MyTheme.market_red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                  ),
                  child: Text(f.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : MyTheme.secondaryText(context))),
                ),
              );
            }).toList(),
          ),
        ),
        // ── Filter + Sort action row ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedFilter.option_key == 'product') {
                      _showAdvancedFilterSheet();
                    } else {
                      ToastComponent.showDialog(AppLocalizations.of(context)!.filter_screen_sort_warning, context);
                    }
                  },
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: MyTheme.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: activeCount > 0 ? MyTheme.golden : MyTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 14, color: activeCount > 0 ? MyTheme.golden : MyTheme.primaryText(context)),
                        const SizedBox(width: 5),
                        Text(AppLocalizations.of(context)!.filter_screen_filter,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: activeCount > 0 ? MyTheme.golden : MyTheme.primaryText(context))),
                        if (activeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: MyTheme.golden, borderRadius: BorderRadius.circular(10)),
                            child: Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedFilter.option_key == 'product') {
                      _showSortSheet();
                    } else {
                      ToastComponent.showDialog(AppLocalizations.of(context)!.filter_screen_filter_warning, context);
                    }
                  },
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: MyTheme.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _selectedSort.isNotEmpty ? MyTheme.golden : MyTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_vert, size: 14, color: _selectedSort.isNotEmpty ? MyTheme.golden : MyTheme.primaryText(context)),
                        const SizedBox(width: 5),
                        Text('Sort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _selectedSort.isNotEmpty ? MyTheme.golden : MyTheme.primaryText(context))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterTabItem(BuildContext context, {Widget? child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: MediaQuery.of(context).size.width * .3,
        decoration: BoxDecoration(
          color: MyTheme.surface(context).withOpacity(0.05),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: MyTheme.golden.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(child: child),
      ),
    );
  }

  // ── Sort bottom sheet ──────────────────────────────────────────────────
  void _showSortSheet() {
    final options = [
      ("", AppLocalizations.of(context)!.filter_screen_default),
      ("price_high_to_low", AppLocalizations.of(context)!.filter_screen_price_high_to_low),
      ("price_low_to_high", AppLocalizations.of(context)!.filter_screen_price_low_to_high),
      ("new_arrival", AppLocalizations.of(context)!.filter_screen_price_new_arrival),
      ("popularity", AppLocalizations.of(context)!.filter_screen_popularity),
      ("top_rated", AppLocalizations.of(context)!.filter_screen_top_rated),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: MyTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: MyTheme.border(context), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.filter_screen_sort_products_by,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MyTheme.primaryText(context))),
              const SizedBox(height: 12),
              ...options.map((o) {
                final selected = _selectedSort == o.$1;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSort = o.$1);
                    _onSortChange();
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? MyTheme.golden.withOpacity(0.1) : MyTheme.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? MyTheme.golden : MyTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(o.$2, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? MyTheme.golden : MyTheme.primaryText(context)))),
                        if (selected) Icon(Icons.check_circle_rounded, color: MyTheme.golden, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Advanced filter bottom sheet ───────────────────────────────────────
  double _priceRangeMin = 0;
  double _priceRangeMax = 500000;
  final double _priceRangeAbsMax = 500000;

  void _showAdvancedFilterSheet() {
    // Sync current values in
    if (_minPriceController.text.isNotEmpty) {
      _priceRangeMin = double.tryParse(_minPriceController.text) ?? 0;
    }
    if (_maxPriceController.text.isNotEmpty) {
      _priceRangeMax = double.tryParse(_maxPriceController.text) ?? _priceRangeAbsMax;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MyTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: MyTheme.border(context), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Advanced Filter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MyTheme.primaryText(context))),
                        GestureDetector(
                          onTap: () {
                            setSheet(() {
                              _priceRangeMin = 0;
                              _priceRangeMax = _priceRangeAbsMax;
                              _minPriceController.clear();
                              _maxPriceController.clear();
                            });
                            setState(() {
                              _selectedCategories.clear();
                              _selectedBrands.clear();
                            });
                          },
                          child: Text('CLEAR ALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MyTheme.market_red)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Divider(color: MyTheme.border(context)),
                  ],
                ),
              ),
              // Scrollable body
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // ── Price Range ──────────────────────────────────────
                    Text('Price Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MyTheme.primaryText(context))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: MyTheme.background(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: MyTheme.border(context))),
                          child: Text('₦${_priceRangeMin.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyTheme.primaryText(context))),
                        ),
                        Text('—', style: TextStyle(color: MyTheme.secondaryText(context))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: MyTheme.background(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: MyTheme.border(context))),
                          child: Text(_priceRangeMax >= _priceRangeAbsMax ? 'Any' : '₦${_priceRangeMax.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyTheme.primaryText(context))),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: MyTheme.golden,
                        inactiveTrackColor: MyTheme.border(context),
                        thumbColor: MyTheme.golden,
                        overlayColor: MyTheme.golden.withOpacity(0.15),
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                        trackHeight: 4,
                      ),
                      child: RangeSlider(
                        min: 0,
                        max: _priceRangeAbsMax,
                        values: RangeValues(_priceRangeMin, _priceRangeMax),
                        onChanged: (v) {
                          setSheet(() {
                            _priceRangeMin = v.start;
                            _priceRangeMax = v.end;
                            _minPriceController.text = v.start > 0 ? v.start.toStringAsFixed(0) : '';
                            _maxPriceController.text = v.end < _priceRangeAbsMax ? v.end.toStringAsFixed(0) : '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: MyTheme.border(context)),
                    const SizedBox(height: 12),
                    // ── Categories ───────────────────────────────────────
                    Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MyTheme.primaryText(context))),
                    const SizedBox(height: 10),
                    _filterCategoryList.isEmpty
                        ? Text('No categories available', style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _filterCategoryList.map<Widget>((cat) {
                              final selected = _selectedCategories.contains(cat.id);
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.remove(cat.id);
                                    } else {
                                      _selectedCategories.clear();
                                      _selectedCategories.add(cat.id);
                                    }
                                  });
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? MyTheme.golden.withOpacity(0.12) : MyTheme.background(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: selected ? MyTheme.golden : MyTheme.border(context)),
                                  ),
                                  child: Text(cat.name, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      color: selected ? MyTheme.golden : MyTheme.primaryText(context))),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 16),
                    Divider(color: MyTheme.border(context)),
                    const SizedBox(height: 12),
                    // ── Brands ───────────────────────────────────────────
                    Text('Brands', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MyTheme.primaryText(context))),
                    const SizedBox(height: 10),
                    _filterBrandList.isEmpty
                        ? Text('No brands available', style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _filterBrandList.map<Widget>((brand) {
                              final selected = _selectedBrands.contains(brand.id);
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  setState(() {
                                    if (selected) {
                                      _selectedBrands.remove(brand.id);
                                    } else {
                                      _selectedBrands.add(brand.id);
                                    }
                                  });
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? MyTheme.golden.withOpacity(0.12) : MyTheme.background(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: selected ? MyTheme.golden : MyTheme.border(context)),
                                  ),
                                  child: Text(brand.name, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      color: selected ? MyTheme.golden : MyTheme.primaryText(context))),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              // ── Apply CTA ────────────────────────────────────────────
              Container(
                color: MyTheme.surface(context),
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [MyTheme.market_red, MyTheme.secondary_color]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyProductFilter();
                      },
                      child: const Text('APPLY FILTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row buildTopAppbar(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back, color: MyTheme.primaryText(context)),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              height: 38,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: MyTheme.surface(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MyTheme.golden.withOpacity(0.15)),
              ),
              child: TypeAheadField<SearchSuggestionResponse>(
                suggestionsCallback: (pattern) async {
                  return await SearchRepository()
                      .getSearchSuggestionListResponse(
                          query_key: pattern, type: _selectedFilter.option_key);
                },
                loadingBuilder: (context) {
                  return Container(
                    height: 50,
                    child: Center(
                        child: Text(
                            AppLocalizations.of(context)!
                                .filter_screen_loading_suggestions,
                            style: TextStyle(
                                color: MyTheme.secondaryText(context)))),
                  );
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                        color: MyTheme.primaryText(context), fontSize: 13),
                    decoration: InputDecoration(
                      filled: false,
                      hintText:
                          "Search ${_selectedFilter.name}...",
                      hintStyle: TextStyle(
                          color:
                              MyTheme.secondaryText(context).withOpacity(0.5),
                          fontSize: 12),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child:
                            Icon(Icons.search, color: MyTheme.golden, size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  );
                },
                itemBuilder: (context, suggestion) {
                  var item = suggestion;
                  var subtitle =
                      "${AppLocalizations.of(context)!.filter_screen_searched_for} ${item.count} ${AppLocalizations.of(context)!.filter_screen_times}";
                  if (item.type != "search") {
                    subtitle =
                        "${item.type_string} ${AppLocalizations.of(context)!.filter_screen_found}";
                  }
                  return ListTile(
                    dense: true,
                    title: Text(item.query ?? "",
                        style: TextStyle(color: MyTheme.primaryText(context))),
                    subtitle: Text(subtitle,
                        style: TextStyle(
                            color: MyTheme.secondaryText(context),
                            fontSize: 10)),
                  );
                },
                onSelected: (suggestion) {
                  _searchController.text = suggestion.query ?? "";
                  _searchKey = suggestion.query ?? "";
                  _onSearchSubmit();
                },
              ),
            ),
          ),
        ]);
  }

  // buildFilterDrawer removed — replaced by _showAdvancedFilterSheet()
  Widget _removedFilterDrawer() {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: MyTheme.background(context),
        child: Container(
          padding: const EdgeInsets.only(top: 50),
          color: MyTheme.background(context),
          child: Column(
            children: [
              Container(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!
                              .filter_screen_price_range,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: MyTheme.primaryText(context)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .filter_screen_minimum,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.secondaryText(context)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.border(context),
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.primary(context),
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                          Text(" - "),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .filter_screen_maximum,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.secondaryText(context)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.border(context),
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.primary(context),
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!
                              .filter_screen_categories,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: MyTheme.primaryText(context)),
                        ),
                      ),
                      _filterCategoryList.length == 0
                          ? Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .common_no_category_is_available,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: buildFilterCategoryList(),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.filter_screen_brands,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: MyTheme.primaryText(context)),
                        ),
                      ),
                      _filterBrandList.length == 0
                          ? Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .common_no_brand_is_available,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: buildFilterBrandsList(),
                            ),
                    ]),
                  )
                ]),
              ),
              Container(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: MyTheme.primary(context), width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .common_clear_in_all_capital,
                        style: TextStyle(color: MyTheme.primary(context)),
                      ),
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        setState(() {
                          _selectedCategories.clear();
                          _selectedBrands.clear();
                        });
                      },
                    ),

                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: MyTheme.golden,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        "APPLY",
                        style: TextStyle(
                            color: MyTheme.isDark(context)
                                ? const Color(0xFF1A1400)
                                : Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        var min = _minPriceController.text.toString();
                        var max = _maxPriceController.text.toString();
                        bool apply = true;
                        if (min != "" && max != "") {
                          if (max.compareTo(min) < 0) {
                            ToastComponent.showDialog(
                                AppLocalizations.of(context)!
                                    .filter_screen_min_max_warning,
                                context);
                            apply = false;
                          }
                        }

                        if (apply) {
                          _applyProductFilter();
                        }
                      },
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildFilterBrandsList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterBrandList
            .map(
              (brand) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: MyTheme.golden,
                checkColor: const Color(0xFF1A1400),
                title: Text(brand.name,
                    style: TextStyle(color: MyTheme.primaryText(context))),

                value: _selectedBrands.contains(brand.id),
                onChanged: (bool? value) {
                  if (value == true) {
                    setState(() {
                      _selectedBrands.add(brand.id);
                    });
                  } else {
                    setState(() {
                      _selectedBrands.remove(brand.id);
                    });
                  }
                },
              ),
            )
            .toList()
      ],
    );
  }

  ListView buildFilterCategoryList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterCategoryList
            .map(
              (category) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: MyTheme.golden,
                checkColor: const Color(0xFF1A1400),
                title: Text(category.name,
                    style: TextStyle(color: MyTheme.primaryText(context))),

                value: _selectedCategories.contains(category.id),
                onChanged: (bool? value) {
                  if (value == true) {
                    setState(() {
                      _selectedCategories.clear();
                      _selectedCategories.add(category.id);
                    });
                  } else {
                    setState(() {
                      _selectedCategories.remove(category.id);
                    });
                  }
                },
              ),
            )
            .toList()
      ],
    );
  }

  Container buildProductList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildProductScrollableList(),
          )
        ],
      ),
    );
  }

  buildProductScrollableList() {
    if (_isProductInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.primary(context),
        backgroundColor: MyTheme.surface(context),
        onRefresh: _onProductListRefresh,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.top > 40 ? 180 : 135
                  //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                  ),
              GridView.builder(
                // 2
                //addAutomaticKeepAlives: true,
                itemCount: _productList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.618),
                padding: EdgeInsets.all(16),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return ProductCard(
                      id: _productList[index].id,
                      image: _productList[index].thumbnail_image,
                      name: _productList[index].name,
                      main_price: _productList[index].main_price,
                      stroked_price: _productList[index].stroked_price,
                      has_discount: _productList[index].has_discount);
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalProductData == 0) {
      return Center(
          child: Text(
              AppLocalizations.of(context)!.common_no_product_is_available,
            style: TextStyle(color: MyTheme.primaryText(context)),
          ));
    } else {
      return Container(); // should never be happening
    }
  }

  Container buildBrandList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildBrandScrollableList(),
          )
        ],
      ),
    );
  }

  buildBrandScrollableList() {
    if (_isBrandInitial && _brandList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_brandList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.primary(context),
        backgroundColor: MyTheme.surface(context),
        onRefresh: _onBrandListRefresh,
        child: SingleChildScrollView(
          controller: _brandScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.top > 40 ? 180 : 135
                  //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                  ),
              GridView.builder(
                // 2
                //addAutomaticKeepAlives: true,
                itemCount: _brandList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1),
                padding: EdgeInsets.all(8),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return BrandSquareCard(
                    id: _brandList[index].id,
                    image: _brandList[index].logo,
                    name: _brandList[index].name,
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalBrandData == 0) {
      return Center(
          child:
              Text(AppLocalizations.of(context)!.common_no_brand_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  Container buildShopList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildShopScrollableList(),
          )
        ],
      ),
    );
  }

  buildShopScrollableList() {
    if (_isShopInitial && _shopList.length == 0) {
      return SingleChildScrollView(
          controller: _scrollController,
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_shopList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.primary(context),
        backgroundColor: MyTheme.surface(context),
        onRefresh: _onShopListRefresh,
        child: SingleChildScrollView(
          controller: _shopScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.top > 40 ? 180 : 135
                  //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                  ),
              GridView.builder(
                // 2
                //addAutomaticKeepAlives: true,
                itemCount: _shopList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75),
                padding: EdgeInsets.all(8),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return StoreCard(
                    store: Shop(
                      id: _shopList[index].id,
                      name: _shopList[index].name,
                      logo: _shopList[index].logo,
                    ),
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalShopData == 0) {
      return Center(
          child:
              Text(AppLocalizations.of(context)!.common_no_shop_is_available));
    } else {
      return Container(); // should never be happening
    }
  }
}
