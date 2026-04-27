import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/order_mini_response.dart';
import 'package:afriomarkets_cust_app/data_model/order_detail_response.dart';
import 'package:afriomarkets_cust_app/data_model/order_item_response.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_auth_service.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart'; // Added this import
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';

/// Order data repository — backed by Medusa's customer orders API.
///
/// Endpoints:
///   GET /store/customers/me/orders   → order history (requires session cookie)
class OrderRepository {
  static const String _base = AppConfig.MEDUSA_BASE_URL;

  static Future<Map<String, String>> _buildHeaders() async {
    return await MedusaAuthService.getAuthBearerHeaders();
  }

  // ─── Order List ─────────────────────────────────────────────────────────

  Future<OrderMiniResponse> getOrderList({
    page = 1,
    payment_status = '',
    delivery_status = '',
  }) async {
    return safeApiCall(() async {
      const limit = 10;
      final offset = ((page as int) - 1) * limit;

      final queryParams = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        'expand': 'items,payments',
      };
      if ((payment_status as String).isNotEmpty) {
        queryParams['payment_status'] = payment_status;
      }

      final uri = Uri.parse('$_base/store/customers/me/orders')
          .replace(queryParameters: queryParams);
      final headers = await _buildHeaders();
      final response = await medusaClient.get(uri, headers: headers);
      print('[OrderRepository] getOrderList Status: ${response.statusCode}');
      // print('[OrderRepository] getOrderList Body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please ensure you are logged in.');
      }

      _guardJson(response);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawOrders = body['orders'] as List? ?? [];
      final count = (body['count'] as int?) ?? rawOrders.length;

      final orders = rawOrders
          .cast<Map<String, dynamic>>()
          .map((o) => _mapOrder(o))
          .toList();

      return OrderMiniResponse(
        orders: orders,
        success: true,
        status: 200,
        meta: Meta(
          total: count,
          currentPage: page,
          perPage: limit,
          lastPage: (count / limit).ceil(),
        ),
      );
    }, OrderMiniResponse(orders: [], success: false, status: 0));
  }

  // ─── Order Details ───────────────────────────────────────────────────────

  Future<OrderDetailResponse> getOrderDetails({int id = 0}) async {
    return safeApiCall(() async {
      final headers = await _buildHeaders();
      final uri = Uri.parse('$_base/store/customers/me/orders').replace(
          queryParameters: {
            'limit': '100',
            'expand': 'items,payments,shipping_address'
          });
      final response = await medusaClient.get(uri, headers: headers);

      if (response.statusCode == 401) {
        return OrderDetailResponse(detailed_orders: [], success: true, status: 200);
      }
      _guardJson(response);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawOrders = (body['orders'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      // Find the one matching our stable int ID
      final o = rawOrders.firstWhere(
        (o) => _stableId(o['id']) == id,
        orElse: () => <String, dynamic>{},
      );

      if (o.isEmpty) {
        return OrderDetailResponse(detailed_orders: [], success: false, status: 404);
      }

      final currency = (o['currency_code'] as String?)?.toUpperCase() ??
          RegionService.currencyCodeSync;
      final displayId = o['display_id']?.toString() ?? o['id'].toString();
      final payStatus = o['payment_status'] as String? ?? '';
      final delStatus = o['fulfillment_status'] as String? ?? '';

      // Medusa shipping address
      final sa = o['shipping_address'] as Map<String, dynamic>? ?? {};

      final detailed = DetailedOrder(
        id: id,
        code: '#$displayId',
        user_id: 0,
        manually_payable: false,
        shipping_address: ShippingAddress(
          name: '${sa['first_name'] ?? ''} ${sa['last_name'] ?? ''}'.trim(),
          email: o['email'] as String?,
          address: sa['address_1'] as String?,
          country: sa['country_code'] as String?,
          city: sa['city'] as String?,
          postal_code: sa['postal_code'] as String?,
          phone: sa['phone'] as String?,
          state: sa['province'] as String?,
          checkout_type: null,
        ),
        shipping_type: 'standard',
        shipping_type_string: 'Standard',
        payment_type: o['payment_provider'] as String?,
        payment_status: payStatus,
        payment_status_string: _cap(payStatus),
        delivery_status: delStatus,
        delivery_status_string: _cap(delStatus),
        grand_total: PriceHelper.formatPrice(
            (o['total'] as int?) ?? 0, currency),
        coupon_discount: PriceHelper.formatPrice(
            (o['discount_total'] as int?) ?? 0, currency),
        shipping_cost: PriceHelper.formatPrice(
            (o['shipping_total'] as int?) ?? 0, currency),
        subtotal: PriceHelper.formatPrice(
            (o['subtotal'] as int?) ?? 0, currency),
        tax: PriceHelper.formatPrice((o['tax_total'] as int?) ?? 0, currency),
        date: _fmtDate(o['created_at']),
        links: null,
      );

      return OrderDetailResponse(
          detailed_orders: [detailed], success: true, status: 200);
    }, OrderDetailResponse(detailed_orders: [], success: false, status: 0));
  }

  // ─── Order Items ─────────────────────────────────────────────────────────

  Future<OrderItemResponse> getOrderItems({int id = 0}) async {
    return safeApiCall(() async {
      final headers = await _buildHeaders();
      final uri = Uri.parse('$_base/store/customers/me/orders').replace(
          queryParameters: {
            'limit': '100',
            'expand': 'items,items.variant,items.variant.product'
          });
      final response = await medusaClient.get(uri, headers: headers);

      if (response.statusCode == 401) {
        return OrderItemResponse(ordered_items: [], success: true, status: 200);
      }
      _guardJson(response);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawOrders = (body['orders'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final o = rawOrders.firstWhere(
        (o) => _stableId(o['id']) == id,
        orElse: () => <String, dynamic>{},
      );

      if (o.isEmpty) {
        return OrderItemResponse(ordered_items: [], success: false, status: 404);
      }

      final currency = (o['currency_code'] as String?)?.toUpperCase() ??
          RegionService.currencyCodeSync;
      final payStatus = o['payment_status'] as String? ?? '';
      final delStatus = o['fulfillment_status'] as String? ?? '';

      final rawItems = (o['items'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final items = rawItems.map((item) {
        final variant = item['variant'] as Map<String, dynamic>? ?? {};
        final product = variant['product'] as Map<String, dynamic>? ?? {};
        final qty = (item['quantity'] as int?) ?? 1;
        return OrderItem(
          id: _stableId(item['id']),
          product_id: _stableId(product['id'] ?? 0),
          product_name: item['title'] as String? ??
              product['title'] as String? ?? '',
          variation: variant['title'] as String? ?? '',
          price: PriceHelper.formatPrice(
              (item['unit_price'] as int?) ?? 0, currency),
          quantity: qty,
          tax: '',
          shipping_cost: '',
          coupon_discount: '',
          payment_status: payStatus,
          payment_status_string: _cap(payStatus),
          delivery_status: delStatus,
          delivery_status_string: _cap(delStatus),
          refund_section: false,
          refund_button: false,
          refund_label: '',
          refund_request_status: 0,
        );
      }).toList();

      return OrderItemResponse(
          ordered_items: items, success: true, status: 200);
    }, OrderItemResponse(ordered_items: [], success: false, status: 0));
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  static Order _mapOrder(Map<String, dynamic> o) {
    final total = (o['total'] as int?) ?? 0;
    final currency = (o['currency_code'] as String?)?.toUpperCase() ??
        RegionService.currencyCodeSync;
    final payStatus = o['payment_status'] as String? ?? '';
    final delStatus = o['fulfillment_status'] as String? ?? '';
    final displayId = o['display_id']?.toString() ?? o['id'].toString();

    return Order(
      id: _stableId(o['id']),
      code: '#$displayId',
      user_id: 0,
      payment_type: o['payment_provider'] as String?,
      payment_status: payStatus,
      payment_status_string: _cap(payStatus),
      delivery_status: delStatus,
      delivery_status_string: _cap(delStatus),
      grand_total: PriceHelper.formatPrice(total, currency),
      date: _fmtDate(o['created_at']),
      links: null,
    );
  }

  static void _guardJson(http.Response response) {
    final trimmed = response.body.trim();
    if (trimmed.startsWith('<') || trimmed.toLowerCase().contains('<!doctype')) {
      final snippet =
          trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
      print('[OrderRepository] HTML Response detected (${response.statusCode}): $snippet');
      throw Exception(
          'Medusa API returned HTML (${response.statusCode}) for '
          '${response.request?.url}. Snippet: $snippet');
    }
  }

  static int _stableId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId == null) return 0;
    return rawId.toString().hashCode.abs();
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  static String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }
}
