import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TempChatCountdownBar extends StatelessWidget {
  const TempChatCountdownBar({
    super.key,
    required this.chatController,
  });

  final BaseChatController chatController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!chatController.isGroupExpireSoon.value) {
        return const SizedBox(); // Return an empty widget if not visible
      }
      return GestureDetector(
        onTap: () {
          if (chatController.showEditExpireShortcutArrow.value) {
            chatController.onTapExpiringBar();
          }
        },
        child: Container(
          height: 40,
          color: colorBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(flex: 1, child: SizedBox()),
              Expanded(
                flex: 8,
                child: Obx(() {
                  return Text(
                    localized(
                        temporaryGroupChatCountdown, params: [chatController
                        .remainingTime.value
                    ]),
                    style: jxTextStyle.textStyle16(color: colorRed),
                    textAlign: TextAlign.center,
                  );
                }),
              ),
              Flexible(
                flex: 1,
                child: Obx(() => chatController.showEditExpireShortcutArrow.value
                    ? SvgPicture.asset(
                        'assets/svgs/right_arrow_thick.svg',
                        color: colorTextSupporting,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                            colorTextPrimary.withOpacity(0.2),
                            BlendMode.srcIn),
                      )
                    : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}