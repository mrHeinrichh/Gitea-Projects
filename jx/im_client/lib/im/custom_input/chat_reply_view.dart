import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:path/path.dart' as path;

class ChatReplyView extends StatelessWidget {
  final Chat chat;
  final CustomInputController controller;

  const ChatReplyView({
    super.key,
    required this.chat,
    required this.controller,
  });

  void _onClear() {
    if (objectMgr.chatMgr.editMessageMap.isNotEmpty) {
      controller.clearText();
    }
    objectMgr.chatMgr.replyMessageMap.remove(chat.id);
    objectMgr.chatMgr.editMessageMap.remove(chat.id);
    objectMgr.chatMgr.selectedMessageMap[chat.id]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chat.id);

    if (controller.inputController.text.trim().isEmpty) {
      controller.sendState.value = false;
    }

    controller.update();
  }

  ReplyModel get getMessage => objectMgr.chatMgr.replyMessageMap[chat.id]!;

  bool get isMediaType => getMessage.isMediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8.0,
        left: objectMgr.loginMgr.isDesktop ? 14.5 : 12.0,
        right: objectMgr.loginMgr.isDesktop ? 14.5 : 12.0,
      ),
      height: 46,
      width: double.infinity,
      color: colorBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 17.0),
            child: SvgPicture.asset(
              'assets/svgs/reply_icon.svg',
              width: 24,
              height: 24,
              color: themeColor,
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  height: 35,
                  width: 2,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8.0),
                if (isMediaType) buildMsgThumbnail(context),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildTitle(chat),
                      buildContent(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: GestureDetector(
              onTap: _onClear,
              child: const OpacityEffect(
                child: Icon(
                  Icons.close,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMsgThumbnail(BuildContext context) {
    ReplyModel msg = getMessage;
    Widget child = const SizedBox();
    switch (msg.typ) {
      case messageTypeImage:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeNewAlbum:
        if (msg.filePath.isNotEmpty && File(msg.filePath).existsSync()) {
          child = Image.file(
            File(msg.filePath),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        } else {
          child = RemoteImage(
            src: msg.url.isNotEmpty ? msg.url : msg.filePath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          );
        }
        break;
      case messageTypeLink:
        if (msg.url.isNotEmpty) {
          child = RemoteImage(
            src: msg.url,
            width: 36.0,
            height: 36.0,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          );
        }
        break;
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: child,
    );
  }

  Widget buildTitle(Chat chat) {
    return NicknameText(
      uid: objectMgr.chatMgr.replyMessageMap[chat.id]?.userId ?? 0,
      color: themeColor,
      isReply: true,
      groupId: chat.isGroup ? chat.chat_id : null,
      fontSize: MFontSize.size15.value,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildContent(BuildContext context) {
    return Text(
      replyMessageContent(),
      style: jxTextStyle.headerSmallText(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String replyMessageContent() {
    switch (getMessage.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return ChatHelp.formalizeMentionContent(
          getMessage.text,
          Message()..atUser = getMessage.atUser,
          groupId: chat.isGroup ? chat.chat_id : null,
        );
      case messageTypeImage:
        return getMessage.text.isNotEmpty
            ? '${localized(replyPhoto)} ${ChatHelp.formalizeMentionContent(
                getMessage.text,
                Message()..atUser = getMessage.atUser,
                groupId: chat.isGroup ? chat.chat_id : null,
              )}'
            : localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return getMessage.text.isNotEmpty
            ? '${localized(replyVideo)} ${ChatHelp.formalizeMentionContent(
                getMessage.text,
                Message()..atUser = getMessage.atUser,
                groupId: chat.isGroup ? chat.chat_id : null,
              )}'
            : localized(replyVideo);
      case messageTypeNewAlbum:
        return getMessage.text.isNotEmpty
            ? '${localized(chatTagAlbum)} ${ChatHelp.formalizeMentionContent(
                getMessage.text,
                Message()..atUser = getMessage.atUser,
                groupId: chat.isGroup ? chat.chat_id : null,
              )}'
            : localized(chatTagAlbum);
      case messageTypeFile:
        return getMessage.filePath.isNotEmpty
            ? path.basename(getMessage.filePath)
            : localized(chatTagFile);
      case messageTypeVoice:
        return localized(replyVoice);
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);
      case messageTypeTransferMoneySuccess:
        return localized(chatTagTransferMoney);
      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeNote:
        return localized(noteEditTitle);
      case messageTypeChatHistory:
        return localized(chatHistory);
      default:
        return '';
    }
  }
}
