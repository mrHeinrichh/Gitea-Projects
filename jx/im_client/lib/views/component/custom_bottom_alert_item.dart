import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomBottomAlertItem extends StatelessWidget {
  final String text;
  final Color? textColor;

  /// Can close the dialog using [Get.back]
  final bool canPop;
  final Function()? onClick;

  const CustomBottomAlertItem({
    super.key,
    required this.text,
    this.textColor,
    this.canPop = true,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        (canPop && !objectMgr.loginMgr.isDesktop)
            ? Get.back()
            : Navigator.pop(context);
        if (onClick != null) onClick!();
      },
      behavior: HitTestBehavior.translucent,
      child: OverlayEffect(
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            text,
            style: jxTextStyle.textStyle20(color: textColor ?? themeColor),
          ),
        ),
      ),
    );
  }
}
