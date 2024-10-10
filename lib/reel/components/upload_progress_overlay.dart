import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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

  void show(AssetEntity asset) {
    overlayEntry ??= OverlayEntry(
      builder: (context) {
        return _buildOverlayWidget(asset);
      },
    );
    isOpen = true;
    overlayState?.insert(overlayEntry!);
  }

  UploadProgressOverlay._create(this._context) {
    overlayState = Overlay.of(_context);
  }

  factory UploadProgressOverlay.of(BuildContext context) {
    return UploadProgressOverlay._create(context);
  }

  Widget _buildOverlayWidget(AssetEntity asset) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(_context).viewPadding.top + 56,
          left: 8,
        ),
        width: 80,
        height: 106,
        decoration: BoxDecoration(
          color: asset.mimeType!="text"?Colors.black:const Color(0xffABABAB),
          image: asset.mimeType!="text"?DecorationImage(
            image: AssetEntityImageProvider(
              asset,
              isOriginal: false,
            ),
            fit: BoxFit.cover,
          ):null,
          border: Border.all(
            width: 1,
            color: colorWhite,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: colorTextPrimary.withOpacity(0.40),
              blurRadius: 4,
            ),
          ],
        ),
        child: Obx(() {
          return Stack(
                children: [
                 if(asset.mimeType=="text")
                   Align(
                     alignment: Alignment.center,
                     child: Padding(
                       padding: const EdgeInsets.all(6),
                       child: LayoutBuilder(
                         builder: (context, constraints) {
                           final textStyle = TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w400,
                             color: const Color(0xff121212).withOpacity(0.48),
                             decoration: TextDecoration.none,
                           );

                           final textSpan = TextSpan(text: asset.title, style: textStyle);
                           final textPainter = TextPainter(
                             text: textSpan,
                             maxLines: 2,
                             ellipsis: '...',
                             textDirection: TextDirection.ltr,
                           );

                           textPainter.layout(maxWidth: constraints.maxWidth);

                           int maxLines = 2;
                           if (textPainter.didExceedMaxLines) {
                             maxLines = (constraints.maxHeight / textPainter.preferredLineHeight).floor();
                           }

                           return Text(
                             asset.title!,
                             maxLines: maxLines,
                             overflow: TextOverflow.ellipsis,
                             style: textStyle,
                           );
                         },
                       ),
                     ),
                   ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 45,
                      width: 45,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorTextPrimary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        value: curProgress.value,
                        color: colorWhite,
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "${(curProgress.value * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: MFontSize.size12.value,
                        fontWeight: MFontWeight.bold5.value,
                        color: colorWhite,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 2),
                  // Text(
                  //   "${curStatus.value.name}",
                  //   style: TextStyle(
                  //       fontSize: MFontSize.size10.value,
                  //       color: colorWhite,
                  //       decoration: TextDecoration.none,
                  //       overflow: TextOverflow.ellipsis),
                  // ),
                ],
              );
        }),
      ),
    );
  }

  void reset() {
    curProgress.value = 0.0;
    curStatus.value = SubmitStatus.INIT;
  }

  void updateProgress(double value) {
    curProgress.value = value;
  }
}

enum SubmitStatus { INIT, COMPRESSING, WAIT_UPLOAD, UPLOADING, UPLOADED, DONE }

extension CatExtension on SubmitStatus {
  String get name {
    switch (this) {
      case SubmitStatus.INIT:
        return localized(reelCheckVideo);
      case SubmitStatus.COMPRESSING:
        return localized(reelCompressing);
      case SubmitStatus.WAIT_UPLOAD:
        return localized(reelWaitUpload);
      case SubmitStatus.UPLOADING:
        return localized(reelUploading);
      case SubmitStatus.DONE:
        return localized(reelCreateDone);
      default:
        return '';
    }
  }
}
