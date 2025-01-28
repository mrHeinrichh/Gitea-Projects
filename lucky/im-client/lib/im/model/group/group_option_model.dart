import 'package:flutter/material.dart';

class GroupOptionModel {
  String? title;
  IconData? icon;
  Color? iconBackground;
  String? trailingText;

  GroupOptionModel({
    this.title,
    this.icon,
    this.iconBackground,
    this.trailingText,
  });

  GroupOptionModel.fromMap(Map<String, dynamic> map) {
    title = map['title'];
    icon = map['icon'];
    iconBackground = map['iconBackground'];
    trailingText = map['trailingText'];
  }
}
