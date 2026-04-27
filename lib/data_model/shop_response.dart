// To parse this JSON data, do
//
//     final shopResponse = shopResponseFromJson(jsonString);
// https://app.quicktype.io/

import 'dart:convert';

ShopResponse shopResponseFromJson(String str) =>
    ShopResponse.fromJson(json.decode(str));

String shopResponseToJson(ShopResponse data) => json.encode(data.toJson());

class ShopResponse {
  ShopResponse({
    required this.shops,
    this.meta,
    this.success,
    this.status,
  });

  List<Shop> shops;
  Meta? meta;
  bool? success;
  int? status;

  factory ShopResponse.fromJson(Map<String, dynamic> json) => ShopResponse(
        shops: (json["data"] == null)
            ? []
            : List<Shop>.from(json["data"].map((x) => Shop.fromJson(x))),
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(shops.map((x) => x.toJson())),
        "meta": meta?.toJson(),
        "success": success,
        "status": status,
      };
}

class Shop {
  Shop({
    this.id,
    this.name,
    this.logo,
    this.banner,
    this.tagline,
    this.rating,
    this.reviewCount,
    this.metadata,
  });

  dynamic id;
  String? name;
  String? logo;
  String? banner;
  String? tagline;
  double? rating;
  int? reviewCount;
  Map<String, dynamic>? metadata;

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json["id"],
        name: json["name"],
        logo: json["logo"],
        banner: json["banner"],
        tagline: json["tagline"],
        rating: json["rating"]?.toDouble(),
        reviewCount: json["review_count"],
        metadata: json["metadata"],
      );

  factory Shop.fromSupabase(Map<String, dynamic> json) {
    final meta = json['metadata'] ?? {};
    return Shop(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id'].toString()) ?? 0),
      name: json['name'] ?? json['store_name'] ?? '',
      logo: json['logo'] ?? '',
      banner: json['banner'] ?? meta['banner'] ?? '',
      tagline: json['tagline'] ?? meta['tagline'] ?? '',
      rating: (json['rating'] ?? meta['rating'] ?? 4.8).toDouble(),
      reviewCount: json['review_count'] ?? meta['review_count'] ?? 120,
      metadata: meta,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "logo": logo,
        "banner": banner,
        "tagline": tagline,
        "rating": rating,
        "review_count": reviewCount,
        "metadata": metadata,
      };
}

class Meta {
  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  int? currentPage;
  int? from;
  int? lastPage;
  String? path;
  int? perPage;
  int? to;
  int? total;

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        currentPage: json["current_page"],
        from: json["from"],
        lastPage: json["last_page"],
        path: json["path"],
        perPage: json["per_page"],
        to: json["to"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "path": path,
        "per_page": perPage,
        "to": to,
        "total": total,
      };
}
