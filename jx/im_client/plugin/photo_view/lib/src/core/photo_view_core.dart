import 'dart:math';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:im_photo_view/photo_view.dart'
    show
        PhotoViewHeroAttributes,
        PhotoViewImageTapDownCallback,
        PhotoViewImageTapUpCallback,
        PhotoViewImageScaleEndCallback,
        PhotoViewImageDoubleTabCallback,
        ScaleStateCycle;
import 'package:im_photo_view/src/controller/photo_view_controller.dart';
import 'package:im_photo_view/src/controller/photo_view_controller_delegate.dart';
import 'package:im_photo_view/src/controller/photo_view_scalestate_controller.dart';
import 'package:im_photo_view/src/core/photo_view_gesture_detector.dart';
import 'package:im_photo_view/src/core/photo_view_hit_corners.dart';
import 'package:im_photo_view/src/photo_view_scale_state.dart';
import 'package:im_photo_view/src/utils/photo_view_utils.dart';

const _defaultDecoration = BoxDecoration(
  color: Color.fromRGBO(0, 0, 0, 1.0),
);

/// Internal widget in which controls all animations lifecycle, core responses
/// to user gestures, updates to  the controller state and mounts the entire PhotoView Layout
class PhotoViewCore extends StatefulWidget {
  const PhotoViewCore(
      {Key? key,
      required this.imageProvider,
      required this.backgroundDecoration,
      required this.gaplessPlayback,
      required this.heroAttributes,
      required this.enableRotation,
      required this.onTapUp,
      required this.onTapDown,
      required this.onScaleEnd,
      required this.gestureDetectorBehavior,
      required this.controller,
      required this.scaleBoundaries,
      required this.scaleStateCycle,
      required this.scaleStateController,
      required this.basePosition,
      required this.tightMode,
      required this.filterQuality,
      required this.disableGestures,
      required this.enablePanAlways,
      this.onScaleUpdate,
      this.onScaleStart,
      this.onDoubleTap,
      this.childSize,
      this.index = 0,
      this.pointEvent})
      : customChild = null,
        super(key: key);

  const PhotoViewCore.customChild(
      {Key? key,
      required this.customChild,
      required this.backgroundDecoration,
      this.heroAttributes,
      required this.enableRotation,
      this.onTapUp,
      this.onTapDown,
      this.onScaleEnd,
      this.gestureDetectorBehavior,
      required this.controller,
      required this.scaleBoundaries,
      required this.scaleStateCycle,
      required this.scaleStateController,
      required this.basePosition,
      required this.tightMode,
      required this.filterQuality,
      required this.disableGestures,
      required this.enablePanAlways,
      this.onScaleUpdate,
      this.onScaleStart,
      this.onDoubleTap,
      this.childSize,
      this.index = 0,
      this.pointEvent})
      : imageProvider = null,
        gaplessPlayback = false,
        super(key: key);

  final Decoration? backgroundDecoration;
  final ImageProvider? imageProvider;
  final bool? gaplessPlayback;
  final PhotoViewHeroAttributes? heroAttributes;
  final bool enableRotation;
  final Widget? customChild;

  final PhotoViewControllerBase controller;
  final PhotoViewScaleStateController scaleStateController;
  final ScaleBoundaries scaleBoundaries;
  final ScaleStateCycle scaleStateCycle;
  final Alignment basePosition;
  final Function(ScaleUpdateDetails details)? onScaleUpdate;
  final Function(ScaleStartDetails details)? onScaleStart;
  final PhotoViewImageTapUpCallback? onTapUp;
  final PhotoViewImageTapDownCallback? onTapDown;
  final PhotoViewImageScaleEndCallback? onScaleEnd;
  final PhotoViewImageDoubleTabCallback? onDoubleTap;
  final HitTestBehavior? gestureDetectorBehavior;
  final bool tightMode;
  final bool disableGestures;
  final bool enablePanAlways;

  final FilterQuality filterQuality;
  final Size? childSize;
  final int index;
  final dynamic pointEvent;

  @override
  State<StatefulWidget> createState() {
    return PhotoViewCoreState();
  }

  bool get hasCustomChild => customChild != null;
}

