import 'dart:math';

import 'package:events_widget/event_dispatcher.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';

///自定义范围选择器
class CustomRangeSlider extends StatefulWidget {
  ///自定义范围选择器
  const CustomRangeSlider({
    super.key,
    required this.width,
    required this.height,
    required this.backHeight,
    required this.cursorSize,
    required this.min,
    required this.max,
    required this.values,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    this.cursorColor,
    this.cursorShadow,
  });
  final double width;
  final double height;
  final double backHeight;
  final double cursorSize;
  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final ValueChanged<RangeValues>? onChangeStart;
  final ValueChanged<RangeValues>? onChangeEnd;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? cursorColor;
  final List<BoxShadow>? cursorShadow;

  @override
  State<CustomRangeSlider> createState() => _CustomRangeSliderState();
}

class _CustomRangeSliderState extends State<CustomRangeSlider> {
  late final _CustomDragData _data;
  late final double _times;
  @override
  void initState() {
    super.initState();
    double width = widget.width - widget.cursorSize;
    double start = max(min(widget.values.start, widget.max), widget.min);
    double end = max(min(widget.values.end, widget.max), widget.min);
    _times = width / (widget.max - widget.min);
    _data = _CustomDragData(
        width: width,
        left: (start - widget.min) * _times,
        right: (end - widget.min) * _times);
    _data.on(_CustomDragData.eventDragUpdate, _onDragUpdate);
  }

  @override
  void dispose() {
    _data.off(_CustomDragData.eventDragUpdate, _onDragUpdate);
    super.dispose();
  }

  _onDragUpdate(sender, type, data) {
    double start = _data.left / _times + widget.min;
    double end = _data.right / _times + widget.min;
    RangeValues values = RangeValues(start, end);
    if (widget.onChanged != null) widget.onChanged!(values);
    if (data) {
      if (widget.onChangeStart != null) widget.onChangeStart!(values);
    } else {
      if (widget.onChangeEnd != null) widget.onChangeEnd!(values);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EventsWidget(
      data: _data,
      eventTypes: const [_CustomDragData.eventDragUpdate],
      builder: (context) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: widget.width - widget.cursorSize,
                  height: widget.backHeight,
                  color: widget.inactiveColor ?? Colors.white,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(left: _data.left),
                    width: _data.right - _data.left,
                    color: widget.activeColor ?? Colors.white,
                  ),
                ),
              ),
              Positioned(
                left: _data.left,
                child: _buildCursor(true),
              ),
              Positioned(
                left: _data.right,
                child: _buildCursor(false),
              ),
            ],
          ),
        );
      },
    );
  }

  _buildCursor(bool isLeft) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _data.onDragUpdate(details, isLeft),
      // onHorizontalDragEnd: (details) => _data.onDragEnd(details, isLeft),
      child: Container(
        width: widget.cursorSize,
        height: widget.cursorSize,
        decoration: BoxDecoration(
          color: widget.cursorColor ?? Colors.white,
          borderRadius: BorderRadius.circular(widget.cursorSize),
          boxShadow: widget.cursorShadow,
        ),
      ),
    );
  }
}

class _CustomDragData extends EventDispatcher {
  static const eventDragUpdate = 'eventDragUpdate';
  // static const eventDragEnd = 'eventDragEnd';
  double _width = 0;
  double _left = 0;
  double _right = 0;
  double get width => _width;
  double get left => _left;
  double get right => _right;
  _CustomDragData({
    required double width,
    double? left,
    double? right,
  }) {
    _width = width;
    _left = left ?? 0;
    _right = right ?? width;
  }

  void onDragUpdate(DragUpdateDetails details, bool isLeft) {
    if (isLeft) {
      _left += details.delta.dx;
      if (_left < 0) _left = 0;
      if (_left > _right) _left = _right;
    } else {
      _right += details.delta.dx;
      if (_right > _width) _right = _width;
      if (_right < _left) _right = _left;
    }
    event(this, eventDragUpdate, data: isLeft);
  }

  // void onDragEnd(DragEndDetails details, bool isLeft) {
  //   event(this, eventDragEnd);
  // }
}
