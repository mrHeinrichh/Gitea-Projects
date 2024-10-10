import 'package:flutter/material.dart';

class SelectionOptionModel {
  final String? title;
  final int? value;
  final String? stringValue;
  bool isSelected;
  final Color? color;
  final TextStyle? titleTextStyle;

  SelectionOptionModel({
    this.title,
    this.value,
    this.stringValue,
    this.isSelected = false,
    this.color,
    this.titleTextStyle,
  });
}
