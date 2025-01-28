import 'package:jxim_client/views/floating_window/assist/Point.dart';

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

  int width;
  int height;
  bool isInitFullscreen = false;

  double snapToEdgeSpace = 0;

  Point<double>? point;

  FloatingSlideType slideType;

  FloatingData(this.slideType, this.width, this.height,
      {this.left, this.top, this.right, this.bottom,this.point, this.snapToEdgeSpace = 0, this.isInitFullscreen = false});
}
