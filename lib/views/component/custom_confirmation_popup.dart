import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomConfirmationPopup extends StatelessWidget {
  const CustomConfirmationPopup({
    super.key,
    this.title = "",
    this.subTitle = "",
    required this.confirmButtonText,
    required this.cancelButtonText,
    this.confirmButtonColor,
    this.cancelButtonColor,
    required this.confirmCallback,
    required this.cancelCallback,
    this.img,
    this.withHeader = true,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.cancelButtonTextStyle,
    this.confirmButtonTextStyle,
  });

  final String title;
  final String subTitle;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final Function() confirmCallback;
  final Function() cancelCallback;
  final Widget? img;
  final bool withHeader;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? cancelButtonTextStyle;
  final TextStyle? confirmButtonTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom > 0
            ? MediaQuery.of(context).viewPadding.bottom
            : 12,
        left: 10,
        right: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              children: [
                if (withHeader)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorTextPlaceholder,
                          width: 0.33,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (img != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: img!,
                          ),
                        if (notBlank(title))
                          Text(
                            title,
                            style: titleTextStyle ?? jxTextStyle.textStyle14(),
                            textAlign: TextAlign.center,
                            // textAlign: TextAlign.center,
                          ),
                        if (notBlank(subTitle))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              subTitle,
                              style: subtitleTextStyle ??
                                  jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Get.back();
                    confirmCallback();
                  },
                  child: OverlayEffect(
                    radius: const BorderRadius.vertical(
                      top: Radius.circular(0),
                      bottom: Radius.circular(16),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        textAlign: TextAlign.center,
                        confirmButtonText,
                        style: confirmButtonTextStyle ??
                            jxTextStyle.textStyle20(
                              color: confirmButtonColor ?? themeColor,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          GestureDetector(
            onTap: () => cancelCallback(),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                color: Colors.white,
              ),
              child: OverlayEffect(
                radius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    cancelButtonText,
                    style: cancelButtonTextStyle ??
                        jxTextStyle.textStyle20(
                          color: cancelButtonColor ?? colorRed,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
