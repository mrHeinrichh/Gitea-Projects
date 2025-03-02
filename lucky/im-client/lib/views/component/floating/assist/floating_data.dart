import 'package:flutter/cupertino.dart';

import 'floating_slide_type.dart';

/// @name：floating_data
/// @package：
/// @author：345 QQ:1831712732
/// @time：2022/02/10 17:35
/// @des：悬浮窗数据记录

class FloatingData {
  double? left;

  double? top;

  double? right;

  double? bottom;

  double width;

  double height;

  bool showToolbar;

  ValueNotifier<bool> isExpanded;

  FloatingSlideType slideType;

  FloatingData(this.slideType,
      {this.left,
        this.top,
        this.right,
        this.bottom,
        this.showToolbar = true,
        bool isExpanded = false,
        required this.width,
        required this.height})
      : isExpanded = ValueNotifier(isExpanded);
}
