import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/filter.dart';
import 'package:afriomarkets_cust_app/ui_elements/african_market_card.dart';

class MarketExplorer extends StatefulWidget {
  const MarketExplorer({Key? key}) : super(key: key);

  @override
  _MarketExplorerState createState() => _MarketExplorerState();
}

class _MarketExplorerState extends State<MarketExplorer> {
  // Simulated data for the African Marketplace Explorer
  final List<Map<String, dynamic>> _hubs = [
    {
      'country': 'Nigeria',
      'markets': [
        {
          'title': 'Balogun',
          'subtitle': 'Lagos Island • Textiles & Fashion',
          'emoji': '👗'
        },
        {
          'title': 'Computer Village',
          'subtitle': 'Ikeja • Tech & Electronics',
          'emoji': '💻'
        },
        {
          'title': 'Alaba Int.',
          'subtitle': 'Ojo • Electronics & Appliances',
          'emoji': '📺'
        },
        {
          'title': 'Ariaria Int.',
          'subtitle': 'Aba • Leather & Shoes',
          'emoji': '👞'
        },
        {
          'title': 'Main Market',
          'subtitle': 'Onitsha • General Goods',
          'emoji': '🏪'
        },
      ]
    },
    {
      'country': 'Ghana',
      'markets': [
        {
          'title': 'Makola',
          'subtitle': 'Accra • General Goods & Food',
          'emoji': '🍅'
        },
        {
          'title': 'Kaneshie',
          'subtitle': 'Accra • Fabrics & Spices',
          'emoji': '🌶️'
        },
        {
          'title': 'Kejetia',
          'subtitle': 'Kumasi • West Africa’s Largest',
          'emoji': '🏙️'
        },
      ]
    },
    {
      'country': 'Kenya',
      'markets': [
        {
          'title': 'Maasai Market',
          'subtitle': 'Nairobi • Crafts & Souvenirs',
          'emoji': '🏺'
        },
        {
          'title': 'Gikomba',
          'subtitle': 'Nairobi • Thrift & Apparel',
          'emoji': '👕'
        },
      ]
    },
    {
      'country': 'South Africa',
      'markets': [
        {
          'title': 'Rosebank',
          'subtitle': 'Johannesburg • Art & Curios',
          'emoji': '🎨'
        },
        {
          'title': 'Greenmarket Sq.',
          'subtitle': 'Cape Town • Crafts',
          'emoji': '🎭'
        },
      ]
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 16),
          ),
          ..._buildMarketList(),
          SliverToBoxAdapter(
            child: const SizedBox(height: 60),
          )
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Market Explorer',
        style: TextStyle(
          color: MyTheme.accent_color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.map_outlined, color: MyTheme.dark_grey),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover markets across the continent',
            style: TextStyle(
              color: MyTheme.font_grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for a market, city, or country...',
                hintStyle: TextStyle(
                  color: MyTheme.medium_grey,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: MyTheme.medium_grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMarketList() {
    List<Widget> slivers = [];

    for (var hub in _hubs) {
      String country = hub['country'];
      List<dynamic> markets = hub['markets'];

      // Filter markets based on search
      var filteredMarkets = markets.where((m) {
        String title = m['title'].toString().toLowerCase();
        String sub = m['subtitle'].toString().toLowerCase();
        return country.toLowerCase().contains(_searchQuery) ||
            title.contains(_searchQuery) ||
            sub.contains(_searchQuery);
      }).toList();

      if (filteredMarkets.isEmpty) continue;

      // Add Country Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(Icons.location_on, color: MyTheme.teal_accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  country,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Add Markets Grid for this country
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var m = filteredMarkets[index];
                return AfricanMarketCard(
                  title: m['title'],
                  subtitle: m['subtitle'],
                  emoji: m['emoji'],
                  color: MyTheme.marketCardColors[
                      index % MyTheme.marketCardColors.length],
                  onTap: () {
                    // Navigate to filter view for this specific market's sellers
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Filter(
                          selected_filter:
                              "sellers"); // Simulate diving into market sellers
                    }));
                  },
                );
              },
              childCount: filteredMarkets.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
          ),
        ),
      );
    }

    if (slivers.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: MyTheme.medium_grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No markets found for "$_searchQuery"',
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return slivers;
  }
}
