import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/im/custom_content/painter/voice_painter.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/audio_recording_model/volume_model.dart';
import 'package:jxim_client/im/services/audio_services/volume_record_service.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef RecordEndedCallback = VoidCallback;

class VoiceRecordButton extends StatefulWidget {
  final bool isRecording;
  final bool isLocked;
  final bool isLockedSelected;
  final bool isDeleteSelected;
  final Function(bool, bool) onRecordingStateChange;
  final RecordEndedCallback? onEnd;
  final CustomInputController controller;

  const VoiceRecordButton({
    super.key,
    required this.isRecording,
    required this.onRecordingStateChange,
    required this.controller,
    this.isLocked = false,
    this.isLockedSelected = false,
    this.isDeleteSelected = false,
    this.onEnd,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final int _animationDuration = 150;
  final int _reverseAnimationDuration = 0;
  final int maxDecibelLength = 55;

  late final AnimationController _animationController;
  late final AnimationController _toggleHoldController;
  late Animation<double> _animation;
  late Animation<double> _toggleHoldAnimation;
  late Animation<Color?> _recorderColorTween;

  double initialAngle = 180;

  VolumeRecordService recordService = VolumeRecordService.sharedInstance;
  ValueNotifier<List<double>> recordDecibels = ValueNotifier<List<double>>([]);
  ValueNotifier<int> recordTime = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HapticFeedback.mediumImpact();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _animationDuration,
      ),
      reverseDuration: Duration(
        milliseconds: _reverseAnimationDuration,
      ),
    );

