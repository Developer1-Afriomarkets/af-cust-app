import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'package:afriomarkets_cust_app/services/supabase_service.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';
import 'package:afriomarkets_cust_app/data_model/product_mini_response.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:flutter/foundation.dart';

class ExplorerRepository {
  get _supabase => SupabaseService.client;

  /// Fetch all States from Supabase, optionally filtered by name.
  Future<List<StateModel>> getStates({String query = ''}) async {
    try {
      var request = _supabase.from('state').select('*');
      if (query.isNotEmpty) {
        request = request.ilike('state', '%$query%');
      }
      final response = await request;
      
      final List<StateModel> states = [];
      for (var row in response) {
        states.add(StateModel.fromJson(row));
      }
      return states;
    } catch (e) {
      debugPrint("Error fetching states: $e");
      return [];
    }
  }

  /// Fetch Markets belonging to a specific state from Supabase, optionally filtered.
  Future<List<MarketModel>> getMarketsByState(String stateId, {String query = ''}) async {
    try {
      var request = _supabase
          .from('market')
          .select('*')
          .eq('state_id', stateId);
      
      if (query.isNotEmpty) {
        request = request.ilike('market_name', '%$query%');
      }
      final response = await request;
      
      final List<MarketModel> markets = [];
      for (var row in response) {
        markets.add(MarketModel.fromJson(row));
      }
      return markets;
    } catch (e) {
      debugPrint("Error fetching markets: $e");
      return [];
    }
  }

  /// Fetch general top Markets without state bound
  Future<List<MarketModel>> getTopMarkets({String query = ''}) async {
    try {
      var request = _supabase.from('market').select('*');
      if (query.isNotEmpty) {
        request = request.ilike('market_name', '%$query%');
      }
      final response = await request.limit(10);
      
      final List<MarketModel> markets = [];
      for (var row in response) {
        markets.add(MarketModel.fromJson(row));
      }
      return markets;
    } catch (e) {
      debugPrint("Error fetching top markets: $e");
      return [];
    }
  }

  /// Fetch Stores. Currently uses the Medusa-backed ShopRepository,
  /// optionally filtered by name.
  /// Fetch Stores directly from Supabase, bridging Store profiles into native Market environments.
  Future<List<Shop>> getStoresByMarket(String marketId, {int page = 1, String query = ''}) async {
    try {
      var request = _supabase
          .from('store')
          .select('*')
          .eq('market_id', marketId);
          
      if (query.isNotEmpty) {
        request = request.ilike('name', '%$query%');
      }
      
      final response = await request;

      final List<Shop> shops = [];
      for (var row in response) {
        // Handle ID mappings explicitly as Supabase migrations might carry raw string types or numeric mappings.
        shops.add(Shop(
           id: row['id'] is int ? row['id'] : (int.tryParse(row['id'].toString()) ?? 0),
           name: row['name'] ?? row['store_name'] ?? '',
           logo: row['logo'] ?? '',
        ));
      }
      return shops;
    } catch (e) {
      debugPrint("Error fetching native Supabase stores: $e");
      return [];
    }
  }

