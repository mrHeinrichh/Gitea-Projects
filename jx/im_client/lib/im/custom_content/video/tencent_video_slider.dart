import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:jxim_client/utils/color.dart';

enum SliderType {
  normal,
  moment,
  myMoment,
  momentInteractive,
  floating,
}

class TencentVideoSlider extends StatefulWidget {
  const TencentVideoSlider({
    super.key,
    required this.controller,
    this.height = 48,
    this.showTime = true,
    this.sliderType = SliderType.normal,
    this.timeStyle,
    this.sliderColors,
  });

  final TencentVideoController controller;
  final double height;
  final bool showTime;
  final SliderType sliderType;
  final TextStyle? timeStyle;
  final FijkSliderColors? sliderColors;

  @override
  TencentVideoSliderState createState() => TencentVideoSliderState();
}

class TencentVideoSliderState extends State<TencentVideoSlider> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.sliderType) {
      case SliderType.myMoment:
        return _buildMomentSlider(true);
      case SliderType.floating:
        return _buildFloatingSlider();
      case SliderType.moment:
        return _buildMomentSlider(false);
      case SliderType.normal:
      case SliderType.momentInteractive:
        return _buildSlider();
    }
  }

  Widget _buildFloatingSlider() {
    return Container(
      height: widget.height,
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Obx(() {
            return Align(
              alignment: Alignment.center,
              child: Padding(
                  padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
                  child: FijkSlider(
                    colors: widget.sliderColors ??
                        FijkSliderColors(
                          playedColor: Colors.white,
                          cursorColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.5),
                          baselineColor: Colors.white.withOpacity(0.3),
                          hasCursor: false,
                          hasFullLine: true,
                        ),
                    value: widget.controller.currentProgress.value == 0
                        ? 0.0
                        : (widget.controller.currentProgress.value >=
                                widget.controller.videoDuration.value
                            ? widget.controller.videoDuration.value.toDouble()
                            : widget.controller.currentProgress.value
                                .toDouble()),
                    //3
                    // cacheValue: controller.bufferValue.value,
                    cacheValue: widget.controller.bufferProgress.value == 0
                        ? 0.0
                        : widget.controller.bufferProgress.value.toDouble(),
                    //4
                    min: 0.0,
                    max: widget.controller.videoDuration.value == 0
                        ? 0.0
                        : widget.controller.videoDuration.value.toDouble(),
                    onChangeStart: widget.controller.onChangeStart,
                    onChanged: widget.controller.onChange,
                    onChangeEnd: widget.controller.onChangeEnd,
                    sliderType: widget.sliderType,
                  )),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMomentSlider(bool isMyMoment) {
    return Container(
      height: widget.height,
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Obx(() {
            return Align(
              alignment: Alignment.center,
              child: Padding(
                  padding: EdgeInsets.only(
                      left: isMyMoment ? 0 : 43,
                      right: isMyMoment ? 0 : 43,
                      bottom: isMyMoment ? 0 : 26),
                  child: FijkSlider(
                    colors: widget.sliderColors ??
                        FijkSliderColors(
                          playedColor: Colors.white,
                          cursorColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.5),
                          baselineColor: Colors.white.withOpacity(0.3),
                        ),
                    value: widget.controller.currentProgress.value == 0
                        ? 0.0
                        : (widget.controller.currentProgress.value >=
                                widget.controller.videoDuration.value
                            ? widget.controller.videoDuration.value.toDouble()
                            : widget.controller.currentProgress.value
                                .toDouble()),
                    //3
                    // cacheValue: controller.bufferValue.value,
                    cacheValue: widget.controller.bufferProgress.value == 0
                        ? 0.0
                        : widget.controller.bufferProgress.value.toDouble(),
                    //4
                    min: 0.0,
                    max: widget.controller.videoDuration.value == 0
                        ? 0.0
                        : widget.controller.videoDuration.value.toDouble(),
                    onChangeStart: widget.controller.onChangeStart,
                    onChanged: widget.controller.onChange,
                    onChangeEnd: widget.controller.onChangeEnd,
                    sliderType: widget.sliderType,
                  )),
            );
          }),
          if (!isMyMoment)
            Obx(
              () => (widget.controller.isSeeking.value)
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 26),
                        child: Obx(() {
                          return Text(
                            getTime(widget.controller.currentProgress.value ~/
                                1000), // 8
                            style: widget.timeStyle ??
                                TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12.0,
                                  fontFamily: appFontfamily,
                                ),
                          );
                        }),
                      ),
                    )
                  : const SizedBox(),
            ),
          if (!isMyMoment)
            Obx(() => (widget.controller.isSeeking.value)
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 26),
                      child: Obx(() {
                        return Text(
                          getTime(
                              widget.controller.videoDuration.value ~/ 1000),
                          style: widget.timeStyle ??
                              TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.0,
                                fontFamily: appFontfamily,
                              ),
                        );
                      }),
                    ),
                  )
                : const SizedBox()),
        ],
      ),
    );
  }

  //时间进度条UI
  Widget _buildSlider() {
    return Obx(
      () => Stack(
        children: [
          SizedBox(
            // height: widget.isReel ? 35 : 48,
            height: widget.height,
            // color: Colors.blue,
            child: FijkSlider(
              colors: widget.sliderColors ??
                  FijkSliderColors(
                    playedColor: Colors.white,
                    cursorColor: Colors.white,
                    bufferedColor: Colors.white.withOpacity(0.5),
                    baselineColor: Colors.white.withOpacity(0.3),
                  ),
              value: widget.controller.currentProgress.value == 0
                  ? 0.0
                  : (widget.controller.currentProgress.value >=
                          widget.controller.videoDuration.value
                      ? widget.controller.videoDuration.value.toDouble()
                      : widget.controller.currentProgress.value.toDouble()),
              //3
              // cacheValue: controller.bufferValue.value,
              cacheValue: widget.controller.bufferProgress.value == 0
                  ? 0.0
                  : widget.controller.bufferProgress.value.toDouble(),
              //4
              min: 0.0,
              max: widget.controller.videoDuration.value == 0
                  ? 0.0
                  : widget.controller.videoDuration.value.toDouble(),
              onChangeStart: widget.controller.onChangeStart,
              onChanged: widget.controller.onChange,
              onChangeEnd: widget.controller.onChangeEnd,
              sliderType: widget.sliderType,
            ),
          ),
          Obx(
            () => Positioned(
              // left: !controller.isFullMode.value ? 10 : 16, //7
              left: 16,
              bottom: 0,
              child: Offstage(
                offstage: !widget.showTime,
                child: Text(
                  getTime(widget.controller.currentProgress.value ~/ 1000),
                  // 8
                  style: widget.timeStyle ??
                      TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                        fontFamily: appFontfamily,
                      ),
                ),
              ),
            ),
          ),
          Obx(
            () => Positioned(
              // right: !controller.isFullMode.value ? 10 : 16,
              right: 16,
              bottom: 0,
              child: Offstage(
                offstage: !widget.showTime,
                child: Text(
                  getTime(widget.controller.videoDuration.value ~/ 1000),
                  style: widget.timeStyle ??
                      TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                        fontFamily: appFontfamily,
                      ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String getTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

/// FijkSlider is like Slider in Flutter SDK.
/// FijkSlider support [cacheValue] which can be used
/// to show the player's cached buffer.
/// The [colors] is used to make colorful painter to draw the line and circle.

class FijkSlider extends StatefulWidget {
  final double value;
  final double cacheValue;

  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  final double min;
  final double max;

  final FijkSliderColors colors;
  final SliderType sliderType;

  const FijkSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.cacheValue = 0.0,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.colors = const FijkSliderColors(),
    this.sliderType = SliderType.normal,
  })  : assert(min <= max),
        assert(value >= min && value <= max);

  @override
  State<StatefulWidget> createState() {
    return _FijkSliderState();
  }
}

class _FijkSliderState extends State<FijkSlider> {
  bool dragging = false;

  double dragValue = 0.0;

  static const double margin = 16.0;

  @override
  Widget build(BuildContext context) {
    double v = widget.value / (widget.max - widget.min);
    double cv = widget.cacheValue / (widget.max - widget.min);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      child: Container(
        margin: const EdgeInsets.only(left: margin, right: margin),
        height: double.infinity,
        width: double.infinity,
        color: Colors.transparent,
        child: CustomPaint(
          // size: Size(0, 4),
          painter: _SliderPainter(v, cv, dragging,
              colors: widget.colors, sliderType: widget.sliderType),
        ),
      ),
      onHorizontalDragStart: (DragStartDetails details) {
        setState(() {
          dragging = true;
        });
        dragValue = widget.value;
        widget.onChangeStart?.call(dragValue);
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        final box = context.findRenderObject() as RenderBox;
        final dx = details.localPosition.dx;
        dragValue = (dx - margin) / (box.size.width - 2 * margin);
        dragValue = max(0, min(1, dragValue));
        dragValue = dragValue * (widget.max - widget.min) + widget.min;
        widget.onChanged(dragValue);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        setState(() {
          dragging = false;
        });
        widget.onChangeEnd?.call(dragValue);
      },
    );
  }
}

/// Colors for the FijkSlider
class FijkSliderColors {
  const FijkSliderColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.6),
    this.bufferedColor = const Color.fromRGBO(50, 50, 100, 0.4),
    this.cursorColor = const Color.fromRGBO(255, 0, 0, 0.8),
    this.baselineColor = const Color.fromRGBO(200, 200, 200, 0.5),
    this.hasCursor = true,
    this.hasFullLine = false,
  });

  final Color playedColor;
  final Color bufferedColor;
  final Color cursorColor;
  final Color baselineColor;
  final bool hasCursor;
  final bool hasFullLine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FijkSliderColors &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode =>
      Object.hash(playedColor, bufferedColor, cursorColor, baselineColor);
}

class _SliderPainter extends CustomPainter {
  final double v;
  final double cv;

  final bool dragging;
  final Paint pt = Paint();

  final FijkSliderColors colors;
  final SliderType sliderType;

  _SliderPainter(
    this.v,
    this.cv,
    this.dragging, {
    this.colors = const FijkSliderColors(),
    this.sliderType = SliderType.normal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double lineHeight = min(size.height / 2, colors.hasFullLine ? 2.5 : 1);
    pt.color = colors.baselineColor;

    double radius = min(size.height / 2, 4);

    // draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, size.height / 2 - lineHeight),
          Offset(size.width, size.height / 2 + lineHeight),
        ),
        Radius.circular(radius),
      ),
      pt,
    );

    double value = v * size.width;
    if (value.isNaN) {
      value = 0.0;
    }

    // draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, size.height / 2 - lineHeight),
          Offset(size.width, size.height / 2 + lineHeight),
        ),
        Radius.circular(radius),
      ),
      pt,
    );

    // draw played part
    pt.color = colors.playedColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(
              0,
              size.height / 2 -
                  (dragging
                      ? sliderType != SliderType.normal
                          ? 2
                          : lineHeight
                      : lineHeight)),
          Offset(
              value,
              size.height / 2 +
                  (dragging
                      ? sliderType != SliderType.normal
                          ? 2
                          : lineHeight
                      : lineHeight)),
        ),
        Radius.circular(radius),
      ),
      pt,
    );

    // draw cached part
    final double cacheValue = cv * size.width;
    if (cacheValue > value && cacheValue > 0) {
      pt.color = colors.bufferedColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(
                value,
                size.height / 2 -
                    (dragging
                        ? sliderType != SliderType.normal
                            ? 2
                            : lineHeight
                        : lineHeight)),
            Offset(
                cacheValue,
                size.height / 2 +
                    (dragging
                        ? sliderType != SliderType.normal
                            ? 2
                            : lineHeight
                        : lineHeight)),
          ),
          Radius.circular(radius),
        ),
        pt,
      );
    }

    // draw circle cursor
    if (colors.hasCursor) {
      pt.color = colors.cursorColor;
      pt.color = pt.color.withAlpha(max(0, pt.color.alpha - 50));
      radius = min(size.height / 2, dragging ? 10 : 5);
      canvas.drawCircle(Offset(value, size.height / 2), radius, pt);
      pt.color = colors.cursorColor;
      radius = min(size.height / 2, dragging ? 6 : 3);
      canvas.drawCircle(Offset(value, size.height / 2), radius, pt);
    }

  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SliderPainter && hashCode == other.hashCode;

  @override
  int get hashCode => Object.hash(v, cv, dragging, colors);

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) {
    return hashCode != oldDelegate.hashCode;
  }
}
