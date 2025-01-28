import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

enum CustomAlertButtonType {
  single, // only confirm
  confirm, // with option close or yes

  //we can add more buttons like persistent
  // persistent,
}

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.cancelColor,
    this.confirmCallback,
    this.buttonType = CustomAlertButtonType.confirm,
  });

  final String title;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final Color? cancelColor;
  final CustomAlertButtonType buttonType;
  final Function()? confirmCallback;

  Widget widgetButtonType(CustomAlertButtonType type) {
    switch (type) {
      case CustomAlertButtonType.single:
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => Get.back(),
            child: ForegroundOverlayEffect(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11.0),
                alignment: Alignment.center,
                child: Text(
                  localized(popupConfirm),
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        );
      default:
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Get.back(),
                child: ForegroundOverlayEffect(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11.0),
                    alignment: Alignment.center,
                    child: Text(
                      cancelText ?? localized(buttonCancel),
                      style: jxTextStyle.textStyle17(
                        color: cancelColor ?? themeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorBackground6,
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Get.back();
                  confirmCallback?.call();
                },
                child: ForegroundOverlayEffect(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11.0),
                    alignment: Alignment.center,
                    child: Text(
                      confirmText ?? localized(buttonConfirm),
                      style: jxTextStyle.textStyleBold17(
                        color: confirmColor ?? colorRed,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.transparent,
      elevation: 1,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: jxTextStyle.textStyleBold17(),
                  textAlign: TextAlign.center,
                ),
                Visibility(
                  visible: content != null,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: content ?? const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),
          IntrinsicHeight(child: widgetButtonType(buttonType)),
        ],
      ),
    );
  }
}
