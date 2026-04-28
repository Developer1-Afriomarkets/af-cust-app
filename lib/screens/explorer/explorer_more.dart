import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/repositories/culture_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/screens/explorer/story_viewer.dart';
import 'package:shimmer/shimmer.dart';

class ExplorerDiscover extends StatefulWidget {
  final ExplorerContext explorerContext;
  final ValueChanged<ExplorerContext>? onContextChanged;

  const ExplorerDiscover({Key? key, required this.explorerContext, this.onContextChanged}) : super(key: key);

  @override
  _ExplorerDiscoverState createState() => _ExplorerDiscoverState();
}

class _ExplorerDiscoverState extends State<ExplorerDiscover> {
  final CultureRepository _repo = CultureRepository();
  int _currentVerticalPage = 0;

  @override
  void dispose() {
    super.dispose();
  }


  String get _contextSubLabel {
    if (widget.explorerContext.isAtMarketLevel) return "Market View";
    if (widget.explorerContext.isAtStateLevel) return "State View";
    return "Regional Overview";
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: const SizedBox(height: 16)),

        // ── 1. Spotlights (tab-filtered, horizontal scroll)
        _buildSectionHeader("Market Spotlights", subtitle: "Tap a level · swipe stories →"),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        _buildTwoDimensionalSpotlights(),

        SliverToBoxAdapter(child: const SizedBox(height: 32)),

        // ── 2. Economic Pulse
        _buildSectionHeader("Economic Pulse", subtitle: _contextSubLabel),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        _buildEconomySliver(),

        SliverToBoxAdapter(child: const SizedBox(height: 32)),

        // ── 3. Artisans
        _buildSectionHeader("Meet the Artisans", subtitle: "The hands behind the craft"),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        _buildArtisansSliver(),

