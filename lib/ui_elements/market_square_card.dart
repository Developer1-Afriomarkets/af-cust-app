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
    
    // Vibrant 'Earth, Gold, and Fire' consistent palette
    final earthyColors = [
      MyTheme.market_amber,
      MyTheme.secondary_color,
      MyTheme.market_red,
      MyTheme.teal_accent,
      MyTheme.accent_brown,
    ];
    final color = earthyColors[market.marketName.length % earthyColors.length];
    final surfaceColor = MyTheme.surface(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: surfaceColor,
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              // Decorative background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.12),
                        color.withOpacity(0.01),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Brand silhouette overlay
              Positioned(
                right: -10,
                top: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 70,
                    color: color,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: color,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            market.marketName,
                            style: TextStyle(
                              color: MyTheme.primaryText(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Enter Market',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: color,
                          size: 12,
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
