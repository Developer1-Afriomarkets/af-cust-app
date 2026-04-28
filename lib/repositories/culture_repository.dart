import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class SpotlightModel {
  final String id;
  final String title;
  final String subtitle;
  final String thumbnail;
  final String contextLevel; // 'region' | 'state' | 'market'
  final String? contextId;   // id of the state/market this belongs to
  final List<Map<String, dynamic>> stories;

  SpotlightModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    required this.contextLevel,
    this.contextId,
    required this.stories,
  });
}

class ArtisanModel {
  final String id;
  final String name;
  final String craft;
  final String location;
  final String imageUrl;
  final String bio;
  final String? stateId;

  ArtisanModel({
    required this.id,
    required this.name,
    required this.craft,
    required this.location,
    required this.imageUrl,
    required this.bio,
    this.stateId,
  });
}

class EconomySnapshot {
  final String title;
  final String description;
  final String gdpContribution;
  final String activeMerchants;
  final List<Map<String, String>> sectors;

  EconomySnapshot({
    required this.title,
    required this.description,
    required this.gdpContribution,
    required this.activeMerchants,
    required this.sectors,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

/// All data fetched through this repository.
/// Swap out the mock implementations below for real API calls when ready.
class CultureRepository {

  // ── SPOTLIGHTS ──────────────────────────────────────────────────────────────

  /// Returns ALL available spotlights (all context levels).
  Future<List<SpotlightModel>> getAllSpotlights() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _allSpotlights;
  }

  /// Returns spotlights filtered for the given [context].
  Future<List<SpotlightModel>> getMarketSpotlights(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.isAtStateLevel && context.selectedState != null) {
      return _allSpotlights.where((s) => s.stateId == context.selectedState!.id || s.contextLevel == 'state').toList();
    }
    if (context.isAtMarketLevel && context.selectedMarket != null) {
      return _allSpotlights.where((s) => s.contextLevel == 'market' || s.contextLevel == 'state').toList();
    }
    return _allSpotlights; // region level shows everything
  }

  // ── ECONOMY ─────────────────────────────────────────────────────────────────

  Future<EconomySnapshot> getEconomyData(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (context.isAtMarketLevel && context.selectedMarket != null) {
      return EconomySnapshot(
        title: "${context.selectedMarket!.marketName} Economy",
        description: "A vibrant local market generating trade activity and supporting thousands of livelihoods.",
        gdpContribution: "2.1%",
        activeMerchants: "8,400+",
        sectors: [
          {"name": "Retail Trade", "percentage": "55%", "icon": "storefront"},
          {"name": "Food & Farm", "percentage": "30%", "icon": "eco"},
          {"name": "Crafts", "percentage": "15%", "icon": "handyman"},
        ],
      );
    }

    if (context.isAtStateLevel && context.selectedState != null) {
      final name = context.selectedState!.stateName.toLowerCase();
      if (name.contains("lagos")) {
        return EconomySnapshot(
          title: "Lagos State Economy",
          description: "Nigeria's economic engine — the intersection of tech, finance, and culture.",
          gdpContribution: "29.4%",
          activeMerchants: "3.4M+",
          sectors: [
            {"name": "Tech & Services", "percentage": "50%", "icon": "computer"},
            {"name": "Entertainment", "percentage": "30%", "icon": "movie"},
            {"name": "Manufacturing", "percentage": "20%", "icon": "factory"},
          ],
        );
      }
      if (name.contains("kano")) {
        return EconomySnapshot(
          title: "Kano State Economy",
          description: "The historic commercial capital of northern Nigeria with deep roots in trade.",
          gdpContribution: "9.7%",
          activeMerchants: "1.1M+",
          sectors: [
            {"name": "Leather Goods", "percentage": "40%", "icon": "checkroom"},
            {"name": "Agriculture", "percentage": "35%", "icon": "agriculture"},
            {"name": "Textiles", "percentage": "25%", "icon": "eco"},
          ],
        );
      }
      return EconomySnapshot(
        title: "${context.selectedState!.stateName} Economy",
        description: "A thriving local economy contributing significantly to the national GDP.",
        gdpContribution: "5.2%",
        activeMerchants: "420K+",
        sectors: [
          {"name": "Agriculture", "percentage": "45%", "icon": "agriculture"},
          {"name": "Solid Minerals", "percentage": "30%", "icon": "diamond"},
          {"name": "Local Crafts", "percentage": "25%", "icon": "handyman"},
        ],
      );
    }

    return EconomySnapshot(
      title: "West African Economy",
      description: "A booming region driven by natural resources, emerging tech, and rich agricultural exports.",
      gdpContribution: "12.4%",
      activeMerchants: "1.2M+",
      sectors: [
        {"name": "Crude Oil", "percentage": "65%", "icon": "oil_barrel"},
        {"name": "Cocoa Beans", "percentage": "15%", "icon": "eco"},
        {"name": "Textiles", "percentage": "10%", "icon": "checkroom"},
      ],
    );
  }

  // ── ARTISANS ─────────────────────────────────────────────────────────────────

  Future<List<ArtisanModel>> getArtisans(ExplorerContext context) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (context.isAtStateLevel && context.selectedState != null) {
      return _allArtisans.where((a) => a.stateId == context.selectedState!.id).toList().isEmpty
          ? _allArtisans
          : _allArtisans.where((a) => a.stateId == context.selectedState!.id).toList();
    }
    return _allArtisans;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mock Data
  // ─────────────────────────────────────────────────────────────────────────

  static final List<SpotlightModel> _allSpotlights = [
    SpotlightModel(
      id: "1",
      title: "Onitsha Main Market",
      subtitle: "West Africa's Commercial Powerhouse",
      thumbnail: "https://picsum.photos/seed/onitsha_main/400/700",
      contextLevel: "region",
      stories: [
        {"mediaUrl": "https://picsum.photos/seed/onitsha_1/800/1600", "type": "image", "caption": "The sheer scale of Onitsha Main Market makes it one of the largest in West Africa, trading billions of Naira daily.", "duration": 5},
        {"mediaUrl": "https://picsum.photos/seed/onitsha_2/800/1600", "type": "image", "caption": "From imported textiles to local manufactured goods, it's a critical hub for the Nigerian economy.", "duration": 5},
      ],
    ),
    SpotlightModel(
      id: "2",
      title: "Balogun Market",
      subtitle: "The Fashion Capital of Lagos",
      thumbnail: "https://picsum.photos/seed/balogun/400/700",
      contextLevel: "state",
      stories: [
        {"mediaUrl": "https://picsum.photos/seed/balogun_1/800/1600", "type": "image", "caption": "Sprawling across Lagos Island, Balogun Market is the premier destination for Aso Ebi, lace, and ankara fabrics.", "duration": 5},
        {"mediaUrl": "https://picsum.photos/seed/balogun_2/800/1600", "type": "image", "caption": "Navigating the narrow alleys is an experience of vibrant colors and the energetic hustle of Lagos.", "duration": 5},
      ],
    ),
    SpotlightModel(
      id: "3",
      title: "Kurmi Market",
      subtitle: "Centuries of Trans-Saharan Trade",
      thumbnail: "https://picsum.photos/seed/kurmi/400/700",
      contextLevel: "region",
      stories: [
        {"mediaUrl": "https://picsum.photos/seed/kurmi_1/800/1600", "type": "image", "caption": "Established in the 15th century in Kano, Kurmi Market was a central point in the trans-Saharan trade route.", "duration": 5},
        {"mediaUrl": "https://picsum.photos/seed/kurmi_2/800/1600", "type": "image", "caption": "Today, it remains famous for traditional crafts, dyed fabrics, leatherwork, and spices.", "duration": 5},
      ],
    ),
    SpotlightModel(
      id: "4",
      title: "Alaba International",
      subtitle: "West Africa's Tech & Electronics Hub",
      thumbnail: "https://picsum.photos/seed/alaba_int/400/700",
      contextLevel: "state",
      stories: [
        {"mediaUrl": "https://picsum.photos/seed/alaba_1/800/1600", "type": "image", "caption": "Alaba International Market in Lagos is the nerve center for electronics trade across West Africa.", "duration": 5},
        {"mediaUrl": "https://picsum.photos/seed/alaba_2/800/1600", "type": "image", "caption": "Thousands of traders bring cutting-edge technology to everyday consumers in every corner of the continent.", "duration": 5},
      ],
    ),
    SpotlightModel(
      id: "5",
      title: "Ariaria Market",
      subtitle: "The Leather Capital of Nigeria",
      thumbnail: "https://picsum.photos/seed/ariaria/400/700",
      contextLevel: "market",
      stories: [
        {"mediaUrl": "https://picsum.photos/seed/ariaria_1/800/1600", "type": "image", "caption": "Located in Aba, Ariaria International Market is the heartbeat of Nigeria's leather manufacturing industry.", "duration": 5},
        {"mediaUrl": "https://picsum.photos/seed/ariaria_2/800/1600", "type": "image", "caption": "Shoes, bags, and clothing made in Aba are exported across the continent, a testament to local ingenuity.", "duration": 5},
      ],
    ),
  ];

  static final List<ArtisanModel> _allArtisans = [
    ArtisanModel(id: "1", name: "Nneka Eze", craft: "Akwete Weaver", location: "Abia State", imageUrl: "https://picsum.photos/seed/artisan1/300/400", bio: "Preserving the centuries-old tradition of Akwete weaving with vibrant modern patterns."),
    ArtisanModel(id: "2", name: "Oluwaseun Adire", craft: "Indigo Dyer", location: "Ogun State", imageUrl: "https://picsum.photos/seed/artisan2/300/400", bio: "Creating stunning Adire fabrics using traditional resist-dyeing techniques passed down for generations."),
    ArtisanModel(id: "3", name: "Idris Leatherworks", craft: "Leather Artisan", location: "Kano State", imageUrl: "https://picsum.photos/seed/artisan3/300/400", bio: "Crafting premium leather bags and footwear using the famous Kano tannery techniques."),
    ArtisanModel(id: "4", name: "Aminata Woode", craft: "Wood Carver", location: "Osun State", imageUrl: "https://picsum.photos/seed/artisan4/300/400", bio: "Intricate wood carvings reflecting rich cultural stories and heritage."),
  ];
}

extension SpotlightExt on SpotlightModel {
  String? get stateId => null; // extend when real data is available
  Map<String, dynamic> toMap() => {
    "id": id, "title": title, "subtitle": subtitle, "thumbnail": thumbnail,
    "contextLevel": contextLevel, "stories": stories,
  };
}
