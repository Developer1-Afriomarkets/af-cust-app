import 'package:flutter/material.dart' hide Slider;
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';
import 'package:afriomarkets_cust_app/repositories/sliders_repository.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:afriomarkets_cust_app/ui_elements/state_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/market_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/store_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/screens/seller_details.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:afriomarkets_cust_app/screens/explorer/blog_story_page.dart';

class ExplorerOverview extends StatefulWidget {
  final ExplorerContext explorerContext;
  final ValueChanged<ExplorerContext> onContextChanged;
  /// Shared scroll controller threaded from ExplorerMain so the outer
  /// AppBar can read offset and blend its background over the hero.
  final ScrollController? scrollController;
  /// Called when the user overscrolls downward at the top of the list,
  /// triggering the fullscreen immersive geo-explorer view.
  final VoidCallback? onImmersiveRequested;

  const ExplorerOverview({
    Key? key,
    required this.explorerContext,
    required this.onContextChanged,
    this.scrollController,
    this.onImmersiveRequested,
  }) : super(key: key);

  @override
  _ExplorerOverviewState createState() => _ExplorerOverviewState();
}

class _ExplorerOverviewState extends State<ExplorerOverview> {
  final ExplorerRepository _repository = ExplorerRepository();

  List<dynamic> _carouselSliderList = [];
  List<dynamic> _categoryList = [];

  bool _showAllContextEntities = false;
  bool _showAllTopProducts = false;

  // ── New Sliver Hero state ─────────────────────────────────────────────────
  int _heroTabIndex = 0;
  static const List<String> _heroTabLabels = ["Featured", "Markets", "Stores", "Products"];
  bool _immersiveLaunching = false; // guard against double-fire

