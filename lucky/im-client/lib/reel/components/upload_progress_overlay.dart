import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class UploadProgressOverlay {
  BuildContext _context;
  OverlayState? overlayState;
  OverlayEntry? overlayEntry;

  bool isOpen = false;
  final curProgress = 0.0.obs;
  final curStatus = SubmitStatus.INIT.obs;

  void close() {
    overlayEntry?.remove();
    overlayEntry = null;
    isOpen = false;
    reset();
  }

  void show() {
    if(overlayEntry == null){
      overlayEntry = OverlayEntry(
        builder: (context) {
          return _buildOverlayWidget();
        },
      );
    }
    isOpen = true;
    overlayState?.insert(overlayEntry!);
  }

  UploadProgressOverlay._create(this._context) {
    overlayState = Overlay.of(_context);
  }

  factory UploadProgressOverlay.of(BuildContext context) {
    return UploadProgressOverlay._create(context);
  }

  Widget _buildOverlayWidget() {
    return Positioned(
      top: MediaQuery.of(_context).viewPadding.top,
      right: 20,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: JXColors.white.withOpacity(0.3),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            color: JXColors.black,
          ),
          child: Center(
              child: Obx(() {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: curProgress.value,
                          color: JXColors.white,
                          backgroundColor: JXColors.white.withOpacity(0.3),
                          strokeWidth: 3,
                        ),
                        Text(
                          "${(curProgress.value * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                              fontSize: MFontSize.size10.value,
                              color: JXColors.white,
                              decoration: TextDecoration.none
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${curStatus.value.name}",
                      style: TextStyle(
                          fontSize: MFontSize.size12.value,
                          color: JXColors.white,
                          decoration: TextDecoration.none
                      ),
                    ),
                  ],
                );
              })
          ),
        ),
      ),
    );
  }

  void reset(){
    curProgress.value = 0.0;
    curStatus.value = SubmitStatus.INIT;
  }

  void updateProgress(double value){
    curProgress.value = value;
  }
}

enum SubmitStatus { INIT, COMPRESSING, WAIT_UPLOAD, UPLOADING, UPLOADED, DONE }

extension CatExtension on SubmitStatus {
  String get name {
    switch (this) {
      case SubmitStatus.INIT:
        return '检查视频';
      case SubmitStatus.COMPRESSING:
        return '压缩中';
      case SubmitStatus.WAIT_UPLOAD:
        return '等待上传';
      case SubmitStatus.UPLOADING:
        return "上传中";
      case SubmitStatus.UPLOADING:
        return "已上传";
      case SubmitStatus.DONE:
        return "创建成功";
      default:
        return '';
    }
  }

}
