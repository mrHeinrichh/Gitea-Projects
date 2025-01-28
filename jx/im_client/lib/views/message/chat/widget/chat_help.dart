import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path/path.dart' as path;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ChatHelp {
  static ImageConfiguration? imgConfig;

  static int imageNumLimit = 10;

  static List<List<T>> splitList<T>(List<T> inputList, int imageNumLimit) {
    List<List<T>> resultList = [];
    int size = (inputList.length / imageNumLimit).ceil();
    for (int i = 0; i < size; i++) {
      int len = (i + 1) * imageNumLimit;
      resultList.add(
        inputList.sublist(
          i * imageNumLimit,
          len > inputList.length ? inputList.length : len,
        ),
      );
    }
    return resultList;
  }

  static Future<void> onSplitImageOrVideo<T>({
    required List<T> assets,
    required String? caption,
    required Chat chat,
    String? reply,
    String? translation,
    String atUser = '',
  }) async {
    await objectMgr.chatMgr.sendNewAlbum(
      chatID: chat.id,
      assets: assets,
      caption: caption,
      reply: reply,
      translation: translation,
      atUser: atUser,
    );
  }

  static void sendImageAsset(
    AssetEntity data,
    Chat chat, {
    String? caption,
    MediaResolution resolution = MediaResolution.image_standard,
    String? reply,
    String atUser = '',
    String? translation,
  }) async {
    objectMgr.chatMgr.sendImage(
      chatID: chat.chat_id,
      width: data.orientatedWidth,
      height: data.orientatedHeight,
      caption: caption,
      resolution: resolution,
      reply: reply,
      data: data,
      atUser: atUser,
      translation: translation ?? '',
    );
  }

  static void sendImageFile(
    File data,
    Chat chat, {
    int width = 0,
    int height = 0,
    MediaResolution resolution = MediaResolution.image_standard,
    String? caption,
    String? reply,
    String atUser = '',
    String? translation,
  }) async {
    objectMgr.chatMgr.sendImage(
      chatID: chat.chat_id,
      width: width,
      height: height,
      reply: reply,
      caption: caption,
      resolution: resolution,
      data: data,
      atUser: atUser,
      translation: translation ?? '',
    );
  }

  static Future<ResponseData?> sendVideoAsset(
    AssetEntity data,
    Chat chat,
    String? caption, {
    MediaResolution resolution = MediaResolution.video_standard,
    String? reply,
    String atUser = '',
    String? translation,
  }) async {
    if (data.duration > 60 * 60) {
      Toast.showToast(localized(toastVideoLength));
      return null;
    }

    final File? file = await data.originFile;

    return await objectMgr.chatMgr.sendVideo(
      chat.chat_id,
      data.title ?? '',
      file!.lengthSync(),
      data.orientatedWidth,
      data.orientatedHeight,
      data.duration,
      data: data,
      caption: caption,
      resolution: resolution,
      reply: reply,
      atUser: atUser,
      translation: translation ?? '',
    );
  }

  static void sendReactEmoji({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int recipientId,
    required int userId,
    required String emoji,
  }) async {
    await objectMgr.chatMgr.sendReactEmoji(
      chatID: chatID,
      messageId: messageId,
      chatIdx: chatIdx,
      recipientId: recipientId,
      userId: userId,
      emoji: emoji,
    );
  }

  static void sendRemoveReactEmoji({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int recipientId,
    required int userId,
    required String emoji,
  }) async {
    await objectMgr.chatMgr.sendRemoveReactEmoji(
      chatID: chatID,
      messageId: messageId,
      chatIdx: chatIdx,
      recipientId: recipientId,
      userId: userId,
      emoji: emoji,
    );
  }

  static void sendFileOperate({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int userId,
    required List<int>? receivers,
  }) async {
    await objectMgr.chatMgr.sendFileOperate(
      chatID: chatID,
      messageId: messageId,
      chatIdx: chatIdx,
      userId: userId,
      receivers: receivers,
    );
  }

  static Future<bool> sendAutoDeleteMessage({
    required int chatId,
    required int interval,
  }) async {
    try {
      final res =
          await objectMgr.chatMgr.sendAutoDeleteInterval(chatId, interval);
      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_PERMISSION_DENY) {
        Toast.showToast(localized(insufficientPermissions));
      } else {
        Toast.showToast(e.getMessage());
      }
      return false;
    }
  }

  static String lastMsg(
    Chat chat,
    Message message,
  ) {
    return typShowMessage(chat, message);
  }

  static String typShowMessage(
    Chat chat,
    Message message,
  ) {
    final int typ = message.typ;
    switch (typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeReplyWithdraw:
      case messageTypeLink:
        final textData =
            message.decodeContent(cl: message.getMessageModel(message.typ));

        String? translatedContent = message.getTranslationFromMessage();

        return formalizeMentionContent(
          translatedContent ?? textData.text,
          message,
        );
      case messageTypeImage:
        final map = jsonDecode(message.content) as Map<String, dynamic>;
        return [map['url'], localized(chatTagPhoto)].join(':|');
      case messageTypeSysmsg:
      case messageTypeCreateGroup:
      case messageTypeBeingFriend:
        return systemMessageText(
          chat,
          message.decodeContent(cl: MessageSystem.creator),
        );
      case messageTypeVideo:
      case messageTypeReel:
        final map = jsonDecode(message.content) as Map<String, dynamic>;
        return [map['url'], localized(chatTagVideoCall)].join(':|');
      case messageTypeVoice:
        return localized(chatTagVoiceCall);

      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);

      case messageTypeFile:
        return localized(chatTagFile);

      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeExitGroup:
        var textData = message.decodeContent(cl: MessageText.creator);
        return textData.text;
      case messageTypeBlack:
        return localized(chatTagRiskReminder);
      case messageTypeSecretaryRecommend:
        MessageSecretaryRecommend recommendData =
            message.decodeContent(cl: MessageSecretaryRecommend.creator);
        return recommendData.text.join('');
      case messageTypeCustom:
        return localized(chatTagVoice);
      case messageDiscussCall:
      case messageCloseDiscussCall:
        return localized(chatTagVoice);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);
      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeGetRed:
        return localized(haveReceivedARedPacket);
      case messageTypeDeleted:
        return localized(chatTagDelete);
      case messageTypeNewAlbum:
        return localized(chatTagAlbum);
      case messageTypeTaskCreated:
        return localized(taskComing);
      case messageTypeTransferMoneySuccess:
        return localized(transferMoney);
      case messageTypeChatScreenshot:
        return localized(tookScreenshotNotification);
      case messageTypeChatScreenshotEnable:
        MessageSystem systemMsg =
            message.decodeContent(cl: MessageSystem.creator);
        return localized(
          systemMsg.isEnabled == 1 ? screenshotTurnedOn : screenshotTurnedOff,
        );
      default:
        if (typ == 0) {
          return '';
        }
        return localized(chatNotSupport);
    }
  }

  static String systemMessageText(Chat chat, MessageSystem systemData) {
    return systemData.text;
  }

  static Size getMediaRenderSize(int width, int height, {String? caption}) {
    if (width == 0 || height == 0) {
      width = 16;
      height = 9;
    }
    final double imageRatio = width / height;

    final bool isPortrait =
        ObjectMgr.screenMQ!.orientation == Orientation.portrait;
    double screenWidth = 294;

    final double deviceScreenWidth = isPortrait
        ? ObjectMgr.screenMQ!.size.width
        : ObjectMgr.screenMQ!.size.height;

    if (deviceScreenWidth < screenWidth) {
      screenWidth = deviceScreenWidth * 0.7;
    }

    double resultWidth = 0;
    double resultHeight = 0;

    if (imageRatio > 1.0) {
      resultWidth = screenWidth;
      resultHeight = max(resultWidth / imageRatio, 73.5);
    } else {
      resultWidth = screenWidth * 0.9;
      resultHeight = screenWidth * min(0.9 / imageRatio, 1.4);
    }

    return Size(resultWidth, resultHeight);
  }

  static String callImageContent(MessageCall c) {
    String imageName =
        c.is_videocall == 1 ? "chat_icon_video_call" : "chat_icon_call";
    String callerReceiver =
        objectMgr.userMgr.isMe(c.inviter) ? "_caller" : "_receiver";
    String takenCallOrRejected = "";
    String imageFull = "$imageName$takenCallOrRejected$callerReceiver";
    return 'assets/svgs/$imageFull.svg';
  }

  static String callMsgContent(Message message) {
    final messageCall = MessageCall.creator()
      ..applyJson(jsonDecode(message.content));
    if (message.typ == messageRejectCall) {
      return localized(missedCall);
    } else if (message.typ == messageCancelCall) {
      return localized(missedCall);
    } else if (message.typ == messageEndCall) {
      return messageCall.is_videocall == 1
          ? localized(attachmentCallVideo)
          : localized(attachmentCallVoice);
    } else if (message.typ == messageMissedCall) {
      return localized(missedCall);
    } else if (message.typ == messageBusyCall) {
      return localized(missedCall);
    } else {
      return localized(missedCall);
    }
  }

  static Future<void> desktopSendFile(
    List<XFile> fileItem,
    int chatId,
    String caption,
    String? reply,
  ) async {
    for (var file in fileItem) {
      await objectMgr.chatMgr.sendFile(
        data: File(file.path),
        chatID: chatId,
        length: File(file.path).lengthSync(),
        fileName: path.basename(file.path),
        suffix: path.extension(file.name),
        caption: caption,
        reply: reply,
      );
    }
  }

  static Future<void> desktopSendImage(
    XFile file,
    int chatId,
    String caption,
    String? reply,
  ) async {
    final Size imageSize = await getDesktopImageSize(file.path);

    objectMgr.chatMgr.sendImage(
      chatID: chatId,
      width: imageSize.width.toInt(),
      height: imageSize.height.toInt(),
      resolution: MediaResolution.image_standard,
      caption: caption,
      data: File(file.path),
      reply: reply,
    );
  }

  static Future<void> desktopSendVideo(
    XFile file,
    int chatId,
    String caption,
    int width,
    int height,
    int duration,
    String? reply,
  ) async {
    await objectMgr.chatMgr.sendVideo(
      chatId,
      '',
      0,
      width,
      height,
      duration,
      data: File(file.path),
      caption: caption,
      resolution: MediaResolution.video_standard,
      reply: reply,
    );
  }

  static Future<Size> getDesktopImageSize(String imagePath) async {
    if (Platform.isMacOS) {
      // MacOS 从原生层获取尺寸
      const MethodChannel methodChannel = MethodChannel('desktopAction');
      List size = await methodChannel
          .invokeMethod('imageSize', {'imagePath': imagePath});
      if (size.isEmpty) {
        throw Exception('Failed to decode the image.');
      } else {
        return Size(size[0], size[1]);
      }
    } else {
      final Uint8List byteList = await File(imagePath).readAsBytes();
      final image = img.decodeImage(byteList);

      if (image != null) {
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();
        return Size(imageWidth, imageHeight);
      } else {
        throw Exception('Failed to decode the image.');
      }
    }
  }

  static String formalizeMentionContent(String text, Message message,
      {int? groupId}) {
    Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);

    if (mentionMatches.isNotEmpty) {
      List<MentionModel> mentionList = <MentionModel>[];

      if (message.atUser.isNotEmpty) {
        mentionList.addAll(message.atUser);
      } else if (notBlank(message.getValue('at_users')) &&
          message.getValue('at_users') is String) {
        final atUser = jsonDecode(message.getValue('at_users'));
        if (notBlank(atUser) && atUser is List) {
          mentionList.addAll(
            atUser.map<MentionModel>((e) => MentionModel.fromJson(e)).toList(),
          );
        }
      }

      for (int i = mentionMatches.length - 1; i >= 0; i--) {
        final match = mentionMatches.toList()[i];
        String uidStr =
            Regular.extractDigit(match.group(0) ?? '')?.group(0) ?? '';

        if (uidStr.isEmpty) continue;

        int uid = int.parse(uidStr);

        final MentionModel? model =
            mentionList.firstWhereOrNull((mention) => mention.userId == uid);

        String name = '';

        if (uid == 0 && model != null && model.role == Role.all) {
          name = localized(mentionAll);
        } else {
          if (uid == 0) {
            name = localized(mentionAll);
          } else {
            name = objectMgr.userMgr.getUserTitle(
                objectMgr.userMgr.getUserById(uid),
                groupId: groupId);
          }
        }

        if (name.isEmpty) {
          if (model == null) {
            name = uidStr.toString();
          } else {
            name = model.userName;
          }
        }

        text = text.replaceRange(match.start, match.end, '@$name');
      }
    }

    return text;
  }

  static bool hasEncryptedFlag(int flag) {
    return flag & ChatEncryptionFlag.encrypted.value ==
        ChatEncryptionFlag.encrypted.value;
  }
}
