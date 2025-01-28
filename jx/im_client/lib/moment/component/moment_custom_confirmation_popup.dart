import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class MomentCustomConfirmationPopup extends StatelessWidget {
  const MomentCustomConfirmationPopup({
    super.key,
    this.title = "",
    this.subTitle = "",
    required this.firstButtonText,
    required this.cancelButtonText,
    required this.secondButtonText,
    this.firstButtonColor,
    this.cancelButtonColor,
    required this.firstCallback,
    required this.cancelCallback,
    required this.secondButtonCallback,
    this.img,
    this.withHeader = true,
    this.isShowingFirstButton = true,
    this.isShowingSecondButton = true,
  });

  final String title;
  final String subTitle;
  final String firstButtonText;
  final String cancelButtonText;
  final Color? firstButtonColor;
  final Color? cancelButtonColor;
  final Function() firstCallback;
  final Function() cancelCallback;
  final Widget? img;
  final bool withHeader;
  final bool isShowingFirstButton;
  final bool isShowingSecondButton;

  final String secondButtonText;
  final Function() secondButtonCallback;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 8,
          // bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? MediaQuery.of(context).viewPadding.bottom : 12,
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
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
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
                            style: jxTextStyle.textStyle20(),
                            textAlign: TextAlign.center,
                            // textAlign: TextAlign.center,
                          ),
                        if (notBlank(subTitle))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              subTitle,
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (isShowingSecondButton)
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            Get.back();
                            secondButtonCallback();
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: colorBackground6, width: 1),
                              ),
                            ),
                            child: OverlayEffect(
                              radius: const BorderRadius.vertical(
                                top: Radius.circular(0),
                                bottom: Radius.circular(16),
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  textAlign: TextAlign.center,
                                  secondButtonText,
                                  style: jxTextStyle.textStyle20(
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (isShowingFirstButton)
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            Get.back();
                            firstCallback();
                          },
                          child: OverlayEffect(
                            radius: const BorderRadius.vertical(
                              top: Radius.circular(0),
                              bottom: Radius.circular(16),
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Text(
                                textAlign: TextAlign.center,
                                firstButtonText,
                                style: jxTextStyle.textStyle20(
                                  color: firstButtonColor ?? themeColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 8,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      cancelButtonText,
                      style: jxTextStyle.textStyle20(
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
      ),
    );
  }
}
