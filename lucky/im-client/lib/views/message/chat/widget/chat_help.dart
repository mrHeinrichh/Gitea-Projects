import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:path/path.dart' as path;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/response_data.dart';

class ChatHelp {
  static ImageConfiguration? imgConfig;

  /// 图片最大限制数量
  static int imageNumLimit = 10;

  static List<List<T>> splitList<T>(List<T> inputList, int imageNumLimit) {
    List<List<T>> resultList = [];
    int size = (inputList.length / imageNumLimit).ceil();
    for (int i = 0; i < size; i++) {
      int len = (i + 1) * imageNumLimit;
      resultList.add(inputList.sublist(
          i * imageNumLimit, len > inputList.length ? inputList.length : len));
    }
    return resultList;
  }

  static Future<void> onSplitImageOrVideo<T>({
    required List<T> assets,
    required String? caption,
    required Chat chat,
    String? reply,
    bool isOriginalImageSend = false,
  }) async {
    await objectMgr.chatMgr.sendNewAlbum(
      chatID: chat.id,
      assets: assets,
      caption: caption,
      isOriginalImageSend: isOriginalImageSend,
      reply: reply,
    );
  }

  static Future<ResponseData> sendImageAsset(
    AssetEntity data,
    Chat chat, {
    String? caption,
    String? reply,
    String atUser = '',
    bool isOriginalImageSend = false,
  }) async {
    return await objectMgr.chatMgr.sendImage(
      chatID: chat.chat_id,
      width: data.orientatedWidth,
      height: data.orientatedHeight,
      caption: caption,
      reply: reply,
      data: data,
      atUser: atUser,
      isOriginalImageSend: isOriginalImageSend,
    );
  }

  static Future<ResponseData> sendImageFile(
    File data,
    Chat chat, {
    int width = 0,
    int height = 0,
    String? caption,
    String? reply,
    String atUser = '',
    bool isOriginalImageSend = false,
  }) async {
    return await objectMgr.chatMgr.sendImage(
      chatID: chat.chat_id,
      width: width,
      height: height,
      reply: reply,
      caption: caption,
      data: data,
      atUser: atUser,
      isOriginalImageSend: isOriginalImageSend,
    );
  }

