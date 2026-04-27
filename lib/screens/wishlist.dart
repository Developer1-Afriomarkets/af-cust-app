import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/screens/product_details.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart'; // Added import

class Wishlist extends StatefulWidget {
  @override
  _WishlistState createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  ScrollController _mainScrollController = ScrollController();

  //init
  bool _wishlistInit = true;
  List<dynamic> _wishlistItems = [];

  @override
  void initState() {
    if (is_logged_in.$ == true) {
      fetchWishlistItems();
    }

    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchWishlistItems() async {
    List<String> wishlistIds = local_wishlist_ids.$.split(',').where((e) => e.isNotEmpty).toList();
    List<dynamic> loadedItems = [];
    
    await Future.wait(wishlistIds.map((idString) async {
      int id = int.tryParse(idString) ?? 0;
      if (id > 0) {
        var response = await ProductRepository().getProductDetails(id: id);
        if (response.detailed_products.isNotEmpty) {
           loadedItems.add(response.detailed_products.first);
        }
      }
    }));
    
    _wishlistItems.addAll(loadedItems);
    _wishlistInit = false;
    setState(() {});
  }

  reset() {
    _wishlistInit = true;
    _wishlistItems.clear();
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchWishlistItems();
  }

  Future<void> _onPressRemove(index) async {
    var productId = _wishlistItems[index].id;
    _wishlistItems.removeAt(index);
    
    List<String> wishlistIds = local_wishlist_ids.$.split(',').where((e) => e.isNotEmpty).toList();
    wishlistIds.remove(productId.toString());
    local_wishlist_ids.$ = wishlistIds.join(',');
    local_wishlist_ids.save();
    
    setState(() {});
    ToastComponent.showDialog("Removed from wishlist", context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: buildAppBar(context),
          body: MyTheme.brandBackground(
            context: context,
            child: RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: MyTheme.surface(context),
              onRefresh: _onPageRefresh,
              child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverList(
                    delegate: SliverChildListDelegate([
                  buildWishlist(),
                ])),
              ],
            ),
          ),
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
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        AppLocalizations.of(context)!.wishlist_screen_my_wishlist,
        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildWishlist() {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.wishlist_screen_login_warning,
            style: TextStyle(color: MyTheme.secondaryText(context)),
          )));
    } else if (_wishlistInit == true && _wishlistItems.length == 0) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(item_count: 10),
      );
    } else if (_wishlistItems.length > 0) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: _wishlistItems.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: buildWishListItem(index),
            );
          },
        ),
      );
    } else {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                  AppLocalizations.of(context)!.common_no_item_is_available,
                  style: TextStyle(color: MyTheme.secondaryText(context)))));
    }
  }

  buildWishListItem(index) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            id: _wishlistItems[index].id,
          );
        }));
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Card(
              color: MyTheme.surface(context),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: MyTheme.border(context), width: 1.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              shadowColor: MyTheme.isDark(context) ? Colors.black54 : Colors.black12,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(16), right: Radius.zero),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/placeholder.png',
                              image: PathHelper.getImageUrlSafe(_wishlistItems[index]
                                  .thumbnail_image),
                              fit: BoxFit.cover,
                            ))),
                    Container(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: Text(
                               _wishlistItems[index].name ?? "",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                  color: MyTheme.primaryText(context),
                                  fontSize: 14,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Text(
                              _wishlistItems[index].main_price ?? "",
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
            ),
          ),
          app_language_rtl.$
              ? Positioned(
                  bottom: 8,
                  left: 12,
                  child: IconButton(
                    icon: Icon(Icons.delete_forever_outlined,
                        color: MyTheme.secondaryText(context)),
                    onPressed: () {
                      _onPressRemove(index);
                    },
                  ),
                )
              : Positioned(
                  bottom: 8,
                  right: 12,
                  child: IconButton(
                    icon: Icon(Icons.delete_forever_outlined,
                        color: MyTheme.secondaryText(context)),
                    onPressed: () {
                      _onPressRemove(index);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
