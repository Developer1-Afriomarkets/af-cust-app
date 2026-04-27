import 'package:flutter/material.dart' hide Slider;
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';
import 'package:afriomarkets_cust_app/repositories/sliders_repository.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:afriomarkets_cust_app/ui_elements/state_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/market_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/store_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/screens/seller_details.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:afriomarkets_cust_app/screens/explorer/blog_story_page.dart';

class ExplorerOverview extends StatefulWidget {
  final ExplorerContext explorerContext;
  final ValueChanged<ExplorerContext> onContextChanged;

  const ExplorerOverview({
    Key? key,
    required this.explorerContext,
    required this.onContextChanged,
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

  @override
  void initState() {
    super.initState();
    _fetchBannersAndCategories();
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
          childAspectRatio: 0.9,
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
        child: FutureBuilder(
          future: _repository.getStoresByMarket(widget.explorerContext.selectedMarket!.id),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No stores.")));
            
            if (!_showAllContextEntities) {
               return SizedBox(
                 height: 180,
                 child: ListView.separated(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   itemCount: snapshot.data!.length,
                   separatorBuilder: (context, index) => const SizedBox(width: 14),
                   itemBuilder: (context, index) => SizedBox(
                     width: 140,
                     child: StoreSquareCard(
                       store: snapshot.data![index],
                       onTapOverride: () => widget.onContextChanged(widget.explorerContext.withStore(snapshot.data![index])),
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
              itemBuilder: (context, index) => StoreSquareCard(
                store: snapshot.data![index],
                onTapOverride: () => widget.onContextChanged(widget.explorerContext.withStore(snapshot.data![index])),
              ),
            );
          },
        ),
      );
    }

    // If at State level
    if (widget.explorerContext.isAtStateLevel) {
      return SliverToBoxAdapter(
        child: FutureBuilder(
          future: _repository.getMarketsByState(widget.explorerContext.selectedState!.id),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No markets.")));
            
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
      );
    }

    // If at Region level (States)
    return SliverToBoxAdapter(
      child: FutureBuilder(
        future: _repository.getStates(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _showAllContextEntities ? _buildLoadingGrid() : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No states.")));
          
          if (!_showAllContextEntities) {
             return SizedBox(
               height: 180, // StateCards usually fit nicely here
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
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.9, crossAxisSpacing: 16, mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => StateSquareCard(
              stateModel: snapshot.data![index],
              onTap: () => widget.onContextChanged(widget.explorerContext.withState(snapshot.data![index])),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PHASE 7 - CONTEXTUAL DATA VISUALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.4 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                    decoration: BoxDecoration(
                      gradient: MyTheme.heroGradient,
                    ),
                  ),
            ),
            // Glassmorphism Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
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
                  opacity: 0.2,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: MyTheme.golden.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "LIVE EXPLORER",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Pulsing "Learn More" Circle
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyTheme.border(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(6),
                 ),
                 child: Icon(icon, size: 14, color: color),
               ),
               const SizedBox(width: 8),
               Expanded(
                 child: Text(
                   label,
                   style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 11, fontWeight: FontWeight.w600),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: MyTheme.primaryText(context),
              letterSpacing: -0.5,
            ),
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
                   borderRadius: BorderRadius.circular(20.0),
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: MyTheme.isDark(context) ? Colors.black54 : Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
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
          if (snapshot.connectionState == ConnectionState.waiting) return _showAllTopProducts ? _buildLoadingGrid() : const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
          if (!snapshot.hasData || snapshot.data!.products.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No products.")));

          if (!_showAllTopProducts) {
             return SizedBox(
               height: 240,
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
              crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 16, mainAxisSpacing: 16,
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

    String entityHeaderTitle = "Explore States";
    if (widget.explorerContext.isAtMarketLevel) entityHeaderTitle = "Stores in ${widget.explorerContext.selectedMarket?.marketName}";
    else if (widget.explorerContext.isAtStateLevel) entityHeaderTitle = "Markets in ${widget.explorerContext.selectedState?.stateName}";

    return CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 0)),
          SliverToBoxAdapter(child: _buildContextualHeroBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Legacy Global Sliders & Categories (Hidden per request)
          /*
          if (!_isCarouselInitial && _carouselSliderList.isNotEmpty)
            SliverToBoxAdapter(child: _buildHeroBanner()),
          if (!_isCarouselInitial && _carouselSliderList.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          if (!_isCategoryInitial && _categoryList.isNotEmpty)
            SliverToBoxAdapter(child: _buildSectionHeader("Categories")),
          if (!_isCategoryInitial && _categoryList.isNotEmpty)
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
          if (!_isCategoryInitial && _categoryList.isNotEmpty)
            SliverToBoxAdapter(child: _buildCategoryChips()),
          if (!_isCategoryInitial && _categoryList.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          */

          // ─── Phase 7 Contextual Slivers ───
          SliverToBoxAdapter(
            child: _buildSectionHeader(
               widget.explorerContext.isAtStoreLevel ? "Store Analytics" : widget.explorerContext.isAtMarketLevel ? "Market Analytics" : widget.explorerContext.isAtStateLevel ? "State Analytics" : "Regional Analytics"
            )
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildAnalyticsSliver()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(child: _buildSectionHeader(
              entityHeaderTitle,
              onViewAll: () => setState(() => _showAllContextEntities = !_showAllContextEntities),
              isExpanded: _showAllContextEntities
          )),
          SliverToBoxAdapter(child: const SizedBox(height: 4)),
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
      );
  }
}
