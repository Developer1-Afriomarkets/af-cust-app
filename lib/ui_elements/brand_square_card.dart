import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/screens/brand_products.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';

class BrandSquareCard extends StatefulWidget {
  int? id;
  String? image;
  String? name;

  BrandSquareCard({Key? key, this.id, this.image, this.name}) : super(key: key);

  @override
  _BrandSquareCardState createState() => _BrandSquareCardState();
}

class _BrandSquareCardState extends State<BrandSquareCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return BrandProducts(
            id: widget.id ?? 0,
            brand_name: widget.name ?? "",
          );
        }));
      },
      child: Card(
        color: MyTheme.surface(context),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: MyTheme.border(context), width: 1.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0.0,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                  width: double.infinity,
                  height: ((MediaQuery.of(context).size.width - 24) / 2) * .72,
                  child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12), bottom: Radius.zero),
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
                      })())),
              Container(
                height: 40,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    widget.name ?? "",
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}
