import 'package:flutter/material.dart';

/// BouncyBalls 组件：
/// 一个响应偏移量 `offset` 的动画组件，用于展示小球的动态效果。
/// 根据偏移量分阶段控制中间球的缩放，以及左右球的平移和透明度变化。
class BouncyBalls extends StatelessWidget {
  const BouncyBalls({
    super.key,
    required this.offset,
    required this.dragging,
  });

  /// 偏移量，用于控制动画进度，需大于等于 0。
  final double offset;

  /// 是否处于用户拖拽状态。
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    // 定义各阶段的临界偏移量
    const double stage1Distance = 120; // 阶段 I 临界点
    const double stage2Distance = 140; // 阶段 II 临界点
    const double stage3Distance = 160; // 阶段 III 临界点
    const double stage4Distance = 180; // 阶段 IV 临界点

    // 计算顶部偏移量，基于 offset 的动态位置
    final top = (offset + 44 + 10 - 6) * 0.5;

    // 初始化各阶段动画参数
    double scale = 0.0; // 中间球缩放比例
    double opacityC = 0.0; // 中间球透明度
    double translateR = 0.0; // 右边球水平平移
    double opacityR = 0.0; // 右边球透明度
    double translateL = 0.0; // 左边球水平平移
    double opacityL = 0.0; // 左边球透明度
    double leftRightScale = 1.0;

    // 限制 offset 不超过阶段 IV 的最大值
    final cOffset = (offset <= stage4Distance) ? offset : stage4Distance;

    // 根据偏移量计算动画参数
    if (offset > stage3Distance) {
      // 阶段 IV：小球保持固定位置，但透明度逐渐降低到 0.2
      const step = 0.8 / (stage4Distance - stage3Distance);
      double opacity = 1 - step * (cOffset - stage3Distance);
      opacity = opacity < 0.2 ? 0.2 : opacity;

      opacityC = opacity;
      scale = 1; // 中间球保持正常大小

      opacityR = opacity;
      translateR = 16; // 右边球平移到最右侧

      opacityL = opacity;
      translateL = -16; // 左边球平移到最左侧

      leftRightScale = opacity < 0.6 ? 0.6 : opacity;
    } else if (offset > stage2Distance) {
      // 阶段 III：中间球缩小，左右球平移到指定位置
      const delta = stage3Distance - stage2Distance;
      final deltaOffset = offset - stage2Distance;

      opacityC = 1;
      scale = 2 - (deltaOffset * 1 / delta); // 中间球从 2 缩小到 1

      opacityR = 1;
      translateR = deltaOffset * (16.0 / delta); // 右边球从 0 平移到 16

      opacityL = 1;
      translateL = deltaOffset * (-16.0 / delta); // 左边球从 0 平移到 -16
    } else if (offset > stage1Distance) {
      // 阶段 II：中间球从透明变为可见并逐渐放大
      const delta = stage2Distance - stage1Distance;
      final deltaOffset = offset - stage1Distance;

      opacityC = 1;
      scale = deltaOffset * (2 / delta); // 中间球从 0 放大到 2
    }

    // 渲染组件
    return SizedBox(
      height: cOffset,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 左边球
          Positioned(
            top: top,
            child: Opacity(
              opacity: opacityL,
              child: Transform.translate(
                offset: Offset(translateL, 0.0),
                child: Transform.scale(scale: leftRightScale,child: _buildBallWidget(),),
              ),
            ),
          ),
          // 右边球
          Positioned(
            top: top,
            child: Opacity(
              opacity: opacityR,
              child: Transform.translate(
                offset: Offset(translateR, 0.0),
                child: Transform.scale(scale: leftRightScale,child: _buildBallWidget()),
              ),
            ),
          ),
          // 中间球
          Positioned(
            top: top,
            child: Opacity(
              opacity: opacityC,
              child: Transform.scale(
                scale: scale,
                child: _buildBallWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个小球部件
  Widget _buildBallWidget() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFb7b7b7), // 小球颜色
        borderRadius: BorderRadius.circular(3), // 圆角半径
      ),
      width: 6, // 小球宽度
      height: 6, // 小球高度
    );
  }
}