  static Future<ResponseData?> sendVideoAsset(
    AssetEntity data,
    Chat chat,
    String? caption, {
    String? reply,
    String atUser = '',
    bool isOriginalImageSend = false,
  }) async {
    if (data.duration > 60 * 60) {
      // 一个小时
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
      reply: reply,
      atUser: atUser,
      isOriginalImageSend: isOriginalImageSend,
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

  static Map<String, int> adaptationSize(int nomalW, int nomalH) {
    int max_v = max(nomalW, nomalH);
    int min_v = min(nomalW, nomalH);
    if (max_v / min_v > 3 && max_v > 2048) {
      if (nomalW > nomalH) {
        nomalW = 1024;
      } else {
        nomalH = 1024;
      }
    }

    int _imageWidth = 0;
    int _imageHeight = 0;

    if (nomalW / nomalH > 1) {
      _imageWidth = 180;
      _imageHeight = 0;
      if (nomalW != 0) {
        _imageHeight = _imageWidth * nomalH ~/ nomalW;
      }
      if (_imageHeight == 0) {
        _imageHeight = 180;
      } else if (_imageHeight > 180) {
        _imageHeight = 180;
      } else if (_imageHeight < 76) {
        _imageHeight = 76;
      }
    } else {
      _imageWidth = 152;
      _imageHeight = 0;
      if (nomalW != 0) {
        _imageHeight = _imageWidth * nomalH ~/ nomalW;
      }
      if (_imageHeight == 0) {
        _imageHeight = 152;
      } else if (_imageHeight > 240) {
        _imageHeight = 240;
      } else if (_imageHeight < 152) {
        _imageHeight = 152;
      }
    }

    // int _imageWidth = 152;
    // int _imageHeight = 0;
    // if (nomalW != 0) {
    //   _imageHeight = _imageWidth * nomalH ~/ nomalW;
    // }
    // if (_imageHeight == 0) {
    //   _imageHeight = 152;
    // } else if (_imageHeight > 240) {
    //   _imageHeight = 240;
    // } else if (_imageHeight < 76) {
    //   _imageHeight = 76;
    // }
    return {
      'width': _imageWidth,
      'height': _imageHeight,
    };
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
        MessageText _textData = message.decodeContent(cl: MessageText.creator);
        if (_textData.text == "[语音通话]") {
          return localized(chatTagVoice);
        }

        if (_textData.text == "[视频通话]") {
          return localized(chatTagVideo);
        }

        return formalizeMentionContent(_textData.text, message);
      case messageTypeImage:
        final map = jsonDecode(message.content) as Map<String, dynamic>;
        return [map['url'], localized(chatTagPhoto)].join(':|');
      case messageTypeSysmsg:
      case messageTypeCreateGroup:
      case messageTypeBeingFriend:
        return systemMessageText(
            chat, message.decodeContent(cl: MessageSystem.creator));
      case messageTypeFollowBet:
        return localized(chatTypeFollowBet);
      case messageTypeOpenLottery:
        return localized(chatTypeOpenLottery);
      case messageTypeWinLottery:
        return localized(chatTypeWinLottery);
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeLiveVideo:
        // return localized(chatTagVideoCall);
        final map = jsonDecode(message.content) as Map<String, dynamic>;
        return [map['url'], localized(chatTagVideoCall)].join(':|');
      case messageTypeVoice:
        return localized(chatTagVoiceCall);
      // case messageTypeShare:
      //   return isGroup
      //       ? _lastGroupMsg(chat.last_send, chat.last_sender, '[动态]')
      //       : '[动态]';
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      // case messageTypeShareActivity:
      //   return isGroup
      //       ? _lastGroupMsg(chat.last_send, chat.last_sender, '[活动]')
      //       : '[活动]';
      // case messageTypePartyRegistr:
      //   return isGroup
      //       ? _lastGroupMsg(chat.last_send, chat.last_sender, '[聚会]')
      //       : '[聚会]';
      // case messageTypeShareLive:
      //   return isGroup
      //       ? _lastGroupMsg(chat.last_send, chat.last_sender, '[邀请]')
      //       : '[邀请]';
      case messageTypeFile:
        return localized(chatTagFile);
      // case messageTypeShareLocationStart:
      //   return isGroup
      //       ? _lastGroupMsg(chat.last_send, chat.last_sender, '[位置共享]')
      //       : '[位置共享]';
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeExitGroup:
        var _textData = message.decodeContent(cl: MessageText.creator);
        return _textData.text;
      case messageTypeBlack:
        return localized(chatTagRiskReminder);
      case messageTypeSecretaryRecommend:
        MessageSecretaryRecommend _recommendData =
            message.decodeContent(cl: MessageSecretaryRecommend.creator);
        return _recommendData.text.join('');
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
      case messageTypeBetOpening:
        String content = message.content;
        Map<String, dynamic> map = {};
        try {
          map = jsonDecode(content);
        } catch (e) {
          return "-开盘消息-";
        }
        String hit = map['hit'] ?? '--开盘消息--';
        return hit;
      case messageTypeBetClosed:
        String content = message.content;
        Map<String, dynamic> map = {};
        try {
          map = jsonDecode(content);
        } catch (e) {
          return "-封盘消息-";
        }
        String hit = map['hit'] ?? '--封盘消息--';
        return hit;
      case messageTypeBetStatistics:
        return "下注统计";
      case messageTypeTaskCreated:
        return localized(taskComing);
      case messageTypeTransferMoneySuccess:
        return localized(transferMoney);
      case messageTypeChatScreenshot:
        return localized(tookScreenshotNotification);
      case messageTypeChatScreenshotEnable:
        MessageSystem _systemMsg =
            message.decodeContent(cl: MessageSystem.creator);
        return localized(_systemMsg.isEnabled == 1
            ? screenshotTurnedOn
            : screenshotTurnedOff);
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
    final double imageRatio = width / height;
    // prevent device rotated
    final bool isPortrait =
        ObjectMgr.screenMQ!.orientation == Orientation.portrait;
    final double screenWidth = isPortrait
        ? ObjectMgr.screenMQ!.size.width
        : ObjectMgr.screenMQ!.size.height;
    double resultWidth = 0;
    double resultHeight = 0;
    // 正方形图片
    if (imageRatio >= 0.90 && imageRatio <= 1.1) {
      resultWidth = screenWidth * 0.55;
      resultHeight = screenWidth * 0.55;
    } else if (imageRatio < 0.90) {
      if (imageRatio < 0.23) {
        if ((caption?.length ?? 0) > 25) {
          resultWidth = screenWidth * 0.7;
          resultHeight = 300;
        } else if ((caption?.length ?? 0) > 10) {
          resultWidth = screenWidth * 0.55;
          resultHeight = 300;
        } else {
          resultWidth = 100;
          resultHeight = 300;
        }
      } else {
        resultHeight = height.toDouble();
        if (resultHeight > screenWidth * 0.8) {
          resultHeight = screenWidth * 0.8;
        }

        if ((caption?.length ?? 0) > 25) {
          resultWidth = screenWidth * 0.7;
        } else if ((caption?.length ?? 0) > 10) {
          resultWidth = screenWidth * 0.55;
        } else {
          resultWidth = resultHeight * imageRatio;
        }
      }
    } else {
      if (imageRatio > 4.33) {
        resultWidth = 260;
        resultHeight = 80;
      } else {
        resultWidth = width.toDouble();

        if (resultWidth > screenWidth * 0.7) {
          resultWidth = screenWidth * 0.7;
        }

        resultHeight = resultWidth / imageRatio;
      }
    }

    return Size(resultWidth, resultHeight);
  }

  static double fromSourceHeight(int forwardUserId) {
    if (forwardUserId != 0) {
      return 36.w;
    }
    return 0.0;
  }

  static String callMsgContent(Message message) {
    // String messageTime = FormatTime.chartTime(message.create_time, false);
    final messageCall = MessageCall.creator()
      ..applyJson(jsonDecode(message.content));
    if (message.typ == messageRejectCall) {
      return localized(callDeclined); //, params: [messageTime]);
    } else if (message.typ == messageCancelCall) {
      if (objectMgr.userMgr.isMe(messageCall.inviter)) {
        if (messageCall.status == ServerCallState.optNoRsp.status) {
          return localized(callNotAnswer); //, params: [messageTime]);
        } else {
          return localized(callCancel); //, params: [messageTime]);
        }
      } else {
        return localized(callNotAnswerFriend); //, params: [messageTime]);
      }
    } else if (message.typ == messageEndCall) {
      return localized(
        chatCallDuration,
      );
      // params: [messageTime, constructTimeVerbose(messageCall.time)]);
    } else if (message.typ == messageMissedCall) {
      return objectMgr.userMgr.isMe(messageCall.inviter)
          ? localized(callNotAnswer) //, params: [messageTime])
          : localized(callNotAnswerFriend); //, params: [messageTime]);
    } else if (message.typ == messageBusyCall) {
      return objectMgr.userMgr.isMe(messageCall.inviter)
          ? localized(callBusy) //, params: [messageTime])
          : localized(callNotAnswerFriend); //, params: [messageTime]);
    } else {
      return '';
    }
  }

  static Widget callMsgIcon(Message message, MessageCall messageCall) {
    bool isMe = objectMgr.userMgr.isMe(messageCall.inviter);
    bool isVoiceCall = messageCall.is_videocall == 0;
    String asset = isVoiceCall
        ? 'assets/svgs/missed-call.svg'
        : 'assets/svgs/missedcall-video.svg';
    Color color = Colors.red;

    if (message.typ == messageRejectCall) {
      if (isMe) {
        asset = isVoiceCall
            ? 'assets/svgs/outgoing-call.svg'
            : 'assets/svgs/outgoing-video.svg';
      } else {
        asset = isVoiceCall
            ? 'assets/svgs/incoming-call.svg'
            : 'assets/svgs/incoming-video.svg';
      }
      color = JXColors.secondaryTextBlack;
    } else if (message.typ == messageCancelCall) {
      if (isMe) {
        asset = isVoiceCall
            ? 'assets/svgs/outgoing-call.svg'
            : 'assets/svgs/outgoing-video.svg';
        color = JXColors.secondaryTextBlack;
      }
    } else if (message.typ == messageEndCall) {
      if (isMe) {
        asset = isVoiceCall
            ? 'assets/svgs/outgoing-call.svg'
            : 'assets/svgs/outgoing-video.svg';
        color = Colors.black;
      } else {
        asset = isVoiceCall
            ? 'assets/svgs/incoming-call.svg'
            : 'assets/svgs/incoming-video.svg';
        color = Colors.black;
      }
    } else if (message.typ == messageMissedCall) {
      if (isMe) {
        asset = isVoiceCall
            ? 'assets/svgs/outgoing-call.svg'
            : 'assets/svgs/outgoing-video.svg';
        color = JXColors.secondaryTextBlack;
      }
    } else if (message.typ == messageBusyCall) {
      if (isMe) {
        asset = isVoiceCall
            ? 'assets/svgs/outgoing-call.svg'
            : 'assets/svgs/outgoing-video.svg';
        color = JXColors.secondaryTextBlack;
      }
    }

    return SvgPicture.asset(asset, color: color);
  }

  ///Desktop Version ====================================================
  static void desktopSendFile(
    List<XFile> fileItem,
    int chatId,
    String caption,
    String? reply,
  ) {
    fileItem.forEach((file) async {
      await objectMgr.chatMgr.sendFile(
        data: File(file.path),
        chatID: chatId,
        length: File(file.path).lengthSync(),
        file_name: path.basename(file.path),
        suffix: path.extension(file.name),
        caption: caption,
        reply: reply,
      );
    });
  }

  static Future<void> desktopSendImage(
    XFile file,
    int chatId,
    String caption,
    String? reply,
  ) async {
    final Size imageSize = await getDesktopImageSize(file.path);

    await objectMgr.chatMgr.sendImage(
      chatID: chatId,
      width: imageSize.width.toInt(),
      height: imageSize.height.toInt(),
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
      reply: reply,
    );
  }

  static int getSplitPosition(List<Message> messages, {int limit = 5}) {
    if (messages.length < limit) {
      return 0;
    }

    int position = 0;
    List<Message> sublist = messages.sublist(0, limit);
    sublist.sort((a, b) => a.chat_idx.compareTo(b.chat_idx));

    int count = 0;
    for (int i = 0; i < sublist.length; i++) {
      Message message = sublist[i];
      if (message.typ == messageTypeImage ||
          message.typ == messageTypeVideo ||
          message.typ == messageTypeReel ||
          message.typ == messageTypeNewAlbum) {
        if (i < 2) {
          continue;
        }
        count++;
      }
    }

    if (count >= 2) {
      position = 2;
    }

    return position;
  }

  static Future<Size> getDesktopImageSize(String imagePath) async {
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

  static String formalizeMentionContent(String text, Message message) {
    Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);

    if (mentionMatches.isNotEmpty) {
      List<MentionModel> mentionList = <MentionModel>[];

      if (message.atUser.isNotEmpty) {
        mentionList.addAll(message.atUser);
      } else if (notBlank(message.getValue('at_users')) &&
          message.getValue('at_users') is String) {
        final atUser = jsonDecode(message.getValue('at_users'));
        if (notBlank(atUser) && atUser is List) {
          mentionList.addAll(atUser
              .map<MentionModel>((e) => MentionModel.fromJson(e))
              .toList());
        }
      }

      for (int i = mentionMatches.length - 1; i >= 0; i--) {
        final match = mentionMatches.toList()[i];
        String uidStr =
            Regular.extractDigit(match.group(0) ?? '')?.group(0) ?? '';

        if (uidStr.isEmpty) continue;

        int uid = int.parse(uidStr);

        String name =
            objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(uid));

        if (name.isEmpty) {
          final MentionModel? model =
              mentionList.firstWhereOrNull((mention) => mention.userId == uid);
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

  static String formalizeMentionBetClosed(Message lastMessage) {
    String content = "";
    String msg = lastMessage.content;
    Map<String, dynamic> map = {};
    try {
      map = jsonDecode(msg);
    } catch (e) {
      content = "-封盘消息-";
    }
    String hit = map['hit'] ?? '--封盘消息--';
    content = hit;
    return content;
  }

  static String formalizeMentionBetOpening(Message lastMessage) {
    String content = "";
    String msg = lastMessage.content;
    Map<String, dynamic> map = {};
    try {
      map = jsonDecode(msg);
    } catch (e) {
      content = "-开盘消息-";
    }
    String hit = map['hit'] ?? '--开盘消息--';
    content = hit;
    return content;
  }
}
