import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomConfirmationPopup extends StatelessWidget {
  const CustomConfirmationPopup({
    Key? key,
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
  }) : super(key: key);

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
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(
                      top: 16, left: 16, right: 16, bottom: 16),
                  decoration: const BoxDecoration(
                    border: const Border(
                      bottom:
                          BorderSide(color: JXColors.outlineColor, width: 1),
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
                          style: jxTextStyle.textStyle14(),
                          textAlign: TextAlign.center,
                          // textAlign: TextAlign.center,
                        ),
                      if (notBlank(subTitle))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            subTitle,
                            style: jxTextStyle.textStyle12(
                                color: JXColors.secondaryTextBlack),
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
                        style: jxTextStyle.textStyle16(
                            color: confirmButtonColor ?? accentColor),
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
                    style: jxTextStyle.textStyle16(
                        color: cancelButtonColor ?? errorColor),
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
