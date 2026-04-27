import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/screens/seller_details.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';

class StoreCard extends StatelessWidget {
  final Shop store;
  final VoidCallback? onTap;

  const StoreCard({
    Key? key, 
    required this.store, 
    this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    
    // Fallback logic for images
    String? bannerUrl = PathHelper.getImageUrl(store.banner);
    String? logoUrl = PathHelper.getImageUrl(store.logo);
    
    return InkWell(
      onTap: onTap ?? () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SellerDetails(id: store.id ?? 0);
        }));
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner & Floating Logo Section
              Expanded(
                flex: 4,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner Image
                    Positioned.fill(
                      child: bannerUrl != null && bannerUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: bannerUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => ShimmerHelper().buildBasicShimmer(radius: 0),
                              errorWidget: (c, u, e) => Container(
                                decoration: const BoxDecoration(gradient: MyTheme.heroGradient),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(gradient: MyTheme.heroGradient),
                            ),
                    ),
                    // Darkening Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Logo (Floating)
                    Positioned(
                      bottom: -15,
                      left: 12,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: MyTheme.golden, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                          ],
                        ),
                        child: ClipOval(
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.storefront_rounded, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                    // Verified Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MyTheme.teal_accent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              "VERIFIED",
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 2. Info Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name ?? "Store Name",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MyTheme.primaryText(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.tagline ?? "Freshly curated artisanal goods",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MyTheme.secondaryText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: MyTheme.golden, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                "${store.rating ?? '4.8'}",
                                style: TextStyle(
                                  color: MyTheme.primaryText(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${store.reviewCount ?? '120'}+)",
                                style: TextStyle(
                                  color: MyTheme.secondaryText(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded, color: MyTheme.accent_color, size: 12),
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
      ),
    );
  }
}
