import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/screens/product_details.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';

class ProductCard extends StatefulWidget {
  int? id;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;

  ProductCard(
      {Key? key,
      this.id,
      this.image,
      this.name,
      this.main_price,
      this.stroked_price,
      this.has_discount})
      : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            id: widget.id ?? 0,
          );
        }));
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.08),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product image with rounded top corners
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                child: ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.zero,
                  ),
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
                      // Discount badge
                      if (widget.has_discount ?? false)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MyTheme.market_red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Product info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      widget.name ?? "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600),
                    ),
                    // Price row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.main_price ?? "",
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: MyTheme.primary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (widget.has_discount ?? false)
                          Text(
                            widget.stroked_price ?? "",
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.secondaryText(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
