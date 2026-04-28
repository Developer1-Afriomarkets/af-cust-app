import 'package:afriomarkets_cust_app/screens/seller_products.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/list_product_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/mini_product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:afriomarkets_cust_app/repositories/shop_repository.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class SellerDetails extends StatefulWidget {
  final dynamic id;

  SellerDetails({Key? key, required this.id}) : super(key: key);

  @override
  _SellerDetailsState createState() => _SellerDetailsState();
}

class _SellerDetailsState extends State<SellerDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScrollController _mainScrollController = ScrollController();

  //init
  int _current_slider = 0;
  List<dynamic> _carouselImageList = [];
  bool _carouselInit = false;
  var _shopDetails = null;

  List<dynamic> _newArrivalProducts = [];
  bool _newArrivalProductInit = false;
  List<dynamic> _topProducts = [];
  bool _topProductInit = false;
  List<dynamic> _featuredProducts = [];
  bool _featuredProductInit = false;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    fetchAll();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  fetchAll() {
    fetchProductDetails();
    fetchNewArrivalProducts();
    fetchTopProducts();
    fetchFeaturedProducts();
  }

  fetchProductDetails() async {
    var shopDetailsResponse = await ShopRepository().getShopInfo(id: widget.id);

    if (shopDetailsResponse.shops.isNotEmpty) {
      _shopDetails = shopDetailsResponse.shops[0];
    }

    if (_shopDetails != null) {
      _shopDetails.sliders.forEach((slider) {
        _carouselImageList.add(slider);
      });
    }
    _carouselInit = true;

    setState(() {});
  }

  fetchNewArrivalProducts() async {
    var newArrivalProductResponse =
        await ShopRepository().getNewFromThisSellerProducts(id: widget.id);
    _newArrivalProducts.addAll(newArrivalProductResponse.products);
    _newArrivalProductInit = true;

    setState(() {});
  }

  fetchTopProducts() async {
    var topProductResponse =
        await ShopRepository().getTopFromThisSellerProducts(id: widget.id);
    _topProducts.addAll(topProductResponse.products);
    _topProductInit = true;
    setState(() {});
  }

  fetchFeaturedProducts() async {
    var featuredProductResponse =
        await ShopRepository().getfeaturedFromThisSellerProducts(id: widget.id);
    _featuredProducts.addAll(featuredProductResponse.products);
    _featuredProductInit = true;
    setState(() {});
  }

  reset() {
    _shopDetails = null;
    _carouselImageList.clear();
    _carouselInit = false;
    _newArrivalProducts.clear();
    _topProducts.clear();
    _featuredProducts.clear();
    _topProductInit = false;
    _newArrivalProductInit = false;
    _featuredProductInit = false;
    setState(() {});
  }

  String? get _bannerImage {
    if (_shopDetails == null) return null;
    if (_shopDetails.banner != null && _shopDetails.banner.toString().isNotEmpty) {
      return _shopDetails.banner;
    }
    if (_carouselImageList.isNotEmpty && _carouselImageList[0] != null) {
      return _carouselImageList[0];
    }
    return null;
  }

  String? get _logoImage {
    if (_shopDetails == null) return null;
    if (_shopDetails.logo != null && _shopDetails.logo.toString().isNotEmpty) {
      return _shopDetails.logo;
    }
    return null;
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.background(context),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: MyTheme.surface(context),
          onRefresh: _onPageRefresh,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. Immersive Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                elevation: 0,
                backgroundColor: isDark ? MyTheme.accent_brown : MyTheme.accent_color,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Background
                      _bannerImage != null && PathHelper.getImageUrl(_bannerImage) != null
                          ? CachedNetworkImage(
                              imageUrl: PathHelper.getImageUrl(_bannerImage)!,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(decoration: const BoxDecoration(gradient: MyTheme.heroGradient)),
                            )
                          : Container(decoration: const BoxDecoration(gradient: MyTheme.heroGradient)),
                      
                      // Soft Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),

                      // Store Info Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Logo
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: MyTheme.golden, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: _logoImage != null && PathHelper.getImageUrl(_logoImage) != null
                                        ? CachedNetworkImage(
                                            imageUrl: PathHelper.getImageUrl(_logoImage)!,
                                            fit: BoxFit.cover,
                                          )
                                        : ShimmerHelper().buildBasicShimmer(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _shopDetails?.name ?? "Loading...",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _shopDetails?.tagline ?? "Authentic Artisanal Marketplace",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: MyTheme.teal_accent, size: 14),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Verified Store",
                                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.star_rounded, color: MyTheme.golden, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${_shopDetails?.rating ?? '4.8'}",
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              // 2. Tab Bar Section
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: MyTheme.accent_color,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: MyTheme.primaryText(context),
                    unselectedLabelColor: MyTheme.secondaryText(context),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    tabs: const [
                      Tab(text: "OVERVIEW"),
                      Tab(text: "PRODUCTS"),
                      Tab(text: "REVIEWS"),
                    ],
                  ),
                  color: MyTheme.surface(context),
                ),
              ),

              // 3. Main Content
              SliverPadding(
                padding: const EdgeInsets.only(top: 24),
                sliver: SliverToBoxAdapter(
                  child: [
                    _buildOverviewTab(),
                    _buildProductsTab(),
                    _buildReviewsTab(),
                  ][_tabController.index > 2 ? 0 : _tabController.index],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        bottomNavigationBar: _shopDetails != null ? _buildModernBottomBar() : null,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildSimpleStat("Total Products", "${_topProducts.length + 10}+", Icons.inventory_2_rounded, MyTheme.accent_color),
              _buildSimpleStat("Reg. Since", "2021", Icons.event_available_rounded, MyTheme.market_green),
              _buildSimpleStat("Response", "99%", Icons.bolt_rounded, MyTheme.golden),
              _buildSimpleStat("Delivery", "< 24h", Icons.local_shipping_rounded, MyTheme.secondary_color),
            ],
          ),
          const SizedBox(height: 32),
          
          // About Section
          Text("About this Store", style: TextStyle(color: MyTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            "Welcome to ${_shopDetails?.name ?? 'our store'}. We specialize in high-quality artisanal products sourced directly from local markets. Our mission is to bridge the gap between traditional craftsmanship and modern convenience.",
            style: TextStyle(color: MyTheme.secondaryText(context), height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // New Arrivals Horizontal
          if (_newArrivalProducts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("New Arrivals", style: TextStyle(color: MyTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.w800)),
                TextButton(onPressed: () => _tabController.animateTo(1), child: Text("View All", style: TextStyle(color: MyTheme.accent_color))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240, // Increased to prevent overflows
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _newArrivalProducts.length,
                separatorBuilder: (c, i) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: 140,
                  child: ProductCard(
                    id: _newArrivalProducts[index].id,
                    image: _newArrivalProducts[index].thumbnail_image,
                    name: _newArrivalProducts[index].name,
                    main_price: _newArrivalProducts[index].main_price,
                    stroked_price: _newArrivalProducts[index].stroked_price,
                    has_discount: _newArrivalProducts[index].has_discount,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_featuredProducts.isEmpty && _topProducts.isEmpty) {
      return Center(child: Text("No products available."));
    }
    
    final allProducts = [..._featuredProducts, ..._topProducts];
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: allProducts.length,
      itemBuilder: (context, index) => ProductCard(
        id: allProducts[index].id,
        image: allProducts[index].thumbnail_image,
        name: allProducts[index].name,
        main_price: allProducts[index].main_price,
        stroked_price: allProducts[index].stroked_price,
        has_discount: allProducts[index].has_discount,
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 60, color: MyTheme.secondaryText(context).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No reviews yet", style: TextStyle(color: MyTheme.primaryText(context), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Be the first to share your experience with this store.", textAlign: TextAlign.center, style: TextStyle(color: MyTheme.secondaryText(context))),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyTheme.border(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text(label, style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.primary(context),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: MyTheme.primary(context).withOpacity(0.4),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return SellerProducts(id: _shopDetails.id, shop_name: _shopDetails.name);
          }));
        },
        child: const Text(
          "CONTACT STORE",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.color});

  final TabBar _tabBar;
  final Color color;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
