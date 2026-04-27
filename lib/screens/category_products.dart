import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:afriomarkets_cust_app/repositories/search_repository.dart';
import 'package:afriomarkets_cust_app/data_model/search_suggestion_response.dart';

class CategoryProducts extends StatefulWidget {
  CategoryProducts(
      {Key? key, required this.category_name, required this.category_id})
      : super(key: key);
  final String category_name;
  final int category_id;

  @override
  _CategoryProductsState createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
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
    var productResponse = await ProductRepository().getCategoryProducts(
        id: widget.category_id, page: _page, name: _searchKey);
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
    return MyTheme.brandBackground(
      context: context,
      child: Scaffold(
          backgroundColor: Colors.transparent,
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

  Widget buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 40 : 0,
      width: double.infinity,
      color: MyTheme.surface(context).withOpacity(0.8),
      child: Center(
        child: Text(
          _totalData == _productList.length
              ? AppLocalizations.of(context)!.common_no_more_products
              : AppLocalizations.of(context)!.common_loading_more_products,
          style: TextStyle(color: MyTheme.primaryText(context)),
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
          gradient:
              isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden,
                  opacity: isDark ? 0.2 : 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      toolbarHeight: 90,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Builder(
            builder: (context) => IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                )),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          child: TypeAheadField<SearchSuggestionResponse>(
            suggestionsCallback: (pattern) async {
              return await SearchRepository().getSearchSuggestionListResponse(
                  query_key: pattern, type: "product");
            },
            loadingBuilder: (context) {
              return Container(
                height: 50,
                child: Center(
                    child: Text(
                        AppLocalizations.of(context)!
                            .filter_screen_loading_suggestions,
                        style:
                            TextStyle(color: MyTheme.secondaryText(context)))),
              );
            },
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 13),
                decoration: InputDecoration(
                  filled: false,
                  hintText:
                      "${AppLocalizations.of(context)!.category_products_screen_search_products_from} ${widget.category_name}",
                  hintStyle: TextStyle(
                      fontSize: 12.0, color: Colors.white.withOpacity(0.6)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.search, color: MyTheme.golden, size: 20),
                  ),
                ),
                onSubmitted: (txt) {
                  _searchKey = txt;
                  reset();
                  fetchData();
                },
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
                        color: MyTheme.secondaryText(context), fontSize: 10)),
              );
            },
            onSelected: (suggestion) {
              _searchController.text = suggestion.query ?? "";
              _searchKey = suggestion.query ?? "";
              reset();
              fetchData();
            },
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        const SizedBox(width: 16),
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
            //physics: NeverScrollableScrollPhysics(),
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
          child: Text(
        AppLocalizations.of(context)!.common_no_data_available,
        style: TextStyle(color: MyTheme.secondaryText(context)),
      ));
    } else {
      return Container(); // should never be happening
    }
  }
}
