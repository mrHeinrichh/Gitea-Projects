import 'package:flutter/material.dart';

///卡片拖动切换拖动项动画
class CardDropDragItem extends StatefulWidget {
  ///卡片拖动切换拖动项动画
  const CardDropDragItem({
    super.key,
    required this.child,
    required this.data,
    this.onCreate,
    this.onDispose,
  });

  ///子对象
  final Widget child;

  ///动画数据
  final CardDropDragItemData data;

  ///动画创建回调
  final void Function(AnimationController controller)? onCreate;

  ///动画销毁
  final void Function(AnimationController controller)? onDispose;

  @override
  State<CardDropDragItem> createState() => _CardDropDragItemState();
}

class _CardDropDragItemState extends State<CardDropDragItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _turns;
  late Animation<double> _scale;
  double _targetAngle = 0;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _targetAngle = widget.data.targetAngle;
    _turns = Tween<double>(begin: widget.data.angle, end: widget.data.targetAngle)
        .animate(_controller);
    _scale = Tween<double>(begin: widget.data.scale, end: widget.data.targetScale)
        .animate(_controller);
    _controller.addListener(() {
      if (_targetAngle == widget.data.targetAngle) return;
      _targetAngle = widget.data.targetAngle;
      _turns = Tween<double>(begin: widget.data.angle, end: widget.data.targetAngle)
          .animate(_controller);
      if (mounted) setState(() {});
    });
    if (widget.onCreate != null) widget.onCreate!(_controller);
  }

  @override
  void dispose() {
    if (widget.onDispose != null) widget.onDispose!(_controller);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turns,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class CardDropDragItemData{
  ///当前缩放
  double scale = 1;

  ///目标缩放
  double targetScale = 1;

  ///当前角度
  double angle = 0;

  ///目标角度
  double targetAngle = 0;

  CardDropDragItemData({this.scale = 1, this.targetScale = 1, this.angle = 0, this.targetAngle = 0});
}
