import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    Key? key,
    required this.title,
    this.content,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.cancelColor,
    this.confirmCallback,
  }) : super(key: key);

  final String title;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final Color? cancelColor;
  final Function()? confirmCallback;

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
          horizontal: MediaQuery.of(context).size.width * 0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            child: Container(
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
          ),
          const CustomDivider(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Navigator.of(context).pop(),
                  child: OverlayEffect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                      child: Text(
                        cancelText ?? localized(buttonCancel),
                        textAlign: TextAlign.center,
                        style: jxTextStyle.textStyle17(
                            color: cancelColor ?? accentColor),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 44,
                width: 0.5, // Width to make a vertical line
                color: JXColors.outlineColor, // Adjust the color as needed
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Get.back();
                    confirmCallback?.call();
                  },
                  child: OverlayEffect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                      child: Text(
                        confirmText ?? localized(buttonConfirm),
                        textAlign: TextAlign.center,
                        style: jxTextStyle.textStyleBold17(
                            color: confirmColor ?? errorColor,
                            fontWeight: MFontWeight.bold6.value),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
