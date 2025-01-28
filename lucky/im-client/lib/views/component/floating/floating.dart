import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/views/component/floating/utils/floating_log.dart';
import 'package:jxim_client/views/component/floating/view/floating_view.dart';

import 'assist/floating_data.dart';
import 'assist/floating_slide_type.dart';
import 'listener/floating_listener.dart';

export 'utils/floating_log.dart' show lerpDouble;

/// @name：floating
/// @package：
/// @author：345 QQ:1831712732
/// @time：2022/02/10 14:23
/// @des：

class Floating {
  late OverlayEntry _overlayEntry;

  late FloatingView _floatingView;

  late FloatingData floatingData;

  final List<FloatingListener> _listener = [];

  final GlobalKey<FloatingViewState> _floatingViewStateKey = GlobalKey();

  final double width;
  final double height;
  final double slideTopHeight;
  final double slideBottomHeight;
  late FloatingLog _log;
  String logKey = "";

  ///是否真正显示
  bool get isShowing => _isShowing;
  bool _isShowing = false;

  ValueNotifier<bool> isHide = ValueNotifier<bool>(false);

  ///[child]需要悬浮的 widget
  ///[slideType]，可参考[FloatingSlideType]
  ///
  ///[top],[left],[left],[bottom] 对应 [slideType]，
  ///例如设置[slideType]为[FloatingSlideType.onRightAndBottom]，则需要传入[bottom]和[right]
  ///
  ///[isPosCache]启用之后当调用之后 [Floating.close] 重新调用 [Floating.open] 后会保持之前的位置
  ///[isSnapToEdge]是否自动吸附边缘，默认为 true ，请注意，移动默认是有透明动画的，如需要关闭透明度动画，
  ///请修改 [moveOpacity]为 1
  ///[slideTopHeight] 滑动边界控制，可滑动到顶部的距离
  ///[slideBottomHeight] 滑动边界控制，可滑动到底部的距离
  Floating(
      Widget child, {
        FloatingSlideType slideType = FloatingSlideType.onRightAndBottom,
        double? top,
        double? left,
        double? right,
        double? bottom,
        double moveOpacity = 0.3,
        bool isPosCache = true,
        bool isShowLog = true,
        bool isSnapToEdge = true,
        bool showToolbar = true,
        void Function()? onTapCallback,
        this.width = 150,
        this.height = 100,
        this.slideTopHeight = 0,
        this.slideBottomHeight = 0,
      }) {
    floatingData = FloatingData(slideType,
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        showToolbar: showToolbar,
        width: width,
        height: height);
    _log = FloatingLog(isShowLog);

    _floatingView = FloatingView(
      child,
      floatingData,
      isPosCache,
      isSnapToEdge,
      _listener,
      _log,
      key: _floatingViewStateKey,
      moveOpacity: moveOpacity,
      slideTopHeight: slideTopHeight,
      slideBottomHeight: slideBottomHeight,
      isHide: isHide,
      onClose: close,
      onTapCallback: onTapCallback,
    );
  }

  ///打开悬浮窗
  ///此方法配合 [close]方法进行使用，调用[close]之后在调用此方法会丢失 Floating 状态
  ///否则请使用 [hideFloating] 进行隐藏，使用 [showFloating]进行显示，而不是使用 [close]
  void open(BuildContext context) {
    if (_isShowing) return;
    _overlayEntry =
        OverlayEntry(builder: (BuildContext context) => _floatingView);
    Overlay.of(context).insert(_overlayEntry);
    _isShowing = true;
    _notifyOpen();
  }

  ///关闭悬浮窗
  void close() {
    if (!_isShowing) return;
    _overlayEntry.remove();
    _isShowing = false;
    _notifyClose();
  }

  ///隐藏悬浮窗，保留其状态
  ///只有在悬浮窗显示的状态下才可以使用，否则调用无效
  void hideFloating() {
    if (!_isShowing) return;
    this.isHide.value = true;
    _isShowing = false;
    _notifyHideFloating();
  }

  ///显示悬浮窗，恢复其状态
  ///只有在悬浮窗是隐藏的状态下才可以使用，否则调用无效
  void showFloating() {
    if (_isShowing) return;
    this.isHide.value = false;
    _isShowing = true;
    _notifyShowFloating();
  }

  ///添加监听
  addFloatingListener(FloatingListener listener) {
    _listener.contains(listener) ? null : _listener.add(listener);
  }

  ///设置 [FloatingLog] 标识
  setLogKey(String key) {
    _log.logKey = key;
  }

  _notifyClose() {
    _log.log("关闭");
    for (var listener in _listener) {
      listener.closeListener?.call();
    }
  }

  _notifyOpen() {
    _log.log("打开");
    for (var listener in _listener) {
      listener.openListener?.call();
    }
  }

  _notifyHideFloating() {
    _log.log("隐藏");
    for (var listener in _listener) {
      listener.hideFloatingListener?.call();
    }
  }

  _notifyShowFloating() {
    _log.log("显示");
    for (var listener in _listener) {
      listener.showFloatingListener?.call();
    }
  }

  fullScreen(){
    _floatingViewStateKey.currentState?.fullScreen();
  }

  minimize(){
    _floatingViewStateKey.currentState?.minimize();
  }
}
