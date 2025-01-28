import 'package:flutter/material.dart';

class SettingOptionModel {
  String? title;
  String? type;
  IconData? icon;
  String? imageUrl;
  Color? iconBackground;
  bool? trailingWidgetEnabled;

  SettingOptionModel({
    this.title,
    this.type,
    this.icon,
    this.imageUrl,
    this.iconBackground,
    this.trailingWidgetEnabled,
  });

  SettingOptionModel.fromMap(Map<String, dynamic> map) {
    title = map['title'];
    type = map['type'];
    icon = map['icon'];
    imageUrl = map['imageUrl'];
    iconBackground = map['iconBackground'];
    trailingWidgetEnabled = map['trailingWidgetEnabled'];
  }
}
