// To parse this JSON data, do
//
//     final sliderResponse = sliderResponseFromJson(jsonString);
//https://app.quicktype.io/
import 'dart:convert';

SliderResponse sliderResponseFromJson(String str) =>
    SliderResponse.fromJson(json.decode(str));

String sliderResponseToJson(SliderResponse data) => json.encode(data.toJson());

class SliderResponse {
  SliderResponse({
    required this.sliders,
    this.success,
    this.status,
  });

  List<Slider> sliders;
  bool? success;
  int? status;

  factory SliderResponse.fromJson(Map<String, dynamic> json) => SliderResponse(
        sliders: (json["data"] == null)
            ? []
            : List<Slider>.from(json["data"].map((x) => Slider.fromJson(x))),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(sliders.map((x) => x.toJson())),
        "success": success,
        "status": status,
      };
}

class Slider {
  Slider({
    this.photo,
    this.title,
    this.subtitle,
    this.type,
    this.actionText,
    this.colorHex,
  });

  String? photo;
  String? title;
  String? subtitle;
  String? type;
  String? actionText;
  String? colorHex;

  factory Slider.fromJson(Map<String, dynamic> json) => Slider(
        photo: json["photo"],
        title: json["title"],
        subtitle: json["subtitle"],
        type: json["type"],
        actionText: json["actionText"],
        colorHex: json["colorHex"],
      );

  Map<String, dynamic> toJson() => {
        "photo": photo,
        "title": title,
        "subtitle": subtitle,
        "type": type,
        "actionText": actionText,
        "colorHex": colorHex,
      };
}
