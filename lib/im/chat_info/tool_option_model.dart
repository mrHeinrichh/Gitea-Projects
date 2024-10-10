import 'package:flutter/material.dart';

class ToolOptionModel {
  String title;
  String optionType;
  final IconData? icon;
  final String? imageUrl;
  final String? checkImageUrl;
  final String? unCheckImageUrl;
  final String? trailingText;
  final Color? color;
  final bool? largeDivider;
  bool isShow;
  List<ToolOptionModel>? subOptions;
  final String? footage;
  bool? trailing;
  List<String>? specialTitles;

  //属于哪一个 多选项
  final int? tabBelonging;
  final int? duration;
  final TextStyle? trailingTextStyle;
  final TextStyle? titleTextStyle;
  final String? leftIconUrl;


  ToolOptionModel({
    required this.title,
    required this.optionType,
    required this.isShow,
    required this.tabBelonging,
    this.icon,
    this.imageUrl,
    this.trailingText,
    this.color,
    this.largeDivider,
    this.subOptions,
    this.trailing,
    this.footage,
    this.checkImageUrl,
    this.unCheckImageUrl,
    this.duration,
    this.trailingTextStyle,
    this.titleTextStyle,
    this.leftIconUrl,
    this.specialTitles,
  });

  ToolOptionModel fromJson(Map<String, dynamic> json) {
    return ToolOptionModel(
      title: json['title'],
      optionType: json['optionType'],
      icon: json['icon'],
      tabBelonging: json['tabBelonging'],
      imageUrl: json['imageUrl'],
      titleTextStyle: json['titleTextStyle'],
      largeDivider: json['largeDivider'],
      color: json['color'],
      isShow: json['isShow'],
      subOptions: json['subOptions'],
      footage: json['footage'],
      trailing: json['trailing'],
      duration: json['duration'],
      leftIconUrl: json['leftIconUrl'],
      trailingTextStyle: json['trailingTextStyle'],
      specialTitles: json['specialTitles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'optionType': optionType,
      'icon': icon,
      'tabBelonging': tabBelonging,
      'imageUrl': imageUrl,
      'titleTextStyle': titleTextStyle,
      'color': color,
      'largeDivider': largeDivider,
      'isShow': isShow,
      'subOptions': subOptions,
      'footage': footage,
      'trailing': trailing,
      'duration': duration,
      'leftIconUrl': leftIconUrl,
      'trailingTextStyle': trailingTextStyle,
      'specialTitles': specialTitles,
    };
  }

  get hasSubOption => subOptions != null && subOptions!.isNotEmpty;
}
