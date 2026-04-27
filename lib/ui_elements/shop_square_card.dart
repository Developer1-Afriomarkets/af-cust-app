import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/screens/seller_details.dart';

class ShopSquareCard extends StatefulWidget {
  int? id;
  String? image;
  String? name;

  ShopSquareCard({Key? key, this.id, this.image, this.name}) : super(key: key);

  @override
  _ShopSquareCardState createState() => _ShopSquareCardState();
}

class _ShopSquareCardState extends State<ShopSquareCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SellerDetails(
            id: widget.id ?? 0,
          );
        }));
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: MyTheme.border(context).withOpacity(0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Store Hero Image/Logo
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (() {
                      String? imageUrl = PathHelper.getImageUrl(widget.image);
                      return imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  ShimmerHelper().buildBasicShimmer(radius: 0),
                              errorWidget: (context, url, error) => Container(
                                color: MyTheme.border(context).withOpacity(0.2),
                                child: Icon(Icons.store_rounded, color: MyTheme.secondaryText(context).withOpacity(0.3)),
                              ),
                            )
                          : Container(
                                color: MyTheme.border(context).withOpacity(0.2),
                                child: Icon(Icons.store_rounded, color: MyTheme.secondaryText(context).withOpacity(0.3)),
                              );
                    })(),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Verified Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified_rounded, color: MyTheme.teal_accent, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              // Store Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name ?? "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: MyTheme.golden, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "4.8 (120+)",
                          style: TextStyle(
                            color: MyTheme.secondaryText(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
