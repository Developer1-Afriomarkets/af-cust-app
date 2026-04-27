import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class SellerProducts extends StatefulWidget {
  SellerProducts({Key? key, required this.id, required this.shop_name})
      : super(key: key);
  final dynamic id;
  final String shop_name;

  @override
  _SellerProductsState createState() => _SellerProductsState();
}

class _SellerProductsState extends State<SellerProducts> {
  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();

  List<dynamic> _productList = [];
  bool _isInitial = true;
  int _page = 1;
  String _searchKey = "";
  int _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      //print("position: " + _xcrollController.position.pixels.toString());
      //print("max: " + _xcrollController.position.maxScrollExtent.toString());

      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _xcrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  fetchData() async {
    var productResponse = await ProductRepository()
        .getShopProducts(id: widget.id, page: _page, name: _searchKey);
    _productList.addAll(productResponse.products);
    _isInitial = false;
    _totalData = productResponse.meta?.total ?? 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _productList.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          backgroundColor: MyTheme.background(context),
          appBar: buildAppBar(context),
          body: Stack(
            children: [
              buildProductList(),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: buildLoadingContainer())
            ],
          )),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(
          _totalData == _productList.length
              ? AppLocalizations.of(context)!.common_no_more_products
              : AppLocalizations.of(context)!.common_loading_more_products,
          style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return AppBar(
      backgroundColor: isDark ? Colors.transparent : MyTheme.accent_color,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (txt) {
            _searchKey = txt;
            reset();
            fetchData();
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.seller_products_screen_search_products_of_shop.split(':')[0],
              hintStyle: TextStyle(fontSize: 13.0, color: Colors.white.withOpacity(0.6)),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10)),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: const [SizedBox(width: 16)],
    );
  }

  buildProductList() {
    if (_isInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: MyTheme.surface(context),
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: GridView.builder(
            itemCount: _productList.length,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72),
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ProductCard(
                id: _productList[index].id,
                image: _productList[index].thumbnail_image,
                name: _productList[index].name,
                main_price: _productList[index].main_price,
                stroked_price: _productList[index].stroked_price,
                has_discount: _productList[index].has_discount,
              );
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
          child: Text(
            AppLocalizations.of(context)!.common_no_data_available,
            style: TextStyle(color: MyTheme.secondaryText(context)),
          ));
    } else {
      return Container();
    }
  }
}
