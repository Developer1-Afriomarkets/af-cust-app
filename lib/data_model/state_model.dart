class StateModel {
  final String id;
  final String stateName;
  final String? funFact;
  final String? handle;
  
  StateModel({
    required this.id,
    required this.stateName,
    this.funFact,
    this.handle,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'].toString(), // UUIDs or strings
      stateName: json['state']?.toString() ?? '',
      funFact: json['fun_fact']?.toString(),
      handle: json['handle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': stateName,
      'fun_fact': funFact,
      'handle': handle,
    };
  }
}
