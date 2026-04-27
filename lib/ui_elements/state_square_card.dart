import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'dart:math';

class StateSquareCard extends StatelessWidget {
  final StateModel stateModel;
  final VoidCallback? onTap;

  const StateSquareCard({Key? key, required this.stateModel, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    
    // Vibrant 'Earth, Gold, and Fire' consistent palette
    final earthyColors = [
      MyTheme.secondary_color, // Fire (Orange)
      MyTheme.golden,          // Gold (Amber)
      MyTheme.accent_brown,    // Earth (Brown)
      MyTheme.market_red,      // Fire (Deep Red)
      MyTheme.teal_accent,     // Earth (Muted Teal)
    ];
    final color = earthyColors[stateModel.stateName.length % earthyColors.length];
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
                bottom: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    Icons.map_outlined,
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
                          Icons.location_city_rounded,
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
                            stateModel.stateName,
                            style: TextStyle(
                              color: MyTheme.primaryText(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              (stateModel.funFact != null && stateModel.funFact!.isNotEmpty)
                                  ? stateModel.funFact!
                                  : 'Discover local treasures and vibrant markets.',
                              style: TextStyle(
                                color: MyTheme.secondaryText(context),
                                fontSize: 10,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Explore',
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
