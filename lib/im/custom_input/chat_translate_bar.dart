import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:lottie/lottie.dart';

class ChatTranslateBar extends StatelessWidget {
  final bool isTranslating;
  final String translatedText;
  final Chat chat;
  final String translateLocale;
  final bool needTopBorder;
  final bool isDetailView;

  const ChatTranslateBar({
    super.key,
    required this.isTranslating,
    required this.translatedText,
    required this.chat,
    required this.translateLocale,
    this.needTopBorder = false,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDetailView ? Colors.transparent : colorBackground,
        border: Border(
          top: needTopBorder
              ? const BorderSide(
                  color: colorBorder,
                  width: 1.0,
                )
              : BorderSide.none,
          bottom: const BorderSide(
            color: colorBorder,
            width: 1.0,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 40,
            maxHeight: 82,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 24,
                child: Lottie.asset(
                  'assets/lottie/loading.json',
                  width: 24,
                  animate: isTranslating,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    translatedText,
                    style: TextStyle(
                      fontSize: MFontSize.size17.value,
                      color: isDetailView ? Colors.white : colorTextPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: OpacityEffect(
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(
                        RouteName.translateToView,
                        arguments: [
                          chat,
                          false,
                        ],
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svgs/translate.svg',
                          width: 16,
                          height: 16,
                          color: isDetailView ? Colors.white : colorTextSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          translateLocale,
                          style: TextStyle(
                            fontSize: MFontSize.size14.value,
                            color: isDetailView
                                ? Colors.white
                                : colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
