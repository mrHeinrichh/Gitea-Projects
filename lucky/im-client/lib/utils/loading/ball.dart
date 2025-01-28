import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:flutter/material.dart';

///
/// 默认球的样式
///
const kDefaultBallStyle = BallStyle(
  size: 10.0,
  color: Colors.white,
  ballType: BallType.solid,
  borderWidth: 0.0,
  borderColor: Colors.white,
);

///
/// desc:球
///
class Ball extends StatelessWidget {
  ///
  /// 球样式
  ///
  final BallStyle style;

  const Ball({
    Key? key,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BallStyle _ballStyle = kDefaultBallStyle.copyWith(
        size: style.size,
        color: style.color,
        ballType: style.ballType,
        borderWidth: style.borderWidth,
        borderColor: style.borderColor);

    return SizedBox(
      width: _ballStyle.size,
      height: _ballStyle.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _ballStyle.ballType == BallType.solid ? _ballStyle.color : null,
            border: Border.all(
                color: _ballStyle.borderColor, width: _ballStyle.borderWidth)),
      ),
    );
  }
}

enum BallType {
  ///
  /// 空心
  ///
  hollow,

  ///
  /// 实心
  ///
  solid
}
