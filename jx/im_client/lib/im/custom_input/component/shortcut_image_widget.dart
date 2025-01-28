import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ShortcutImage extends StatelessWidget {
  final BaseChatController controller;

  const ShortcutImage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Visibility(
        visible: controller.showShortcutImage.value,
        child: Stack(
          children: [
            if (controller.showShortcutImage.value ||
                controller.recentPhoto.value != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                bottom: 4,
                left: 4,
                child: AnimatedOpacity(
                  opacity: controller.showShortcutAnimation.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  onEnd: () {
                    // prevent immediate invisible for animation
                    controller.showShortcutImage.value = false;
                  },
                  child: GestureDetector(
                    onTap: () {
                      if (controller.showShortcutImage.value) {
                        _goToMediaPreview();
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: ForegroundOverlayEffect(
                      overlayColor: colorBackground8,
                      child: CustomPaint(
                        painter: ShortcutImagePainter(),
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          margin: const EdgeInsets.only(bottom: 4),
                          width: 68,
                          child: Column(
                            children: [
                              Text(
                                localized(shortcutImageDescription),
                                style: jxTextStyle.supportSmallText(
                                    color: colorTextLevelTwo),
                              ),
                              const SizedBox(height: 4),
                              if (controller.recentPhoto.value != null)
                                FutureBuilder(
                                  future: controller.recentPhoto.value!.file,
                                  builder: (ctx, snapshot) {
                                    if (snapshot.data != null) {
                                      return ClipRRect(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        child: Image.file(
                                          snapshot.data!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  _goToMediaPreview() {
    AssetPickerConfig pickerConfig = AssetPickerConfig(
      requestType: RequestType.common,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: 1,
      textDelegate: Get.locale!.languageCode.contains('en')
          ? const EnglishAssetPickerTextDelegate()
          : const AssetPickerTextDelegate(),
    );
    DefaultAssetPickerProvider assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig.maxAssets,
      pageSize: pickerConfig.pageSize,
      pathThumbnailSize: pickerConfig.pathThumbnailSize,
      selectedAssets: pickerConfig.selectedAssets,
      requestType: pickerConfig.requestType,
      sortPathDelegate: pickerConfig.sortPathDelegate,
      filterOptions: pickerConfig.filterOptions,
    );
    controller.removeShortcutImage();
    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'chat': controller.chat,
          'isEdit': false,
          'entity': controller.recentPhoto.value,
          'provider': assetPickerProvider,
          'pConfig': pickerConfig,
          'isFromPhoto': false,
          'showCaption': true,
          'showResolution': true,
          'fromShortcut': true,
        })?.then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          assetPickerProvider.selectedAssets.clear();
          return;
        }

        final customInputController = Get.find<CustomInputController>();

        if (customInputController != null) {
          if (result['translation'] != null) {
            customInputController.translatedText.value = result['translation'];
          }

          customInputController.onSend(
            result?['caption'],
            assets: result['assets'],
          );
        }
      }
    });
  }
}

class ShortcutImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    const arrowWidth = 10.0;
    const arrowHeight = 5.0;
    const cornerRadius = 8.0;

    // Arrow offset from the center (move to the left)
    const arrowOffset = 15.0;

    // Start at the top-left corner
    path.moveTo(cornerRadius, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Right edge
    path.lineTo(size.width, size.height - cornerRadius - arrowHeight);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height - arrowHeight),
      radius: const Radius.circular(cornerRadius),
    );

    // Bottom edge (with arrow)
    final arrowStartX = (size.width / 2) - arrowOffset; // Shifted start point
    path.lineTo(arrowStartX + arrowWidth / 2, size.height - arrowHeight);
    path.lineTo(arrowStartX, size.height); // Arrow tip
    path.lineTo(arrowStartX - arrowWidth / 2, size.height - arrowHeight);

    // Continue bottom edge
    path.lineTo(cornerRadius, size.height - arrowHeight);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius - arrowHeight),
      radius: const Radius.circular(cornerRadius),
    );

    // Left edge
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );

    // Close the path
    path.close();

    // Draw the shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
