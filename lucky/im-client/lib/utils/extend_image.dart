import 'package:jxim_client/utils/cache_image.dart';
import 'package:flutter/material.dart';

class ExtendImage extends StatefulWidget {
  final List<int> images;
  final int? index;
  const ExtendImage({Key? key, required this.images, this.index = 0})
      : super(key: key);

  @override
  State<ExtendImage> createState() => _ExtendImageState();
}

class _ExtendImageState extends State<ExtendImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset = Offset.zero;
  double _previousScale = 0;
  double _kMinFlingVelocity = 600.0;
  // bool _isHideTitleBar = false;
  late PageController _pageController;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index!);
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {
        _offset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Offset _clampOffset(Offset offset) {
    final Size size = MediaQuery.of(context).size;
    // widget的屏幕宽度
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    // 限制他的最小尺寸
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      // _isHideTitleBar = true;
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // 计算图片放大后的位置
      _controller.stop();
    });
  }

  _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 3.0);
      // 限制放大倍数 1~3倍
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      // 更新当前位置
    });
  }

  _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distanceSquared;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    // 计算当前的方向
    final double distance =
        (Offset.zero & MediaQuery.of(context).size).shortestSide;
    // 计算放大倍速，并相应的放大宽和高，比如原来是600*480的图片，放大后倍数为1.25倍时，宽和高是同时变化的
    _animation = _controller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  _onDoubleTap() {}

  _onTap() {
    Navigator.pop(context);
  }

  _onTapDown(TapDownDetails detail) {}

  Offset offset = Offset(10, kToolbarHeight + 100);

  Offset _calOffset(Size size, Offset offset, Offset nextOffset) {
    double dx = 0;
    //水平方向偏移量不能小于0不能大于屏幕最大宽度
    if (offset.dx + nextOffset.dx <= 0) {
      dx = 0;
    } else if (offset.dx + nextOffset.dx >= (size.width - 50)) {
      dx = size.width - 50;
    } else {
      dx = offset.dx + nextOffset.dx;
    }
    double dy = 0;
    //垂直方向偏移量不能小于0不能大于屏幕最大高度
    if (offset.dy + nextOffset.dy >= (size.height - 100)) {
      dy = size.height - 100;
    } else if (offset.dy + nextOffset.dy <= kToolbarHeight) {
      dy = kToolbarHeight;
    } else {
      dy = offset.dy + nextOffset.dy;
    }
    return Offset(
      dx,
      dy,
    );
  }

  // Offset startOffset = Offset.zero;
  // _onPanDown(DragDownDetails detail){
  //   startOffset = detail.localPosition;
  // }

  _onPanUpdate(PointerMoveEvent detail) {
    setState(() {
      offset = _calOffset(MediaQuery.of(context).size, offset, detail.delta);
    });
  }

  // _onPanEnd(DragEndDetails detail){
  //   offset = startOffset;
  //   Navigator.pop(context);
  // }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PageView(
        controller: _pageController,
        children: widget.images.map((e) {
          return pageItem(e);
        }).toList(),
      ),
    );
  }

  Widget pageItem(int src) {
    return Hero(
      tag: src,
      child: Listener(
        onPointerMove: _onPanUpdate,
        child: GestureDetector(
          onScaleStart: _handleOnScaleStart,
          onScaleUpdate: _handleOnScaleUpdate,
          onScaleEnd: _handleOnScaleEnd,
          onDoubleTap: _onDoubleTap,
          onTap: _onTap,
          onTapDown: _onTapDown,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: ClipRect(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(_offset.dx, _offset.dy)
                  ..scale(_scale),
                child: RemoteImage(
                  src: src.toString(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
