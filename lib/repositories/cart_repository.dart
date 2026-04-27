import 'package:afriomarkets_cust_app/data_model/cart_add_response.dart';
import 'package:afriomarkets_cust_app/data_model/cart_delete_response.dart';
import 'package:afriomarkets_cust_app/data_model/cart_process_response.dart';
import 'package:afriomarkets_cust_app/data_model/cart_summary_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_cart_service.dart';
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';

/// Cart repository — delegates all operations to [MedusaCartService].
class CartRepository {
  /// Returns line items from the active Medusa cart, grouped for display.
  /// Used by the Cart screen to populate the shop list.
  Future<List<MedusaCartShop>> getCartResponseList(int userId) async {
    final cart = await MedusaCartService.ensureCart();
    if (cart == null) return [];

    final lineItems = (cart['items'] as List? ?? []);
    if (lineItems.isEmpty) return [];

    final currency = RegionService.currencyCodeSync.toUpperCase();

    // Group by vendor / store_name — fall back to collection title or "Afriomarkets"
    final Map<String, MedusaCartShop> shopMap = {};
    for (final item in lineItems) {
      final variant = item['variant'] as Map<String, dynamic>? ?? {};
      final product = variant['product'] as Map<String, dynamic>? ?? {};
      final shopName = product['collection']?['title']?.toString() ?? 'Afriomarkets';

      double unitPrice = ((item['unit_price'] as int?) ?? 0) / 100;

      final cartItem = MedusaCartItem(
        id: item['id'].toString(),
        variantId: variant['id']?.toString() ?? '',
        productName: product['title']?.toString() ?? item['title']?.toString() ?? '',
        thumbnailImage: item['thumbnail']?.toString() ?? product['thumbnail']?.toString() ?? '',
        unitPrice: unitPrice,
        quantity: (item['quantity'] as int?) ?? 1,
        upperLimit: 99,
        lowerLimit: 1,
        currencySymbol: PriceHelper.getSymbol(currency),
        currencyCode: currency,
      );

      if (!shopMap.containsKey(shopName)) {
        shopMap[shopName] = MedusaCartShop(name: shopName, items: []);
      }
      shopMap[shopName]!.items.add(cartItem);
    }

    return shopMap.values.toList();
  }

  Future<CartDeleteResponse> getCartDeleteResponse(String lineItemId) async {
    final ok = await MedusaCartService.removeLineItem(lineItemId);
    return CartDeleteResponse(
      result: ok,
      message: ok ? 'Item removed' : 'Failed to remove item',
    );
  }

  Future<CartProcessResponse> getCartProcessResponse(
      String cartIds, String cartQuantities) async {
    return CartProcessResponse(result: true, message: 'Ready for checkout');
  }

  Future<CartAddResponse> getCartAddResponse(
      String variantId, int quantity) async {
    final cart = await MedusaCartService.addLineItem(variantId, quantity);
    final ok = cart != null;
    return CartAddResponse(
      result: ok,
      message: ok ? 'Added to cart' : 'Could not add to cart',
    );
  }

  Future<CartSummaryResponse> getCartSummaryResponse() async {
    return CartSummaryResponse();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight data models for Medusa cart display
// ─────────────────────────────────────────────────────────────────────────────

class MedusaCartShop {
  final String name;
  final List<MedusaCartItem> items;
  MedusaCartShop({required this.name, required this.items});
  List<MedusaCartItem> get cart_items => items;
}

class MedusaCartItem {
  final String id;
  final String variantId;
  final String productName;
  final String thumbnailImage;
  double unitPrice;
  int quantity;
  final int upperLimit;
  final int lowerLimit;
  final String currencySymbol;
  final String currencyCode;

  MedusaCartItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.thumbnailImage,
    required this.unitPrice,
    required this.quantity,
    required this.upperLimit,
    required this.lowerLimit,
    required this.currencySymbol,
    required this.currencyCode,
  });

  String get product_name => productName;
  String get product_thumbnail_image => thumbnailImage;
  double get price => unitPrice;
  String get currency_symbol => currencySymbol;
  int get upper_limit => upperLimit;
  int get lower_limit => lowerLimit;
}
