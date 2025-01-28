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

  //属于哪一个 多选项
  final int? tabBelonging;

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
  });

  ToolOptionModel fromJson(Map<String, dynamic> json) {
    return ToolOptionModel(
      title: json['title'],
      optionType: json['optionType'],
      icon: json['icon'],
      tabBelonging: json['tabBelonging'],
      imageUrl: json['imageUrl'],
      color: json['color'],
      largeDivider: json['largeDivider'],
      isShow: json['isShow'],
      subOptions: json['subOptions'],
      footage: json['footage'],
      trailing: json['trailing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'optionType': optionType,
      'icon': icon,
      'tabBelonging': tabBelonging,
      'imageUrl': imageUrl,
      'color': color,
      'largeDivider': largeDivider,
      'isShow': isShow,
      'subOptions': subOptions,
      'footage': footage,
      'trailing': trailing,
    };
  }

  get hasSubOption => subOptions != null && subOptions!.isNotEmpty;
}
