import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'dart:math';

class MarketSquareCard extends StatelessWidget {
  final MarketModel market;
  final VoidCallback? onTap;

  const MarketSquareCard({Key? key, required this.market, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    final accentColor = MyTheme.primary(context);
    final surfaceColor = MyTheme.surface(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: surfaceColor,
          border: Border.all(
            color: MyTheme.border(context).withOpacity(0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Stack(
            children: [
              // Decorative background gradient/pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Brand silhouette overlay
              Positioned(
                right: -15,
                top: -15,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 90,
                    color: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      market.marketName,
                      style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Enter Market',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: accentColor,
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
      ),
    );
  }
}
