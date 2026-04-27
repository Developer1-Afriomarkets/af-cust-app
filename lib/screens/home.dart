import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_sections/animated_sidebar.dart';
import 'package:afriomarkets_cust_app/screens/filter.dart';
import 'package:afriomarkets_cust_app/screens/category_products.dart';
import 'package:afriomarkets_cust_app/screens/category_list.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:afriomarkets_cust_app/data_model/slider_response.dart' as model;
import 'package:afriomarkets_cust_app/repositories/sliders_repository.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:afriomarkets_cust_app/repositories/product_repository.dart';

import 'package:shimmer/shimmer.dart';

import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

import 'package:afriomarkets_cust_app/screens/explorer/explorer_main.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';
import 'package:afriomarkets_cust_app/ui_elements/state_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/market_square_card.dart';
import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';

class Home extends StatefulWidget {
  Home(
      {Key? key,
      this.title,
      this.show_back_button = false,
      this.go_back = true})
      : super(key: key);

  final String? title;
  final bool show_back_button;
  final bool go_back;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController? _featuredProductScrollController;
  ScrollController _mainScrollController = ScrollController();

  List<model.Slider> _carouselSliderList = [];
  var _featuredCategoryList = [];
  var _featuredProductList = [];
  bool _isProductInitial = true;
  bool _isCategoryInitial = true;
  bool _isCarouselInitial = true;
  int _totalProductData = 0;
  int _productPage = 1;
  bool _showProductLoadingContainer = false;

  bool _showAllProducts = false;

  @override
  void initState() {
    super.initState();
    fetchAll();

    _mainScrollController.addListener(() {
      if (_mainScrollController.position.pixels ==
          _mainScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        fetchFeaturedProducts();
      }
    });
  }

  fetchAll() {
    fetchCarouselImages();
    fetchFeaturedCategories();
    fetchFeaturedProducts();
  }

  fetchCarouselImages() async {
    var carouselResponse = await SlidersRepository().getSliders();
    for (var slider in carouselResponse.sliders) {
      _carouselSliderList.add(slider);
    }
    _isCarouselInitial = false;
    if (mounted) setState(() {});
  }

  fetchFeaturedCategories() async {
    var categoryResponse = await CategoryRepository().getFeturedCategories();
    _featuredCategoryList.addAll(categoryResponse.categories);
    _isCategoryInitial = false;
    if (mounted) setState(() {});
  }

  fetchFeaturedProducts() async {
    var productResponse = await ProductRepository().getFeaturedProducts(
      page: _productPage,
    );

    _featuredProductList.addAll(productResponse.products);
    _isProductInitial = false;
    _totalProductData = productResponse.meta?.total ?? 0;
    _showProductLoadingContainer = false;
    if (mounted) setState(() {});
  }

  reset() {
    _carouselSliderList.clear();
    _featuredCategoryList.clear();
    _isCarouselInitial = true;
    _isCategoryInitial = true;
    setState(() {});
    resetProductList();
  }

  Future<void> _onRefresh() async {
    reset();
    fetchAll();
  }

