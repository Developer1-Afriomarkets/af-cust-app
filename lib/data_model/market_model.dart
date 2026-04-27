class MarketModel {
  final String id;
  final String stateId;
  final String marketName;
  final String? handle;

  MarketModel({
    required this.id,
    required this.stateId,
    required this.marketName,
    this.handle,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'].toString(),
      stateId: json['state_id'].toString(),
      marketName: json['market_name']?.toString() ?? '',
      handle: json['handle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state_id': stateId,
      'market_name': marketName,
      'handle': handle,
    };
  }
}
