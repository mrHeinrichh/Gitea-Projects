import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jxim_client/utils/debug_info.dart';

import '../assist/floating_data.dart';
import '../assist/floating_slide_type.dart';
import '../listener/floating_listener.dart';
import '../utils/floating_log.dart';

/// @name：floating
/// @package：
/// @author：345 QQ:1831712732
/// @time：2022/02/09 22:33
/// @des：

class FloatingView extends StatefulWidget {
  final Widget child;
  final FloatingData floatingData;
  final bool isPosCache;
  final bool isSnapToEdge;
  final List<FloatingListener> _listener;
  final FloatingLog _log;
  final double slideTopHeight;
  final double slideBottomHeight;
  final double moveOpacity; // 悬浮组件透明度
  final ValueNotifier<bool>? isHide;
  final Function()? onClose;
  final Function()? onTapCallback;

  const FloatingView(
      this.child,
      this.floatingData,
      this.isPosCache,
      this.isSnapToEdge,
      this._listener,
      this._log, {
        Key? key,
        this.slideTopHeight = 0,
        this.slideBottomHeight = 0,
        this.moveOpacity = 0.3,
        this.isHide,
        this.onClose,
        this.onTapCallback,
      }) : super(key: key);

  @override
  FloatingViewState createState() => FloatingViewState();
}

