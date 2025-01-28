import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
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
  bool showAllItemBorder = false,
  bool showConfirmButton = true,
  bool showCancelButton = true,

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
    color: colorSurface,
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
                style: jxTextStyle.headerText(
                  fontWeight: MFontWeight.bold5.value,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle,
              style: jxTextStyle.headerSmallText(color: colorTextSecondary),
              textAlign: TextAlign.center,
            ),
          if (content != null) content,
        ],
      ),
    );
  }

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: colorOverlay40,
    context: Get.context!,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    builder: (BuildContext context) {
      bool isDesktop = objectMgr.loginMgr.isDesktop;
      return Container(
        padding: isDesktop
            ? const EdgeInsets.only(left: 300.0) // Desktop-specific padding
            : const EdgeInsets.all(0),
        child: WillPopScope(
          onWillPop: () async => isDismissible,
          child: SafeArea(
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
                                border: showAllItemBorder
                                    ? customBorder
                                    : index != (items.length - 1)
                                        ? customBorder
                                        : null,
                              ),
                              child: items[index],
                            ),
                          )
                        else
                          Visibility(
                            visible: showConfirmButton,
                            child: CustomBottomAlertItem(
                              text: confirmText ?? localized(buttonConfirm),
                              textColor: confirmTextColor,
                              canPop: canPopConfirm,
                              onClick: onConfirmListener,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: showCancelButton,
                    child: const SizedBox(height: 8),
                  ),
                  Visibility(
                    visible: showCancelButton,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: boxDecoration,
                      child: CustomBottomAlertItem(
                        text: cancelText ?? localized(buttonCancel),
                        textColor: cancelTextColor,
                        canPop: canPopCancel,
                        onClick: onCancelListener,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
