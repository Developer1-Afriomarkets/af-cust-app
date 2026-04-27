import 'package:flutter/foundation.dart';
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';
import 'package:afriomarkets_cust_app/data_model/shop_details_response.dart' as detail;
import 'package:afriomarkets_cust_app/data_model/product_mini_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/supabase_service.dart';
import 'package:afriomarkets_cust_app/services/medusa_service.dart';

class ShopRepository {
  static final _emptyMini =
      ProductMiniResponse(products: [], success: false, status: 0);

  Future<ShopResponse> getShops({name = "", page = 1}) async {
    try {
      final supabaseClient = SupabaseService.client;
      var request = supabaseClient.from('store').select('*');
      if (name.isNotEmpty) {
        request = request.ilike('name', '%$name%');
      }
      final response = await request;
      
      final List<Shop> shops = [];
      for (var row in response) {
        shops.add(Shop(
            id: row['id']?.toString(),
           name: row['name'] ?? row['store_name'] ?? '',
           logo: row['logo'] ?? '',
        ));
      }
      return ShopResponse(shops: shops, success: true, status: 200);
    } catch (e) {
      debugPrint('Error fetching shops from Supabase: $e');
      return ShopResponse(shops: [], success: false, status: 0);
    }
  }

  Future<detail.ShopDetailsResponse> getShopInfo({id = 0}) async {
    try {
      final supabaseClient = SupabaseService.client;
      final response = await supabaseClient
          .from('store')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return detail.ShopDetailsResponse(shops: [], success: false, status: 404);

      final shop = detail.Shop(
        id: response['id']?.toString(),
        name: response['name'] ?? response['store_name'] ?? '',
        logo: response['logo'] ?? '',
        sliders: response['sliders'] != null ? List<String>.from(response['sliders']) : [],
        address: response['address'] ?? '',
        rating: response['rating'] ?? 0,
      );
      
      return detail.ShopDetailsResponse(shops: [shop], success: true, status: 200);
    } catch (e) {
      debugPrint('Error fetching shop info from Supabase: $e');
      return detail.ShopDetailsResponse(shops: [], success: false, status: 0);
    }
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts({dynamic id = 0}) async {
    try {
      final supabaseClient = SupabaseService.client;
      final response = await supabaseClient
          .from('product')
          .select('id')
          .eq('store_id', id);
      
      final List<String> medusaIds = (response as List).map((row) => row['id'].toString()).toList();
      return MedusaService.getProductsByIdsMapped(medusaIds);
    } catch (e) {
      debugPrint('Error fetching shop top products: $e');
      return _emptyMini;
    }
  }

  Future<ProductMiniResponse> getNewFromThisSellerProducts({dynamic id = 0}) async {
    return getTopFromThisSellerProducts(id: id);
  }

  Future<ProductMiniResponse> getfeaturedFromThisSellerProducts({dynamic id = 0}) async {
    return getTopFromThisSellerProducts(id: id);
  }
}
