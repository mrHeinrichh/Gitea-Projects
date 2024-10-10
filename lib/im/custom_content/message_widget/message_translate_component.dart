// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class MessageTranslateComponent extends StatelessWidget
    with MessageWidgetMixin {
  final Chat chat;
  @override
  final Message message;
  final String translatedText;
  final String locale;
  final ChatContentController controller;
  final bool showDivider;
  final BoxConstraints? constraints;
  final bool showPinned;
  final bool isSender;

  MessageTranslateComponent({
    super.key,
    required this.chat,
    required this.message,
    required this.translatedText,
    required this.locale,
    required this.controller,
    required this.showDivider,
    this.showPinned = false,
    this.isSender = false,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    var messageContent = jsonDecode(message.content);
    if (notBlank(messageContent['text']) &&
        EmojiParser.hasOnlyEmojis(messageContent['text'])) {
      return const SizedBox.shrink();
    }
    return Container(
      constraints: constraints,
      padding: EdgeInsets.only(right: getRight()),
      decoration: BoxDecoration(
        border: Border(
          top:showDivider? const BorderSide(
            color: colorTextPlaceholder,
            width: 0.33,
          ):BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (showDivider)
          //   Padding(
          //     padding: EdgeInsets.only(top: 3.w, bottom: 3.w),
          //     child: const CustomDivider(),
          //   ),
          OpacityEffect(
            child: GestureDetector(
                onTap: () {
                  controller.chatController
                      .convertTextToVoice(message, isTranslation: true);
                },
                child: _buildTranslationComponent(context)),
          ),
          OpacityEffect(
            child: GestureDetector(
              onTap: () async {
                if (!controller.chatController.popupEnabled) {
                  Get.toNamed(
                    RouteName.translateToView,
                    arguments: [
                      chat,
                      message,
                    ],
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/translate.svg',
                    width: 14,
                    height: 14,
                    color: objectMgr.userMgr.isMe(message.send_id)
                        ? bubblePrimary
                        : themeColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    locale,
                    style: TextStyle(
                      fontSize: MFontSize.size12.value,
                      color: objectMgr.userMgr.isMe(message.send_id)
                          ? bubblePrimary
                          : themeColor,
                    ),
                  ),
                  const SizedBox(width: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationComponent(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          ...BuildTextUtil.buildSpanList(
            message,
            translatedText,
            isEmojiOnly: EmojiParser.hasOnlyEmojis(translatedText),
            launchLink:
                controller.chatController.popupEnabled ? null : onLinkOpen,
            onMentionTap:
                controller.chatController.popupEnabled ? null : onMentionTap,
            openLinkPopup: (value) => controller.chatController.popupEnabled
                ? null
                : onLinkLongPress(value, context),
            openPhonePopup: (value) => controller.chatController.popupEnabled
                ? null
                : onPhoneLongPress(value, context),
            textColor: colorTextPrimary,
            isSender: objectMgr.userMgr.isMe(message.send_id),
          ),
        ],
      ),
    );
  }

  double getRight() {
    if (!isSender) {
      if (objectMgr.loginMgr.isDesktop) {
        return 0;
      } else {
        if (showPinned && isEditMessage(message)) {
          return GroupTextPlaceHolderType.isMeEditAndPin.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        } else if (isEditMessage(message)) {
          return GroupTextPlaceHolderType.isMeOnlyEdit.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        } else if (showPinned) {
          return GroupTextPlaceHolderType.isMeOnlyPin.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        }
        // return GroupTextPlaceHolderType.isMeNone.multilingualWidth;
        return 0;
      }
    } else {
      if (objectMgr.loginMgr.isDesktop) {
        return 0;
      } else {
        if (showPinned && isEditMessage(message)) {
          return GroupTextPlaceHolderType.isSendEditAndPin.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        } else if (isEditMessage(message)) {
          return GroupTextPlaceHolderType.isSendOnlyEdit.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        } else if (showPinned) {
          return GroupTextPlaceHolderType.isSendOnlyPin.multilingualWidth-GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        }
        // return GroupTextPlaceHolderType.isSendNone.multilingualWidth;
        return 0;
      }
    }
  }
}
