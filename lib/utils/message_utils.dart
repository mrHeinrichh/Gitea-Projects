import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/message.dart';
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

Future<(String, String, String?, int, int)> getVideoParams(
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

      if (File(messageVideo.filePath).existsSync()) {
        filePath = messageVideo.filePath;
      }


      return (
        filePath,
        messageVideo.cover,
        messageVideo.gausPath,
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

        if (File(asset.filePath).existsSync()) {
          filePath = asset.filePath;
        }

        return (
          filePath,
          asset.cover,
          asset.gausPath,
          asset.aswidth ?? 0,
          asset.asheight ?? 0
        );
      }
      return ("", "", null, 0, 0);
  }
}
