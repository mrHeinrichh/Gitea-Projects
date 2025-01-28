import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class CameraRecordScreen extends StatefulWidget {
  final String tag;
  const CameraRecordScreen({Key? key, required this.tag}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraRecordScreen> {
  CameraController? controller;
  bool _isCameraInitialized = false;
  late List<CameraDescription> cameras;
  late Timer timer;
  int direction = 1;
  int remainSeconds = 60;
  int totalSeconds = 60;
  int minSeconds = 2;

  @override
  void initState() {
    super.initState();
    startCamera(direction);
  }

  void startCamera(int direction) async {
    cameras = await availableCameras();
    controller = CameraController(cameras[direction], ResolutionPreset.high);
    await controller?.initialize().then((value) {
      if (!mounted) {
        return;
      }
      Future.delayed(Duration(milliseconds: 400), () {
        setState(() {
          _isCameraInitialized = true;
          startVideoRecording();
        });
      });
    });
  }

  startVideoRecording() {
    controller!.startVideoRecording().then((value) {
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainSeconds == 0) {
          stopVideoRecording();
          timer.cancel();
        } else {
          remainSeconds--;
        }
        // Get.find<CustomInputController>(tag: widget.tag).recordTime.value =
        //     totalSeconds - remainSeconds;
      });
    });
  }

  stopVideoRecording() async {
    if (controller!.value.isRecordingVideo) {
      try {
        XFile file = await controller!.stopVideoRecording();
        if (remainSeconds <= 58) {
          Get.find<CustomInputController>(tag: widget.tag)
              .receiveCircleVideoData(file, 60 - remainSeconds);
        }
      } on CameraException catch (e) {
        pdebug('Error stopping video recording: $e');
      }
    }
  }

  @override
  void dispose() async {
    super.dispose();

    if (timer.isActive) {
      timer.cancel();
    }
    await stopVideoRecording();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isCameraInitialized
        ? Stack(
            fit: StackFit.expand,
            children: [
              if (Platform.isIOS) iosBlurBackground(),
              Platform.isIOS ? _buildCamera(context) : androidBlurBackground(),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios_outlined,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      direction = direction == 1 ? 0 : 1;
                      startCamera(direction);
                    });
                  },
                ),
              ),
            ],
          )
        : Platform.isIOS
            ? iosBlurBackground()
            : androidBlurBackground();
  }

  Widget androidBlurBackground() {
    return Container(
      color: Colors.grey.withOpacity(0.3),
      child: _isCameraInitialized
          ? _buildCamera(context)
          : Container(
              width: double.infinity,
              height: double.infinity,
            ),
    );
  }

  UiKitView iosBlurBackground() {
    return const UiKitView(
      viewType: 'video_player',
      layoutDirection: TextDirection.ltr,
      creationParams: {'showBlur': true},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Stack _buildCamera(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
            clipper: MyClipper(context),
            child: CameraPreview(
              controller!,
            )),
        SizedBox(
          width: 300,
          height: 300,
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(seconds: totalSeconds),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.5),
                  strokeWidth: 10,
                  value: value,
                );
              }),
        ),
      ],
    );
  }
}

class MyClipper extends CustomClipper<Rect> {
  final BuildContext ctx;
  MyClipper(this.ctx);

  @override
  Rect getClip(Size size) {
    final Size windowSize = MediaQuery.of(ctx).size;
    Offset offset = Offset(windowSize.width / 2.12, windowSize.height / 2.5);
    if (Platform.isIOS) {
      offset = Offset(windowSize.width / 2.17, windowSize.height / 2.64);
    }
    return Rect.fromCircle(center: offset, radius: 160);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}
