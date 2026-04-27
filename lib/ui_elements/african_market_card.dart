import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

/// A vibrant, color-coded card for African markets/states/regions.
///
/// Mirrors the web's `RegionCard` pattern with gradient backgrounds,
/// emoji icons, and a "Discover →" call-to-action.
class AfricanMarketCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;

  const AfricanMarketCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle in top-right
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Decorative circle in bottom-left
            Positioned(
              bottom: -20,
              left: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Emoji badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // CTA
                  Row(
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrolling section of African market cards.
/// Used for "Explore African Markets" and "Shop by Region" sections.
class AfricanMarketSection extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final List<AfricanMarketCard> cards;

  const AfricanMarketSection({
    Key? key,
    required this.title,
    this.actionText,
    this.onActionTap,
    required this.cards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: MyTheme.sectionHeading),
              if (actionText != null)
                GestureDetector(
                  onTap: onActionTap,
                  child: Text(actionText!, style: MyTheme.sectionLink),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal scroll of cards
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            physics: const BouncingScrollPhysics(),
            children: cards,
          ),
        ),
      ],
    );
  }
}
