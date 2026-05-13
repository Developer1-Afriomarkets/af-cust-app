import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExplorerImmersiveView
//
// A fullscreen geographic explorer that inherits the visual language of
// StoryViewer (full-bleed images, progress indicators, close button) and
// extends it with bi-directional swipe navigation:
//
//   ← → Horizontal swipe  : siblings at same level (states / markets)
//   ↓   Drag down         : drill into children (state → markets)
//   ↑   Drag up           : go back to parent level
//
// Progress dots (top strip) mirror StoryViewer's AnimatedProgressBar pattern
// but represent position in the sibling list rather than story duration.
// ─────────────────────────────────────────────────────────────────────────────

/// Describes the geographic level currently displayed.
enum ExplorerLevel { region, state, market }

/// Launched from ExplorerOverview when the user overscrolls downward on the
/// hero SliverAppBar — enters a Deepstash/TikTok-shop-style fullscreen
/// immersive exploration mode.
class ExplorerImmersiveView extends StatefulWidget {
  final ExplorerContext initialContext;
  final ValueChanged<ExplorerContext> onContextChanged;

  /// The sibling items at this level (StateModel list or MarketModel list).
  final List<dynamic> items;

  /// Which item in [items] to show first.
  final int initialIndex;

  /// The geographic level these items represent.
  final ExplorerLevel level;

  const ExplorerImmersiveView({
    Key? key,
    required this.initialContext,
    required this.onContextChanged,
    required this.items,
    this.initialIndex = 0,
    this.level = ExplorerLevel.region,
  }) : super(key: key);

  @override
  _ExplorerImmersiveViewState createState() => _ExplorerImmersiveViewState();
}