  Future<ProductMiniResponse> getProductsByContext(ExplorerContext context, {String query = '', int page = 1, String sort_key = ''}) async {
    try {
      final productRepo = ProductRepository();
      if (context.isAtStoreLevel) {
        return await productRepo.getShopProducts(id: context.selectedStore?.id ?? 0, page: page, name: query);
      }
      return await productRepo.getFilteredProducts(name: query, page: page, sort_key: sort_key);
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return ProductMiniResponse(products: [], success: false, status: 0);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONTEXTUAL DATA MOCKS (PHASE 7 API ARCHITECTURE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch localized demographics and vendor statistics for the current scope.
  Future<Map<String, String>> getContextStats(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (context.isAtStoreLevel) {
       return {
         "Years Active": "3+",
         "Products": "142",
         "Rating": "4.8/5.0",
         "Avg. Dispatch": "< 2 hrs",
       };
    } else if (context.isAtMarketLevel) {
       return {
         "Active Shops": "340",
         "Daily Buyers": "4.2k",
         "Categories": "15+",
         "Avg. Volume": "\$12k/day",
       };
    } else if (context.isAtStateLevel) {
       return {
         "Population": "4.2M",
         "Active Markets": "12",
         "Reg. Vendors": "2,100",
         "State Economy": "\$2.1B",
       };
    } else {
       return {
         "Total Regions": "5",
         "Active States": "36",
         "Total Markets": "320+",
         "Reg. Vendors": "12k+",
       };
    }
  }

  /// Fetch dynamic ad banners configured for this specific context level.
  Future<List<Map<String, String>>> getContextAds(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (context.isAtStoreLevel) {
       return [{
         "imageUrl": "https://picsum.photos/seed/store_promo_x/800/200",
         "title": "${context.selectedStore!.name} Exclusive",
         "subtitle": "Get 10% off your first purchase today.",
         "cta": "Claim Now"
       }];
    } else if (context.isAtMarketLevel) {
       return [{
         "imageUrl": "https://picsum.photos/seed/market_promo_x/800/200",
         "title": "${context.selectedMarket!.marketName} Weekend Fair",
         "subtitle": "Discover handmade textiles starting this Saturday.",
         "cta": "Learn More"
       }];
    } else if (context.isAtStateLevel) {
       return [{
         "imageUrl": "https://picsum.photos/seed/state_promo_x/800/200",
         "title": "Invest in ${context.selectedState!.stateName}",
         "subtitle": "New agricultural grants available for local entrepreneurs.",
         "cta": "Apply Here"
       }];
    } else {
       return [{
         "imageUrl": "https://picsum.photos/seed/adxbanner_x/800/200",
         "title": "Pan-African Trade Summit",
         "subtitle": "Join leaders shaping the future of continental commerce.",
         "cta": "Register"
       }];
    }
  }

  /// Fetch Economic/Cultural highlights for the active state/market.
  Future<List<Map<String, String>>> getContextHighlights(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final levelName = context.selectedStore?.name ?? context.selectedMarket?.marketName ?? context.selectedState?.stateName ?? "Regional";
    
    if (context.isAtStoreLevel) {
       return [
         {"title": "Artisan Craftsmanship", "desc": "Sourced from 100% sustainable local materials.", "icon": "eco", "color": "0xFF34A853"},
         {"title": "Fast Fulfillment", "desc": "Most orders processed and dispatched within 2 hours.", "icon": "local_shipping", "color": "0xFFFBBC05"},
         {"title": "Verified Quality", "desc": "Top rated by 500+ buyers in the network.", "icon": "verified", "color": "0xFF4285F4"},
       ];
    }
    
    return [
      {"title": "$levelName Growth", "desc": "Trade volume increased by 14% over the last fiscal quarter.", "icon": "trending_up", "color": "0xFF34A853"},
      {"title": "Cultural Heritage", "desc": "Annual festivals driving deep economic impact.", "icon": "festival", "color": "0xFFFBBC05"},
      {"title": "Infrastructure", "desc": "Logistics networks expanding rapidly in the area.", "icon": "construction", "color": "0xFF4285F4"},
    ];
  }

  /// Fetch contextual blog stories and articles.
  Future<List<Map<String, String>>> getContextStories(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final levelName = context.selectedStore?.name ?? context.selectedMarket?.marketName ?? context.selectedState?.stateName ?? "Africa";
    
    return [
      {
        "id": "1",
        "title": "The Rise of Digital Artisans in $levelName",
        "author": "Chidi E.",
        "imageUrl": "https://picsum.photos/seed/story1x_${levelName.replaceAll(' ', '')}/400/300",
        "excerpt": "How craftsmen in $levelName are using e-commerce globally.",
        "content": "Traditional craftsmen in $levelName are finding new life through digital platforms. Instead of relying purely on foot traffic, these incredible artisans showcase their intricate fabrics and stunning woodwork directly to international buyers..."
      },
      {
        "id": "2",
        "title": "Top Sourced Exports from $levelName",
        "author": "Amina Y.",
        "imageUrl": "https://picsum.photos/seed/story2x_${levelName.replaceAll(' ', '')}/400/300",
        "excerpt": "A deep dive into the highest requested items from the region.",
        "content": "The heart of $levelName holds incredible potential. The rich aroma of locally sourced herbs and the fiery zest of indigenous peppers define the culture here. A large percentage of exports have skyrocketed recently..."
      }
    ];
  }
}
