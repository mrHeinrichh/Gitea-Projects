
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_ui_component.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class ChatUIGroup extends ChatUIComponent {
  ChatUIGroup({
    super.key,
    required super.chat,
    required super.index,
    required super.animation,
    required super.tag,
  });

  @override
  Widget buildHeadView(BuildContext context) {
    final enableAudio = chat.enableAudioChat.value;

    return Padding(
      padding: const EdgeInsets.only(
        left: 2, //the another 8 is on parent.
        right: 10,
      ),
      child: Stack(
        children: <Widget>[
          CustomAvatar(
            key: ValueKey('chat_single_group_${chat.id}'),
            uid: chat.id,
            size: jxDimension.chatListAvatarSize(),
            headMin: Config().headMin,
            isGroup: chat.isGroup,
            fontSize: 24.0,
            shouldAnimate: false,
          ),
          if (chat.autoDeleteEnabled && !enableAudio)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                height: 24,
                width: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/icon_autodelete.png',
                      fit: BoxFit.contain,
                    ),
                    Text(
                      parseAutoDeleteInterval(chat.autoDeleteInterval),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24 * 0.4,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (enableAudio)
            Positioned(
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/svgs/agora_mark_icon.svg',
                width: 20,
                height: 20,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Obx(
      () => Row(
        children: <Widget>[
          Flexible(
            child: NicknameText(
              uid: chat.id,
              displayName: chat.name,
              isGroup: chat.isGroup,
              fontSize: MFontSize.size16.value,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.primaryTextBlack.withOpacity(1),
              isTappable: false,
              overflow: TextOverflow.ellipsis,
              fontSpace: 0,
            ),
          ),
          if (controller.isMuted.value)
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: SvgPicture.asset(
                'assets/svgs/mute_icon3.svg',
                width: 16,
                height: 16,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildUnreadView(BuildContext context) {
    return Obx(() {
      if (chat.isDisband ||
          controller.unreadCount.value <= 0 && !controller.isNewChat.value) {
        if (chat.sort != 0) {
          return Container(
            margin: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(minWidth: 20, maxHeight: 24),
            child: SvgPicture.asset(
              'assets/svgs/chat_cell_pin_icon.svg',
              width: 20,
              height: 20,
              color: JXColors.iconPrimaryColor,
              fit: BoxFit.fill,
            ),
          );
        }

        return const SizedBox();
      }

      return Row(
        children: <Widget>[
          if (controller.isNewChat.value)
            Text(
              localized(homeNew),
              style:
                  jxTextStyle.textStyleBold14(color: const Color(0xFFEB6A61)),
              textAlign: TextAlign.center,
            ),
          if (objectMgr.chatMgr.mentionMessageMap[chat.chat_id] != null &&
              objectMgr.chatMgr.mentionMessageMap[chat.chat_id]!.length > 0)
            Container(
              margin:
                  EdgeInsets.only(left: objectMgr.loginMgr.isDesktop ? 10 : 8),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: accentColor,
                shape: const CircleBorder(),
              ),
              child: Text(
                "@",
                style: jxTextStyle.textStyle14(
                  color: JXColors.primaryTextWhite,
                ),
              ),
            ),
          if (controller.unreadCount.value > 0)
            Container(
              height: 20,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: controller.isMuted.value
                    ? JXColors.supportingTextBlack
                    : accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: controller.unreadCount.value < 999
                    ? AnimatedFlipCounter(
                        value: controller.unreadCount.value,
                        textStyle: jxTextStyle.textStyle13(
                          color: JXColors.primaryTextWhite,
                        ),
                      )
                    : Text(
                        '999+',
                        style: jxTextStyle.textStyle14(
                          color: JXColors.primaryTextWhite,
                        ),
                      ),
              ),
            )
        ],
      );
    });
  }
}