class _ExplorerImmersiveViewState extends State<ExplorerImmersiveView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoadingChildren = false;
  bool _showHints = false;

  // Tracks vertical drag for drill-down / pop gesture
  double _verticalDragAccum = 0.0;

  final ExplorerRepository _repo = ExplorerRepository();

  // ── Breadcrumb ─────────────────────────────────────────────────────────────
  List<String> get _breadcrumb {
    final crumbs = <String>['Nigeria'];
    if (widget.initialContext.selectedState != null) {
      crumbs.add(widget.initialContext.selectedState!.stateName);
    }
    if (widget.initialContext.selectedMarket != null) {
      crumbs.add(widget.initialContext.selectedMarket!.marketName);
    }
    return crumbs;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Show swipe hint arrows briefly after open
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHints = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showHints = false);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Item helpers ───────────────────────────────────────────────────────────

  String _imageSeed(int i) {
    final item = widget.items[i];
    if (item is StateModel) return 'state_immersive_${item.id}';
    if (item is MarketModel) return 'market_immersive_${item.id}';
    return 'geo_slide_$i';
  }

  String _title(int i) {
    final item = widget.items[i];
    if (item is StateModel) return item.stateName;
    if (item is MarketModel) return item.marketName;
    return 'Location ${i + 1}';
  }

  String _meta(int i) {
    final item = widget.items[i];
    if (item is StateModel) {
      return 'State  ·  Nigeria  ·  Active';
    }
    if (item is MarketModel) {
      return 'Market Hub  ·  ${widget.initialContext.selectedState?.stateName ?? 'Nigeria'}  ·  Open';
    }
    return 'Region  ·  Africa';
  }

  String _levelTag() {
    switch (widget.level) {
      case ExplorerLevel.state:
        return 'STATE';
      case ExplorerLevel.market:
        return 'MARKET';
      default:
        return 'REGION';
    }
  }

  String _drillLabel() {
    switch (widget.level) {
      case ExplorerLevel.region:
        return 'Explore States';
      case ExplorerLevel.state:
        return 'Explore Markets';
      case ExplorerLevel.market:
        return 'Browse Stores';
    }
  }

  bool get _canDrillDown => widget.level != ExplorerLevel.market;

  // ── Drill navigation ───────────────────────────────────────────────────────

  Future<void> _drillDown() async {
    if (_isLoadingChildren || !_canDrillDown) return;

    setState(() => _isLoadingChildren = true);

    final item = widget.items[_currentIndex];
    List<dynamic> children = [];
    ExplorerContext newCtx = widget.initialContext;
    ExplorerLevel newLevel = ExplorerLevel.state;

    try {
      if (item is StateModel) {
        children = await _repo.getMarketsByState(item.id);
        newCtx = widget.initialContext.withState(item);
        newLevel = ExplorerLevel.state;
      } else if (item is MarketModel) {
        children = await _repo.getStoresByMarket(item.id);
        newCtx = widget.initialContext.withMarket(item);
        newLevel = ExplorerLevel.market;
      }
    } catch (e) {
      debugPrint('[ImmersiveView] drillDown error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoadingChildren = false);

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to explore here yet'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onContextChanged(newCtx);
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, secondaryAnimation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: ExplorerImmersiveView(
              initialContext: newCtx,
              onContextChanged: widget.onContextChanged,
              items: children,
              level: newLevel,
            ),
          );
        },
      ),
    );
  }

  // ── Vertical gesture ───────────────────────────────────────────────────────

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() => _verticalDragAccum += d.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final accumulated = _verticalDragAccum;
    setState(() => _verticalDragAccum = 0);

    if (velocity > 500 || accumulated > 80) {
      // Swipe down → drill in
      _drillDown();
    } else if (velocity < -500 || accumulated < -80) {
      // Swipe up → go back
      Navigator.maybePop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxDots = widget.items.length.clamp(1, 10);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            // ── Main: horizontal sibling PageView ────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => _buildSlide(i, safeBottom),
            ),

            // ── Top gradient + breadcrumb bar ────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: safeTop + 8,
                  left: 16,
                  right: 8,
                  bottom: 14,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xBB000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MyTheme.golden.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _levelTag(),
                        style: const TextStyle(
                          color: Color(0xFF1A1400),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Breadcrumb
                    Expanded(
                      child: Text(
                        _breadcrumb.join(' › '),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Close
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sibling position dots (StoryViewer-style progress strip) ─────
            Positioned(
              top: safeTop + 60,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(maxDots, (i) {
                  final isActive = widget.items.length <= 10
                      ? i == _currentIndex
                      : (i == maxDots - 1 ? _currentIndex >= maxDots - 1 : i == _currentIndex);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Swipe hint arrows ────────────────────────────────────────────
            if (_showHints) ...[
              // Left/right siblings
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHints ? 0.55 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHints ? 0.55 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
              // Drill-down hint (only when possible)
              if (_canDrillDown)
                Positioned(
                  bottom: safeBottom + 175,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showHints ? 0.65 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: const Column(
                      children: [
                        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                        SizedBox(height: 2),
                        Text(
                          'Swipe down to explore',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            // ── Loading overlay (drilling in progress) ───────────────────────
            if (_isLoadingChildren)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading ${_drillLabel()}...',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Individual slide ───────────────────────────────────────────────────────

  Widget _buildSlide(int i, double safeBottom) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed background
        CachedNetworkImage(
          imageUrl: 'https://picsum.photos/seed/${_imageSeed(i)}/900/1600',
          fit: BoxFit.cover,
          placeholder: (_, __) => Shimmer.fromColors(
            baseColor: const Color(0xFF1C1800),
            highlightColor: const Color(0xFF2E2800),
            child: Container(color: Colors.white),
          ),
          errorWidget: (_, __, ___) =>
              Container(decoration: const BoxDecoration(gradient: MyTheme.heroGradient)),
        ),

        // African silhouette decoration
        Positioned.fill(
          child: CustomPaint(
            painter: AfricanSilhouettePainter(baseColor: MyTheme.golden, opacity: 0.28),
          ),
        ),

        // Bottom-heavy dark scrim
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 0.62, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x55000000),
                  Color(0xEE000000),
                ],
              ),
            ),
          ),
        ),

        // Bottom content block
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, safeBottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  _title(i),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.08,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 6),
                // Meta
                Text(
                  _meta(i),
                  style: const TextStyle(
                    color: Color(0xFFA9A9A9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Charcoal info card (mirrors the sliver hero card) ─────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xD91A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MyTheme.golden.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.level == ExplorerLevel.region
                              ? Icons.location_city_rounded
                              : Icons.storefront_rounded,
                          color: MyTheme.golden,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _canDrillDown ? _drillLabel() : 'View Stores',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _canDrillDown
                                  ? 'Swipe down to go deeper'
                                  : 'Tap to browse products',
                              style: const TextStyle(
                                color: Color(0xFF8A8A8A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Golden CTA
                      GestureDetector(
                        onTap: _drillDown,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: MyTheme.golden,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MyTheme.golden.withOpacity(0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.south_rounded,
                            color: Color(0xFF1A1400),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
