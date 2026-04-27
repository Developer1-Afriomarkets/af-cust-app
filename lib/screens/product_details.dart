import 'package:afriomarkets_cust_app/screens/cart.dart';
import 'package:afriomarkets_cust_app/screens/common_webview_screen.dart';
import 'package:afriomarkets_cust_app/screens/product_reviews.dart';
import 'package:afriomarkets_cust_app/services/medusa_cart_service.dart';
import 'package:afriomarkets_cust_app/ui_elements/list_product_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/mini_product_card.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/addon_config.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:expandable/expandable.dart';
import 'dart:ui';
import 'package:flutter_html/flutter_html.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/services/medusa_service.dart';
import 'package:afriomarkets_cust_app/repositories/cart_repository.dart';
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/helpers/color_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';

import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'package:afriomarkets_cust_app/repositories/chat_repository.dart';
import 'package:afriomarkets_cust_app/screens/chat.dart';

import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:afriomarkets_cust_app/screens/video_description_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:afriomarkets_cust_app/screens/brand_products.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class ProductDetails extends StatefulWidget {
  final int id;

  ProductDetails({Key? key, required this.id}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _showCopied = false;
  String _appbarPriceString = ". . .";
  int _currentImage = 0;
  ScrollController _mainScrollController = ScrollController();
  ScrollController _colorScrollController = ScrollController();
  ScrollController _variantScrollController = ScrollController();
  ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  //init values
  bool _isInWishList = false;
  var _productDetailsFetched = false;
  var _productDetails = null;
  var _productImageList = [];
  var _colorList = [];
  int _selectedColorIndex = 0;
  var _selectedChoices = [];
  var _choiceString = "";
  var _variant = "";
  var _totalPrice;
  var _singlePrice;
  var _singlePriceString;
  int _quantity = 1;
  int _stock = 0;

  List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  @override
  void initState() {
    fetchAll();
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _variantScrollController.dispose();
    _imageScrollController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  fetchAll() {
    print("product id : ${widget.id}");
    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }

    fetchRelatedProducts();
    fetchTopProducts();
  }

  /// Returns [url] unchanged if it already has an http:// or https:// scheme
  /// (Medusa CDN URLs), otherwise returns a placeholder URL so FadeInImage
  /// never makes a network request to `BASE_PATH + ""`.
  String _resolveImageUrl(String? url) {
    return PathHelper.getImageUrlSafe(url);
  }

  fetchProductDetails() async {
    var productDetailsResponse =
        await ProductRepository().getProductDetails(id: widget.id);

    if (productDetailsResponse.detailed_products.isNotEmpty) {
      _productDetails = productDetailsResponse.detailed_products[0];
      sellerChatTitleController.text =
          productDetailsResponse.detailed_products[0].name ?? "";
    }

    // Always mark fetch as done so the screen exits shimmer state.
    _productDetailsFetched = true;
    setProductDetailValues();
    if (mounted) setState(() {});
  }

  fetchRelatedProducts() async {
    var relatedProductResponse =
        await ProductRepository().getRelatedProducts(id: widget.id);
    _relatedProducts.addAll(relatedProductResponse.products);
    _relatedProductInit = true;

    setState(() {});
  }

  fetchTopProducts() async {
    var topProductResponse =
        await ProductRepository().getTopFromThisSellerProducts(id: widget.id);
    _topProducts.addAll(topProductResponse.products);
    _topProductInit = true;
  }

  setProductDetailValues() {
    if (_productDetails != null) {
      _appbarPriceString = _productDetails.price_high_low ?? "";
      _singlePrice = _productDetails.calculable_price;
      _singlePriceString = _productDetails.main_price ?? "";
      calculateTotalPrice();
      _stock = _productDetails.current_stock;
      _productDetails.photos?.forEach((photo) {
        _productImageList.add(photo.path);
      });

      _productDetails.choice_options?.forEach((choice_opiton) {
        if (choice_opiton.options != null && choice_opiton.options.length > 0) {
          _selectedChoices.add(choice_opiton.options[0]);
        }
      });
      _productDetails.colors?.forEach((color) {
        _colorList.add(color);
      });

      setChoiceString();

      if ((_productDetails.colors?.length ?? 0) > 0 ||
          (_productDetails.choice_options?.length ?? 0) > 0) {
        fetchAndSetVariantWiseInfo(change_appbar_string: true);
      }
      _productDetailsFetched = true;

      setState(() {});
    }
  }

  setChoiceString() {
    _choiceString = _selectedChoices.join(",").toString();
    //print(_choiceString);
    setState(() {});
  }

  fetchWishListCheckInfo() async {
    List<String> wishlistIds = local_wishlist_ids.$.split(',').where((e) => e.isNotEmpty).toList();
    _isInWishList = wishlistIds.contains(widget.id.toString());
    setState(() {});
  }

  addToWishList() async {
    List<String> wishlistIds = local_wishlist_ids.$.split(',').where((e) => e.isNotEmpty).toList();
    if (!wishlistIds.contains(widget.id.toString())) {
      wishlistIds.add(widget.id.toString());
      local_wishlist_ids.$ = wishlistIds.join(',');
      local_wishlist_ids.save();
    }
    _isInWishList = true;
    setState(() {});
  }

  removeFromWishList() async {
    List<String> wishlistIds = local_wishlist_ids.$.split(',').where((e) => e.isNotEmpty).toList();
    wishlistIds.remove(widget.id.toString());
    local_wishlist_ids.$ = wishlistIds.join(',');
    local_wishlist_ids.save();
    _isInWishList = false;
    setState(() {});
  }

  onWishTap() {
    if (_isInWishList) {
      removeFromWishList();
    } else {
      addToWishList();
    }
  }

  fetchAndSetVariantWiseInfo({bool change_appbar_string = true}) async {
    var color_string = _colorList.length > 0
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    /*print("color string: "+color_string);
    return;*/

    var variantResponse = await ProductRepository().getVariantWiseInfo(
        id: widget.id, color: color_string, variants: _choiceString);

    /*print("vr"+variantResponse.toJson().toString());
    return;*/

    _singlePrice = variantResponse.price;
    _stock = variantResponse.stock ?? 0;
    if (_quantity > _stock) {
      _quantity = _stock;
      setState(() {});
    }

    _variant = variantResponse.variant ?? "";
    setState(() {});

    calculateTotalPrice();
    _singlePriceString = variantResponse.price_string ?? "";

    if (change_appbar_string) {
      _appbarPriceString =
          "${variantResponse.variant ?? ""} ${_singlePriceString}";
    }

    int pindex = 0;
    _productDetails.photos?.forEach((photo) {
      if (photo.variant == _variant && variantResponse.image != "") {
        _currentImage = pindex;
      }

      pindex++;
    });

    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _topProducts.clear();
    _choiceString = "";
    _variant = "";
    _selectedColorIndex = 0;
    _quantity = 1;
    _productDetailsFetched = false;
    _isInWishList = false;
    sellerChatTitleController.clear();
    setState(() {});
  }

  restProductDetailValues() {
    _appbarPriceString = " . . .";
    _productDetails = null;
    _productImageList.clear();
    _currentImage = 0;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  calculateTotalPrice() {
    _totalPrice = _singlePrice * _quantity;
    setState(() {});
  }

  _onVariantChange(_choice_options_index, value) {
    _selectedChoices[_choice_options_index] = value;
    setChoiceString();
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndex = index;
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  onPressAddToCart(context, snackbar) {
    addToCart(mode: "add_to_cart", context: context, snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now", context: context);
  }

  addToCart({mode, context = null, snackbar = null}) async {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.common_login_warning, context);

      return;
    }

    print(widget.id);
    print(_variant);
    print(user_id.$);
    print(_quantity);

    // Resolve Medusa string ID from stable int ID
    final medusaStringId = await MedusaService.getMedusaIdForStableId(widget.id);
    final choicesStr = _variant;
    
    // If _variant holds a plain choices string (even empty) and not a variant ID, resolve it
    String variantId = choicesStr;
    if (!variantId.startsWith('variant_') && medusaStringId != null) {
      variantId = await MedusaCartService.getVariantIdForChoices(medusaStringId, choicesStr) ?? choicesStr;
    }

    var cartAddResponse = await CartRepository()
        .getCartAddResponse(variantId.isEmpty ? '' : variantId, _quantity);

    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(cartAddResponse.message, context);
      return;
    } else {
      if (!mounted) return;
      if (mode == "add_to_cart") {
        if (snackbar != null) {
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
        reset();
        fetchAll();
      } else if (mode == 'buy_now') {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Cart(has_bottomnav: false);
        })).then((value) {
          onPopped(value);
        });
      }
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(setState) {
    setState(() {
      _showCopied = true;
    });
    Timer timer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showCopied = false;
      });
    });
  }

  onPressShare(context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size(75, 26),
                            backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: Colors.black, width: 1.0)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .product_details_screen_copy_product_link,
                            style: TextStyle(
                              color: MyTheme.medium_grey,
                            ),
                          ),
                          onPressed: () {
                            onCopyTap(setState);
                            Clipboard.setData(
                                ClipboardData(text: _productDetails.link));
                          },
                        ),
                      ),
                      _showCopied
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.common_copied,
                                style: TextStyle(
                                    color: MyTheme.medium_grey, fontSize: 12),
                              ),
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size(75, 26),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: Colors.black, width: 1.0)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .product_details_screen_share_options,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            Share.share(_productDetails.link);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: app_language_rtl.$
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size(75, 30),
                          backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                  color: MyTheme.font_grey, width: 1.0)),
                        ),
                        child: Text(
                          "CLOSE",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          });
        });
  }

  onTapSellerChat() {
    return showDialog(
        context: context,
        builder: (_) => Directionality(
              textDirection:
                  app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                insetPadding: EdgeInsets.symmetric(horizontal: 10),
                contentPadding: EdgeInsets.only(
                    top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
                content: Container(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                              AppLocalizations.of(context)!
                                  .product_details_screen_seller_chat_title,
                              style: TextStyle(
                                  color: MyTheme.font_grey, fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            height: 40,
                            child: TextField(
                              controller: sellerChatTitleController,
                              autofocus: false,
                              decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!
                                      .product_details_screen_seller_chat_enter_title,
                                  hintStyle: TextStyle(
                                      fontSize: 12.0,
                                      color: MyTheme.textfield_grey),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.textfield_grey,
                                        width: 0.5),
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(8.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.textfield_grey,
                                        width: 1.0),
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(8.0),
                                    ),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8.0)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                              "${AppLocalizations.of(context)!.product_details_screen_seller_chat_messasge} *",
                              style: TextStyle(
                                  color: MyTheme.font_grey, fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            height: 55,
                            child: TextField(
                              controller: sellerChatMessageController,
                              autofocus: false,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!
                                      .product_details_screen_seller_chat_enter_messasge,
                                  hintStyle: TextStyle(
                                      fontSize: 12.0,
                                      color: MyTheme.textfield_grey),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.textfield_grey,
                                        width: 0.5),
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(8.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.textfield_grey,
                                        width: 1.0),
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(8.0),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.only(
                                      right: 16.0,
                                      left: 8.0,
                                      top: 16.0,
                                      bottom: 16.0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size(75, 30),
                            backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: MyTheme.light_grey, width: 1.0)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .common_close_in_all_capital,
                            style: TextStyle(
                              color: MyTheme.font_grey,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size(75, 30),
                            backgroundColor: MyTheme.accent_color,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: MyTheme.light_grey, width: 1.0)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .common_send_in_all_capital,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            onPressSendMessage();
                          },
                        ),
                      )
                    ],
                  )
                ],
              ),
            ));
  }

  onPressSendMessage() async {
    var title = sellerChatTitleController.text.toString();
    var message = sellerChatMessageController.text.toString();

    if (title == "" || message == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .product_details_screen_seller_chat_title_message_empty_warning,
          context);
      return;
    }

    var conversationCreateResponse = await ChatRepository()
        .getCreateConversationResponse(
            product_id: widget.id, title: title, message: message);

    if (conversationCreateResponse.result == false) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .product_details_screen_seller_chat_creation_unable_warning,
          context);
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    sellerChatTitleController.clear();
    sellerChatMessageController.clear();
    setState(() {});

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Chat(
        conversation_id: conversationCreateResponse.conversation_id ?? 0,
        messenger_name: _productDetails?.shop_name ?? "",
        messenger_title: _productDetails?.shop_name ?? "",
        messenger_image: _productDetails?.shop_logo ?? "",
      );
    })).then((value) {
      onPopped(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    SnackBar _addedToCartSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)!
            .product_details_screen_snackbar_added_to_cart,
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!
            .product_details_screen_snackbar_show_cart,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Cart(has_bottomnav: false);
          })).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          bottomNavigationBar: buildBottomAppBar(context, _addedToCartSnackbar),
          backgroundColor: MyTheme.background(context),
          appBar: buildAppBar(statusBarHeight, context),
          body: RefreshIndicator(
            color: MyTheme.primary(context),
            backgroundColor: MyTheme.surface(context),
            onRefresh: _onPageRefresh,
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: <Widget>[
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      0.0,
                      16.0,
                      0.0,
                    ),
                    child: buildProductImageSection(),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        8.0,
                        16.0,
                        0.0,
                      ),
                      child: _productDetails != null
                          ? Text(
                              _productDetails.name,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: MyTheme.primaryText(context),
                                  fontWeight: FontWeight.w700),
                              maxLines: 2,
                            )
                          : ShimmerHelper().buildBasicShimmer(
                              height: 30.0,
                            )),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      8.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildRatingAndWishButtonRow()
                        : ShimmerHelper().buildBasicShimmer(
                            height: 30.0,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      16.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildBrandRow()
                        : ShimmerHelper().buildBasicShimmer(
                            height: 50.0,
                          ),
                  ),
                  Divider(
                    height: 24.0,
                    color: MyTheme.border(context),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      8.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildMainPriceRow()
                        : ShimmerHelper().buildBasicShimmer(
                            height: 30.0,
                          ),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  AddonConfig.club_point_addon_installed
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            0.0,
                          ),
                          child: _productDetails != null
                              ? buildClubPointRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        )
                      : Container(),
                  Divider(
                    height: 24.0,
                    color: MyTheme.border(context),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  _productDetails != null
                      ? buildChoiceOptionList()
                      : buildVariantShimmers(),
                ])),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      16.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? (_colorList.length > 0
                            ? buildColorRow()
                            : Container())
                        : ShimmerHelper().buildBasicShimmer(
                            height: 30.0,
                          ),
                  ),
                ),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      8.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildQuantityRow()
                        : ShimmerHelper().buildBasicShimmer(
                            height: 30.0,
                          ),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      16.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildTotalPriceRow()
                        : ShimmerHelper().buildBasicShimmer(
                            height: 30.0,
                          ),
                  ),
                  Divider(
                    height: 24.0,
                    color: MyTheme.border(context),
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      0.0,
                      16.0,
                      0.0,
                    ),
                    child: _productDetails != null
                        ? buildSellerRow(context)
                        : ShimmerHelper().buildBasicShimmer(
                            height: 50.0,
                          ),
                  ),
                  Divider(
                    height: 24,
                  ),
                ])),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        0.0,
                        16.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .product_details_screen_description,
                        style: TextStyle(
                            color: MyTheme.primaryText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        8.0,
                        0.0,
                        8.0,
                        8.0,
                      ),
                      child: _productDetails != null
                          ? buildExpandableDescription()
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              child: ShimmerHelper().buildBasicShimmer(
                                height: 60.0,
                              )),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                    InkWell(
                      onTap: () {
                        if ((_productDetails?.video_link ?? "") == "") {
                          ToastComponent.showDialog(
                              AppLocalizations.of(context)!
                                  .product_details_screen_video_not_available,
                              context,
                              gravity: ToastComponent.center);
                          return;
                        }

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return VideoDescription(
                            url: _productDetails!.video_link!,
                          );
                        })).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            8.0,
                            0.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .product_details_screen_video,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Icon(
                                Icons.add,
                                color: MyTheme.font_grey,
                                size: 24,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ProductReviews(id: widget.id);
                        })).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            8.0,
                            0.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .product_details_screen_reviews,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Icon(
                                Icons.add,
                                color: MyTheme.font_grey,
                                size: 24,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CommonWebviewScreen(
                            url:
                                "${AppConfig.RAW_BASE_URL}/mobile-page/sellerpolicy",
                            page_name: AppLocalizations.of(context)!
                                .product_details_screen_seller_policy,
                          );
                        }));
                      },
                      child: Container(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            8.0,
                            0.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .product_details_screen_seller_policy,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Icon(
                                Icons.add,
                                color: MyTheme.font_grey,
                                size: 24,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CommonWebviewScreen(
                            url:
                                "${AppConfig.RAW_BASE_URL}/mobile-page/returnpolicy",
                            page_name: AppLocalizations.of(context)!
                                .product_details_screen_return_policy,
                          );
                        }));
                      },
                      child: Container(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            8.0,
                            0.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .product_details_screen_return_policy,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Icon(
                                Icons.add,
                                color: MyTheme.font_grey,
                                size: 24,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CommonWebviewScreen(
                            url:
                                "${AppConfig.RAW_BASE_URL}/mobile-page/supportpolicy",
                            page_name: AppLocalizations.of(context)!
                                .product_details_screen_support_policy,
                          );
                        }));
                      },
                      child: Container(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            8.0,
                            0.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .product_details_screen_support_policy,
                                style: TextStyle(
                                    color: MyTheme.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Icon(
                                Icons.add,
                                color: MyTheme.font_grey,
                                size: 24,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: MyTheme.border(context),
                    ),
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .product_details_screen_products_may_like,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        8.0,
                        16.0,
                        0.0,
                        0.0,
                      ),
                      child: buildProductsMayLikeList(),
                    )
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .top_selling_products_screen_top_selling_products,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        0.0,
                      ),
                      child: buildTopSellingProductList(),
                    )
                  ]),
                )
              ],
            ),
          )),
    );
  }

  Row buildSellerRow(BuildContext context) {

    return Row(
      children: [
        _productDetails.added_by == "admin"
            ? Container()
            : Padding(
                padding: app_language_rtl.$
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.0),
                    border: Border.all(
                        color: Color.fromRGBO(112, 112, 112, .3), width: 0.5),
                    //shape: BoxShape.rectangle,
                  ),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: _resolveImageUrl(_productDetails?.shop_logo),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        Container(
          width: MediaQuery.of(context).size.width * (.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.product_details_screen_seller,
                  style: TextStyle(
                    color: Color.fromRGBO(153, 153, 153, 1),
                  )),
              Text(
                _productDetails?.shop_name ?? "",
                style: TextStyle(
                    color: MyTheme.font_grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
        Spacer(),
        Container(
            child: Row(
          children: [
            InkWell(
              onTap: () {
                if (is_logged_in == false) {
                  ToastComponent.showDialog("You need to log in", context);
                  return;
                }

                onTapSellerChat();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  AppLocalizations.of(context)!
                      .product_details_screen_chat_with_seller,
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color.fromRGBO(7, 101, 136, 1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Icon(Icons.message, size: 16, color: Color.fromRGBO(7, 101, 136, 1))
          ],
        ))
      ],
    );
  }

  Row buildTotalPriceRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.product_details_screen_total_price,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Text(
          "${_productDetails?.currency_symbol ?? ""}${_totalPrice.toString()}",
          style: TextStyle(
              color: MyTheme.primary(context),
              fontSize: 18.0,
              fontWeight: FontWeight.w700),
        )
      ],
    );
  }

  Row buildQuantityRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.product_details_screen_quantity,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          height: 36,
          width: 120,
          decoration: BoxDecoration(
              border:
                  Border.all(color: MyTheme.border(context), width: 1),
              borderRadius: BorderRadius.circular(36.0),
              color: MyTheme.surface(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              buildQuantityDownButton(),
              Container(
                  width: 36,
                  child: Center(
                      child: Text(
                    _quantity.toString(),
                    style: TextStyle(fontSize: 18, color: MyTheme.dark_grey),
                  ))),
              buildQuantityUpButton()
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "(${_stock} ${AppLocalizations.of(context)!.product_details_screen_available})",
            style: TextStyle(
                color: MyTheme.secondaryText(context), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Padding buildVariantShimmers() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        0.0,
        8.0,
        0.0,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetails.choice_options.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetails.choice_options, index),
        );
      },
    );
  }

  buildChoiceOpiton(choice_options, choice_options_index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        8.0,
        16.0,
        0.0,
      ),
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: Container(
              width: 75,
              child: Text(
                choice_options[choice_options_index].title,
                style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width - (75 + 40),
            child: Scrollbar(
              controller: _variantScrollController,
              thumbVisibility: false,
              child: ListView.builder(
                itemCount: choice_options[choice_options_index].options.length,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: buildChoiceItem(
                        choice_options[choice_options_index].options[index],
                        choice_options_index,
                        index),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  buildChoiceItem(option, choice_options_index, index) {
    return Padding(
      padding: app_language_rtl.$
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choice_options_index, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: _selectedChoices[choice_options_index] == option
                    ? MyTheme.accent_color
                    : Color.fromRGBO(224, 224, 225, 1),
                width: 1.5),
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                    color: _selectedChoices[choice_options_index] == option
                        ? MyTheme.accent_color
                        : Color.fromRGBO(224, 224, 225, 1),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.product_details_screen_color,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          height: 40,
          width: MediaQuery.of(context).size.width - (75 + 40),
          child: Scrollbar(
            controller: _colorScrollController,
            thumbVisibility: false,
            child: ListView.builder(
              itemCount: _colorList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: buildColorItem(index),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  buildColorItem(index) {
    return Padding(
      padding: app_language_rtl.$
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onColorChange(index);
        },
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
              border: Border.all(
                  color: _selectedColorIndex == index
                      ? Colors.purple
                      : Colors.white,
                  width: 1),
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Color.fromRGBO(222, 222, 222, 1), width: 1),
                  borderRadius: BorderRadius.circular(12.0),
                  color: ColorHelper.getColorFromColorCode(_colorList[index])),
              child: _selectedColorIndex == index
                  ? buildColorCheckerContainer()
                  : Container(),
            ),
          ),
        ),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
        padding: const EdgeInsets.all(3),
        child: /*Icon(FontAwesome.check, color: Colors.white, size: 16),*/
            Image.asset(
          "assets/white_tick.png",
          width: 16,
          height: 16,
        ));
  }

  Row buildClubPointRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.product_details_screen_club_point,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: MyTheme.golden, width: 1),
              borderRadius: BorderRadius.circular(12.0),
              color: Color.fromRGBO(253, 235, 212, 1)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Text(
              _productDetails.earn_point.toString(),
              style: TextStyle(color: MyTheme.golden, fontSize: 12.0),
            ),
          ),
        )
      ],
    );
  }

  Row buildMainPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _singlePriceString,
          style: TextStyle(
              color: MyTheme.primary(context),
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1),
        ),
        if (_productDetails.has_discount) ...[
          const SizedBox(width: 12),
          Text(
            _productDetails.stroked_price,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: MyTheme.secondaryText(context).withOpacity(0.5),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _appbarPriceString,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
          onPressed: () {
            onPressShare(context);
          },
        ),
      ],
    );
  }

  buildBottomAppBar(BuildContext context, _addedToCartSnackbar) {
    final isDark = MyTheme.isDark(context);
    return Container(
      color: MyTheme.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: MyTheme.golden.withOpacity(0.15),
                side: BorderSide(color: MyTheme.golden, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!
                    .product_details_screen_button_add_to_cart
                    .toUpperCase(),
                style: TextStyle(
                    color: MyTheme.golden,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8),
              ),
              onPressed: () {
                onPressAddToCart(context, _addedToCartSnackbar);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: MyTheme.primary(context),
                elevation: 4,
                shadowColor: MyTheme.primary(context).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!
                    .product_details_screen_button_buy_now
                    .toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8),
              ),
              onPressed: () {
                onPressBuyNow(context);
              },
            ),
          )
        ],
      ),
    );
  }

  buildRatingAndWishButtonRow() {
    return Row(
      children: [
        RatingBar(
          itemSize: 18.0,
          ignoreGestures: true,
          initialRating: (_productDetails.rating ?? 0).toDouble(),
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: Colors.amber),
            half: Icon(Icons.star_half, color: Colors.amber),
            empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
          ),
          itemPadding: EdgeInsets.only(right: 1.0),
          onRatingUpdate: (rating) {
            //print(rating);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "(" + _productDetails.rating_count.toString() + ")",
            style: TextStyle(
                color: MyTheme.secondaryText(context), fontSize: 13),
          ),
        ),
        Spacer(),
        _isInWishList
            ? InkWell(
                onTap: () {
                  onWishTap();
                },
                child: Icon(
                  Icons.favorite,
                  color: Color.fromRGBO(230, 46, 4, 1),
                  size: 20,
                ),
              )
            : InkWell(
                onTap: () {
                  onWishTap();
                },
                child: Icon(
                  Icons.favorite_border,
                  color: Color.fromRGBO(230, 46, 4, 1),
                  size: 20,
                ),
              )
      ],
    );
  }

  buildBrandRow() {
    return (_productDetails.brand?.id ?? 0) > 0
        ? InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BrandProducts(
                  id: _productDetails.brand?.id ?? 0,
                  brand_name: _productDetails.brand?.name ?? "",
                );
              }));
            },
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 75,
                    child: Text(
                      AppLocalizations.of(context)!
                          .product_details_screen_brand,
                      style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      _productDetails.brand?.name ?? "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: MyTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Color.fromRGBO(112, 112, 112, .3), width: 1),
                    //shape: BoxShape.rectangle,
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: _resolveImageUrl(_productDetails?.brand?.logo),
                        fit: BoxFit.contain,
                      )),
                ),
              ],
            ),
          )
        : Container();
  }

  ExpandableNotifier buildExpandableDescription() {
    return ExpandableNotifier(
        child: ScrollOnExpand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expandable(
            collapsed: Container(
                height: 50, child: Html(data: _productDetails.description)),
            expanded: Container(child: Html(data: _productDetails.description)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Builder(
                builder: (context) {
                  var controller = ExpandableController.of(context);
                  return TextButton(
                    child: Text(
                      !(controller?.expanded ?? false)
                          ? AppLocalizations.of(context)!.common_view_more
                          : AppLocalizations.of(context)!.common_show_less,
                      style: TextStyle(color: MyTheme.font_grey, fontSize: 11),
                    ),
                    onPressed: () {
                      controller?.toggle();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ));
  }

  buildTopSellingProductList() {
    if (_topProductInit == false && _topProducts.length == 0) {
      return Column(
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
        ],
      );
    } else if (_topProducts.length > 0) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: _topProducts.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: ListProductCard(
                  id: _topProducts[index]?.id ?? 0,
                  image: _topProducts[index].thumbnail_image,
                  name: _topProducts[index].name,
                  main_price: _topProducts[index].main_price,
                  stroked_price: _topProducts[index].stroked_price,
                  has_discount: _topProducts[index].has_discount),
            );
          },
        ),
      );
    } else {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                  AppLocalizations.of(context)!
                      .product_details_screen_no_top_selling_product,
                  style: TextStyle(color: MyTheme.font_grey))));
    }
  }

  buildProductsMayLikeList() {
    if (_relatedProductInit == false && _relatedProducts.length == 0) {
      return Row(
        children: [
          Padding(
              padding: app_language_rtl.$
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: app_language_rtl.$
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
        ],
      );
    } else if (_relatedProducts.length > 0) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 175,
          child: ListView.builder(
            itemCount: _relatedProducts.length,
            scrollDirection: Axis.horizontal,
            itemExtent: 120,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 3.0),
                child: MiniProductCard(
                    id: _relatedProducts[index]?.id ?? 0,
                    image: _relatedProducts[index].thumbnail_image,
                    name: _relatedProducts[index].name,
                    main_price: _relatedProducts[index].main_price,
                    stroked_price: _relatedProducts[index].stroked_price,
                    has_discount: _relatedProducts[index].has_discount),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!
                .product_details_screen_no_related_product,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
  }

  buildQuantityUpButton() => SizedBox(
        width: 36,
        child: IconButton(
            icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
            onPressed: () {
              if (_quantity < _stock) {
                _quantity++;
                setState(() {});
                calculateTotalPrice();
              }
            }),
      );

  buildQuantityDownButton() => SizedBox(
      width: 36,
      child: IconButton(
          icon: Icon(Icons.remove, size: 16, color: MyTheme.dark_grey),
          onPressed: () {
            if (_quantity > 1) {
              _quantity--;
              setState(() {});
              calculateTotalPrice();
            }
          }));

  openPhotoDialog(BuildContext context, path) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: Stack(
              children: [
                PhotoView(
                  enableRotation: true,
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                  imageProvider: NetworkImage(path),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: MyTheme.medium_grey_50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: MyTheme.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );

  buildProductImageSection() {
    if (_productImageList.length == 0) {
      return Row(
        children: [
          Container(
            width: 40,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 190.0,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: 64,
            child: Scrollbar(
              controller: _imageScrollController,
              thumbVisibility: false,
              thickness: 4.0,
              child: Padding(
                padding: app_language_rtl.$
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: ListView.builder(
                    itemCount: _productImageList.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      int itemIndex = index;
                      return GestureDetector(
                        onTap: () {
                          _currentImage = itemIndex;
                          print(_currentImage);
                          setState(() {});
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                                color: _currentImage == itemIndex
                                    ? MyTheme.accent_color
                                    : Color.fromRGBO(112, 112, 112, .3),
                                width: _currentImage == itemIndex ? 2 : 1),
                            //shape: BoxShape.rectangle,
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child:
                                  /*Image.asset(
                                        singleProduct.product_images[index])*/
                                  FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: _resolveImageUrl(_productImageList[index]),
                                fit: BoxFit.contain,
                              )),
                        ),
                      );
                    }),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              openPhotoDialog(context,
                  _resolveImageUrl(_productImageList[_currentImage]));
            },
            child: Container(
              height: 250,
              width: MediaQuery.of(context).size.width - 96,
              child: Container(
                  child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder_rectangle.png',
                image: _resolveImageUrl(_productImageList[_currentImage]),
                fit: BoxFit.scaleDown,
              )),
            ),
          ),
        ],
      );
    }
  }
}