class FloatingViewState extends State<FloatingView>
    with TickerProviderStateMixin {
  /// 悬浮窗位子
  final ValueNotifier<double> _top = ValueNotifier<double>(0);
  final ValueNotifier<double> _left = ValueNotifier<double>(0);

  /// 工具栏 动态图标大小
  final ValueNotifier<double> _dynamicIconSize = ValueNotifier<double>(25);

  /// 工具栏 长宽动态变化
  final ValueNotifier<double> _controlBarWidth = ValueNotifier<double>(0);
  final ValueNotifier<double> _controlBarHeight = ValueNotifier<double>(30);

  late FloatingData _floatingData;

  double _width = 0;
  double _height = 0;

  double _parentWidth = 0; //记录屏幕或者父组件宽度
  double _parentHeight = 0; //记录屏幕或者父组件宽度

  bool get isExpanded => _isExpanded;
  bool _isExpanded = false;

  double _opacity = 1.0; // 悬浮组件透明度

  bool _isInitPosition = false;

  late AnimationController _controller; //动画控制器

  late Animation<double> _animation; //动画

  late AnimationController _fullScreenController;
  // late Animation<double> _fullScreenAnimation;
  ValueNotifier<bool> isHide = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    /// 初始化 floatingData
    _floatingData = widget.floatingData;

    /// 初始化 宽度
    _width = widget.floatingData.width;
    _controlBarWidth.value = widget.floatingData.width;

    /// 初始化 高度
    _height = widget.floatingData.height;

    /// 初始化动画
    _controller = AnimationController(
        duration: const Duration(milliseconds: 0), vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    /// 初始化 全屏控制器
    _fullScreenController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);

    setState(() {
      _setParentHeightAndWidget();
      _initPosition();
    });

    _fullScreenController.addListener(() {
      if (widget.isPosCache) {
        _left.value =
            lerpDouble(_floatingData.left!, 0, _fullScreenController.value);
        _top.value =
            lerpDouble(_floatingData.top!, 0, _fullScreenController.value);
        _dynamicIconSize.value =
            lerpDouble(25, 30, _fullScreenController.value);
        _controlBarWidth.value = lerpDouble(widget.floatingData.width,
            _parentWidth, _fullScreenController.value);
        _controlBarHeight.value =
            lerpDouble(30, 0, _fullScreenController.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: _left,
          builder: (BuildContext context, double left, Widget? _) {
            return ValueListenableBuilder<double>(
              valueListenable: _top,
              builder: (BuildContext context, double top, Widget? __) {
                return Positioned(
                  left: left,
                  top: top,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 300),
                    child: ValueListenableBuilder<bool>(
                        valueListenable:
                        widget.isHide ?? ValueNotifier<bool>(false),
                        builder: (BuildContext context, bool value, Widget? _) {
                          return Offstage(
                            offstage: value,
                            child: OrientationBuilder(
                              builder: (BuildContext context,
                                  Orientation orientation) {
                                checkScreenChange();
                                return Opacity(
                                  opacity: _isInitPosition ? 1 : 0,
                                  child: _content(),
                                );
                              },
                            ),
                          );
                        }),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _content() {
    return AnimatedBuilder(
      animation: _fullScreenController.view,
      builder: (BuildContext context, Widget? _) {
        var size = Offset.lerp(
          Offset(
            _floatingData.width,
            _floatingData.height,
          ),
          Offset(
            _parentWidth,
            _parentHeight,
          ),
          _fullScreenController.value,
        )!;
        return SizedBox(
          width: size.dx,
          height: size.dy,
          child: Stack(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTapCallback,
                onPanUpdate: (DragUpdateDetails details) {
                  /// 拖拽 移动悬浮窗
                  _left.value += details.delta.dx;
                  _top.value += details.delta.dy;
                  _opacity = widget.moveOpacity;
                  _changePosition();
                  _notifyMove(_left.value, _top.value);
                },
                onPanEnd: (DragEndDetails details) {
                  _changePosition();
                  _animateMovePosition();
                },
                onPanCancel: () {
                  _changePosition();
                },
                child: widget.child,
              ),
              if (_floatingData.isExpanded.value)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: minimize,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: const Icon(
                            Icons.fullscreen_exit_rounded,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  fullScreen() {
    if (!_floatingData.isExpanded.value) {
      _floatingData.isExpanded.value = true;
      pdebug("========> $_parentWidth-$_parentHeight");
      setState(() {
        _width = _parentWidth;
        _height = _parentHeight;
      });

      _fullScreenController.forward();
    }
  }

  minimize() {
    if (_floatingData.isExpanded.value) {
      _floatingData.isExpanded.value = false;
      setState(() {
        _width = _floatingData.width;
        _height = _floatingData.height;
      });
      _fullScreenController.reverse();
    }
  }

  ///边界判断
  _changePosition() {
    //不能超过左边界
    if (_left.value < 0) _left.value = 0;
    //不能超过右边界
    var w = _parentWidth;
    if (_left.value >= w - _width) {
      _left.value = w - _width;
    }
    if (_top.value < widget.slideTopHeight) _top.value = widget.slideTopHeight;
    var t = _parentHeight;
    if (_top.value >= t - _height - widget.slideBottomHeight) {
      _top.value = t - _height - widget.slideBottomHeight;
    }
    setState(() {
      _saveCacheData(_left.value, _top.value);
    });
  }

  ///中线回弹动画
  _animateMovePosition() {
    if (!widget.isSnapToEdge) return;
    double centerX = _left.value + _width / 2.0;
    double toPositionX = 0;
    double needMoveLength = 0;

    //计算靠边的距离
    if (centerX <= _parentWidth / 2) {
      needMoveLength = _left.value;
    } else {
      //靠右边的距离
      needMoveLength = (_parentWidth - _left.value - _width);
    }
    //根据滑动距离计算滑动时间
    double parent = (needMoveLength / (_parentWidth / 2.0));
    int time = (600 * parent).ceil();

    if (centerX <= _parentWidth / 2.0) {
      toPositionX = 0; //回到左边缘
    } else {
      toPositionX = _parentWidth - _width; //回到右边缘
    }

    _controller.dispose();
    _controller = AnimationController(
        duration: Duration(milliseconds: time), vsync: this);
    _animation =
        Tween(begin: _left.value, end: toPositionX * 1.0).animate(_controller);
    //回弹动画
    _animation.addListener(() {
      _left.value = _animation.value.toDouble();
      setState(() {
        _saveCacheData(_left.value, _top.value);
        _notifyMove(_left.value, _top.value);
      });
    });

    if (_opacity != 1.0) {
      //恢复透明度
      _animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _opacity = 1.0);
            _notifyMoveEnd(_left.value, _top.value);
          });
        }
      });
    }
    _controller.forward();
  }

  void _initPosition() {
    //使用缓存
    if (widget.isPosCache) {
      //如果之前没有缓存数据
      if (_floatingData.top == null || _floatingData.left == null) {
        setSlide();
      } else {
        _setCacheData();
      }
    } else {
      setSlide();
    }
    _isInitPosition = true;
  }

  ///判断屏幕是否发生改变
  checkScreenChange() {
    //如果屏幕宽高为0，直接退出
    if (_parentWidth == 0 || _parentHeight == 0) return;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    if (width != _parentWidth || height != _parentHeight) {
      setState(() {
        if (!widget.isSnapToEdge) {
          if (height > _parentHeight) {
            _top.value = _top.value * (height / _parentHeight);
          } else {
            _top.value = _top.value / (_parentHeight / height);
          }
          if (_left.value > _parentWidth) {
            _left.value = _left.value * (_width / _parentWidth);
          } else {
            _left.value = _left.value / (_parentWidth / width);
          }
        } else {
          if (_left.value < _parentWidth / 2) {
            _left.value = 0;
          } else {
            _left.value = width - _width;
          }
          if (height > _parentHeight) {
            _top.value = _top.value * (height / _parentHeight);
          } else {
            _top.value = _top.value / (_parentHeight / height);
          }
        }
        _parentWidth = width;
        _parentHeight = height;
      });
    }
  }

  setSlide() {
    switch (_floatingData.slideType) {
      case FloatingSlideType.onLeftAndTop:
        _top.value = _floatingData.top ?? 0;
        _left.value = _floatingData.left ?? 0;
        break;
      case FloatingSlideType.onLeftAndBottom:
        _left.value = _floatingData.left ?? 0;
        _top.value = _parentHeight - (_floatingData.bottom ?? 0) - _height;
        break;
      case FloatingSlideType.onRightAndTop:
        _top.value = _floatingData.top ?? 0;
        _left.value = _parentWidth - (_floatingData.right ?? 0) - _width;
        break;
      case FloatingSlideType.onRightAndBottom:
        _left.value = _parentWidth - (_floatingData.right ?? 0) - _width;
        _top.value = _parentHeight - (_floatingData.bottom ?? 0) - _height;
        break;
    }
    _saveCacheData(_left.value, _top.value);
  }

  ///保存缓存位置
  _saveCacheData(double left, double top) {
    if (widget.isPosCache) {
      _floatingData.left = left;
      _floatingData.top = top;
    }
  }

  ///设置缓存数据
  _setCacheData() {
    _top.value = _floatingData.top ?? 0;
    _left.value = _floatingData.left ?? 0;
  }

  _setParentHeightAndWidget() {
    if (_parentHeight == 0 || _parentWidth == 0) {
      _parentWidth = MediaQuery.of(context).size.width;
      _parentHeight = MediaQuery.of(context).size.height;
    }
  }

  _notifyMove(double x, double y) {
    widget._log.log("移动 X:$x Y:$y");
    for (var element in widget._listener) {
      element.moveListener?.call(x, y);
    }
  }

  _notifyMoveEnd(double x, double y) {
    widget._log.log("移动结束 X:$x Y:$y");
    for (var element in widget._listener) {
      element.moveEndListener?.call(x, y);
    }
  }

  _notifyDown(double x, double y) {
    widget._log.log("按下 X:$x Y:$y");
    for (var element in widget._listener) {
      element.downListener?.call(x, y);
    }
  }

  _notifyUp(double x, double y) {
    widget._log.log("抬起 X:$x Y:$y");
    for (var element in widget._listener) {
      element.upListener?.call(x, y);
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
      if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          super.setState(fn);
        });
      } else {
        super.setState(fn);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
