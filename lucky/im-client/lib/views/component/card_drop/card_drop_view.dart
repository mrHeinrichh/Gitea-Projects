import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:jxim_client/views/component/card_drop/card_drop_drag_item.dart';
import 'package:jxim_client/views/component/card_drop/card_drop_show_item.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///卡片拖动切换(左右)
class CardDropView extends StatefulWidget {
  ///卡片拖动切换(左右)
  CardDropView({
    Key? key,
    required this.children,
    this.showCount = 3,
  }) : super(key: key);

  ///卡片构建函数
  final List<Widget> children;

  ///显示数量
  final int showCount;

  @override
  State<CardDropView> createState() => _CardDropViewState();
}

class _CardDropViewState extends State<CardDropView> {
  _ActivityDragData _dragData = _ActivityDragData();
  List<AnimationController?> _controllers = [];
  List<GlobalKey> _childKeys = [];
  List<Image?> _childImages = [];
  bool _isShowFirst = true;
  bool _isListScale = false;

  @override
  void initState() {
    super.initState();
    _dragData.on(_ActivityDragData.eventDragStarted, _onDragStarted);
    _dragData.on(_ActivityDragData.eventDragUpdate, _onDragUpdate);
    _dragData.on(_ActivityDragData.eventDragEnd, _onDragEnd);
  }

  @override
  void dispose() {
    _dragData.off(_ActivityDragData.eventDragStarted, _onDragStarted);
    _dragData.off(_ActivityDragData.eventDragUpdate, _onDragUpdate);
    _dragData.off(_ActivityDragData.eventDragEnd, _onDragEnd);
    super.dispose();
  }

  _onDragStarted(sender, type, data) {
    _isShowFirst = false;
    if (mounted) setState(() {});
  }

  _onDragUpdate(sender, type, data) {
    if (_dragData.controller == null) return;
    _dragData.controller!.value = _dragData.offset.abs() / _dragData.width;
    if (_data.targetAngle * _dragData.offset < 0) {
      _data.targetAngle = -_data.targetAngle;
      if (mounted) setState(() {});
    }
  }

  _onDragEnd(sender, type, data) {
    _isShowFirst = true;
    if (data) _isListScale = true;
    if (mounted) setState(() {});
  }

  ///检测并播放动画
  void _checkAnimate() {
    if (!mounted) return;
    for (int i = 0; i < widget.showCount; i++) {
      if (_controllers[i] == null) return;
    }
    //开始动画
    for (int i = 0; i < widget.showCount; i++) {
      _controllers[i]!.reset();
      _controllers[i]!.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
      if (!mounted) return;
      Future.delayed(
          const Duration(milliseconds: 2000), () => _getChildImages());
      if (_isListScale) _checkAnimate();
    });
    int length = widget.children.length;
    _controllers.length = length;
    _childImages.length = length;
    var children = <Widget>[];
    int baseIndex = _dragData.index % length;
    for (int i = 0; i < length; i++) {
      if (i >= _childKeys.length) _childKeys.add(GlobalKey());
      int index = (baseIndex + i) % length;
      var child = !_isListScale && length > 1 && i == 0
          ? Draggable(
              axis: Axis.horizontal,
              affinity: Axis.horizontal,
              maxSimultaneousDrags: 1,
              child: RepaintBoundary(
                  key: _childKeys[index], child: widget.children[index]),
              childWhenDragging: const SizedBox(),
              feedback: _buildFeedback(baseIndex),
              onDragStarted: _dragData.onDragStarted,
              onDragUpdate: _dragData.onDragUpdate,
              onDragEnd: _dragData.onDragEnd,
            )
          : _buildChild(index, i);
      children.insert(0, child);
    }
    return Stack(
      children: children,
    );
  }

  _getChildImages() async {
    if (!mounted) return;
    if (_childImages[0] != null) return;
    for (var i = 0; i < _childKeys.length; i++) {
      RenderRepaintBoundary? boundary = _childKeys[i]
          .currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) continue;
      ui.Image image = await boundary.toImage();
      if (_dragData.width == 0) _dragData.width = image.width.w;
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) continue;
      _childImages[i] = Image.memory(
        byteData.buffer.asUint8List(), width: image.width.w,
        height: image.height.w, fit: BoxFit.cover,
        gaplessPlayback: true, //防止重绘
      );
    }
    if (mounted) setState(() {});
  }

  _buildChild(int index, int showIndex) {
    int idx = showIndex;
    double top = 0;
    double targetTop = 0;
    double scale = 0.5;
    double targetScale = 0.5;
    bool isVisible = showIndex < widget.showCount;
    if (isVisible) {
      isVisible = _isShowFirst || showIndex > 0;
      if (_isListScale) idx++;
      top = idx * 20.w;
      targetTop = (idx - 1) * 20.w;
      scale = pow(0.95, idx).toDouble();
      targetScale = pow(0.95, idx - 1).toDouble();
    }
    return Visibility(
      // visible: isVisible,
      child: CardDropShowItem(
        data: CardDropShowItemData(
          top: top,
          targetTop: targetTop,
          scale: scale,
          targetScale: targetScale,
        ),
        child: RepaintBoundary(
            key: _childKeys[index], child: widget.children[index]),
        onComplete: () {
          if (!_isListScale) return;
          _isListScale = false;
          if (mounted) setState(() {});
        },
        onCreate: (controller) {
          _controllers[showIndex] = controller;
        },
        onDispose: (controller) {
          if (_controllers[showIndex] != controller) return;
          _controllers[showIndex] = null;
        },
      ),
    );
  }

  CardDropDragItemData _data = CardDropDragItemData(
    scale: 1,
    targetScale: 0.5,
    angle: 0,
    targetAngle: 45 * pi / 1800,
  );
  _buildFeedback(int index) {
    Image? image = _childImages[index];
    if (image == null) return const SizedBox();
    return CardDropDragItem(
      data: _data,
      child: image,
      onCreate: (controller) {
        _dragData.controller = controller;
      },
      onDispose: (controller) {
        if (_dragData.controller != controller) return;
        _dragData.controller = null;
      },
    );
  }
}

///拖动数据
class _ActivityDragData extends EventDispatcher {
  static const eventDragStarted = 'eventDragStarted';
  static const eventDragUpdate = 'eventDragUpdate';
  static const eventDragEnd = 'eventDragEnd';
  int index = 0;
  double width = 0;
  double offset = 0;
  AnimationController? controller;

  void onDragStarted() {
    event(this, eventDragStarted);
  }

  void onDragUpdate(DragUpdateDetails details) {
    offset = details.globalPosition.dx - width.w / 2;
    event(this, eventDragUpdate);
  }

  void onDragEnd(DraggableDetails details) {
    if (details.offset.dx.abs() < 80.w) {
      event(this, eventDragEnd, data: false);
      return;
    }
    controller = null;
    index++;
    event(this, eventDragEnd, data: true);
  }
}
