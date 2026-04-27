import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

/// Medusa region with its associated countries and currency.
class MedusaRegion {
  final String id;
  final String name;
  final String currencyCode;
  final List<RegionCountry> countries;

  MedusaRegion({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.countries,
  });

  factory MedusaRegion.fromJson(Map<String, dynamic> json) {
    final countries = (json['countries'] as List? ?? [])
        .map((c) => RegionCountry.fromJson(c))
        .toList();
    return MedusaRegion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      currencyCode: (json['currency_code'] as String?)?.toUpperCase() ?? 'NGN',
      countries: countries,
    );
  }
}

class RegionCountry {
  final String iso2;
  final String displayName;

  RegionCountry({required this.iso2, required this.displayName});

  factory RegionCountry.fromJson(Map<String, dynamic> json) {
    return RegionCountry(
      iso2: (json['iso_2'] as String?)?.toLowerCase() ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
    );
  }
}

/// Manages Medusa regions, auto-detection, and persistence.
///
/// Mirrors the web store-context.tsx region logic:
/// 1. On first launch, detect region from device locale (default Nigeria)
/// 2. User can manually switch via RegionPicker
/// 3. Region is persisted in SharedPreferences
class RegionService {
  static const String _regionIdKey = 'medusa_region_id';
  static const String _countryCodeKey = 'medusa_country_code';
  static const String _currencyCodeKey = 'medusa_currency_code';

  static List<MedusaRegion> _cachedRegions = [];
  static MedusaRegion? _currentRegion;

  // ═══════════════════════════════════════════════════════════════════════
  //  Fetch all regions from Medusa
  // ═══════════════════════════════════════════════════════════════════════

  static Future<List<MedusaRegion>> fetchRegions() async {
    if (_cachedRegions.isNotEmpty) return _cachedRegions;

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.MEDUSA_BASE_URL}/store/regions'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> rawRegions = body['regions'] ?? [];
        _cachedRegions =
            rawRegions.map((r) => MedusaRegion.fromJson(r)).toList();
      }
    } catch (e) {
      print('RegionService.fetchRegions error: $e');
    }

    // If fetch failed, provide a sensible default
    if (_cachedRegions.isEmpty) {
      _cachedRegions = [
        MedusaRegion(
          id: 'default_ng',
          name: 'Nigeria',
          currencyCode: 'NGN',
          countries: [
            RegionCountry(iso2: 'ng', displayName: 'Nigeria'),
          ],
        ),
      ];
    }

    return _cachedRegions;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Detect user region from device locale (default: Nigeria)
  // ═══════════════════════════════════════════════════════════════════════

  static Future<MedusaRegion> detectAndSetRegion() async {
    // Check if already stored
    final stored = await getStoredRegion();
    if (stored != null) {
      _currentRegion = stored;
      return stored;
    }

    // Fetch regions
    final regions = await fetchRegions();

    // Try to match device country to a Medusa region using network IP API
    String deviceCountry = 'ng'; // default Nigeria
    try {
      final ipRes = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      if (ipRes.statusCode == 200) {
         final ipData = jsonDecode(ipRes.body);
         if (ipData['countryCode'] != null) {
            deviceCountry = ipData['countryCode'].toString().toLowerCase();
         }
      }
    } catch (_) {
      deviceCountry = 'ng';
    }

    // Find matching region
    MedusaRegion? matched;
    for (final region in regions) {
      for (final country in region.countries) {
        if (country.iso2 == deviceCountry) {
          matched = region;
          break;
        }
      }
      if (matched != null) break;
    }

    // Fallback: Nigeria region or first available
    matched ??= regions.firstWhere(
      (r) => r.countries.any((c) => c.iso2 == 'ng'),
      orElse: () => regions.first,
    );

    await setRegion(matched, deviceCountry);
    return matched;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Get / Set / Store region
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> setRegion(MedusaRegion region, String countryCode) async {
    _currentRegion = region;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionIdKey, region.id);
    await prefs.setString(_countryCodeKey, countryCode);
    await prefs.setString(_currencyCodeKey, region.currencyCode);
    
    // Sync to global SharedValues
    current_region_id.$ = region.id;
    current_region_id.save();
    current_country_code.$ = countryCode;
    current_country_code.save();
  }

  static Future<MedusaRegion?> getStoredRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final regionId = prefs.getString(_regionIdKey);
    if (regionId == null) return null;

    final regions = await fetchRegions();
    try {
      final region = regions.firstWhere((r) => r.id == regionId);
      _currentRegion = region;
      
      // Sync to global SharedValues
      current_region_id.$ = region.id;
      current_region_id.save();
      current_country_code.$ = prefs.getString(_countryCodeKey) ?? 'ng';
      current_country_code.save();
      
      return region;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current region, detecting if needed.
  static Future<MedusaRegion> getCurrentRegion() async {
    if (_currentRegion != null) return _currentRegion!;
    return detectAndSetRegion();
  }

  /// Returns the current currency code (e.g. "NGN", "USD").
  static Future<String> getCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyCodeKey) ?? 'NGN';
  }

  /// Synchronous getter for cached current region (may be null before init).
  static MedusaRegion? get currentRegionSync => _currentRegion;

  /// Synchronous currency code from cache.
  static String get currencyCodeSync => _currentRegion?.currencyCode ?? 'NGN';
}
