import 'dart:convert';
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Medusa v1 Cart Service
///
/// Mirrors the checkout-context.tsx flow from the web storefront:
///   1. Create / restore cart
///   2. PATCH cart with address + email
///   3. GET shipping options
///   4. POST shipping method
///   5. POST payment sessions (idempotency-keyed)
///   6. POST select payment session
///   7. POST complete cart → order confirmed
class MedusaCartService {
  static final String _base = AppConfig.MEDUSA_BASE_URL;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ──────────────────────────────────────────────────────────────────────────
  // Cart lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the current cart map, creating a new one if none exists or if
  /// the persisted ID is no longer valid (404 / completed).
  static Future<Map<String, dynamic>?> ensureCart() async {
    final existingId = medusa_cart_id.$;
    if (existingId.isNotEmpty) {
      final existing = await _getCart(existingId);
      if (existing != null) {
        final status = existing['status'];
        // If cart is already completed, create a fresh one
        if (status == null || status == 'pending') return existing;
      }
    }
    return _createCart();
  }

  static Future<Map<String, dynamic>?> _getCart(String cartId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/store/carts/$cartId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[MedusaCartService] getCart error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _createCart() async {
    try {
      final regionId = current_region_id.$;
      final payload = regionId.isNotEmpty ? {'region_id': regionId} : {};

      final res = await http.post(
        Uri.parse('$_base/store/carts'),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final cart = body['cart'] as Map<String, dynamic>?;
        if (cart != null) {
          medusa_cart_id.$ = cart['id'].toString();
          medusa_cart_id.save();
          debugPrint('[MedusaCartService] Created cart: ${cart['id']}');
        }
        return cart;
      }
      debugPrint('[MedusaCartService] createCart failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] createCart error: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Line items
  // ──────────────────────────────────────────────────────────────────────────

  /// Adds a variant to the cart. Returns updated cart or null on failure.
  static Future<Map<String, dynamic>?> addLineItem(
      String variantId, int quantity) async {
    final cart = await ensureCart();
    if (cart == null) return null;
    final cartId = cart['id'].toString();

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/line-items'),
        headers: _headers,
        body: jsonEncode({'variant_id': variantId, 'quantity': quantity}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] addLineItem failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] addLineItem error: $e');
    }
    return null;
  }

  /// Updates quantity of an existing line item.
  static Future<Map<String, dynamic>?> updateLineItem(
      String lineItemId, int quantity) async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/line-items/$lineItemId'),
        headers: _headers,
        body: jsonEncode({'quantity': quantity}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[MedusaCartService] updateLineItem error: $e');
    }
    return null;
  }

  /// Removes a line item from the cart.
  static Future<bool> removeLineItem(String lineItemId) async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return false;

    try {
      final res = await http.delete(
        Uri.parse('$_base/store/carts/$cartId/line-items/$lineItemId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[MedusaCartService] removeLineItem error: $e');
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Address & contact (Step 1 of checkout — mirrors setAddresses in web ctx)
  // ──────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> updateCartAddress({
    required String email,
    required Map<String, dynamic> shippingAddress,
    Map<String, dynamic>? billingAddress,
  }) async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    final payload = {
      'email': email,
      'shipping_address': shippingAddress,
      'billing_address': billingAddress ?? shippingAddress,
    };

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] updateCartAddress failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] updateCartAddress error: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Shipping (Step 2)
  // ──────────────────────────────────────────────────────────────────────────

  /// Lists available shipping options for the current cart.
  static Future<List<Map<String, dynamic>>> getShippingOptions() async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return [];

    try {
      final res = await http.get(
        Uri.parse('$_base/store/shipping-options/$cartId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(
            body['shipping_options'] as List? ?? []);
      }
    } catch (e) {
      debugPrint('[MedusaCartService] getShippingOptions error: $e');
    }
    return [];
  }

  /// Attaches a shipping method to the cart.
  static Future<Map<String, dynamic>?> addShippingMethod(
      String optionId) async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/shipping-methods'),
        headers: _headers,
        body: jsonEncode({'option_id': optionId}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] addShippingMethod failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] addShippingMethod error: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Payment (Step 3) — mirrors initPayment + setPaymentSession from web ctx
  // ──────────────────────────────────────────────────────────────────────────

  static const _idempotencyKey = 'create_payment_session_key';

  /// Creates payment sessions for the cart. Idempotency-keyed to avoid duplication.
  static Future<Map<String, dynamic>?> createPaymentSessions() async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/payment-sessions'),
        headers: {
          ..._headers,
          'Idempotency-Key': _idempotencyKey,
        },
        body: jsonEncode({}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] createPaymentSessions failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] createPaymentSessions error: $e');
    }
    return null;
  }

  /// Selects a specific payment provider session on the cart.
  static Future<Map<String, dynamic>?> selectPaymentSession(
      String providerId) async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/payment-session'),
        headers: _headers,
        body: jsonEncode({'provider_id': providerId}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['cart'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] selectPaymentSession failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] selectPaymentSession error: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Complete cart (Step 4) — mirrors onPaymentCompleted in web ctx
  // ──────────────────────────────────────────────────────────────────────────

  /// Completes the cart and places the order.
  /// Returns the order data map or null on failure.
  static Future<Map<String, dynamic>?> completeCart() async {
    final cartId = medusa_cart_id.$;
    if (cartId.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('$_base/store/carts/$cartId/complete'),
        headers: _headers,
        body: jsonEncode({}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        // On success, clear the cart ID so next session starts fresh
        medusa_cart_id.$ = '';
        medusa_cart_id.save();
        debugPrint('[MedusaCartService] Cart completed, order: ${body['data']?['id']}');
        return body['data'] as Map<String, dynamic>?;
      }
      debugPrint('[MedusaCartService] completeCart failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[MedusaCartService] completeCart error: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves the Medusa variant ID for the given product + selected choices string.
  /// E.g. selectedChoices = "Red,XL"
  static Future<String?> getVariantIdForChoices(
      String medusaProductId, String selectedChoices) async {
    try {
      final uri = Uri.parse('$_base/store/products/$medusaProductId').replace(
        queryParameters: {
          'expand': 'variants,variants.options,options',
        },
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) return null;

      final choicesList =
          selectedChoices.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final variants = p['variants'] as List? ?? [];
      for (final variant in variants) {
        final vOptions = variant['options'] as List? ?? [];
        final values =
            vOptions.map((o) => o['value'].toString().trim()).toList();
        bool matches = choicesList.every((c) => values.contains(c));
        if (matches) return variant['id'].toString();
      }
    } catch (e) {
      debugPrint('[MedusaCartService] getVariantIdForChoices error: $e');
    }
    return null;
  }
}
