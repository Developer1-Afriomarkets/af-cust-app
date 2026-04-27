import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/screens/product_details.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';

class MiniProductCard extends StatefulWidget {
  int? id;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;

  MiniProductCard(
      {Key? key,
      this.id,
      this.image,
      this.name,
      this.main_price,
      this.stroked_price,
      this.has_discount})
      : super(key: key);

  @override
  _MiniProductCardState createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<MiniProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(id: widget.id ?? 0);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  width: double.infinity,
                  height: (MediaQuery.of(context).size.width - 36) / 3.5,
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
              SizedBox(
                height: 32,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Text(
                    widget.name ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(
                  widget.main_price ?? "",
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: MyTheme.primary(context),
                      fontSize: 11,
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
                            fontSize: 9,
                            fontWeight: FontWeight.w500),
                      ),
                    )
                  : Container(),
            ]),
      ),
    );
  }
}
