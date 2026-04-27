import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class BrandProducts extends StatefulWidget {
  BrandProducts({Key? key, required this.id, required this.brand_name})
      : super(key: key);
  final int id;
  final String brand_name;

  @override
  _BrandProductsState createState() => _BrandProductsState();
}

class _BrandProductsState extends State<BrandProducts> {
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
    super.dispose();
  }

  fetchData() async {
    var productResponse = await ProductRepository()
        .getBrandProducts(id: widget.id, page: _page, name: _searchKey);
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
    return Scaffold(
        backgroundColor: MyTheme.background(context),
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            buildProductList(),
            Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer())
          ],
        ));
  }

  Widget buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(_totalData == _productList.length
            ? AppLocalizations.of(context)!.common_no_more_products
            : AppLocalizations.of(context)!.common_loading_more_products,
          style: TextStyle(color: MyTheme.secondaryText(context)),
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
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: SizedBox(
          width: 250,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onTap: () {},
            onSubmitted: (txt) {
              _searchKey = txt;
              reset();
              fetchData();
            },
            autofocus: true,
            decoration: InputDecoration(
                hintText:
                    "${AppLocalizations.of(context)!.brand_products_screen_search_product_of_brand} : " +
                        widget.brand_name,
                hintStyle:
                    const TextStyle(fontSize: 12.0, color: Colors.white70),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0)),
          )),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _searchKey = _searchController.text.toString();
              setState(() {});
              reset();
              fetchData();
            },
          ),
        ),
      ],
    );
  }

  buildProductList() {
    if (_isInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.primary(context),
        backgroundColor: MyTheme.surface(context),
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: GridView.builder(
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
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.common_no_data_available,
            style: TextStyle(color: MyTheme.secondaryText(context)),
          ));
    } else {
      return Container(); // should never be happening
    }
  }
}
