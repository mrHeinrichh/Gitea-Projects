import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

///卡片拖动切换显示项动画
class CardDropShowItem extends StatefulWidget {
  ///卡片拖动切换显示项动画
  CardDropShowItem({
    Key? key,
    required this.child,
    required this.data,
    this.onComplete,
    this.onCreate,
    this.onDispose,
  }) : super(key: key);

  ///子对象
  final Widget child;

  ///动画数据
  final CardDropShowItemData data;

  final VoidCallback? onComplete;

  ///动画创建回调
  final void Function(AnimationController controller)? onCreate;

  ///动画销毁
  final void Function(AnimationController controller)? onDispose;

  @override
  State<CardDropShowItem> createState() => _CardDropShowItemState();
}

class _CardDropShowItemState extends State<CardDropShowItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _top;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _top = Tween<double>(
            begin: widget.data.top,
            end: widget.data.targetTop ?? widget.data.top)
        .animate(_controller);
    _scale = Tween<double>(
            begin: widget.data.scale,
            end: widget.data.targetScale ?? widget.data.scale)
        .animate(_controller);
    _controller.addListener(() {
      if (!_controller.isCompleted) return;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (widget.onComplete != null) widget.onComplete!();
        SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
          if (!mounted) return;
          _top = Tween<double>(
                  begin: widget.data.top,
                  end: widget.data.targetTop ?? widget.data.top)
              .animate(_controller);
          _scale = Tween<double>(
                  begin: widget.data.scale,
                  end: widget.data.targetScale ?? widget.data.scale)
              .animate(_controller);
          if (mounted) setState(() {});
        });
      });
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _top.value,
          child: child!,
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class CardDropShowItemData {
  ///当前定位top
  double top = 0;

  ///目标定位top
  double? targetTop = 0;

  ///当前缩放
  double scale = 1;

  ///目标缩放
  double? targetScale = 1;

  CardDropShowItemData(
      {this.top = 0, this.targetTop = 0, this.scale = 1, this.targetScale = 1});
}
