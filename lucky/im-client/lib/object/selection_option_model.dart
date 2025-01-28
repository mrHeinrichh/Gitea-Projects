import 'dart:ui';

class SelectionOptionModel {
  final String? title;
  final int? value;
  final String? stringValue;
  bool isSelected;
  final Color? color;

  SelectionOptionModel({
    this.title,
    this.value,
    this.stringValue,
    this.isSelected = false,
    this.color,
  });
}