    _toggleHoldController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _animationDuration,
      ),
      reverseDuration: Duration(
        milliseconds: _animationDuration,
      ),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(_animationListener);

    _toggleHoldAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _toggleHoldController,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(_animationListener);

    _recorderColorTween = ColorTween(
      begin: Colors.black.withOpacity(0.6),
      end: backgroundColor,
    ).animate(
      CurvedAnimation(
        parent: _toggleHoldAnimation,
        curve: Curves.easeInOutCubic,
      ),
    );

    _toggleHoldController.forward();
    _animationController.forward().whenComplete(startRecord);
  }

  void _animationListener() {
    if (mounted) setState(() {});
  }

  void startRecord() {
    widget.onRecordingStateChange(true, true);
    if (recordService.isRecording) return;
    recordService.startRecorder(
      onStartCallBack: (int recordSeconds, double? decibels) {
        if (decibels != null && decibels < 0) return;
        recordTime.value = recordSeconds;
        recordDecibels.value = [...recordDecibels.value, decibels ?? 5.0];
      },
      onTimeout: () {
        if (recordTime.value <= 0) {
          return;
        }
        widget.onRecordingStateChange(false, true);
      },
    );
  }

  @override
  void didUpdateWidget(VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (!widget.isRecording) {
        if (widget.isDeleteSelected) {
          _animationController.reverse().whenComplete(() async {
            recordService.stopRecord();
            widget.onEnd?.call();
          });
          WakelockPlus.disable();
          return;
        }
        _animationController.reverse().whenComplete(() async {
          await recordService.stopRecord();
          if (recordTime.value >= 1000) {
            recordDecibels.value = getFilteredDecibelData();
            widget.controller.onSendVoice(VolumeModel(
              path: recordService.recordPath,
              second: recordTime.value,
              decibels: recordDecibels.value.toList(),
            ));
          } else {
            Toast.showToast(localized(toastShort));
          }
          widget.onEnd?.call();
        });

        WakelockPlus.disable();
      }
    }

    if (!widget.isLocked &&
        widget.isLockedSelected != oldWidget.isLockedSelected) {
      if (widget.isLockedSelected) {
        _toggleHoldController.reverse();
      } else {
        _toggleHoldController.forward();
      }
      if (mounted) setState(() {});
    } else if (widget.isDeleteSelected != oldWidget.isDeleteSelected) {
      if (widget.isDeleteSelected) {
        _toggleHoldController.reverse();
      } else {
        _toggleHoldController.forward();
      }
      if (mounted) setState(() {});
    }

    if (widget.isLocked != oldWidget.isLocked) {
      if (mounted) setState(() {});
    }
  }

  List<double> getFilteredDecibelData() {
    if (recordDecibels.value.length <= 15) {
      return [
        ///max of 15 wave.
        ...List.generate(16 - recordDecibels.value.length, (_) => 5.0),
        ...recordDecibels.value,
      ];
    } else if (recordDecibels.value.length >= 55) {
      final step = (recordDecibels.value.length / 55).ceil();
      final List<double> tempDecibelValue = [];
      try {
        for (int i = 0; i < recordDecibels.value.length; i += step) {
          if (i + step > recordDecibels.value.length) break;
          if ((i + 1) + step < recordDecibels.value.length) {
            final nextIndex = (i + 1) + step;
            final avgData = recordDecibels.value
                    .getRange(i, nextIndex)
                    .reduce((a, b) => a + b) /
                step;
            tempDecibelValue.add(avgData);
          } else {
            tempDecibelValue.add(recordDecibels.value[i]);
          }
        }
      } catch (e) {
        pdebug(e);
      }
      return tempDecibelValue;
    } else {
      return recordDecibels.value;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      if (recordService.isRecording) {
        widget.onRecordingStateChange(false, false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: _animation.value == 0
                    ? 0.0
                    : MediaQuery.of(context).size.height,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6)),
              ),
            ),
            // if (widget.isLocked)
            //   ...recordLockedButton()
            // else
            recordInfo(),
            recordInteractionButton(),

            // Decibel Display Area
            Align(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 72 * _animation.value,
                    width:
                        ObjectMgr.screenMQ!.size.width * 0.8 * _animation.value,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        recordDeleteColor,
                        bubbleMeColor,
                        widget.isDeleteSelected
                            ? _toggleHoldAnimation.value
                            : 1,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: recordDecibels,
                      builder: (_, List<double> decibels, __) {
                        return Container(
                          padding: EdgeInsets.fromLTRB(12, 24.0, 16, 24.0),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(
                                ObjectMgr.screenMQ!.size.width * 0.8,
                                72,
                              ),
                              willChange: true,
                              painter: VoicePainter(
                                decibels: decibels,
                                lineColor: Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget recordInfo() {
    return Positioned(
      bottom: 0.0,
      left: -20.0,
      right: -20.0,
      child: Transform.translate(
        offset: Offset(
          0.0,
          _animation.value * (MediaQuery.of(context).size.width / 6),
        ),
        child: ClipOval(
          child: Container(
            alignment: Alignment.center,
            height: _animation.value * 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _recorderColorTween.value,
            ),
            child: Offstage(
              offstage: _animation.value != 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 17.0,
                      bottom: 24.0,
                    ),
                    child: ValueListenableBuilder(
                        valueListenable: recordTime,
                        builder: (_, int value, __) {
                          final String hintText;
                          if (value ~/ 1000 > 50) {
                            hintText = localized(
                              recordStopAt,
                              params: ["${60 - (value ~/ 1000)}"],
                            );
                          } else {
                            hintText = constructTime(
                              value ~/ 1000,
                              showHour: false,
                              showMinutes: true,
                            );
                          }
                          return Text(
                            hintText,
                            style: TextStyle(
                              color: Color.lerp(
                                Colors.white,
                                JXColors.black,
                                _toggleHoldAnimation.value,
                              ),
                            ),
                          );
                        }),
                  ),
                  SvgPicture.asset(
                    'assets/svgs/mic.svg',
                    width: 24,
                    height: 24,
                    color: Color.lerp(
                      Colors.white,
                      JXColors.primaryTextBlack,
                      _toggleHoldAnimation.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget recordInteractionButton() {
    return Positioned(
      bottom:
          _animation.value * 200 - (MediaQuery.of(context).size.width / 6) + 16,
      left: 48.0,
      right: 48.0,
      child: Offstage(
        offstage: _animation.value != 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            GestureDetector(
              onTap: widget.isLocked
                  ? () => widget.onRecordingStateChange(false, false)
                  : null,
              child: ForegroundOverlayEffect(
                overlayColor: JXColors.primaryTextBlack.withOpacity(0.3),
                radius: const BorderRadius.vertical(
                  top: Radius.circular(100),
                  bottom: Radius.circular(100),
                ),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: _animationDuration),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: widget.isDeleteSelected
                        ? recordDeleteColor
                        : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(9999.0),
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/delete2_icon.svg',
                    width: 28,
                    height: 28,
                    color:
                        widget.isDeleteSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: widget.isLocked,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  widget.isLockedSelected
                      ? localized(releaseToLock)
                      : widget.isDeleteSelected
                          ? localized(releaseToCancel)
                          : localized(releaseToSend),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.isLocked
                  ? () => widget.onRecordingStateChange(false, true)
                  : null,
              child: ForegroundOverlayEffect(
                overlayColor: JXColors.primaryTextBlack.withOpacity(0.3),
                radius: const BorderRadius.vertical(
                  top: Radius.circular(100),
                  bottom: Radius.circular(100),
                ),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: _animationDuration),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: widget.isLocked
                        ? accentColor
                        : widget.isLockedSelected
                            ? Colors.white
                            : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(9999.0),
                  ),
                  child: AnimatedCrossFade(
                    duration: Duration(milliseconds: _animationDuration),
                    crossFadeState: widget.isLocked
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: SvgPicture.asset(
                      'assets/svgs/nav2.svg',
                      width: 24,
                      height: 24,
                    ),
                    firstCurve: Curves.easeInOutCubic,
                    secondChild: SvgPicture.asset(
                      'assets/svgs/lock_fill_icon.svg',
                      width: 24,
                      height: 24,
                      color:
                          widget.isLockedSelected ? Colors.black : Colors.white,
                    ),
                    secondCurve: Curves.easeInOutCubic,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