class PhotoViewCoreState extends State<PhotoViewCore>
    with
        TickerProviderStateMixin,
        PhotoViewControllerDelegate,
        HitCornersDetector {
  static const double _aniDurInSeconds = 2.0;
  static const double _viewPortFraction = 0.01;

  static const int picTypeNormal = 0; //普通图
  static const int picTypeLongV = 1; //长竖图
  static const int picTypeLongH = 2; //长横图

  static const double minScale = 1.0;
  double maxScale = 3.0;

  bool _isDoublePoint = false;
  bool _isFullHeight = false; //高度是否铺满
  double _scale = 1.0;

  @override
  double get scale => _scale;

  @override
  set scale(double v) {
    _scale = v;
    _updateControlValue();
  }

  double _scaleBefore = 1.0;
  double _scaleBefore1 = 1.0;
  double _posX = 0.0;
  double _posY = 0.0;
  Offset _position = Offset.zero;

  @override
  Offset get position => _position;

  set position(Offset v) {
    // print("scale +++update==============position======$_position");
    _position = v;
    _posX = v.dx;
    _posY = v.dy;
    _updateControlValue();
  }

  Offset _startFocalPoint = Offset.zero;
  Offset _previousPosition = Offset.zero;
  Offset _endFocalPoint = Offset.zero;

  late AnimationController _posAniCtrolHua;

  AnimationController? _posAniCtrolTan;
  Animation<Offset>? _posAniTan;

  AnimationController? _posXAniCtrol;
  Animation<double>? _posXAni;

  AnimationController? _posYAniCtrol;
  Animation<double>? _posYAni;

  late final AnimationController _scaleAniCtrol;
  Animation<double>? _scaleAni;

  Size? _rectSize;
  bool _isInitRect = false;
  int _picType = 0; //图片类型
  //是否长竖图
  bool get isLongPic => _picType == picTypeLongV;

  @override
  void initState() {
    super.initState();
    _scaleAniCtrol = AnimationController(
        duration: Duration(milliseconds: (_aniDurInSeconds * 1000).toInt()),
        vsync: this)
      ..addListener(handleScaleAnimation)
      ..addStatusListener(onAnimationStatus);
    _posAniCtrolHua = AnimationController(
      vsync: this,
    );

    scale = 1.0;
    _picType = picTypeNormal;
    maxScale = 3.0;
    if (widget.childSize != null) {
      final double childWidth = widget.childSize!.width;
      double childHeight = widget.childSize!.height;
      final double imageRate = childWidth / childHeight;
      if (childHeight / childWidth >= 2.4) {
        _picType = picTypeLongV;
      } else if (childWidth > childHeight) {
        if (childWidth / childHeight >= 2.4) {
          _picType = picTypeLongH;
        }
        //最大值已铺满为主
        childHeight =
            (scaleBoundaries.childSize.width * (1 - _viewPortFraction)) /
                imageRate;
        maxScale = max(3.0, scaleBoundaries.childSize.height / childHeight);
      }
    }

    if (widget.pointEvent != null) {
      widget.pointEvent.on("eventPoint", onUpdatePointEvent);
      widget.pointEvent.on("eventScale", onUpdateScaleEvent);
    }
  }

  void onUpdatePointEvent(Object sender, Object type, Object? data) {
    if (data == null || !mounted) {
      return;
    }
    if (data is List) {
      // print("scale +++update====scale +++start====onUpdateEvent====$data, ${widget.index}");
      final int curIndex = data[1];
      final dynamic details = data[2];
      if (curIndex != widget.index || (details != null && _isSelfStart)) {
        return;
      }
      final int eventType = data[0];
      if (eventType == 1) {
        onScaleStart(details, isSelf: false);
      } else if (eventType == 2) {
        onScaleUpdate(details, isSelf: false);
      } else if (eventType == 3) {
        onScaleEnd(details ?? ScaleEndDetails(), isSelf: false);
      } else if (eventType == 4) {
        onDoubleTapDown(details);
      } else if (eventType == 5) {
        onDoubleTap();
      }
    }
  }

  void onUpdateScaleEvent(Object sender, Object type, Object? data) {
    if (data is! List || !mounted || data[0] != widget.index) {
      return;
    }
    if (scale > data[1]) {
      stopAllAni();
      scale = minScale;
      position = Offset.zero;
    }
  }

  void _updateControlValue() {
    controller.value = PhotoViewControllerValue(
        position: position,
        scale: scale,
        rotation: controller.rotation,
        rotationFocusPoint: controller.rotationFocusPoint,
        isPullPage: _isDoublePoint || _scaleAniCtrol.isAnimating
            ? true
            : _isFullHeight);
  }

  PhotoViewHeroAttributes? get heroAttributes => widget.heroAttributes;

  late ScaleBoundaries cachedScaleBoundaries = widget.scaleBoundaries;

  bool get isCanDrag => widget.enablePanAlways || scale != 1;

  bool _isSelfStart = false;
  bool _isScaleStart = false;

  void onScaleStart(ScaleStartDetails details, {bool isSelf = true}) {
    // print("scale +++update====scale +++start========$isScaleAnimating,$_previousPosition,${details.pointerCount},===${_isSelfStart? '+++++++++' : ""},${DateTime.now().millisecondsSinceEpoch}");
    if (isScaleAnimating ||
        (_posAniCtrolTan != null && _posAniCtrolTan!.isAnimating)) {
      return;
    }
    stopAllAni(stopPos1: true);
    _isScaleStart = true;
    if (widget.onScaleStart != null) {
      widget.onScaleStart!(details);
    }
    _pointerCount = details.pointerCount;
    _isDoublePoint = details.pointerCount >= 2;
    _scaleBefore = scale;
    final int nowTime = DateTime.now().millisecondsSinceEpoch;
    _scaleBefore1 = _endScaleTime > 0 &&
            nowTime > _endScaleTime &&
            nowTime - _endScaleTime < 50
        ? _scaleBefore1
        : scale;
    _previousPosition = _position;
    _startFocalPoint = details.focalPoint;
    _endFocalPoint = details.focalPoint;
    if (isSelf) {
      _isSelfStart = true;
    }
    if (!_isInitRect) {
      _isInitRect = true;
      _getRectRange();
    }
    //print("scale +++update====scale +++start========$_startFocalPoint,$_previousPosition,${details.pointerCount},$scale,===${_isSelfStart? 'isSelf' : ""},$_isFullHeight");
  }

  void onScaleUpdate(ScaleUpdateDetails details, {bool isSelf = true}) {
    if (!_isScaleStart) {
      return;
    }
    if (widget.onScaleUpdate != null) {
      widget.onScaleUpdate!(details);
    }
    //print("scale +++update=====111===${details.focalPoint},$_scaleBefore,${details.scale}===${_isSelfStart ? 'isSelf' : ""},");
    const double dragForce = 0.5;
    if (_isDoublePoint) {
      _endFocalPoint = Offset(
          _endFocalPoint.dx + details.focalPointDelta.dx * dragForce,
          _endFocalPoint.dy + details.focalPointDelta.dy * dragForce);
      const scaleForceArg = 0.1; //控制灵敏参数 结合缩放比例 值越小越灵敏(范围0～1)
      const scaleForceMin = 0.5; //灵敏度最小值  值越大越灵敏(范围0～1)
      //为了控制放大的倍数越大缩放幅度
      final double scaleForce = details.scale > 1
          ? max(scaleForceMin, 1 - _scaleBefore * scaleForceArg)
          : 1;
      final double toScale =
          (_scaleBefore + _scaleBefore * (details.scale - 1) * scaleForce)
              .clamp(minScale, maxScale + 2.5);
      scale = toScale;
      //print("scale +++update================222===$scale,$scaleForce");
      _clampPosition(
          target: _endFocalPoint -
              (_startFocalPoint - _previousPosition) * scale / _scaleBefore,
          needClampY: isLongPic);
    } else {
      if (scale == 1.0) {
        return;
      }
      _endFocalPoint = details.focalPoint;
      final Offset targetPos = _endFocalPoint -
          (_startFocalPoint - _previousPosition) * scale / _scaleBefore;

      if ((_posAniCtrolTan != null && _posAniCtrolTan!.isAnimating) ||
          (_posYAniCtrol != null && _posYAniCtrol!.isAnimating)) {
        _clampPosition(target: targetPos, needClampY: isLongPic);
      } else {
        _clampPosition(
            target: targetPos,
            needClampY:
                isLongPic || (!_isFullHeight && _scaleBefore1 == scale));
      }
    }
  }

  int _pointerCount = 0;
  int _endScaleTime = 0;

  void onScaleEnd(ScaleEndDetails details, {bool isSelf = true}) {
    // print("scale +++update====scale +++end========$isScaleAnimating, $scale");
    if (!_isScaleStart) {
      if (scale == 1.0 && _position != Offset.zero) {
        //校正下位置
        animatePosition(_position, Offset.zero);
      }
      return;
    }
    _isScaleStart = false;
    //print("scale +++update====scale +++end========${details.velocity.pixelsPerSecond},$_position,$scale, $_pointerCount===${_isSelfStart ? 'isSelf' : ""}");
    if (isSelf) {
      _isSelfStart = false;
    }
    _endScaleTime =
        _pointerCount > 1 ? DateTime.now().millisecondsSinceEpoch : 0;
    _updateControlValue();
    widget.onScaleEnd?.call(context, details, controller.value);
    _pointerCount--;
    _isDoublePoint = _pointerCount > 1;

    if (scale < minScale) {
      _checkScale(minScale, Offset.zero);
      return;
    } else if (scale > maxScale) {
      _checkScale(
          maxScale,
          _getDestPos(
              _endFocalPoint -
                  (_startFocalPoint - _previousPosition) *
                      maxScale /
                      _scaleBefore,
              toScale: maxScale));
      return;
    }
    if (scale == 1.0) {
      //校正下位置
      if (_position != Offset.zero) {
        animatePosition(_position, Offset.zero);
        widget.pointEvent?.doVibrate();
      }
      return;
    }
    _runFlingAnimation(details.velocity.pixelsPerSecond);
  }

  void _checkScale(double value, Offset toPos) {
    stopAllAni();
    animateScale(scale, value);
    animatePosition(_position, toPos);
    //需要震动下
    widget.pointEvent?.doVibrate();
  }

  VoidCallback? _posAniUpdateFun;

  void _runFlingAnimation(Offset velocity) {
    final dynamic rectRange = _getRectRange();
    final double minX = rectRange['minx'];
    final double minY = rectRange['miny'];
    final double maxX = rectRange['maxx'];
    final double maxY = rectRange['maxy'];

    _posAniCtrolTan?.stop();
    _posAniCtrolHua.stop();
    _posXAniCtrol?.stop();
    _posYAniCtrol?.stop();
    if (velocity.dx == 0.0 && velocity.dy == 0.0) {
      final Offset toPos = Offset(
        _position.dx.clamp(minX, maxX),
        _position.dy.clamp(minY, maxY),
      );
      if (_position != toPos) {
        //  print("scale +++update====scale +++end====animatePosition====$_position,$toPos, $minX,$maxX,$minY,$maxY");
        animatePosition(_position, toPos);
        return;
      }
    }
    if (_posAniUpdateFun != null) {
      _posAniCtrolHua.removeListener(_posAniUpdateFun!);
    }

    final double dragForce = 0.2 / scale; //值越大越灵敏
    final FrictionSimulation frictionX =
        FrictionSimulation(dragForce, _position.dx, velocity.dx);
    final FrictionSimulation frictionY =
        FrictionSimulation(dragForce, _position.dy, velocity.dy);

    final double startX = frictionX.x(0.0).clamp(minX, maxX);
    final double startY = frictionY.x(0.0).clamp(minY, maxY);
    //高度未铺满 并且大小变化了
    if ((isLongPic || !_isFullHeight) && _scaleBefore1 != scale) {
      // print("scale +++update====scale +++end====animatePosition=22===$_position,$velocity,${Offset(startX.clamp(minX, maxX), startY.clamp(minY, maxY))}, $minX,$maxX,$minY,$maxY");
      animatePosition(_position,
          Offset(startX.clamp(minX, maxX), startY.clamp(minY, maxY)));
      return;
    }
    // print("scale +++update====scale +++_posAniUpdateFun==11======");
    _posAniCtrolHua.drive(Tween<Offset>(
      begin: _position,
      end: Offset(
        frictionX.x(_aniDurInSeconds),
        frictionY.x(_aniDurInSeconds),
      ),
    ));

    _posAniCtrolHua.duration =
        Duration(milliseconds: (_aniDurInSeconds * 1000).toInt());

    _posAniUpdateFun = () {
      final double newX = frictionX.x(_posAniCtrolHua.value * _aniDurInSeconds);
      final double newY = frictionY.x(_posAniCtrolHua.value * _aniDurInSeconds);

      final bool isChuY = newY < minY || newY > maxY;
      final bool isChuX = newX < minX || newX > maxX;
      bool needSet = true;
      if (isChuX) {
        if (!isChuY) {
          _posY = newY.clamp(minY, maxY);
        } else {
          needSet = false;
        }
        if (_posXAniCtrol == null || !_posXAniCtrol!.isAnimating) {
          // final bool isChuXTan = isLongPic || (newX < minX && (_posAniCtrolHua.value >= 1 || minX - newX > 3)) || (newX > maxX && (_posAniCtrolHua.value >= 1 || newX - maxX > 3));
          final double toX = newX.clamp(minX, maxX);
          if (position.dx != toX) {
            needSet = false;
            setState(() {
              position = Offset(newX, _posY);
            });
            animatePosX(_posX, toX);
          }
        }
        if (needSet) {
          needSet = false;
          setState(() {
            position = Offset(_posX, _posY);
          });
        }
      }
      if (isChuY) {
        if (!isChuX) {
          _posX = newX.clamp(minX, maxX);
        }
        if (_posYAniCtrol == null || !_posYAniCtrol!.isAnimating) {
          // final bool isChuYTan = isLongPic || (newY < minY && (_posAniCtrolHua.value >= 1 || minY - newY > 3))  || (newY > maxY && (_posAniCtrolHua.value >= 1 || newY - maxY > 3));
          final double toY = newY.clamp(minY, maxY);
          if (_position.dy != toY) {
            needSet = false;
            setState(() {
              position = Offset(_posX, newY);
            });
            animatePosY(_posY, toY);
          }
        }
        if (needSet) {
          needSet = false;
          setState(() {
            position = Offset(_posX, _posY);
          });
        }
      }
      if (needSet) {
        setState(() {
          position = Offset(newX.clamp(minX, maxX), newY.clamp(minY, maxY));
        });
      }
      // print("scale +++update====scale +++_posAniUpdateFun========${_posAniCtrolHua.value},$newX, $newY,  $position,$velocity,${velocity.direction},$isChuX,$isChuY");
    };
    _posAniCtrolHua.addListener(_posAniUpdateFun!);
    _posAniCtrolHua.forward(from: 0);
  }

  @override
  bool shouldMoveAxis(
      HitCorners hitCorners, double mainAxisMove, double crossAxisMove) {
    if (mainAxisMove == 0) {
      return false;
    }
    if (!hitCorners.hasHitAny) {
      return true;
    }
    final axisBlocked = hitCorners.hasHitBoth ||
        (hitCorners.hasHitMax
            ? mainAxisMove > 0 && mainAxisMove > crossAxisMove.abs()
            : mainAxisMove < 0 && mainAxisMove.abs() > crossAxisMove.abs());
    if (axisBlocked) {
      // print("scale +++update====scale +++start========222222222======${hitCorners.hasHitBoth}, ${hitCorners.hasHitMax}, $mainAxisMove, $crossAxisMove");
      return false;
    }
    return true;
  }

  @override
  CornersRange cornersX({double? scale}) {
    if (scale == 1) {
      return super.cornersX(scale: scale);
    }
    final double scale0 = scale ?? this.scale;
    final double screenWidth = scaleBoundaries.outerSize.width;

    final double computedWidth = scaleBoundaries.childSize.width * scale0;

    const double minX = 0.0;
    final double maxX =
        scale0 < 1.0 ? screenWidth : computedWidth - screenWidth;
    final double diff = computedWidth * _viewPortFraction * 0.5;
    return CornersRange(minX + diff, maxX - diff);
  }

  //校正位置
  void _clampPosition(
      {Offset? target, bool needClampX = false, bool needClampY = true}) {
    final Offset toPos = _getDestPos(target ?? _position,
        needClampX: needClampX, needClampY: needClampY);
    setState(() {
      position = toPos;
    });
  }

  Offset _getDestPos(Offset target,
      {double? toScale, bool needClampX = true, bool needClampY = true}) {
    if (!needClampX && !needClampY) {
      return target;
    }
    final dynamic rectRange = _getRectRange(toScale: toScale);
    final double minX = rectRange['minx'];
    final double minY = rectRange['miny'];
    final double maxX = rectRange['maxx'];
    final double maxY = rectRange['maxy'];
    final Offset toPos = Offset(
      needClampX ? target.dx.clamp(minX, maxX) : target.dx,
      needClampY ? target.dy.clamp(minY, maxY) : target.dy,
    );
    return toPos;
  }

  dynamic _getRectRange({double? toScale}) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size containerSize = renderBox.size;

    toScale = toScale ?? scale;

    final double containerWidth = containerSize.width;
    final double containerHeight = containerSize.height;
    final double imageWidth = containerWidth * toScale;
    final double imageHeight = containerHeight * toScale;

    double childWidth = containerWidth * (1 - _viewPortFraction);
    double childHeight = containerHeight;
    if (widget.childSize != null) {
      childWidth = widget.childSize!.width;
      childHeight = widget.childSize!.height;
    }
    final double imageRate = childWidth / childHeight;
    double maxX = 0.0;
    double maxY = 0.0;
    double minX = containerWidth - imageWidth;
    double minY = containerHeight - imageHeight;
    _isFullHeight = false;
    _rectSize = null;
    if (childWidth >= containerWidth) {
      childHeight = (containerWidth * (1 - _viewPortFraction)) / imageRate;
    } else {
      final double bigCW =
          (childWidth + containerWidth * _viewPortFraction) * toScale;
      if (bigCW < containerWidth) {
        maxX = (containerWidth - imageWidth) / 2;
        minX = maxX;
      } else if (!isLongPic) {
        maxX = (containerWidth * toScale - imageWidth) / 2;
        minX -= maxX;
        childHeight = (containerWidth * (1 - _viewPortFraction)) / imageRate;
      } else {
        // childHeight = (containerWidth * (1-_viewPortFraction)) / imageRate;
      }
    }
    final double bigCH = childHeight * toScale;
    if (bigCH.floor() <= containerHeight) {
      maxY = (containerHeight - imageHeight) / 2;
      minY = maxY;
    } else if (!isLongPic) {
      maxY = (bigCH - imageHeight) / 2;
      minY -= maxY;
      // _rectSize = toScale == 1 ||
      //         !((_position.dy - maxY).abs() < 10 ||
      //             (_position.dy - minY).abs() < 10)
      //     ? null
      //     : Size(childWidth, childHeight.floor().toDouble() - 1);
      _isFullHeight = true;
    } else {
      // maxY = (containerHeight - bigCH) / 2;
      // minY = containerHeight - childHeight;
      _isFullHeight = true;
    }
    double diffX = 0.0;
    if (toScale < 1.0) {
      maxX = containerWidth;
      minX = 0.0;
      maxY = containerHeight;
      minY = 0.0;
    } else {
      if (minX.abs() == 0.0) {
        minX = 0.0;
      }
      if (minY.abs() == 0.0) {
        minY = 0.0;
      }
      diffX = (toScale - 1.0) * containerWidth * _viewPortFraction * 0.5;
      if (minX == maxX) {
        diffX = 0.0;
      } else {
        final double diffX1 = maxX - minX;
        if (diffX1 < diffX * 2) {
          diffX = diffX1 / 2;
        }
      }
    }

    return {
      "minx": minX + diffX,
      "miny": minY,
      "maxx": maxX - diffX,
      "maxy": maxY
    };
  }

  void stopAllAni({bool stopPos1 = true}) {
    if (_posAniCtrolHua.isAnimating) {
      _posAniCtrolHua.stop();
    }
    if (_scaleAniCtrol.isAnimating) {
      _scaleAniCtrol.stop();
    }
    if (stopPos1 && _posAniCtrolTan != null && _posAniCtrolTan!.isAnimating) {
      _posAniCtrolTan?.stop();
    }
    // print("scale +++update====scale +++end=====stopAllAni===");
  }

  bool get isScaleAnimating => _scaleAniCtrol.isAnimating;

  bool _isDoubleDown = false;

  void onDoubleTapDown(TapDownDetails data) {
    if (_isDoubleDown || isScaleAnimating) {
      return;
    }
    _isDoubleDown = true;
    _scaleBefore = scale;
    _previousPosition = _position;
    _startFocalPoint = data.localPosition;
    stopAllAni();
  }

  void onDoubleTap() {
    _isDoubleDown = false;
    _isDoublePoint = false;
    if (isScaleAnimating) {
      return;
    }
    stopAllAni();
    // print("scale +++onDoubleTap====================$scale=====");
    if (scale.floor() > minScale) {
      animateScale(scale, minScale);
      animatePosition(_position, Offset.zero);
    } else {
      final double toScale = maxScale;
      animateScale(scale, toScale);
      animatePosition(
          _position,
          _getDestPos(
              _startFocalPoint -
                  (_startFocalPoint - _previousPosition) *
                      toScale /
                      _scaleBefore,
              toScale: toScale));
    }
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
    }
  }

  void animateScale(double from, double to) {
    _scaleAni = Tween<double>(
      begin: from,
      end: to,
    ).animate(_scaleAniCtrol);
    _scaleAniCtrol
      ..value = 0.0
      ..fling(velocity: 0.1);
  }

  void animatePosition(Offset from, Offset to) {
    _posAniCtrolTan ??= AnimationController(
      duration: Duration(milliseconds: (_aniDurInSeconds * 1000).toInt()),
      vsync: this,
    )..addListener(() {
        //  print("scale +++update====scale +++end=====position===$_position,${_positionAnimation1!.value}");
        setState(() {
          if (_posAniTan != null) {
            position = _posAniTan!.value;
          }
        });
      });
    _posAniTan = Tween<Offset>(begin: from, end: to).animate(_posAniCtrolTan!);
    _posAniCtrolTan!
      ..value = 0.0
      ..fling(velocity: 0.1);
  }

  void animatePosX(double from, double to) {
    _posXAniCtrol ??= AnimationController(
      duration: Duration(milliseconds: (_aniDurInSeconds * 1000).toInt()),
      vsync: this,
    )..addListener(() {
        //  print("scale +++update====scale +++end=====position===$_position,${_positionAnimation1!.value}");
        setState(() {
          if (_posXAni != null) {
            position = Offset(_posXAni!.value, _posY);
          }
        });
      });
    _posXAni = Tween<double>(begin: from, end: to).animate(_posXAniCtrol!);
    _posXAniCtrol!
      ..value = 0.0
      ..fling(velocity: 0.1);
  }

  void animatePosY(double from, double to) {
    _posYAniCtrol ??= AnimationController(
      duration: Duration(milliseconds: (_aniDurInSeconds * 1000).toInt()),
      vsync: this,
    )..addListener(() {
        //  print("scale +++update====scale +++end=====position===$_position,${_positionAnimation1!.value}");
        setState(() {
          if (_posYAni != null) {
            position = Offset(_posX, _posYAni!.value);
          }
        });
      });
    _posYAni = Tween<double>(
            begin: from,
            end: to) //.chain(CurveTween(curve: Curves.elasticInOut))
        .animate(_posYAniCtrol!);
    _posYAniCtrol!
      ..value = 0.0
      ..fling(velocity: 0.1);
  }

  void handleScaleAnimation() {
    scale = _scaleAni!.value;
  }

  void onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (scaleStateController.scaleState != PhotoViewScaleState.initial &&
          scale == scaleBoundaries.initialScale) {
        scaleStateController.setInvisibly(PhotoViewScaleState.initial);
      }
    }
  }

  @override
  void dispose() {
    _scaleAniCtrol.removeStatusListener(onAnimationStatus);
    _scaleAniCtrol.dispose();
    _posAniCtrolHua.dispose();
    _posAniCtrolTan?.dispose();
    _posXAniCtrol?.dispose();
    _posYAniCtrol?.dispose();
    if (widget.pointEvent != null) {
      widget.pointEvent.off("eventPoint", onUpdatePointEvent);
      widget.pointEvent.off("eventScale", onUpdateScaleEvent);
    }
    super.dispose();
  }

  void onTapUp(TapUpDetails details) {
    _updateControlValue();
    widget.onTapUp?.call(context, details, controller.value);
  }

  void onTapDown(TapDownDetails details) {
    _updateControlValue();
    widget.onTapDown?.call(context, details, controller.value);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we need a recalc on the scale
    if (widget.scaleBoundaries != cachedScaleBoundaries) {
      markNeedsScaleRecalc = true;
      cachedScaleBoundaries = widget.scaleBoundaries;
    }

    return StreamBuilder(
        stream: controller.outputStateStream,
        initialData: controller.prevValue,
        builder: (
          BuildContext context,
          AsyncSnapshot<PhotoViewControllerValue> snapshot,
        ) {
          if (snapshot.hasData) {
            final PhotoViewControllerValue value = snapshot.data!;
            final useImageScale = widget.filterQuality != FilterQuality.none;
            final matrix = Matrix4.identity()
              ..translate(_position.dx, _position.dy)
              ..scale(scale)
              ..rotateZ(value.rotation);

            final Widget customChildLayout = CustomSingleChildLayout(
              delegate: _CenterWithOriginalSizeDelegate(
                _rectSize ?? scaleBoundaries.childSize,
                basePosition,
                useImageScale,
              ),
              child: _buildHero(),
            );

            final child = Container(
              constraints: widget.tightMode
                  ? BoxConstraints.tight(scaleBoundaries.childSize * scale)
                  : null,
              decoration: widget.backgroundDecoration ?? _defaultDecoration,
              child: ClipRect(
                child: Transform(
                  transform: matrix,
                  child: customChildLayout,
                ),
              ),
            );

            if (widget.disableGestures) {
              return child;
            }

            return PhotoViewGestureDetector(
              onDoubleTapDown: onDoubleTapDown,
              onDoubleTap: onDoubleTap,
              onScaleStart: onScaleStart,
              onScaleUpdate: onScaleUpdate,
              onScaleEnd: onScaleEnd,
              hitDetector: this,
              onTapUp: onTapUp,
              onTapDown: widget.onTapDown != null
                  ? (details) => widget.onTapDown!(context, details, value)
                  : null,
              child: child,
            );
          } else {
            return Container();
          }
        });
  }

  Widget _buildHero() {
    final Widget buildChild = widget.hasCustomChild
        ? widget.customChild!
        : LayoutBuilder(builder: (context, constraints) {
            return Image(
              image: widget.imageProvider!,
              gaplessPlayback: widget.gaplessPlayback ?? false,
              filterQuality: widget.filterQuality,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
            );
          });
    return heroAttributes != null
        ? Hero(
            tag: heroAttributes!.tag,
            createRectTween: heroAttributes!.createRectTween,
            flightShuttleBuilder: heroAttributes!.flightShuttleBuilder,
            placeholderBuilder: heroAttributes!.placeholderBuilder,
            transitionOnUserGestures: heroAttributes!.transitionOnUserGestures,
            child: buildChild,
          )
        : buildChild;
  }
}

class _CenterWithOriginalSizeDelegate extends SingleChildLayoutDelegate {
  const _CenterWithOriginalSizeDelegate(
    this.subjectSize,
    this.basePosition,
    this.useImageScale,
  );

  final Size subjectSize;
  final Alignment basePosition;
  final bool useImageScale;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final childWidth = useImageScale ? childSize.width : subjectSize.width;
    final childHeight = useImageScale ? childSize.height : subjectSize.height;

    final halfWidth = (size.width - childWidth) / 2;
    final halfHeight = (size.height - childHeight) / 2;

    final double offsetX = halfWidth * (basePosition.x + 1);
    final double offsetY = halfHeight * (basePosition.y + 1);
    return Offset(offsetX, offsetY);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return useImageScale
        ? const BoxConstraints()
        : BoxConstraints.tight(subjectSize);
  }

  @override
  bool shouldRelayout(_CenterWithOriginalSizeDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CenterWithOriginalSizeDelegate &&
          runtimeType == other.runtimeType &&
          subjectSize == other.subjectSize &&
          basePosition == other.basePosition &&
          useImageScale == other.useImageScale;

  @override
  int get hashCode =>
      subjectSize.hashCode ^ basePosition.hashCode ^ useImageScale.hashCode;
}