  resetProductList() {
    _featuredProductList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.go_back,
      child: Directionality(
        textDirection:
            app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: MyTheme.background(context),
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              RefreshIndicator(
                color: MyTheme.primary(context),
                backgroundColor: MyTheme.surface(context),
                onRefresh: _onRefresh,
                displacement: 0,
                child: CustomScrollView(
                  controller: _mainScrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: const SizedBox(height: 8)),

                    // ─── 1. HERO BANNER ─────────────────────────────
                    SliverToBoxAdapter(child: _buildHeroBanner()),

                    SliverToBoxAdapter(child: const SizedBox(height: 24)),

                    // ─── 2. FEATURED CATEGORIES ─────────────────────
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(
                      'Browse Categories',
                      onViewAll: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CategoryList(is_base_category: true);
                        }));
                      },
                    )),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          height: 110,
                          child: _buildCategoryChips(),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: const SizedBox(height: 28)),

                    // ─── 3. EXPLORE AFRICAN MARKETS ──────────────────
                    SliverToBoxAdapter(child: _buildExploreMarketsSection()),

                    SliverToBoxAdapter(child: const SizedBox(height: 28)),

                    // ─── 4. POPULAR PRODUCTS ────────────────────────
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(
                      'Popular Products',
                      onViewAll: () {
                         setState(() {
                           _showAllProducts = !_showAllProducts;
                         });
                      },
                      isExpanded: _showAllProducts,
                    )),
                    SliverToBoxAdapter(child: const SizedBox(height: 12)),

                    // Product grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildProductGrid(),
                    ),

                    SliverToBoxAdapter(child: const SizedBox(height: 28)),

                    // ─── 5. SHOP BY REGION ───────────────────────────
                    SliverToBoxAdapter(child: _buildExploreStatesSection()),

                    SliverToBoxAdapter(child: const SizedBox(height: 100)),
                  ],
                ),
              ),
              // Loading indicator for infinite scroll
              Align(
                alignment: Alignment.center,
                child: _buildProductLoadingContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  1. HERO BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroBanner() {
    if (_isCarouselInitial && _carouselSliderList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    if (_carouselSliderList.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        viewportFraction: 0.9,
        enableInfiniteScroll: true,
        autoPlay: true,
      ),
      items: _carouselSliderList.map((slider) {
        return Builder(
          builder: (BuildContext context) {
            final colorHexStr = slider.colorHex ?? '0xFF2E7D32';
            final colorValue = int.tryParse(colorHexStr) ?? 0xFF2E7D32;
            final color = Color(colorValue);

            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: slider.photo != null
                    ? DecorationImage(
                        image: NetworkImage(slider.photo!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4), BlendMode.darken),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                   if (slider.photo == null) ...[
                     Positioned(right: -25, top: -25, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
                     Positioned(left: -15, bottom: -15, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
                   ],
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         if (slider.type != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(slider.type!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                         if (slider.title != null)
                            Text(slider.title!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                         if (slider.subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(slider.subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                         ],
                         if (slider.actionText != null) ...[
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(color: MyTheme.golden, borderRadius: BorderRadius.circular(20)),
                                  child: Text(slider.actionText!, style: const TextStyle(color: Color(0xFF344F16), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                         ]
                       ],
                     ),
                   ),
                 ],
               ),
            );
          },
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  2. CATEGORY CHIPS (pill-shaped, horizontally scrolling)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips() {
    if (_isCategoryInitial && _featuredCategoryList.isEmpty) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ShimmerHelper().buildBasicShimmer(height: 100, width: 100),
        ),
      );
    }

    if (_featuredCategoryList.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.home_screen_no_category_found,
          style: TextStyle(color: MyTheme.secondaryText(context)),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _featuredCategoryList.length,
      itemBuilder: (context, index) {
        final cat = _featuredCategoryList[index];
        final color =
            MyTheme.marketCardColors[index % MyTheme.marketCardColors.length];

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return CategoryProducts(
                category_id: cat.id,
                category_name: cat.name,
              );
            }));
          },
          child: Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: (cat.banner != null &&
                          cat.banner!.isNotEmpty &&
                          cat.banner!.startsWith('http'))
                      ? ClipOval(
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: cat.banner!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.category, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                // Name
                Text(
                  cat.name ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MyTheme.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  3. EXPLORE AFRICAN MARKETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExploreMarketsSection() {
    return FutureBuilder(
      future: ExplorerRepository().getTopMarkets(),
      builder: (context, AsyncSnapshot<List<MarketModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerHelper().buildBasicShimmer(height: 150, width: 150),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Explore Top Markets', onViewAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExplorerMain()));
            }),
            const SizedBox(height: 12),
            SizedBox(
              height: 165,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 150,
                      child: MarketSquareCard(
                        market: snapshot.data![index],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return ExplorerMain(
                               initialContext: ExplorerContext().withMarket(snapshot.data![index])
                            );
                          }));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  4. PRODUCT GRID
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProductGrid() {
    if (_isProductInitial && _featuredProductList.isEmpty) {
      return SliverToBoxAdapter(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: _featuredProductScrollController,
        ),
      );
    }

    if (_featuredProductList.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.common_no_product_is_available,
              style: TextStyle(color: MyTheme.secondaryText(context)),
            ),
          ),
        ),
      );
    }

    if (!_showAllProducts) {
       return SliverToBoxAdapter(
         child: SizedBox(
           height: 240,
           child: ListView.separated(
             scrollDirection: Axis.horizontal,
             itemCount: _featuredProductList.length,
             separatorBuilder: (context, index) => const SizedBox(width: 12),
             itemBuilder: (context, index) {
               return SizedBox(
                 width: 150,
                 child: ProductCard(
                   id: _featuredProductList[index].id,
                   image: _featuredProductList[index].thumbnail_image ?? "",
                   name: _featuredProductList[index].name ?? "",
                   main_price: _featuredProductList[index].main_price ?? "",
                   stroked_price: _featuredProductList[index].stroked_price ?? "",
                   has_discount: _featuredProductList[index].has_discount ?? false,
                 ),
               );
             }
           ),
         ),
       );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return ProductCard(
            id: _featuredProductList[index].id,
            image: _featuredProductList[index].thumbnail_image ?? "",
            name: _featuredProductList[index].name ?? "",
            main_price: _featuredProductList[index].main_price ?? "",
            stroked_price: _featuredProductList[index].stroked_price ?? "",
            has_discount: _featuredProductList[index].has_discount ?? false,
          );
        },
        childCount: _featuredProductList.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  5. SHOP BY REGION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExploreStatesSection() {
    return FutureBuilder(
      future: ExplorerRepository().getStates(),
      builder: (context, AsyncSnapshot<List<StateModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerHelper().buildBasicShimmer(height: 150, width: 150),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Explore States', onViewAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExplorerMain()));
            }),
            const SizedBox(height: 12),
            SizedBox(
              height: 165,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 150,
                      child: StateSquareCard(
                        stateModel: snapshot.data![index],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return ExplorerMain(
                               initialContext: ExplorerContext().withState(snapshot.data![index])
                            );
                          }));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll, bool isExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, 
            style: MyTheme.isDark(context) 
                ? MyTheme.sectionHeadingDark 
                : MyTheme.sectionHeading
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(isExpanded ? 'View Less' : 'View All', style: MyTheme.sectionLink),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: MyTheme.golden,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductLoadingContainer() {
    return _showProductLoadingContainer
        ? Container(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color: MyTheme.primary(context),
            ),
          )
        : const SizedBox.shrink();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  APP BAR — modernized with gradient search
  // ═══════════════════════════════════════════════════════════════════════════

  AppBar _buildAppBar(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return AppBar(
      backgroundColor: isDark ? MyTheme.darkCard : MyTheme.accent_color,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden, 
                  opacity: isDark ? 0.3 : 0.5
                ),
              ),
            ),
          ],
        ),
      ),
      leading: widget.show_back_button
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            )
          : IconButton(
              icon: Image.asset(
                'assets/hamburger.png',
                height: 16,
                color: Colors.white,
              ),
              onPressed: () {
                AnimatedSidebarScaffold.of(context)?.toggleMenu();
              },
            ),
      title: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Filter();
          }));
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 18),
              const SizedBox(width: 8),
              Text(
                'Search African markets...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      elevation: 0,
      titleSpacing: 0,
      actions: [
        // Currency indicator
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: MyTheme.golden.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: MyTheme.golden.withOpacity(0.3), width: 1),
              ),
              child: Text(
                PriceHelper.getSymbol(RegionService.currencyCodeSync),
                style: const TextStyle(
                  color: MyTheme.golden,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
