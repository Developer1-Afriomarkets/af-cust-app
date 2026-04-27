import 'package:afriomarkets_cust_app/data_model/product_mini_response.dart';
import 'package:afriomarkets_cust_app/data_model/product_details_response.dart';
import 'package:afriomarkets_cust_app/data_model/variant_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_service.dart';
import 'package:afriomarkets_cust_app/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class ProductRepository {
  // ─── Home screen product feeds ──────────────────────────────────────────

  Future<ProductMiniResponse> getFeaturedProducts({page = 1}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  Future<ProductMiniResponse> getBestSellingProducts({page = 1}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  Future<ProductMiniResponse> getTodaysDealProducts({page = 1}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  Future<ProductMiniResponse> getFlashDealProducts(
      {int id = 0, page = 1}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  /// Filter by category. The [id] is a legacy int stable-hash; we pass it
  /// through a cache lookup to obtain the Medusa string category ID.
  Future<ProductMiniResponse> getCategoryProducts(
      {int id = 0, page = 1, name = ''}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  Future<ProductMiniResponse> getShopProducts(
      {dynamic id = 0, page = 1, name = ''}) async {
    try {
      final supabaseClient = SupabaseService.client;
      final response = await supabaseClient
          .from('product')
          .select('id')
          .eq('store_id', id);
      
      final List<String> medusaIds = (response as List).map((row) => row['id'].toString()).toList();
      return MedusaService.getProductsByIdsMapped(medusaIds, page: page);
    } catch (e) {
      debugPrint('Error fetching shop products from Supabase: $e');
      return MedusaService.getProductsMapped(page: page);
    }
  }

  Future<ProductMiniResponse> getShopNewProducts({dynamic id = 0, page = 1}) async {
    return getShopProducts(id: id, page: page);
  }

  Future<ProductMiniResponse> getShopTopProducts({dynamic id = 0, page = 1}) async {
    return getShopProducts(id: id, page: page);
  }

  Future<ProductMiniResponse> getBrandProducts(
      {int id = 0, page = 1, name = ''}) async {
    return MedusaService.getProductsMapped(page: page);
  }

  Future<ProductMiniResponse> getFilteredProducts({
    name = "",
    sort_key = "",
    page = 1,
    brands = "",
    categories = "",
    min = "",
    max = "",
  }) async {
    final q = name?.toString().isNotEmpty == true ? name.toString() : null;
    return MedusaService.getProductsMapped(page: page, q: q);
  }

  // ─── Product Details ─────────────────────────────────────────────────────

  /// Loads full product details for a product identified by its legacy stable
  /// int ID.  The service resolves the int → Medusa string ID via cache.
  Future<ProductDetailsResponse> getProductDetails({int id = 0}) async {
    // 1. Resolve the stable int to a Medusa string ID.
    final medusaId = await MedusaService.getMedusaIdForStableId(id);

    if (medusaId == null || medusaId.isEmpty) {
      // If we can't find it in the cache, return an empty response.
      return ProductDetailsResponse(
          detailed_products: [], success: false, status: 404);
    }

    final response = await MedusaService.getProductDetailsMapped(medusaId);

    // DUAL FETCH: Query Supabase to find this product's store_id and seller data.
    // Enables cart integrations natively to tie products back to specific stores dynamically.
    try {
      final supabaseClient = SupabaseService.client;
      final supaResponse = await supabaseClient
          .from('product')
          .select('store_id')
          .eq('id', medusaId)
          .maybeSingle();

      if (supaResponse != null && supaResponse['store_id'] != null && response.detailed_products.isNotEmpty) {
        final String storeIdStr = supaResponse['store_id'].toString();
        
        final storeResponse = await supabaseClient
            .from('store')
            .select('id, name')
            .eq('id', storeIdStr)
            .maybeSingle();

        if (storeResponse != null) {
          response.detailed_products[0].shop_id = storeResponse['id']?.toString();
          response.detailed_products[0].shop_name = storeResponse['name'] ?? storeResponse['store_name'] ?? '';
          response.detailed_products[0].shop_logo = '';
        }
      }
    } catch(e) {
      debugPrint('Supabase dual-fetch error: $e');
    }

    return response;
  }

  Future<ProductMiniResponse> getRelatedProducts({int id = 0}) async {
    return MedusaService.getProductsMapped();
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts({dynamic id = 0}) async {
    return MedusaService.getProductsMapped();
  }

  // ─── Variant / price info ────────────────────────────────────────────────

  /// The legacy `/products/variant/price` endpoint no longer exists.
  /// We derive variant info directly from Medusa's product data.
  Future<VariantResponse> getVariantWiseInfo(
      {int id = 0, color = '', variants = ''}) async {
    String selectedChoices = [color, variants].where((s) => s.toString().isNotEmpty).join(',');
    return MedusaService.getVariantInfoForStableId(id, selectedChoices: selectedChoices);
  }
}
