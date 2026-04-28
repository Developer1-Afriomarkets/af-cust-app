import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:afriomarkets_cust_app/data_model/product_mini_response.dart';
import 'package:afriomarkets_cust_app/data_model/product_details_response.dart';
import 'package:afriomarkets_cust_app/data_model/category_response.dart';
import 'package:afriomarkets_cust_app/data_model/brand_response.dart' hide Meta;
import 'package:afriomarkets_cust_app/data_model/slider_response.dart';
import 'package:afriomarkets_cust_app/data_model/variant_response.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';

/// Central Medusa service — wraps the Medusa v1 storefront API and maps
/// responses to the legacy data models used throughout the app.
class MedusaService {
  static final String _baseUrl = AppConfig.MEDUSA_BASE_URL;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Internal cache: stableId(int) → Medusa string product ID ───────────
  // Populated whenever a product list is fetched.
  static final Map<int, String> _stableIdToMedusaId = {};

  /// Throws a descriptive exception if [body] is an HTML response rather than JSON.
  /// This surfaces a clear error via safeApiCall instead of a cryptic FormatException.
  static void _assertJson(http.Response response) {
    final trimmed = response.body.trimLeft();
    if (trimmed.startsWith('<')) {
      final snippet =
          trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
      print('[MedusaService] HTML Response detected: $snippet');
      throw Exception(
          'Medusa API returned HTML (status ${response.statusCode}) '
          'for ${response.request?.url}. '
          'Snippet: $snippet');
    }
    if (response.statusCode >= 400) {
      final snippet =
          trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
      throw Exception('Medusa API error ${response.statusCode} for '
          '${response.request?.url}: $snippet');
    }
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // Products — mapped to legacy ProductMiniResponse
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches products from Medusa `/store/products` and maps to
  /// [ProductMiniResponse] so the rest of the app keeps working unchanged.
  ///
  /// Pass [categoryId] (the Medusa category string ID) to filter by category.
  static Future<ProductMiniResponse> getProductsMapped({
    int page = 1,
    int limit = 20,
    String? categoryId,
    List<String>? brandIds,
    double? minPrice,
    double? maxPrice,
    String? q,
  }) async {
    return _getProductsInternal(
      page: page, 
      limit: limit, 
      categoryId: categoryId, 
      brandIds: brandIds,
      minPrice: minPrice,
      maxPrice: maxPrice,
      q: q,
    );
  }

  /// Fetches specific products by their Medusa string IDs.
  static Future<ProductMiniResponse> getProductsByIdsMapped(List<String> ids, {int page = 1, int limit = 20}) async {
    if (ids.isEmpty) return ProductMiniResponse(products: [], success: true, status: 200);
    return _getProductsInternal(page: page, limit: limit, ids: ids);
  }

  static Future<ProductMiniResponse> _getProductsInternal({
    int page = 1,
    int limit = 20,
    String? categoryId,
    List<String>? brandIds,
    double? minPrice,
    double? maxPrice,
    String? q,
    List<String>? ids,
  }) async {
    return safeApiCall(() async {
      final offset = (page - 1) * limit;

      final queryParams = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        'expand': 'variants,variants.prices,images',
      };
      
      if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id[]'] = categoryId;
      if (q != null && q.isNotEmpty) queryParams['q'] = q;

      // Medusa v1 filtering extensions
      if (minPrice != null) queryParams['min_price'] = minPrice.toInt().toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toInt().toString();

      var uri = Uri.parse('$_baseUrl/store/products').replace(queryParameters: queryParams);
      
      // Handle multiple IDs and Brand IDs (collections) manually
      String url = uri.toString();
      if (ids != null && ids.isNotEmpty) {
        for (var id in ids) {
          url += '&id[]=$id';
        }
      }
      if (brandIds != null && brandIds.isNotEmpty) {
        for (var bid in brandIds) {
          url += '&collection_id[]=$bid';
        }
      }
      uri = Uri.parse(url);

      final response = await http.get(uri, headers: _headers);
      _assertJson(response);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawProducts = body['products'] ?? [];
      final int total = body['count'] ?? rawProducts.length;

      final products = rawProducts.map((p) {
        final sid = _stableId(p['id']);
        _stableIdToMedusaId[sid] = p['id'].toString();
        final price = _extractPrice(p);
        return Product(
          id: sid,
          name: p['title'] ?? '',
          thumbnail_image: p['thumbnail'] ?? '',
          main_price: price,
          stroked_price: price, // Can add exact comparisons with Medusa's original_price vs calculated_price if available natively later
          has_discount: false,
          rating: 0,
          sales: 0,
          links: null,
        );
      }).toList();

      return ProductMiniResponse(
        products: products,
        success: true,
        status: 200,
        meta: Meta(
          currentPage: page,
          from: offset + 1,
          lastPage: (total / limit).ceil(),
          perPage: limit,
          to: offset + products.length,
          total: total,
        ),
      );
    }, ProductMiniResponse(products: [], success: false, status: 0));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Product Details — mapped to legacy ProductDetailsResponse
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches a single Medusa product by its Medusa string ID and maps it to
  /// the legacy [ProductDetailsResponse] / [DetailedProduct] model.
  static Future<ProductDetailsResponse> getProductDetailsMapped(
      String medusaProductId) async {
    return safeApiCall(() async {
      final uri = Uri.parse('$_baseUrl/store/products/$medusaProductId')
          .replace(queryParameters: {
        'expand': 'variants,variants.prices,images,tags,options,variants.options',
      });
      final response = await http.get(uri, headers: _headers);
      _assertJson(response);

      if (response.statusCode != 200) {
        return ProductDetailsResponse(
            detailed_products: [], success: false, status: response.statusCode);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) {
        return ProductDetailsResponse(
            detailed_products: [], success: false, status: 404);
      }

      final sid = _stableId(p['id']);
      _stableIdToMedusaId[sid] = p['id'].toString();

      final mainPriceStr = _extractPrice(p);
      final calculablePrice = _extractRawAmount(p);

      // Map Medusa images → legacy Photo list
      final photos = <Photo>[];
      final images = p['images'] as List? ?? [];
      for (final img in images) {
        final url = img['url'] as String? ?? '';
        if (url.isNotEmpty) photos.add(Photo(variant: '', path: url));
      }
      // Fallback to thumbnail if no images
      if (photos.isEmpty && (p['thumbnail'] as String?) != null) {
        photos.add(Photo(variant: '', path: p['thumbnail'] as String));
      }

      // Stock from first variant (or 99 as a reasonable default)
      int stock = 99;
      final variants = p['variants'] as List? ?? [];
      if (variants.isNotEmpty) {
        final inv = variants.first['inventory_quantity'] as int? ?? 0;
        stock = inv > 0 ? inv : 99;
      }

      // Tags
      final tagObjs = p['tags'] as List? ?? [];
      final tags =
          tagObjs.map<String>((t) => t['value']?.toString() ?? '').toList();

      // Attempt to locate the cheapest Variant specifically to sort the options natively
      final preferredCurrency = RegionService.currencyCodeSync.toLowerCase();
      Map<String, dynamic>? cheapestVariant;
      Map<String, dynamic>? cheapestPrice;

      for (final variant in (p['variants'] as List? ?? [])) {
        final prices = variant['prices'] as List? ?? [];
        for (final price in prices) {
           final code = (price['currency_code'] as String?)?.toLowerCase();
           if (code == preferredCurrency) {
              if (cheapestPrice == null || (price['amount'] as int) < (cheapestPrice['amount'] as int)) {
                   cheapestPrice = price;
                   cheapestVariant = variant;
              }
           }
        }
      }

      // Map Medusa implicit Options to choice_options correctly bridging legacy variants UI
      final choiceOptions = <ChoiceOption>[];
      final options = p['options'] as List? ?? [];
      for (final opt in options) {
        final optId = opt['id']?.toString() ?? '';
        final title = opt['title']?.toString() ?? '';
        
        String? preferredValue;
        if (cheapestVariant != null) {
           final vOptions = cheapestVariant['options'] as List? ?? [];
           for (final vo in vOptions) {
               if (vo['option_id'] == optId && vo['value'] != null) {
                   preferredValue = vo['value'].toString();
               }
           }
        }

        final Set<String> uniqueValues = {};
        for(final v in p['variants'] as List? ?? []) {
          for(final vo in v['options'] as List? ?? []) {
            if(vo['option_id'] == optId && vo['value'] != null) {
              uniqueValues.add(vo['value'].toString());
            }
          }
        }
        
        if (title.isNotEmpty && uniqueValues.isNotEmpty) {
           List<String> sortedOptions = uniqueValues.toList();
           // Force cheapest option variant to index 0 ensuring correct default UI selection
           if (preferredValue != null && sortedOptions.contains(preferredValue)) {
               sortedOptions.remove(preferredValue);
               sortedOptions.insert(0, preferredValue);
           }
           choiceOptions.add(ChoiceOption(name: optId, title: title, options: sortedOptions));
        }
      }

      final detail = DetailedProduct(
        id: sid,
        name: p['title'] ?? '',
        added_by: 'admin',
        seller_id: 0,
        shop_id: 0,
        shop_name: p['collection']?['title'] ?? 'Afriomarkets',
        shop_logo: '',
        photos: photos,
        thumbnail_image: p['thumbnail'] ?? '',
        tags: tags,
        price_high_low: mainPriceStr,
        choice_options: choiceOptions,
        colors: [], // Medusa rarely formats colors via explicit objects, strictly parsed via options array natively

        has_discount: false,
        stroked_price: mainPriceStr,
        main_price: mainPriceStr,
        calculable_price: calculablePrice,
        currency_symbol: PriceHelper.getSymbol(RegionService.currencyCodeSync),
        current_stock: stock,
        unit: '',
        rating: 0,
        rating_count: 0,
        earn_point: 0,
        description: (p['description'] as String?)?.isNotEmpty == true
            ? p['description'] as String
            : 'No description available.',
        video_link: null,
        link: '$_baseUrl/products/${p['handle'] ?? ''}',
        brand: null,
      );

      return ProductDetailsResponse(
        detailed_products: [detail],
        success: true,
        status: 200,
      );
    },
        ProductDetailsResponse(
            detailed_products: [], success: false, status: 0));
  }

  /// Find the Medusa string product ID for a legacy stable int ID.
  /// If not cached (e.g. cold launch → deep link), fetches the first 100
  /// products to build the cache, then looks up.
  static Future<String?> getMedusaIdForStableId(int stableId) async {
    if (_stableIdToMedusaId.containsKey(stableId)) {
      return _stableIdToMedusaId[stableId];
    }
    // Warm the cache
    await getProductsMapped(page: 1, limit: 100);
    return _stableIdToMedusaId[stableId];
  }

  /// Returns a [VariantResponse] derived from the selected product variant explicitly matching the Medusa payloads.
  /// If [selectedChoices] is empty/null, it natively defaults heavily to the lowest priced matching region variant dynamically mimicking Cart standards.
  static Future<VariantResponse> getVariantInfoForStableId(int stableId, {String? selectedChoices}) async {
    final medusaId = await getMedusaIdForStableId(stableId);
    if (medusaId == null) return VariantResponse();

    return safeApiCall(() async {
      final uri = Uri.parse('$_baseUrl/store/products/$medusaId')
          .replace(queryParameters: {'expand': 'variants,variants.prices,variants.options,options'});
      final response = await http.get(uri, headers: _headers);
      _assertJson(response);
      if (response.statusCode != 200) return VariantResponse();

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) return VariantResponse();

      final preferredCurrency = RegionService.currencyCodeSync.toLowerCase();
      List variants = p['variants'] as List? ?? [];
      Map<String, dynamic>? selectedVariant;

      if (selectedChoices != null && selectedChoices.isNotEmpty) {
         final choicesList = selectedChoices.split(',').map((e)=>e.trim()).toList();
         for(final variant in variants) {
            final vOptions = variant['options'] as List? ?? [];
            final vOptionValues = vOptions.map((v) => v['value'].toString().trim()).toList();
            bool matchesAll = true;
            for (final c in choicesList) {
                if (!vOptionValues.contains(c)) {
                    matchesAll = false; break;
                }
            }
            if (matchesAll) {
                selectedVariant = variant;
                break;
            }
         }
      }

      Map<String, dynamic>? chosenPrice;
      if (selectedVariant != null) {
         final prices = selectedVariant['prices'] as List? ?? [];
         for (final price in prices) {
            if ((price['currency_code'] as String?)?.toLowerCase() == preferredCurrency) {
                chosenPrice = price; break;
            }
         }
      } else {
         for (final variant in variants) {
            final prices = variant['prices'] as List? ?? [];
            for (final price in prices) {
               if ((price['currency_code'] as String?)?.toLowerCase() == preferredCurrency) {
                  if (chosenPrice == null || (price['amount'] as int) < (chosenPrice['amount'] as int)) {
                       chosenPrice = price;
                       selectedVariant = variant;
                  }
               }
            }
         }
      }

      if (chosenPrice != null) {
          final amount = chosenPrice['amount'] as int? ?? 0;
          final currency = (chosenPrice['currency_code'] as String?)?.toUpperCase() ?? 'NGN';
          final stock = (selectedVariant?['inventory_quantity'] as int?) ?? 99;
          return VariantResponse(
            price: amount.toDouble(),
            price_string: PriceHelper.formatPrice(amount, currency),
            stock: stock > 0 ? stock : 99,
            variant: selectedChoices ?? '',
            image: '',
          );
      }

      return VariantResponse();
    }, VariantResponse());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Categories — mapped to legacy CategoryResponse
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<CategoryResponse> getCategoriesMapped({
    String? parentId,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, String>{
        'limit': '100',
        if (parentId != null && parentId.isNotEmpty)
          'parent_category_id': parentId,
      };
      final uri = Uri.parse('$_baseUrl/store/product-categories')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawCats = body['product_categories'] ?? [];

      final categories = rawCats.map((c) {
        final childCount = (c['category_children'] as List?)?.length ?? 0;
        return Category(
          id: _stableId(c['id']),
          name: c['name'] ?? '',
          banner: '',
          icon: '',
          number_of_children: childCount,
          links: null,
        );
      }).toList();

      return CategoryResponse(
        categories: categories,
        success: true,
        status: 200,
      );
    }, CategoryResponse(categories: [], success: false, status: 0));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Collections (Brands) — mapped to legacy BrandResponse
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<BrandResponse> getBrandsMapped({
    String? q,
  }) async {
    return safeApiCall(() async {
      final uri = Uri.parse('$_baseUrl/store/collections');
      final response = await http.get(uri, headers: _headers);
      _assertJson(response);
      
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawCols = body['collections'] ?? [];

      final brands = rawCols.map((c) {
        return Brands(
          id: _stableId(c['id']),
          name: c['title'] ?? '',
          logo: '', // Medusa collections don't have logos by default, can use metadata if present
          links: BrandsLinks(products: ''),
        );
      }).toList();

      return BrandResponse(
        brands: brands,
        success: true,
        status: 200,
      );
    }, BrandResponse(brands: [], success: false, status: 0));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sliders / Carousel
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<SliderResponse> getCarouselSliders({int count = 5}) async {
    return safeApiCall(() async {
      final response = await http.get(
        Uri.parse('$_baseUrl/store/products?limit=$count&offset=0'
            '&expand=images'),
        headers: _headers,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawProducts = body['products'] ?? [];

      final sliders = rawProducts
          .where((p) =>
              p['thumbnail'] != null && (p['thumbnail'] as String).isNotEmpty)
          .map((p) => Slider(photo: p['thumbnail']))
          .toList();

      return SliderResponse(
        sliders: sliders,
        success: true,
        status: 200,
      );
    }, SliderResponse(sliders: [], success: false, status: 0));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Raw API helpers (kept for other parts of the app)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getProducts({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/store/products?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    _assertJson(response);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRegions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/store/regions'),
      headers: _headers,
    );
    _assertJson(response);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createCart(String regionId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/store/carts'),
      headers: _headers,
      body: jsonEncode({'region_id': regionId}),
    );
    _assertJson(response);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addToCart(
    String cartId,
    String variantId,
    int quantity,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/store/carts/$cartId/line-items'),
      headers: _headers,
      body: jsonEncode({
        'variant_id': variantId,
        'quantity': quantity,
      }),
    );
    _assertJson(response);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCollections() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/store/collections'),
      headers: _headers,
    );
    _assertJson(response);
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Price Extractors (Cheapest variant fallback)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stable positive int from a Medusa string ID so legacy int-based UI works.
  static int _stableId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId == null) return 0;
    return rawId.toString().hashCode.abs();
  }

  static Map<String, dynamic>? _getCheapestVariantPrice(Map<String, dynamic> product) {
    final preferredCurrency = RegionService.currencyCodeSync.toLowerCase();
    Map<String, dynamic>? cheapestVariantPrice;
    
    final variants = product['variants'] as List? ?? [];
    for (final variant in variants) {
      final prices = variant['prices'] as List? ?? [];
      for (final price in prices) {
         final code = (price['currency_code'] as String?)?.toLowerCase();
         if (code == preferredCurrency) {
            if (cheapestVariantPrice == null || (price['amount'] as int) < (cheapestVariantPrice['amount'] as int)) {
                 cheapestVariantPrice = price;
            }
         }
      }
    }
    return cheapestVariantPrice;
  }

  /// Formatted price string pulling the mathematically cheapest precise variant.
  static String _extractPrice(Map<String, dynamic> product) {
     try {
       final price = _getCheapestVariantPrice(product);
       if (price != null) {
          final amount = price['amount'] as int? ?? 0;
          final currency = (price['currency_code'] as String?)?.toUpperCase() ?? 'NGN';
          return PriceHelper.formatPrice(amount, currency);
       }
       return 'Price N/A';
     } catch (_) {
       return 'Price N/A';
     }
  }

  /// Raw numeric amount calculating the true cheapest variant matching region locks.
  static double _extractRawAmount(Map<String, dynamic> product) {
     try {
       final price = _getCheapestVariantPrice(product);
       if (price != null) {
           return ((price['amount'] as int?) ?? 0).toDouble();
       }
       return 0.0;
     } catch (_) {
       return 0.0;
     }
  }
}
