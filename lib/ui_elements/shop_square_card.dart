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
          borderRadius: BorderRadius.circular(16.0),
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
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: (() {
                          String? imageUrl = PathHelper.getImageUrl(widget.image);
                          return imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      ShimmerHelper().buildBasicShimmer(),
                                  errorWidget: (context, url, error) => Image.asset(
                                    'assets/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/placeholder.png',
                                  fit: BoxFit.cover,
                                );
                        })(),
                      ),
                      // Subtle gradient overlay for the image
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name ?? "",
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            color: MyTheme.primaryText(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: MyTheme.golden, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Top Rated",
                            style: TextStyle(
                              color: MyTheme.secondaryText(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}
