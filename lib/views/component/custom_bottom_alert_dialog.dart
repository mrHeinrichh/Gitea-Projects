import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

Future<void> showCustomBottomAlertDialog(
  BuildContext context, {
  Widget? imgWidget,
  String? title,
  String? subtitle,
  Widget? content,
  String? confirmText,
  Color confirmTextColor = colorRed,
  Color? cancelTextColor,
  String? cancelText,

  /// It will show the title, subtitle, optional image and content widget
  bool withHeader = true,

  /// List of selection (It will hide the default confirm button)
  List<Widget>? items,

  /// Can close the dialog using [Get.back]
  bool canPopCancel = true,

  /// Can close the dialog using [Get.back]
  bool canPopConfirm = true,
  VoidCallback? onCancelListener,
  VoidCallback? onConfirmListener,
  VoidCallback? thenListener,
  bool isDismissible = true,
}) async {
  final boxDecoration = BoxDecoration(
    color: colorWhite,
    borderRadius: BorderRadius.circular(16),
  );

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: customBorder),
      child: Column(
        children: [
          if (imgWidget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: imgWidget,
            ),
          if (title != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: subtitle != null || content != null ? 12 : 0,
              ),
              child: Text(
                title,
                style: jxTextStyle.textStyleBold17(),
                textAlign: TextAlign.center,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle,
              style: jxTextStyle.textStyle15(color: colorTextSecondary),
              textAlign: TextAlign.center,
            ),
          if (content != null) content,
        ],
      ),
    );
  }

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    builder: (BuildContext context) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: boxDecoration,
                child: Column(
                  children: [
                    if (withHeader) buildHeader(),
                    if (items != null)
                      ...List.generate(
                        items.length,
                        (index) => Container(
                          decoration: BoxDecoration(
                            border: index != (items.length - 1)
                                ? customBorder
                                : null,
                          ),
                          child: items[index],
                        ),
                      )
                    else
                      CustomBottomAlertItem(
                        text: confirmText ?? localized(buttonConfirm),
                        textColor: confirmTextColor,
                        canPop: canPopConfirm,
                        onClick: onConfirmListener,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: boxDecoration,
                child: CustomBottomAlertItem(
                  text: cancelText ?? localized(buttonCancel),
                  textColor: cancelTextColor,
                  canPop: canPopCancel,
                  onClick: onCancelListener,
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((value) {
    if (thenListener != null) {
      thenListener.call();
    }
  });
}
