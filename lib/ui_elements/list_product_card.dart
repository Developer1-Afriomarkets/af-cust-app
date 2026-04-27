import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/screens/product_details.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';

class ListProductCard extends StatefulWidget {
  int? id;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;

  ListProductCard(
      {Key? key,
      this.id,
      this.image,
      this.name,
      this.main_price,
      this.stroked_price,
      this.has_discount})
      : super(key: key);

  @override
  _ListProductCardState createState() => _ListProductCardState();
}

class _ListProductCardState extends State<ListProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            id: widget.id ?? 0,
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
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Container(
              width: 100,
              height: 100,
              child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16), right: Radius.zero),
                  child: CachedNetworkImage(
                    imageUrl: PathHelper.getImageUrlSafe(widget.image),
                    placeholder: (context, url) => ShimmerHelper().buildBasicShimmer(),
                    errorWidget: (context, url, error) => Container(
                      color: MyTheme.surface(context),
                      child: Icon(Icons.image_not_supported_outlined, color: MyTheme.secondaryText(context).withOpacity(0.5), size: 24),
                    ),
                    fit: BoxFit.cover,
                  ))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Text(
                    widget.name ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Text(
                    widget.main_price ?? "",
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: MyTheme.primary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                (widget.has_discount ?? false)
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Text(
                          widget.stroked_price ?? "",
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.secondaryText(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