  @override
  void initState() {
    super.initState();
    _fetchBannersAndCategories();

    // ── Overscroll trigger for immersive view ──────────────────────────────
    // OverscrollNotification with stretch:true gets absorbed by SliverAppBar.
    // Listening directly to the shared ScrollController is more reliable:
    // when the user pulls DOWN past the top (offset goes negative on iOS
    // BouncingScrollPhysics), we trigger the immersive view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController?.addListener(_checkImmersiveOverscroll);
    });
  }

  void _checkImmersiveOverscroll() {
    final ctrl = widget.scrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    // On iOS with BouncingScrollPhysics the offset goes negative when the user
    // pulls down past the top. -30 is a deliberate, perceptible pull.
    if (ctrl.offset < -30 && !_immersiveLaunching) {
      _immersiveLaunching = true;
      widget.onImmersiveRequested?.call();
      // Reset guard after a delay so subsequent pulls can retrigger
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _immersiveLaunching = false);
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_checkImmersiveOverscroll);
    super.dispose();
  }

  void _fetchBannersAndCategories() async {
    // Sliders
    var carouselResponse = await SlidersRepository().getSliders();
    for (var slider in carouselResponse.sliders) {
      _carouselSliderList.add(slider);
    }
    // Categories
    var categoryResponse = await CategoryRepository().getFeturedCategories();
    _categoryList.addAll(categoryResponse.categories);

    if (mounted) setState(() {});
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll, bool isExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyTheme.primaryText(context)),
          ),
          if (onViewAll != null)
             InkWell(
               onTap: onViewAll,
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 4.0),
                 child: Text(
                   isExpanded ? "View Less" : "View All", 
                   style: TextStyle(color: MyTheme.accent_color, fontSize: 13, fontWeight: FontWeight.w600)
                 ),
               ),
             )
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7, // More vertical space for StoreCard
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            decoration: BoxDecoration(
              color: MyTheme.surface(context),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntitiesSliver() {
    // If at Store level
    if (widget.explorerContext.isAtStoreLevel) {
       return const SliverToBoxAdapter(child: SizedBox.shrink()); 
    }

    // If at Market level
    if (widget.explorerContext.isAtMarketLevel) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Stores in ${widget.explorerContext.selectedMarket?.marketName}", 
                onViewAll: () => setState(() => _showAllContextEntities = !_showAllContextEntities),
                isExpanded: _showAllContextEntities),
            const SizedBox(height: 16),
            FutureBuilder(
              future: _repository.getStoresByMarket(widget.explorerContext.selectedMarket!.id),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No stores found in this market.")));
                
                if (!_showAllContextEntities) {
                   return _buildStoreHorizontalList(snapshot.data!);
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.65, 
                    crossAxisSpacing: 16, 
                    mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => StoreCard(
                    store: snapshot.data![index],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // If at State level
    if (widget.explorerContext.isAtStateLevel) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Markets in ${widget.explorerContext.selectedState?.stateName}", 
                onViewAll: () => setState(() => _showAllContextEntities = !_showAllContextEntities),
                isExpanded: _showAllContextEntities),
            const SizedBox(height: 16),
            FutureBuilder(
              future: _repository.getMarketsByState(widget.explorerContext.selectedState!.id),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No markets found in this state.")));
                
                if (!_showAllContextEntities) {
                   return SizedBox(
                     height: 180,
                     child: ListView.separated(
                       scrollDirection: Axis.horizontal,
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       itemCount: snapshot.data!.length,
                       separatorBuilder: (context, index) => const SizedBox(width: 14),
                       itemBuilder: (context, index) => SizedBox(
                         width: 150,
                         child: MarketSquareCard(
                           market: snapshot.data![index],
                           onTap: () => widget.onContextChanged(widget.explorerContext.withMarket(snapshot.data![index])),
                         ),
                       )
                     ),
                   );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.9, crossAxisSpacing: 16, mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => MarketSquareCard(
                    market: snapshot.data![index],
                    onTap: () => widget.onContextChanged(widget.explorerContext.withMarket(snapshot.data![index])),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // If at Region level (States)
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Explore States", 
              onViewAll: () => setState(() => _showAllContextEntities = !_showAllContextEntities),
              isExpanded: _showAllContextEntities),
          const SizedBox(height: 16),
          FutureBuilder(
            future: _repository.getStates(),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No states available.")));
              
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => SizedBox(
                    width: 140,
                    child: StateSquareCard(
                      stateModel: snapshot.data![index],
                      onTap: () => widget.onContextChanged(widget.explorerContext.withState(snapshot.data![index])),
                    ),
                  )
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("Featured Stores"),
          const SizedBox(height: 16),
          FutureBuilder(
            future: _repository.getAllStores(regionId: RegionService.currentRegionSync?.id),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 // Fallback to fetch any stores if regional one is empty
                 return FutureBuilder(
                   future: _repository.getAllStores(),
                   builder: (context, AsyncSnapshot<List<dynamic>> fallbackSnapshot) {
                      if (fallbackSnapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                      if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No stores found.")));
                      return _buildStoreHorizontalList(fallbackSnapshot.data!);
                   },
                 );
              }
              return _buildStoreHorizontalList(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHorizontalList(List<dynamic> stores) {
    return SizedBox(
      height: 280, // Increased to 280 to prevent RenderFlex overflows
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stores.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(
          width: 220,
          child: StoreCard(
            store: stores[index],
          ),
        )
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  NEW SLIVER HERO — lives in the CustomScrollView sliver list.
  //  The original _buildContextualHeroBanner() below is preserved for reuse.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a SliverAppBar that acts as the full-bleed immersive hero for
  /// the Explorer Overview screen, following the seller_details.dart pattern.
  Widget _buildExplorerSliverHero() {
    final isDark = MyTheme.isDark(context);
    final size = MediaQuery.of(context).size;
    final expandedHeight = size.height * 0.46;

    // ── Contextual copy ──────────────────────────────────────────────────────
    String heroTitle, heroMeta, heroSeed, peekTitle, peekSeed;
    if (widget.explorerContext.isAtMarketLevel) {
      heroTitle = widget.explorerContext.selectedMarket!.marketName;
      heroMeta  = "Market Hub  ·  ${widget.explorerContext.selectedState?.stateName ?? 'Nigeria'}  ·  Open";
      heroSeed  = "market_${widget.explorerContext.selectedMarket!.id}";
      peekTitle = "${widget.explorerContext.selectedState?.stateName ?? 'Featured'} Hub";
      peekSeed  = "peek_market_${widget.explorerContext.selectedMarket!.id}";
    } else if (widget.explorerContext.isAtStateLevel) {
      heroTitle = "${widget.explorerContext.selectedState!.stateName} Markets";
      heroMeta  = "State Hub  ·  Nigeria  ·  Live";
      heroSeed  = "state_${widget.explorerContext.selectedState!.id}";
      peekTitle = "Top Stores";
      peekSeed  = "peek_state_${widget.explorerContext.selectedState!.id}";
    } else {
      heroTitle = "Aba Trade Complex";
      heroMeta  = "Flagship Market  ·  Abia  ·  Featured";
      heroSeed  = "african_market_featured";
      peekTitle = "Alaba Int'l";
      peekSeed  = "peek_alaba_intl";
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: false,
      // stretch:false is CRITICAL — stretch:true causes SliverAppBar to
      // absorb the overscroll gesture via StretchMode, which prevents the
      // ScrollController from seeing a negative offset.
      stretch: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroBackground(
          isDark: isDark,
          heroTitle: heroTitle,
          heroMeta: heroMeta,
          heroSeed: heroSeed,
          peekTitle: peekTitle,
          peekSeed: peekSeed,
        ),
      ),
    );
  }

  Widget _buildHeroBackground({
    required bool isDark,
    required String heroTitle,
    required String heroMeta,
    required String heroSeed,
    required String peekTitle,
    required String peekSeed,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1 ── Full-bleed background image
        CachedNetworkImage(
          imageUrl: "https://picsum.photos/seed/$heroSeed/900/500",
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(decoration: const BoxDecoration(gradient: MyTheme.heroGradient)),
          errorWidget: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: MyTheme.heroGradient)),
        ),

        // 2 ── Decorative African silhouette
        Positioned.fill(
          child: CustomPaint(
            painter: AfricanSilhouettePainter(baseColor: MyTheme.golden, opacity: 0.25),
          ),
        ),

        // 3 ── Bottom-to-top dark scrim for text legibility
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.42, 1.0],
                colors: [
                  Color(0x00000000),
                  Color(0x55000000),
                  Color(0xDD000000),
                ],
              ),
            ),
          ),
        ),

        // 4 ── Content column: tab nav ↑ → floating card ↓
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildHeroTabNav(),
              ),
            ),
            const Spacer(),
            // ── Pull-to-explore affordance ──────────────────────────────────
            // Visible tap target as a reliable fallback alongside the
            // ScrollController overscroll trigger.
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_immersiveLaunching) {
                    _immersiveLaunching = true;
                    widget.onImmersiveRequested?.call();
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _immersiveLaunching = false);
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        _immersiveLaunching ? 'Loading...' : 'Explore Immersively',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Main floating info card
                  Expanded(
                    child: _buildHeroInfoCard(
                      title: heroTitle,
                      meta: heroMeta,
                      seed: heroSeed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Peek card — right edge hint of next item
                  _buildHeroPeekCard(title: peekTitle, seed: peekSeed),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Horizontal scrollable tab nav inside the hero.
  Widget _buildHeroTabNav() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _heroTabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 28),
        itemBuilder: (context, i) {
          final active = _heroTabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _heroTabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _heroTabLabels[i],
                style: TextStyle(
                  color: active ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Semi-transparent charcoal info card (lower-left of hero).
  Widget _buildHeroInfoCard({required String title, required String meta, required String seed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xD91A1A1A), // charcoal ~85% opacity
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Portrait thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: "https://picsum.photos/seed/${seed}_thumb/80/100",
              width: 44,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 44, height: 60, color: MyTheme.golden.withOpacity(0.25)),
              errorWidget: (_, __, ___) => Container(
                width: 44, height: 60,
                decoration: BoxDecoration(
                  color: MyTheme.accent_color.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white54, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFFA9A9A9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Golden circular CTA (theme-adapted from the reference's neon-green)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MyTheme.golden,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MyTheme.golden.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1400), size: 18),
          ),
        ],
      ),
    );
  }

  /// Peek card — partial right-edge card hinting horizontal scrollability.
  Widget _buildHeroPeekCard({required String title, required String seed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: "https://picsum.photos/seed/$seed/180/160",
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: MyTheme.accent_color.withOpacity(0.35)),
              errorWidget: (_, __, ___) => Container(
                color: MyTheme.accent_brown,
                child: const Icon(Icons.photo_rounded, color: Colors.white24, size: 24),
              ),
            ),
            // Scrim
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            // Label
            Positioned(
              bottom: 7, left: 7, right: 7,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Chevron pill
            Positioned(
              top: 7, right: 7,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: MyTheme.golden.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A1400), size: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Category filter chips row displayed immediately below the hero.
  Widget _buildHeroCategoryChipsSliver() {
    // Use loaded categories or fall back to static marketplace buckets
    final List<Map<String, String>> chips = _categoryList.isNotEmpty
        ? _categoryList.take(7).map<Map<String, String>>((c) => {
              'label': (c.name ?? 'Category') as String,
              'seed': 'cat_${c.id ?? c.name}',
            }).toList()
        : [
            {'label': 'Electronics', 'seed': 'electronics_mkt'},
            {'label': 'Fashion',     'seed': 'fashion_mkt'},
            {'label': 'Food & Drink','seed': 'food_mkt'},
            {'label': 'Crafts',      'seed': 'crafts_mkt'},
            {'label': 'Textiles',    'seed': 'textiles_mkt'},
            {'label': 'Art',         'seed': 'art_mkt'},
            {'label': 'Agro',        'seed': 'agro_mkt'},
          ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 112,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  CachedNetworkImage(
                    imageUrl: "https://picsum.photos/seed/${chip['seed']}/224/144",
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: MyTheme.border(context)),
                    errorWidget: (_, __, ___) => Container(
                      color: MyTheme.surface(context),
                      child: Icon(Icons.category_rounded, color: MyTheme.secondaryText(context), size: 22),
                    ),
                  ),
                  // Dark tint
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.52),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Label
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        chip['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PHASE 7 - CONTEXTUAL DATA VISUALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  // ignore: unused_element
  // Kept for reuse outside ExplorerOverview (e.g. embedded hero in other screens).
  Widget _buildContextualHeroBanner() {
    final isDark = MyTheme.isDark(context);
    final accentColor = MyTheme.primary(context);

    String title = "Discover Africa";
    String subtitle = "Explore vibrant markets, unique cultures, and untold economic stories.";
    String? backgroundId;
    
    if (widget.explorerContext.isAtStoreLevel) {
       title = "Shop at ${widget.explorerContext.selectedStore!.name}";
       subtitle = "Your direct connection to localized artisan crafts.";
       backgroundId = "store_${widget.explorerContext.selectedStore!.id}";
    } else if (widget.explorerContext.isAtMarketLevel) {
       title = "Welcome to ${widget.explorerContext.selectedMarket!.marketName}";
       subtitle = "A bustling hub for trade, culture, and community growth.";
       backgroundId = "market_${widget.explorerContext.selectedMarket!.id}";
    } else if (widget.explorerContext.isAtStateLevel) {
       title = "Explore ${widget.explorerContext.selectedState!.stateName}";
       subtitle = widget.explorerContext.selectedState!.funFact != null && widget.explorerContext.selectedState!.funFact!.isNotEmpty 
           ? widget.explorerContext.selectedState!.funFact! 
           : "Your gateway to local experiences and massive economic opportunities.";
       backgroundId = "state_${widget.explorerContext.selectedState!.id}";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image/Gradient
            Positioned.fill(
              child: backgroundId != null 
                ? CachedNetworkImage(
                    imageUrl: "https://picsum.photos/seed/$backgroundId/800/400",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: accentColor),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: MyTheme.heroGradient,
                    ),
                  ),
            ),
            // Fire/Gold Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      MyTheme.accent_brown.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // African Silhouette
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden,
                  opacity: 0.15,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: MyTheme.secondary_color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "LIVE EXPLORER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // CTA Circle
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MyTheme.golden.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: MyTheme.golden.withOpacity(0.4)),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSliver() {
    return FutureBuilder(
      future: _repository.getContextStats(widget.explorerContext),
      builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final stats = snapshot.data!;
        
        final icons = [Icons.insights_rounded, Icons.trending_up_rounded, Icons.groups_rounded, Icons.storefront_rounded];
        final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFEA4335), const Color(0xFFFBBC05)];
        
        final List<Widget> children = [];
        int i = 0;
        stats.forEach((key, value) {
          children.add(_buildStatChip(key, value, icons[i % icons.length], colors[i % colors.length]));
          if (i < stats.length - 1) children.add(const SizedBox(width: 12));
          i++;
        });

        return SizedBox(
           height: 100,
           child: ListView(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             scrollDirection: Axis.horizontal,
             physics: const BouncingScrollPhysics(),
             children: children,
           ),
        );
      }
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    final isDark = MyTheme.isDark(context);
    
    return Container(
      width: 140,
      margin: const EdgeInsets.only(bottom: 4), // space for shadow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Tiny background accent
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.05,
              child: Icon(icon, size: 60, color: color),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: MyTheme.secondaryText(context),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: MyTheme.primaryText(context),
                        letterSpacing: -0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // MOCK Trend indicator
                  Icon(
                    Icons.trending_up_rounded,
                    size: 12,
                    color: MyTheme.market_green.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdBannerSliver() {
    return FutureBuilder(
       future: _repository.getContextAds(widget.explorerContext),
       builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
         if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
         final ad = snapshot.data!.first;
         return Container(
           margin: const EdgeInsets.symmetric(horizontal: 16),
           height: 150,
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(12),
             image: DecorationImage(
               image: NetworkImage(ad["imageUrl"]!),
               fit: BoxFit.cover,
               colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
             ),
           ),
           child: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(ad["title"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 const SizedBox(height: 4),
                 Text(ad["subtitle"]!, style: const TextStyle(color: Colors.white, fontSize: 12,), textAlign: TextAlign.center,),
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                   decoration: BoxDecoration(color: MyTheme.accent_color, borderRadius: BorderRadius.circular(12)),
                   child: Text(ad["cta"]!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                 )
               ],
             ),
           ),
         );
       }
    );
  }

  Widget _buildHighlightsSliver() {
    return FutureBuilder(
      future: _repository.getContextHighlights(widget.explorerContext),
      builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final highlight = snapshot.data![index];
              final colorValue = int.tryParse(highlight["color"]!) ?? 0xFF000000;
              final Color iconColor = Color(colorValue);
              
              return Container(
                 width: 240,
                 margin: const EdgeInsets.only(right: 16),
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: MyTheme.surface(context),
                   borderRadius: BorderRadius.circular(14.0),
                   border: Border.all(color: MyTheme.border(context).withOpacity(0.5)),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.04),
                       blurRadius: 10,
                       offset: const Offset(0, 4),
                     ),
                   ],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(
                        children: [
                           Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: iconColor.withOpacity(0.1),
                               shape: BoxShape.circle,
                             ),
                             child: Icon(Icons.auto_awesome_rounded, size: 14, color: iconColor),
                           ),
                           const SizedBox(width: 10),
                           Expanded(child: Text(highlight["title"]!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: MyTheme.primaryText(context)), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(highlight["desc"]!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12, height: 1.5)),
                   ],
                 ),
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildStoriesSliver() {
    return FutureBuilder(
      future: _repository.getContextStories(widget.explorerContext),
      builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final story = snapshot.data![index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BlogStoryPage(story: story)));
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: MyTheme.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: MyTheme.isDark(context) ? Colors.black54 : Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: story["imageUrl"]!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: MyTheme.border(context)),
                                ),
                              ),
                              Positioned(
                                top: 12, left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("BLOG", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            story["title"]!, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3, color: MyTheme.primaryText(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildTopProductsSliver() {
    return SliverToBoxAdapter(
      child: FutureBuilder(
        future: _repository.getProductsByContext(widget.explorerContext),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _showAllTopProducts ? _buildLoadingGrid() : const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
          if (!snapshot.hasData || snapshot.data!.products.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No products.")));

          if (!_showAllTopProducts) {
             return SizedBox(
               height: 280, // Safe height for StoreCard
               child: ListView.separated(
                 scrollDirection: Axis.horizontal,
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 itemCount: snapshot.data!.products.length,
                 separatorBuilder: (context, index) => const SizedBox(width: 14),
                 itemBuilder: (context, index) {
                   final product = snapshot.data!.products[index];
                   return SizedBox(
                     width: 150,
                     child: ProductCard(
                       id: product.id,
                       image: product.thumbnail_image,
                       name: product.name,
                       main_price: product.main_price,
                       stroked_price: product.stroked_price,
                       has_discount: product.has_discount,
                     ),
                   );
                 }
               ),
             );
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.products.length,
            itemBuilder: (context, index) {
              final product = snapshot.data!.products[index];
              return ProductCard(
                id: product.id,
                image: product.thumbnail_image,
                name: product.name,
                main_price: product.main_price,
                stroked_price: product.stroked_price,
                has_discount: product.has_discount,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.explorerContext.isAtStoreLevel) {
      // Direct pass-through for the embedded seller UI if we drill all the way down.
      return SellerDetails(id: widget.explorerContext.selectedStore!.id ?? 0);
    }


    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Fallback: catch OverscrollNotification on Android (ClampingScrollPhysics
        // doesn't produce negative offsets, but does fire OverscrollNotification).
        if (notification is OverscrollNotification &&
            notification.overscroll < 0 &&
            !_immersiveLaunching &&
            widget.onImmersiveRequested != null) {
          _immersiveLaunching = true;
          widget.onImmersiveRequested!();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _immersiveLaunching = false);
          });
        }
        return false;
      },
      child: CustomScrollView(
        // Use the shared controller if provided; fall back to a local one.
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── New immersive sliver hero (seller_details pattern) ──────────────
          _buildExplorerSliverHero(),
          // ── Category chips immediately below the hero ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: _buildHeroCategoryChipsSliver(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ─── Phase 7 Contextual Slivers ───
          SliverToBoxAdapter(
            child: _buildSectionHeader(
               widget.explorerContext.isAtStoreLevel ? "Store Analytics" : widget.explorerContext.isAtMarketLevel ? "Market Analytics" : widget.explorerContext.isAtStateLevel ? "State Analytics" : "Regional Analytics"
            )
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildAnalyticsSliver()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          _buildEntitiesSliver(),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildAdBannerSliver()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(child: _buildSectionHeader("Economic & Cultural Highlights")),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildHighlightsSliver()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(child: _buildSectionHeader("Stories & Blogs")),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildStoriesSliver()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(child: _buildSectionHeader(
             "Top Products",
             onViewAll: () => setState(() => _showAllTopProducts = !_showAllTopProducts),
             isExpanded: _showAllTopProducts
          )),
          _buildTopProductsSliver(),
          
          const SliverToBoxAdapter(child: SizedBox(height: 60)), // Bottom padding
        ],
      ),   // end CustomScrollView
    );     // end NotificationListener
  }
}
