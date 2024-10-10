import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_image.dart';

class TencentVideoFloatingPlayer extends StatefulWidget {
  final int? index;
  final TencentVideoController controller;
  final Widget? overlay;
  final bool hasAspectRatio; //是否占满全屏 是 == 不占满全屏、否 == 占满全屏
  final Function()? onTapWidget;
  final double width;
  final double height;

  const TencentVideoFloatingPlayer({
    super.key,
    this.index,
    required this.controller,
    this.hasAspectRatio = true,
    this.overlay,
    this.onTapWidget,
    required this.width,
    required this.height,
  });

  @override
  TencentVideoFloatingPlayerState createState() =>
      TencentVideoFloatingPlayerState();
}

class TencentVideoFloatingPlayerState
    extends State<TencentVideoFloatingPlayer> {
  RxBool showControls = true.obs;

  final Rx<Offset> _offset = const Offset(100.0, 100.0).obs;
  final RxDouble _keyboardSize = 0.0.obs;
  bool adjustedKeyboard = false;

  StreamSubscription? videoStreamSubscription;
  Rxn<TencentVideoState> currentState = Rxn<TencentVideoState>();
  final controlDebouncer = Debounce(const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _offset.value = Offset(
        MediaQuery.of(navigatorKey.currentContext!).size.width,
        MediaQuery.of(navigatorKey.currentContext!).padding.top);
    _snapToEdges();
    videoStreamSubscription =
        objectMgr.tencentVideoMgr.onStreamBroadcast.listen(_onStream);
  }

  @override
  void dispose() {
    videoStreamSubscription?.cancel();
    super.dispose();
  }

  bool _isCallingDebouncer = false;
  _onStream(TencentVideoStream item) {
    if (item.pageIndex != widget.index) return;
    if (item.controller != widget.controller) return;

    if (item.state.value != currentState.value) {
      currentState.value = item.state.value;
    }

    if (item.state.value == TencentVideoState.PLAYING &&
        showControls.value &&
        !_isCallingDebouncer) {
      _isCallingDebouncer = true;
      controlDebouncer.call(() {
        showControls.value = false;
        _isCallingDebouncer = false;
      });
    }

    if (item.hasManuallyPaused) {
      currentState.value = TencentVideoState.PAUSED;
    }

    if (currentState.value == TencentVideoState.PAUSED) {
      showControls.value = true;
      controlDebouncer.dispose();
      _isCallingDebouncer = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_keyboardSize.value != MediaQuery.of(context).viewInsets.bottom) {
      var increasingKeyboard =
          _keyboardSize.value < MediaQuery.of(context).viewInsets.bottom;

      _keyboardSize.value = MediaQuery.of(context).viewInsets.bottom;
      var bottom = MediaQuery.of(context).padding.bottom + 52;
      if (increasingKeyboard) {
        double newHeight =
            MediaQuery.of(context).size.height - _keyboardSize.value - bottom;
        double videoY = _offset.value.dy + widget.height;
        if (videoY > newHeight) {
          _offset.value = Offset(_offset.value.dx, newHeight - widget.height);
          adjustedKeyboard = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(
          () => Positioned(
            left: _offset.value.dx,
            top: _offset.value.dy,
            child: GestureDetector(
              onTap: () {
                if (currentState.value == TencentVideoState.PAUSED) {
                  showControls.value = true;
                  controlDebouncer.dispose();
                  _isCallingDebouncer = false;
                  return;
                }
                controlDebouncer.dispose();
                showControls.toggle();
                _isCallingDebouncer = false;
              },
              onPanUpdate: (details) {
                var top = MediaQuery.of(context).padding.top; // + 44
                var bottom = MediaQuery.of(context).padding.bottom; // 52
                double height = MediaQuery.of(context).size.height -
                    _keyboardSize.value -
                    bottom -
                    widget.height;
                _offset.value = Offset(
                  (_offset.value.dx + details.delta.dx).clamp(
                      0.0, MediaQuery.of(context).size.width - widget.width),
                  (_offset.value.dy + details.delta.dy).clamp(top, height),
                );
                // widget.overlayController
                //     .alignChildTo(details.globalPosition, size * 0.5);
              },
              onPanEnd: (_) {
                _snapToEdges();
              },
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: colorTextPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4C000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                      spreadRadius: 6,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      TencentVideoPlayer(
                        controller: widget.controller,
                        index: widget.index,
                        showPlayButton: false,
                        pipAspectRatio: widget.width / widget.height,
                      ),
                      Positioned.fill(
                        child: Obx(
                          () => Offstage(
                            offstage: !showControls.value,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomImage(
                                        "assets/svgs/reel_search_close_icon.svg",
                                        size: 24,
                                        onClick: _onControllerClose,
                                        color: Colors.white,
                                      ),
                                      CustomImage(
                                        "assets/svgs/Maximize.svg",
                                        size: 20.0,
                                        onClick: _onMaximize,
                                      ),
                                    ],
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomImage(
                                          "assets/svgs/vid_rewind.svg",
                                          size: 24.0,
                                          onClick: _onControllerRewind,
                                        ),
                                        const SizedBox(width: 24),
                                        Obx(
                                          () => CustomImage(
                                            (widget.controller.isSeeking.value
                                                    ? (widget.controller
                                                                .previousState !=
                                                            TencentVideoState
                                                                .PLAYING &&
                                                        widget.controller
                                                                .previousState !=
                                                            TencentVideoState
                                                                .LOADING)
                                                    : (currentState.value !=
                                                            TencentVideoState
                                                                .PLAYING &&
                                                        currentState.value !=
                                                            TencentVideoState
                                                                .LOADING &&
                                                        currentState.value !=
                                                            TencentVideoState
                                                                .INIT &&
                                                        currentState.value !=
                                                            TencentVideoState
                                                                .PREPARED))
                                                ? 'assets/icons/play.svg'
                                                : 'assets/svgs/Pause.svg',
                                            size: 24.0,
                                            onClick: _onControllerToggle,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        CustomImage(
                                          "assets/svgs/vid_forward.svg",
                                          size: 24.0,
                                          onClick: _onControllerForward,
                                        ),
                                      ],
                                    ),
                                  ),
                                  TencentVideoSlider(
                                    controller: widget.controller,
                                    sliderType: SliderType.floating,
                                    height: 15,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onControllerForward() {
    widget.controller.onForwardVideo();
  }

  void _onControllerRewind() {
    widget.controller.onRewindVideo();
  }

  void _onMaximize() {
    objectMgr.tencentVideoMgr.maximizeFloating();
  }

  void _onControllerClose() {
    objectMgr.tencentVideoMgr.closeFloating();
  }

  void _onControllerToggle() {
    widget.controller.togglePlayState();
  }

  void _snapToEdges() {
    final screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
    double newLeft = _offset.value.dx;
    double newTop = _offset.value.dy;
    double leftCenter = _offset.value.dx + widget.width / 2;

    if (leftCenter < screenSize.width / 2) {
      newLeft = 0.0;
    } else {
      newLeft = screenSize.width - widget.width;
    }

    var bottom =
        MediaQuery.of(navigatorKey.currentContext!).padding.bottom; // 52
    var heightToCheck =
        MediaQuery.of(navigatorKey.currentContext!).size.height -
            (_keyboardSize.value != 0 ? _keyboardSize.value + bottom : bottom) -
            widget.height;

    if (newTop < 50.0) {
      newTop = MediaQuery.of(navigatorKey.currentContext!).padding.top; // 44
    } else if (newTop > heightToCheck - 50.0) {
      newTop = heightToCheck;
    }

    _offset.value = Offset(newLeft, newTop);
  }
}
