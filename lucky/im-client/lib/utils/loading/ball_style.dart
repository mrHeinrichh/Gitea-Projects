import 'package:flutter/material.dart';

import 'ball.dart';

///
/// 球的样式
///
class BallStyle {
  ///
  /// 尺寸
  ///
  final double size;

  ///
  /// 实心球颜色
  ///
  final Color color;

  ///
  /// 球的类型 [ BallType ]
  ///
  final BallType ballType;

  ///
  /// 边框宽
  ///
  final double borderWidth;

  ///
  /// 边框颜色
  ///
  final Color borderColor;

  const BallStyle(
      {required this.size,
      required this.color,
      required this.ballType,
      required this.borderWidth,
      required this.borderColor});

  BallStyle copyWith(
      {required double size,
      required Color color,
      required BallType ballType,
      required double borderWidth,
      required Color borderColor}) {
    return BallStyle(
        size: size,
        color: color,
        ballType: ballType,
        borderWidth: borderWidth,
        borderColor: borderColor);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BallStyle &&
        other.size == size &&
        other.color == color &&
        other.ballType == ballType &&
        other.borderWidth == borderWidth &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode => size.hashCode;
}
