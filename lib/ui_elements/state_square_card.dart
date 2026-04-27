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
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.map_outlined,
                    size: 100,
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_city_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stateModel.stateName,
                      style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (stateModel.funFact != null && stateModel.funFact!.isNotEmpty)
                          ? stateModel.funFact!
                          : 'Discover local treasures',
                      style: TextStyle(
                        color: MyTheme.secondaryText(context),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
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
