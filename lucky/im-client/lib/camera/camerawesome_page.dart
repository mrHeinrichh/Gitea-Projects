import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:all_sensors/all_sensors.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/camera/record_seconds.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image/image.dart' as img;

import 'package:jxim_client/utils/platform_utils.dart';

class CamerawesomePage extends StatefulWidget {
  const CamerawesomePage({
    super.key,
    this.enableRecording = false,
    this.maximumRecordingDuration = const Duration(seconds: 15),
  });

  final bool enableRecording;
  final Duration maximumRecordingDuration;

  @override
  State<CamerawesomePage> createState() => _CamerawesomePageState();
}

class _CamerawesomePageState extends State<CamerawesomePage> {
  late AwesomeCaptureButton captureButton;
  Timer? videoTimer;
  final RecordSeconds recordSeconds = RecordSeconds();
  bool isPortraitVideo = true;
  DateTime? lastSwitchTime;

  @override
  void dispose() {
    videoTimer?.cancel();
    awesomeDidTapTakePhoto = false;
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Future.delayed(const Duration(milliseconds: 1500), () {
    //   resetZoomTo1();
    // });
  }

  @override
  Widget build(BuildContext context) {
    CaptureRequestBuilder? pathBuilder = (sensors) async {
      if (sensors.length == 1) {
        final String filePath =  await downloadMgr.getTmpCachePath(
            "${sensors.first.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg",
            sub: 'camerawesome');

        return SingleCaptureRequest(filePath, sensors.first);
      }
      // Separate pictures taken with front and back camera
      return MultipleCaptureRequest(
        {
          for (final sensor in sensors)
            sensor: await downloadMgr.getTmpCachePath(
                "${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg",
                sub: 'camerawesome'),
        },
      );
    };
    ExifPreferences? exifPreferences = ExifPreferences(saveGPSLocation: false);
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: CameraAwesomeBuilder.awesome(
          progressIndicator: fakeScreenBeforeReady(context),
          onMediaCaptureEvent: (event) async {
            switch ((event.status, event.isPicture, event.isVideo)) {
              case (MediaCaptureStatus.capturing, true, false):
                debugPrint('Capturing picture...');
                awesomeDidTapTakePhoto = true;
              case (MediaCaptureStatus.success, true, false):
                event.captureRequest.when(
                  single: (single) async {
                    bool isPortrait = await _isPortrait();
                    debugPrint('Picture saved: ${single.file?.path}');
                    String filePath = '${single.file?.path}';
                    if (filePath.contains('front_')) {
                      //如果是前置摄像头，翻转图片，并覆盖保存
                      await flipImage(filePath);
                    }
                    final fileName = filePath.split("/").toList().last;
                    // 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    // 保存照片到相册
                    AssetEntity? result = await PhotoManager.editor
                        .saveImageWithPath(filePath, title: fileName);
                    videoTimer?.cancel();
                    Navigator.pop(context, {
                      "result": result,
                      "needSwap":
                          PlatformUtils.deviceBrand == 'samsung' && isPortrait
                    });
                  },
                  multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                      debugPrint('multiple image taken: $key ${value?.path}');
                    });
                  },
                );
              case (MediaCaptureStatus.failure, true, false):
                debugPrint('Failed to capture picture: ${event.exception}');
              case (MediaCaptureStatus.capturing, false, true):
                debugPrint('Capturing video...');
                startTimer(); //开始录屏倒计时
                isPortraitVideo = await _isPortrait();
                break;
              case (MediaCaptureStatus.success, false, true):
                event.captureRequest.when(
                  single: (single) async {
                    debugPrint('Video saved: ${single.file?.path}');
                    String videoPath = '${single.file?.path}';
                    final fileName =
                        'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
                    // 保存视频到相册
                    AssetEntity? result = await PhotoManager.editor.saveVideo(
                      File(videoPath),
                      title: fileName,
                    );
                    videoTimer?.cancel();
                    Navigator.pop(
                        context, {"result": result, "needSwap": false});
                  },
                  multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                      debugPrint('multiple video taken: $key ${value?.path}');
                    });
                  },
                );
              case (MediaCaptureStatus.failure, false, true):
                debugPrint('Failed to capture video: ${event.exception}');
              default:
                debugPrint('Unknown event: $event');
            }
          },
          saveConfig: widget.enableRecording
              ? SaveConfig.photoAndVideo(
                  initialCaptureMode: CaptureMode.photo,
                  photoPathBuilder: pathBuilder,
                  videoOptions: VideoOptions(
                    enableAudio: true,
                    ios: CupertinoVideoOptions(
                      fps: 25,
                    ),
                    android: AndroidVideoOptions(
                      bitrate: 6000000,
                      fallbackStrategy: QualityFallbackStrategy.lower,
                    ),
                  ),
                  exifPreferences: exifPreferences,
                )
              : SaveConfig.photo(
                  pathBuilder: pathBuilder,
                  exifPreferences: exifPreferences,
                  mirrorFrontCamera: false),
          sensorConfig: SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back),
            flashMode: FlashMode.none,
            aspectRatio: CameraAspectRatios.ratio_16_9,
            zoom: 0.0,
          ),
          enablePhysicalButton: true,
          // filter: AwesomeFilter.AddictiveRed,
          previewAlignment: Alignment.center,
          previewFit: CameraPreviewFit.fitHeight,
          onMediaTap: (mediaCapture) {
            mediaCapture.captureRequest.when(
              single: (single) {
                debugPrint('single: ${single.file?.path}');
                // single.file?.open();
              },
              multiple: (multiple) {
                multiple.fileBySensor.forEach((key, value) {
                  debugPrint('multiple file taken: $key ${value?.path}');
                  // value?.open();
                });
              },
            );
          },
          availableFilters: [],
          //awesomePresetFiltersList,
          topActionsBuilder: (state) {
            return AwesomeTopActions(
              state: state,
              children: [
                AwesomeFlashButton(
                    state: state,
                    iconBuilder: (flashMode) {
                      if (flashMode == FlashMode.on) {
                        return SvgPicture.asset(
                          'assets/svgs/awesome_flash_on.svg',
                          width: 28.w,
                          height: 28.w,
                        );
                      } else {
                        return SvgPicture.asset(
                          'assets/svgs/awesome_flash_off.svg',
                          width: 28.w,
                          height: 28.w,
                        );
                      }
                    }),
                const Spacer(),
                Align(alignment: Alignment.center, child: recordSeconds),
                const Spacer(),
              ],
            );
          },
          middleContentBuilder: (state) {
            return (Column(
              children: [
                const Spacer(),
                AwesomeZoomSelector(state: state),
                AwesomeCameraModeSelector(state: state),
              ],
            ));
          },
          bottomActionsBuilder: (state) {
            AwesomeCaptureButton captureButton = AwesomeCaptureButton(
              state: state,
            );
            this.captureButton = captureButton;
            return AwesomeBottomActions(
              state: state,
              left: buildBackButton(context),
              captureButton: captureButton,
              right: AwesomeCameraSwitchButton(
                state: state,
                scale: 1.0,
                iconBuilder: () {
                  return ClipOval(
                    child: Image(
                        image: const AssetImage(
                          "assets/images/awesome_switch_camera.png",
                        ),
                        width: 36.w,
                        height: 36.w),
                  );
                },
                onSwitchTap: (state) async {
                  //按钮冷却限制
                  if (lastSwitchTime != null) {
                    double timePast = DateTime.now()
                        .difference(lastSwitchTime!)
                        .inMilliseconds
                        .toDouble();
                    if (timePast < 1000) {
                      return;
                    }
                  } else {
                    lastSwitchTime = DateTime.now();
                  }
                  awesomeFlipWidgetKey.currentState?.flip();
                  state.switchCameraSensor(
                    aspectRatio: state.sensorConfig.aspectRatio,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// The back button near to the [buildCaptureButton].
  /// 靠近拍照键的返回键
  Widget buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        videoTimer?.cancel();
        Navigator.of(context).pop();
      },
      child: ClipOval(
        child: Image(
            image: const AssetImage(
              "assets/images/awesome_back.png",
            ),
            width: 36.w,
            height: 36.w),
      ),
    );
  }

  startTimer() {
    videoTimer?.cancel();
    double count = widget.maximumRecordingDuration.inSeconds.toDouble();
    double timeLength = 0;
    recordSeconds.updateSeconds(timeLength);
    videoTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (mounted) {
        count -= 1;
        timeLength += 1;
        if (count <= 0) {
          timer.cancel();
          await captureButton.state.when(
            onVideoRecordingMode: (videoState) => videoState.stopRecording(),
          );
        }
        recordSeconds.updateSeconds(timeLength);
      }
    });
  }

  Widget fakeScreenBeforeReady(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/awesome_bg.jpg"),
          fit: BoxFit.fill,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // 包含状态栏高度的 Container
                Container(
                  height: statusBarHeight,
                  color: AwesomeTheme.defaultBlackBgColor,
                ),
                Container(
                  height: 44,
                  color: AwesomeTheme.defaultBlackBgColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                      ),
                      SvgPicture.asset(
                        'assets/svgs/awesome_flash_off.svg',
                        width: 28.w,
                        height: 28.w,
                      ),
                      const Spacer(),
                      const SizedBox(width: 80),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                    child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 56,
                      child: Center(
                        child: AwesomeBouncingWidget(
                          onTap: () {},
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.all(0.0),
                            child: const AwesomeCircleWidget(
                              child: Text(
                                "1.0X",
                                style: TextStyle(
                                    color: Color(0xffFFD50B), fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16)
                  ],
                )),
                Container(color: AwesomeTheme.defaultBlackBgColor, height: 8),
                Container(
                  color: AwesomeTheme.defaultBlackBgColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: PageView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: PageController(
                                viewportFraction: 0.25, initialPage: 0),
                            itemCount: 2,
                            itemBuilder: ((context, index) {
                              final cameraMode = index == 0
                                  ? CaptureMode.photo
                                  : CaptureMode.video;
                              EdgeInsets pad = EdgeInsets.zero;
                              if (index == 1) {
                                pad = const EdgeInsets.only(right: 40);
                              }
                              return Padding(
                                padding: pad,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: 1,
                                  child: AwesomeBouncingWidget(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 0),
                                        child: Text(
                                          // cameraMode.name.toUpperCase(),
                                          cameraMode.chineseName,
                                          style: TextStyle(
                                            color: index == 0
                                                ? const Color(0xffE49E4C)
                                                : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 4,
                                                color: Colors.black,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  color: AwesomeTheme.defaultBlackBgColor,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(width: 16),
                              buildBackButton(context),
                              const Spacer(),
                              SizedBox(
                                key: const ValueKey('cameraButton'),
                                height: 80,
                                width: 80,
                                child: Transform.scale(
                                  scale: 1,
                                  child: CustomPaint(
                                    painter: CameraButtonPainter(),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ClipOval(
                                child: Image(
                                    image: const AssetImage(
                                      "assets/images/awesome_switch_camera.png",
                                    ),
                                    width: 36.w,
                                    height: 36.w),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> flipImage(String imagePath) async {
    try {
      // Read the image file
      File imageFile = File(imagePath);
      List<int> imageBytes = await imageFile.readAsBytes();

      // Decode the image
      img.Image originalImage =
          img.decodeImage(Uint8List.fromList(imageBytes))!;

      // Flip the image horizontally
      img.Image flippedImage = img.flipHorizontal(originalImage);

      // Encode the image
      List<int> flippedImageBytes = img.encodeJpg(flippedImage);

      // Write the image back to the original file
      await imageFile.writeAsBytes(Uint8List.fromList(flippedImageBytes));

      print('Image flipped and saved successfully.');
    } catch (e) {
      print('Error flipping image: $e');
    }
  }
}

Future<bool> _isPortrait() async {
  final accelerometerEvent = await accelerometerEvents!.first;
  return accelerometerEvent.x.abs() < accelerometerEvent.y.abs();
}