        SliverToBoxAdapter(child: const SizedBox(height: 80)),
      ],
    );
  }


  // ── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: MyTheme.primaryText(context), letterSpacing: -0.4)),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(fontSize: 11, color: MyTheme.secondaryText(context), letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  // ── 2D Spotlights: Tab row (context levels) + Horizontal ListView (stories) ──

  Widget _buildTwoDimensionalSpotlights() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<SpotlightModel>>(
        future: _repo.getAllSpotlights(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _shimmerSpotlightGrid();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

          final all = snapshot.data!;
          final regionRows = all.where((s) => s.contextLevel == 'region').toList();
          final stateRows  = all.where((s) => s.contextLevel == 'state').toList();
          final marketRows = all.where((s) => s.contextLevel == 'market').toList();

          final rows = [regionRows, stateRows, marketRows];
          final rowLabels = ["Region Wide", "By State", "By Market"];
          final rowIcons  = [Icons.public_rounded, Icons.location_city_rounded, Icons.storefront_rounded];

          final currentItems = rows[_currentVerticalPage];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Level Tab Row (scrollable to prevent overflow) ────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(rows.length, (i) {
                    final active = i == _currentVerticalPage;
                    return GestureDetector(
                      onTap: () => setState(() => _currentVerticalPage = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: active
                              ? LinearGradient(colors: [MyTheme.market_red, MyTheme.secondary_color])
                              : null,
                          color: active ? null : MyTheme.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? Colors.transparent : MyTheme.border(context),
                          ),
                          boxShadow: active
                              ? [BoxShadow(color: MyTheme.market_red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rowIcons[i], size: 12, color: active ? Colors.white : MyTheme.secondaryText(context)),
                            const SizedBox(width: 5),
                            Text(
                              rowLabels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : MyTheme.secondaryText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // ── Spotlight row (horizontal) with AnimatedSwitcher ────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  key: ValueKey(_currentVerticalPage),
                  height: 185,
                  child: currentItems.isEmpty
                      ? Center(child: Text("No spotlights at this level yet.", style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 13)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentItems.length,
                          itemBuilder: (context, i) => _buildSpotlightCard(currentItems[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildSpotlightCard(SpotlightModel spotlight) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => StoryViewer(spotlight: spotlight.toMap()),
      )),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: spotlight.thumbnail,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: MyTheme.shimmer_base),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Story ring
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: MyTheme.secondary_color, width: 2.5),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(spotlight.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.play_circle_fill_rounded, color: MyTheme.secondary_color, size: 10),
                      const SizedBox(width: 3),
                      Text("${spotlight.stories.length} slides", style: TextStyle(color: Colors.white70, fontSize: 9)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Economic Pulse ──────────────────────────────────────────────────────────

  Widget _buildEconomySliver() {
    return SliverToBoxAdapter(
      child: FutureBuilder<EconomySnapshot>(
        future: _repo.getEconomyData(widget.explorerContext),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _shimmerBox(220));
          }
          if (!snapshot.hasData) return const SizedBox.shrink();
          final data = snapshot.data!;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: MyTheme.secondary_color.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Decorative glow orb
                  Positioned(top: -50, right: -50, child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: MyTheme.primary(context).withOpacity(0.35), blurRadius: 60, spreadRadius: 10)]))),
                  // Faint chart icon background
                  Positioned(bottom: -20, right: -20, child: Opacity(opacity: 0.07,
                    child: Icon(Icons.show_chart_rounded, size: 200, color: MyTheme.market_green))),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(data.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5))),
                            _liveChip(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(data.description, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65), height: 1.5)),
                        const SizedBox(height: 20),
                        // GDP + Merchants
                        Row(
                          children: [
                            _statPill("GDP Share", data.gdpContribution, Icons.pie_chart_rounded),
                            const SizedBox(width: 10),
                            _statPill("Merchants", data.activeMerchants, Icons.storefront_rounded),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("TOP SECTORS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.45), letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: data.sectors.map((s) {
                            final icon = _iconFor(s['icon'] ?? '');
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                                ),
                                child: Column(
                                  children: [
                                    Container(padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(color: MyTheme.secondary_color.withOpacity(0.18), shape: BoxShape.circle),
                                      child: Icon(icon, color: MyTheme.secondary_color, size: 16)),
                                    const SizedBox(height: 10),
                                    Text(s['percentage'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(s['name'] ?? '', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.55)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MyTheme.market_green.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyTheme.market_green.withOpacity(0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: MyTheme.market_green, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text("LIVE", style: TextStyle(color: MyTheme.market_green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ]),
    );
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: MyTheme.secondary_color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'oil_barrel': return Icons.local_gas_station_rounded;
      case 'eco': return Icons.eco_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      case 'computer': return Icons.computer_rounded;
      case 'movie': return Icons.movie_rounded;
      case 'factory': return Icons.factory_rounded;
      case 'agriculture': return Icons.agriculture_rounded;
      case 'diamond': return Icons.diamond_rounded;
      case 'handyman': return Icons.handyman_rounded;
      case 'storefront': return Icons.storefront_rounded;
      default: return Icons.category_rounded;
    }
  }

  // ── Artisans ────────────────────────────────────────────────────────────────

  Widget _buildArtisansSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: FutureBuilder<List<ArtisanModel>>(
        future: _repo.getArtisans(widget.explorerContext),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: 4,
              itemBuilder: (_, __) => _shimmerBox(200),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

          return SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.73, crossAxisSpacing: 14, mainAxisSpacing: 14),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final a = snapshot.data![i];
              return Container(
                decoration: BoxDecoration(
                  color: MyTheme.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: MyTheme.isDark(context) ? Colors.black26 : Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(imageUrl: a.imageUrl, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: MyTheme.shimmer_base)),
                          // Subtle bottom gradient bleed into card
                          Positioned(bottom: 0, left: 0, right: 0, height: 40,
                            child: Container(decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, MyTheme.surface(context)])))),
                        ],
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(a.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MyTheme.primaryText(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text("${a.craft} · ${a.location}", style: TextStyle(color: MyTheme.primary(context), fontSize: 9, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            Text(a.bio, style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 10, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Shimmer helpers ─────────────────────────────────────────────────────────

  Widget _shimmerBox(double height, {double? width}) {
    return Shimmer.fromColors(
      baseColor: MyTheme.shimmer_base,
      highlightColor: MyTheme.shimmer_highlighted,
      child: Container(height: height, width: width, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
    );
  }

  Widget _shimmerSpotlightGrid() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 14), child: _shimmerBox(200, width: 130)),
      ),
    );
  }
}
