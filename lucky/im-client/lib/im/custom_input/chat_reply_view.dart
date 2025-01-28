import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class ChatReplyView extends StatelessWidget {
  final Chat chat;

  const ChatReplyView({
    Key? key,
    required this.chat,
    required this.controller,
  }) : super(key: key);

  final CustomInputController controller;

  void _onClear() {
    objectMgr.chatMgr.replyMessageMap.remove(chat.id);

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
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: surfaceBrightColor,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/svgs/reply_icon.svg',
            width: 20,
            height: 20,
            color: JXColors.primaryTextBlack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: accentColor,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (isMediaType) _buildMsgThumbnail(context),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (notBlank(
                            objectMgr.chatMgr.replyMessageMap[chat.id]))
                          NicknameText(
                            uid: objectMgr
                                .chatMgr.replyMessageMap[chat.id]!.userId,
                            fontSize: 14,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        buildContent(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _onClear,
            child: const Icon(
              Icons.close,
              color: JXColors.primaryTextBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMsgThumbnail(BuildContext context) {
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
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: child,
    );
  }

  Widget buildContent(BuildContext context) {
    return Text(
      replyMessageContent(),
      style: const TextStyle(
        fontSize: 14,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 2,
    );
  }

  String replyMessageContent() {
    switch (getMessage.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return getMessage.text;
      case messageTypeImage:
        return getMessage.text.isNotEmpty
            ? '${localized(replyPhoto)} ${getMessage.text}'
            : localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return getMessage.text.isNotEmpty
            ? '${localized(replyVideo)} ${getMessage.text}'
            : localized(replyVideo);
      case messageTypeNewAlbum:
        return getMessage.text.isNotEmpty
            ? '${localized(chatTagAlbum)} ${getMessage.text}'
            : localized(chatTagAlbum);
      case messageTypeFile:
        return localized(chatTagFile);
      case messageTypeVoice:
        return localized(replyVoice);
      case messageTypeLiveVideo:
        return localized(chatTagLiveVideo);
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);

      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeLocation:
        return localized(chatTagLocation);
      default:
        return '';
    }
  }
}
