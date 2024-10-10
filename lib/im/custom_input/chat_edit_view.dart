import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

class ChatEditView extends StatelessWidget {
  final Chat chat;
  final CustomInputController controller;

  const ChatEditView({
    super.key,
    required this.chat,
    required this.controller,
  });

  void _onClear() {
    objectMgr.chatMgr.replyMessageMap.remove(chat.id);
    objectMgr.chatMgr.editMessageMap.remove(chat.id);
    objectMgr.chatMgr.selectedMessageMap[chat.id]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chat.id);

    if (controller.inputController.text.trim().isEmpty) {
      controller.sendState.value = false;
    }

    controller.clearText();
    controller.update();
  }

  Message get getMessage => objectMgr.chatMgr.editMessageMap[chat.id]!;

  bool get isMediaType => getMessage.isMediaType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SvgPicture.asset(
              'assets/svgs/menu_edit_chat.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 35,
                  width: 2,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8),
                if (isMediaType) buildMsgThumbnail(context),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildTitle(),
                      buildContent(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: _onClear,
              child: const Icon(
                Icons.close,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMsgThumbnail(BuildContext context) {
    Message msg = getMessage;
    Widget child = const SizedBox();
    switch (msg.typ) {
      case messageTypeImage:
        final msgContent = jsonDecode(msg.content);
        if (notBlank(msgContent['filePath']) &&
            File(msgContent['filePath']).existsSync()) {
          child = Image.file(
            File(msgContent['filePath']),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        } else {
          child = RemoteImage(
            src: msgContent['url'].isNotEmpty
                ? msgContent['url']
                : msgContent['filePath'],
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          );
        }
        break;
      case messageTypeVideo:
      case messageTypeReel:
        final msgContent = jsonDecode(msg.content);
        if (notBlank(msgContent['coverPath']) &&
            File(msgContent['coverPath']).existsSync()) {
          child = Image.file(
            File(msgContent['coverPath']),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        } else {
          child = RemoteImage(
            src: msgContent['url'].isNotEmpty
                ? msgContent['url']
                : msgContent['coverPath'],
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            mini: Config().messageMin,
          );
        }
        break;
      case messageTypeNewAlbum:
        final NewMessageMedia msgContent =
            msg.decodeContent(cl: NewMessageMedia.creator);
        final bool isVideo =
            msgContent.albumList?.first.mimeType?.contains('video') ?? false;
        String coverPath = '';

        if (isVideo) {
          if (notBlank(msgContent.albumList?.first.coverPath) &&
              File(msgContent.albumList!.first.coverPath).existsSync()) {
            coverPath = msgContent.albumList!.first.coverPath;
          }
        } else {
          if (notBlank(msgContent.albumList?.first.filePath) &&
              File(msgContent.albumList!.first.filePath).existsSync()) {
            coverPath = msgContent.albumList!.first.filePath;
          }
        }

        if (coverPath.isNotEmpty) {
          child = Image.file(
            File(coverPath),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        } else {
          child = RemoteImage(
            src: notBlank(msgContent.albumList?.first.url)
                ? msgContent.albumList!.first.url
                : msgContent.albumList?.first.filePath ?? '',
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

  Widget buildTitle() {
    return Text(
      getTitle(),
      style: jxTextStyle.textStyle15(
        color: themeColor,
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Text(
      replyMessageContent(),
      style: jxTextStyle.textStyle15(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String replyMessageContent() {
    final msgContent = jsonDecode(getMessage.content);
    String text = notBlank(msgContent['caption'])
        ? msgContent['caption']
        : msgContent['text'] ?? '';

    text = ChatHelp.formalizeMentionContent(
      text,
      getMessage,
    );

    switch (getMessage.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return text;
      case messageTypeImage:
        return text.isNotEmpty
            ? '${localized(replyPhoto)} $text'
            : localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return text.isNotEmpty
            ? '${localized(replyVideo)} $text'
            : localized(replyVideo);
      case messageTypeNewAlbum:
        return text.isNotEmpty
            ? '${localized(chatTagAlbum)} $text'
            : localized(chatTagAlbum);
      case messageTypeFile:
        return localized(chatTagFile);
      case messageTypeVoice:
        return localized(replyVoice);
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

  String getTitle() {
    String text = "";
    switch (getMessage.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        text = localized(editMessageChat);
        break;
      case messageTypeImage:
        text = localized(editPhotoText);
        break;
      case messageTypeFile:
        text = localized(editFile);
        break;
      case messageTypeVideo:
        text = localized(editVideo);
        break;
      case messageTypeNewAlbum:
        text = localized(editAlbum);
        break;
      default:
        break;
    }
    return text;
  }
}
