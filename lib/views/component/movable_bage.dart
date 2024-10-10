import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/component/movable_badge_painter.dart';

class MovableOverlayBadge
{
  BuildContext _context;
  OverlayState? overlayState;
  OverlayEntry? overlayEntry;

  bool isShowing = false;

  Offset? childCenter;
  Size? childSize;

  final touchInfo = TouchInfo().obs;

  final Function(bool update) onLongPressUp;

  MovableOverlayBadge._create(this._context,this.onLongPressUp) {
    overlayState = Overlay.of(_context,);
  }

  factory MovableOverlayBadge.of(BuildContext context,Function(bool update) onLongPressUp) {
    return MovableOverlayBadge._create(context,onLongPressUp);
  }

  void show(GlobalKey childGlobalKey)
  {
    childCenter = WidgetCenterFinder.getWidgetCenter(childGlobalKey);
    childSize = WidgetCenterFinder.getWidgetSize(childGlobalKey);
    overlayEntry ??= OverlayEntry(
      builder: (context) {
        if(childCenter!=null){
          touchInfo.value.addPoint(childCenter!);
        }
        return _buildOverlayWidget(childGlobalKey);
      },
    );
    isShowing = true;
    overlayState?.insert(overlayEntry!);
  }

  bool close() {
    isShowing = false;
    bool update = isNeedToUpdate();
    overlayEntry?.remove();
    overlayEntry = null;
    touchInfo.value.reset();
    return update;
  }

  bool isNeedToUpdate() {
    bool isNeedUpdate = true;
    if(childCenter == null || childSize == null || touchInfo.value.points.isEmpty) {
      isNeedUpdate = false;
      return isNeedUpdate;
    }

    if(touchInfo.value.points.last.dy > childCenter!.dy || touchInfo.value.points.last.dy == childCenter!.dy){
      isNeedUpdate = false;
    }else {
      double distance = sqrt(pow(childCenter!.dx - touchInfo.value.points.last.dx, 2) + pow(childCenter!.dy - touchInfo.value.points.last.dy, 2));
      if(childSize!.width > distance && touchInfo.value.points.last.dy - childCenter!.dy < childSize!.height) {
        isNeedUpdate = false;
      }
    }
    return isNeedUpdate;
  }

  void addPoint(Offset point) {
    if(isShowing){
      touchInfo.value.addPoint(point);
    }
  }

  Widget _buildOverlayWidget(GlobalKey child,{double disappearThreshold=1.0}) {
    return
      Obx(() =>
          GestureDetector(
            onLongPressUp: () {
                onLongPressUp.call(close());
            },
            onLongPressMoveUpdate: (details) {
                touchInfo.value.addPoint(details.localPosition);
            },
            child:Stack(
              children: [
                if(childCenter != null && childSize != null)
                  Container(
                    color:Colors.transparent,
                    child:
                    CustomPaint(
                      size: Size(MediaQuery.of(_context).size.width, MediaQuery.of(_context).size.height),
                      painter: MovableBadgePainter(child,repaint: touchInfo.value,widgetCenterPoint:Point(childCenter!.dx,childCenter!.dy),shortestRadius: childSize!.shortestSide/2,disappearThreshold: disappearThreshold),
                    ),
                  ),
              ],
            ),
          )
      );
  }
}

class WidgetCenterFinder {
  static Offset? getWidgetCenter(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      return Offset(position.dx + size.width / 2, position.dy + size.height / 2);
    }
    return null;
  }

  static Size? getWidgetSize(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.size;
    }
    return null;
  }
}