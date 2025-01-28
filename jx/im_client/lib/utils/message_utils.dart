import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final searchableMessageType = [
  messageTypeText,
  messageTypeReply,
  messageTypeImage,
  messageTypeFile,
  messageTypeLink,
];

String getMessageText(Message message) {
  switch (message.typ) {
    case messageTypeImage:
      return message.decodeContent(cl: MessageImage.creator).caption;
    case messageTypeFile:
      return message.decodeContent(cl: MessageFile.creator).caption;
    default:
      return message.decodeContent(cl: MessageText.creator).text;
  }
}

String getEncryptionText(Message message, Chat chat) {
  EncryptionMessageType type =
      objectMgr.encryptionMgr.getMessageType(message, chat);
  switch (type) {
    case EncryptionMessageType.requireInputPassword:
      return localized(encryptedRequireInputPasswordMessage);
    case EncryptionMessageType.awaitingFriend:
      return localized(encryptedAwaitingFriendMessage);
    case EncryptionMessageType.defaultFailure:
    default:
      return localized(encryptedDefaultFailureMessage);
  }
}

String getMediaMessagePath(Message message) {
  switch (message.typ) {
    case messageTypeImage:
      return message.decodeContent(cl: MessageImage.creator).url;
    case messageTypeVideo:
    case messageTypeReel:
      return message.decodeContent(cl: MessageVideo.creator).url;
    case messageTypeVoice:
      return message.decodeContent(cl: MessageVoice.creator).url;
    case messageTypeFile:
      return message.decodeContent(cl: MessageFile.creator).url;
    default:
      throw const FormatException('Invalid File Type');
  }
}

bool checkForVideo(Message message, dynamic asset) {
  //从message及assetList里边的asset查验选中的消息是否为视频
  switch (message.typ) {
    case messageTypeVideo:
    case messageTypeReel:
      return true;
    case messageTypeMarkdown:
      MessageMarkdown messageMarkdown =
          message.decodeContent(cl: MessageMarkdown.creator);
      return messageMarkdown.video.isNotEmpty;
    default:
      return asset is AlbumDetailBean ? asset.isVideo : false;
  }
}

String getVideoUrl(Message message, dynamic asset) {
  switch (message.typ) {
    case messageTypeVideo:
    case messageTypeReel:
      MessageVideo messageVideo =
          message.decodeContent(cl: MessageVideo.creator);
      return messageVideo.url;
    default:
      if (asset is AlbumDetailBean && asset.isVideo) {
        return asset.url;
      }
      return "";
  }
}

Future<(String, String, String?, String?, int, int)> getVideoParams(
    Message message, dynamic asset) async {
  switch (message.typ) {
    case messageTypeVideo:
    case messageTypeReel:
      MessageVideo messageVideo =
          message.decodeContent(cl: MessageVideo.creator);

      String filePath = messageVideo.url;

      if (message.asset != null) {
        if (message.asset is AssetEntity) {
          final file = await message.asset.originFile;
          if (file != null) {
            filePath = file.path;
          }
        } else if (message.asset is File) {
          filePath = message.asset.path;
        }
      }

      String? sourceExtension;
      if (File(messageVideo.filePath).existsSync()) {
        filePath = messageVideo.filePath;
      } else {
        sourceExtension = path.extension(messageVideo.filePath);
      }

      return (
        filePath,
        messageVideo.cover,
        messageVideo.gausPath,
        sourceExtension,
        messageVideo.width,
        messageVideo.height
      );
    case messageTypeMarkdown:
      MessageMarkdown messageMarkdown =
          message.decodeContent(cl: MessageMarkdown.creator);
      return (
        messageMarkdown.video,
        messageMarkdown.image,
        null,
        null,
        MediaQuery.of(Get.context!).size.width.toInt(),
        MediaQuery.of(Get.context!).size.height.toInt(),
      );
    default:
      if (asset is AlbumDetailBean && asset.isVideo) {
        String filePath = asset.url;

        if (message.asset != null) {
          if (message.asset is AssetEntity) {
            final file = await message.asset.originFile;
            if (file != null) {
              filePath = file.path;
            }
          } else if (message.asset is File) {
            filePath = message.asset.path;
          }
        }

        String? sourceExtension;
        if (File(asset.filePath).existsSync()) {
          filePath = asset.filePath;
        } else {
          sourceExtension = path.extension(asset.filePath);
        }

        return (
          filePath,
          asset.cover,
          asset.gausPath,
          sourceExtension,
          asset.aswidth ?? 0,
          asset.asheight ?? 0
        );
      }
      return ("", "", null, null, 0, 0);
  }
}
