import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/hover_click_builder.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class DesktopQrAlertDialog extends GetView<QRCodeViewController> {
  final Offset offset;

  const DesktopQrAlertDialog({
    super.key,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> alertList = [
      alertItem(
          duration: '60 ${localized(seconds)}',
          onClick: () {
            Get.back();
            controller.setDuration(QRCodeDurationType.oneMin.value);
          }),
      alertItem(
        duration: '5 ${localized(minutes)}',
        onClick: () {
          Get.back();
          controller.setDuration(QRCodeDurationType.fiveMin.value);
        },
      ),
      alertItem(
        duration: '60 ${localized(minutes)}',
        onClick: () {
          Get.back();
          controller.setDuration(QRCodeDurationType.sixtyMin.value);
        },
      ),
      alertItem(
        duration: localized(forever),
        onClick: () {
          Get.back();
          controller.setDuration(QRCodeDurationType.forever.value);
        },
      ),
    ];

    return Stack(
      children: [
        AnimatedPositioned(
          key: GlobalKey(),
          left: offset.dx,
          top: offset.dy,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: Container(
            clipBehavior: Clip.hardEdge,
            constraints: const BoxConstraints(minWidth: 100, maxWidth: 120),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: colorWhite.withOpacity(0.80),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  blurRadius: 30,
                  color: colorTextPrimary.withOpacity(0.20),
                )
              ],
            ),
            child: Material(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 50.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: alertList,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget alertItem({
    required String duration,
    required void Function()? onClick,
  }) {
    return HoverClickBuilder(
      builder: (bool isHovered, bool isPressed) {
        return Transform.scale(
            scale: isPressed ? 0.95 : 1,
            child: Container(
                decoration: BoxDecoration(
                  color: isHovered || isPressed ? colorBackground6 : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: GestureDetector(
                    onTap: onClick,
                    child: Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorTextPrimary,
                      ),
                    ),
                  ),
                )));
      },
    );
  }
}
