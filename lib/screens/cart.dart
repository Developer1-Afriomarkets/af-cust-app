import 'package:afriomarkets_cust_app/screens/medusa_checkout.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_sections/animated_sidebar.dart';
import 'package:afriomarkets_cust_app/repositories/cart_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_cart_service.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class Cart extends StatefulWidget {
  Cart({Key? key, this.has_bottomnav = false}) : super(key: key);
  final bool has_bottomnav;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController _mainScrollController = ScrollController();
  List<MedusaCartShop> _shopList = [];
  bool _isInitial = true;
  String _cartTotalString = '. . .';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      fetchData();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  Future<void> fetchData() async {
    setState(() => _isInitial = true);
    final list = await CartRepository().getCartResponseList(user_id.$);
    _shopList = list;
    _isInitial = false;
    _recalcTotal();
    if (mounted) setState(() {});
  }

  void _recalcTotal() {
    double total = 0;
    String sym = '';
    for (final shop in _shopList) {
      for (final item in shop.items) {
        total += item.price * item.quantity;
        sym = item.currencySymbol;
      }
    }
    _cartTotalString = total > 0 ? '$sym${total.toStringAsFixed(2)}' : '—';
  }

  String _shopPartialTotal(MedusaCartShop shop) {
    double t = 0;
    String sym = '';
    for (final item in shop.items) {
      t += item.price * item.quantity;
      sym = item.currencySymbol;
    }
    return t > 0 ? '$sym${t.toStringAsFixed(2)}' : '';
  }

  void _increaseQty(int si, int ii) async {
    final item = _shopList[si].items[ii];
    if (item.quantity < item.upperLimit) {
      setState(() => item.quantity++);
      _recalcTotal();
      await MedusaCartService.updateLineItem(item.id, item.quantity);
    } else {
      ToastComponent.showDialog('Cannot order more than ${item.upperLimit}', context);
    }
  }

  void _decreaseQty(int si, int ii) async {
    final item = _shopList[si].items[ii];
    if (item.quantity > item.lowerLimit) {
      setState(() => item.quantity--);
      _recalcTotal();
      await MedusaCartService.updateLineItem(item.id, item.quantity);
    } else {
      ToastComponent.showDialog('Minimum quantity is ${item.lowerLimit}', context);
    }
  }

  void _onPressDelete(String lineItemId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
        content: Text(
          AppLocalizations.of(context)!.cart_screen_sure_remove_item,
          style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14),
        ),
        backgroundColor: MyTheme.surface(context),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cart_screen_cancel,
                style: TextStyle(color: MyTheme.secondaryText(context))),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: MyTheme.primary(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context)!.cart_screen_confirm,
                style: TextStyle(
                  color: MyTheme.isDark(context) ? const Color(0xFF1A1400) : Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              setState(() => _isLoading = true);
              await MedusaCartService.removeLineItem(lineItemId);
              await fetchData();
              setState(() => _isLoading = false);
            },
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    if (_shopList.isEmpty) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.cart_screen_cart_empty, context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedusaCheckout()),
    ).then((_) => fetchData());
  }

  Future<void> _onRefresh() => fetchData();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.background(context),
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.primary(context),
              backgroundColor: MyTheme.surface(context),
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildCartBody(),
                      ),
                      SizedBox(height: widget.has_bottomnav ? 160 : 120),
                    ]),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBody() {
    if (is_logged_in.$ == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context)!.cart_screen_please_log_in,
            style: TextStyle(color: MyTheme.secondaryText(context)),
          ),
        ),
      );
    }
    if (_isInitial) {
      return ShimmerHelper().buildListShimmer(item_count: 4, item_height: 100);
    }
    if (_shopList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: MyTheme.light_grey),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.cart_screen_cart_empty,
                style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _shopList.asMap().entries.map((shopEntry) {
        final si = shopEntry.key;
        final shop = shopEntry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(shop.name.toUpperCase(), 
                      style: TextStyle(
                        color: MyTheme.primaryText(context), 
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(_shopPartialTotal(shop), 
                      style: TextStyle(
                        color: MyTheme.primary(context), 
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...shop.items.asMap().entries.map((itemEntry) {
                final ii = itemEntry.key;
                final item = itemEntry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCartItemCard(item, si, ii),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCartItemCard(MedusaCartItem item, int si, int ii) {
    return Card(
      color: MyTheme.surface(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: MyTheme.border(context), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(12),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.png',
              image: PathHelper.getImageUrlSafe(item.thumbnailImage),
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: MyTheme.primaryText(context), fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    '${item.currencySymbol}${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: MyTheme.primary(context), fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              _qtyButton(Icons.add, () => _increaseQty(si, ii)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('${item.quantity}',
                    style: TextStyle(color: MyTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _qtyButton(Icons.remove, () => _decreaseQty(si, ii)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: MyTheme.market_red.withOpacity(0.7)),
            onPressed: () => _onPressDelete(item.id),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 28,
      height: 28,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: CircleBorder(side: BorderSide(color: MyTheme.border(context))),
          backgroundColor: MyTheme.isDark(context) ? MyTheme.darkCardElevated : Colors.white,
        ),
        onPressed: onTap,
        child: Icon(icon, size: 16, color: MyTheme.primary(context)),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isDark = MyTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? MyTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: widget.has_bottomnav ? 85 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: MyTheme.isDark(context) ? MyTheme.darkCardElevated : MyTheme.lightBg,
              border: Border.all(color: MyTheme.border(context)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(AppLocalizations.of(context)!.cart_screen_total_amount,
                    style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(_cartTotalString,
                    style: TextStyle(
                        color: MyTheme.primary(context), fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.primary(context),
                foregroundColor: MyTheme.isDark(context) ? const Color(0xFF1A1400) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _proceedToCheckout,
              icon: const Icon(Icons.chevron_right),
              label: Text(
                AppLocalizations.of(context)!.cart_screen_proceed_to_shipping.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          AnimatedSidebarScaffold.of(context)?.toggleMenu();
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Image.asset('assets/hamburger.png', height: 16, color: Colors.white),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.cart_screen_shopping_cart,
        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
