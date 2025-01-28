import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_pop_animation.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/expire_message_task.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/double_message_view.dart';
import 'package:jxim_client/views/navigator_push.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

mixin class MessageWidgetMixin {
  final isExpired = false.obs;
  final isDeleted = false.obs;

  // 消息被点击
  final isPressed = false.obs;

  Offset tapPosition = Offset.zero;

  late final BaseChatController baseController;
  late final Message message;
  late final int index;

  bool get isFirstMessage => firstMessageShow();

  bool get isLastMessage => lastMessageShow();

  void initMessage(
      BaseChatController baseController, int index, Message message) {
    this.baseController = baseController;
    this.index = index;
    this.message = message;
  }

  /// 检查当前消息和上一条消息是否是同一条
  bool firstMessageShow() {
    if (baseController.chat.isSaveMsg || baseController.isPinnedOpened) {
      return true;
    }

    final messageIdx = baseController.visibleMessageList.indexWhere(
      (element) => element.send_time == message.send_time || element == message,
    );
    if (messageIdx + 1 == baseController.visibleMessageList.length) return true;

    if (messageIdx != -1 &&
        messageIdx + 1 < baseController.visibleMessageList.length) {
      final currMsg = baseController.visibleMessageList[messageIdx];
      final prevMsg = baseController.visibleMessageList[messageIdx + 1];
      var currSendTime = currMsg.send_time;
      var prevSendTime = prevMsg.send_time;
      if (currSendTime.toString().length == 10) {
        currSendTime = currSendTime *1000;
      }
      if (prevSendTime.toString().length == 10) {
        prevSendTime = prevSendTime *1000;
      }
      var diffTime = currSendTime - prevSendTime;
      if (diffTime >= 120 * 1000) {
        return true;
      }

      if (prevMsg.send_id != currMsg.send_id) {
        return true;
      }
    }

    return false;
  }

  bool lastMessageShow() {
    if (baseController.chat.isSaveMsg || baseController.isPinnedOpened) {
      return true;
    }

    final messageIdx = baseController.visibleMessageList.indexWhere(
      (element) => element.send_time == message.send_time || element == message,
    );
    if (messageIdx != -1 && messageIdx - 1 >= 0) {
      final currMsg = baseController.visibleMessageList[messageIdx];
      final nextMsg = baseController.visibleMessageList[messageIdx - 1];
      var nextSendTime = nextMsg.send_time;
      var currSendTime = currMsg.send_time;
      if (nextSendTime.toString().length == 10) {
        nextSendTime = nextSendTime *1000;
      }
      if (currSendTime.toString().length == 10) {
        currSendTime = currSendTime *1000;
      }
      var diffTime = nextSendTime - currSendTime;
      if (diffTime >= 120 * 1000) {
        return true;
      }

      for (int i = baseController.normalMessageList.length - 1; i >=0; i --) {
        List<Message> list = baseController.normalMessageList[i];
        if (list.last.chat_idx == message.chat_idx) {
          return true;
        }
      }

      if (baseController.gameMessageIds.contains(message.typ)) {
        for (int i = baseController.gameMessageList.length - 1; i >=0; i --) {
          List<Message> list = baseController.gameMessageList[i];
          if (list.last.chat_idx == message.chat_idx) {
            return true;
          }
        }
      }

      if (nextMsg.send_id == currMsg.send_id) {
        return false;
      }
    }

    return true;
  }

  onPressReply(BaseChatController controller, Message message) {
    final replyMsg = message.replyModel;
    ReplyModel? rModelMsg;

    if (notBlank(replyMsg)) {
      rModelMsg = ReplyModel.fromJson(jsonDecode(replyMsg!));
    } else {
      /// 解决 以文件或图片恢复的消息，message.replyModel会为空
      String? replyContent =
          message.decodeContent(cl: message.getMessageModel(message.typ)).reply;
      if (replyContent != null) {
        rModelMsg = ReplyModel.fromJson(jsonDecode(replyContent));
      }
    }

    if (rModelMsg == null) {
      return;
    }
    int id = 0;
    //兼容以前老的回复消息，以前id指的是chat id，现在指message的id
    if (message.chat_id != rModelMsg.id) {
      id = rModelMsg.id;
    }
    controller.showMessageOnScreen(rModelMsg.chatIdx, id, message.create_time);
    controller.onCreateHighlightTimer();
  }

  // <emoji, <userId, emojiMessage>>
  List<Map<String, Map<int, MessageReactEmoji?>>> getEmojiList(
      BaseChatController controller, Message message) {
    List<Map<String, Map<int, MessageReactEmoji?>>> emojiCountList = [];
    final Map<int, List<Message>>? emojiListMap =
        objectMgr.chatMgr.reactEmojiMap[message.chat_id];

    if (emojiListMap != null) {
      final List<Message>? emojiList = emojiListMap[message.message_id];
      if (emojiList != null && emojiList.isNotEmpty) {
        Map<String, Map<int, MessageReactEmoji?>> emojiUserMap = {};
        for (int i = 0; i < emojiList.length; i++) {
          Message msg = emojiList[i];
          MessageReactEmoji emojiMessage =
              msg.decodeContent(cl: MessageReactEmoji.creator);
          emojiMessage.initBy(msg);

          String key =
              '${MessageReactEmoji.emojiNameOldToNew(emojiMessage.emoji)}';
          if (emojiUserMap.containsKey(key)) {
            if (emojiMessage.typ == messageTypeAddReactEmoji) {
              emojiUserMap[key]![emojiMessage.userId] = emojiMessage;
            } else if (emojiMessage.typ == messageTypeRemoveReactEmoji) {
              if (emojiUserMap[key]!.containsKey(emojiMessage.userId)) {
                emojiUserMap[key]!.remove(emojiMessage.userId);
                if (emojiUserMap[key]!.isEmpty) {
                  emojiUserMap.remove(key);
                }
              }
            }
          } else {
            if (msg.typ == messageTypeAddReactEmoji) {
              emojiUserMap[key] = {emojiMessage.userId: emojiMessage};
            }
          }
        }

        emojiUserMap.forEach((k, v) => emojiCountList.add({k: v}));
      }
    }
    return emojiCountList;
  }

  void onDoubleTap(
      BuildContext context,
      MessageText messageText,
      ) {
    NavigatorPush.to(
      context,
      DoubleMessageView(
        messageText: messageText,
      ),
    );
  }

  void onLinkOpen(String text) async {
    RegExpMatch match = Regular.extractLink(text).first;
    String url = text.substring(match.start, match.end);
    if (!url.startsWith('http')) url = 'http://$url';
    await linkToWebView(url, useInternalWebView: false);
  }

  void onLinkLongPress(
      String text,
      BuildContext context,
      ) async {
    RegExpMatch match = Regular.extractLink(text).first;
    String url = text.substring(match.start, match.end);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            Material(
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                color: Colors.white,
                child: Text(
                  url,
                  style:
                      jxTextStyle.textStyle14(color: JXColors.primaryTextBlack),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  onLinkOpen(url);
                },
                child: Text(
                  localized(openInApp),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  copyToClipboard(url);
                },
                child: Text(
                  localized(copyLink),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            )
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle16(color: accentColor),
            ),
          ),
        );
      },
    );
  }

  void onPhoneLongPress(
    String text,
    BuildContext context,
  ) async {
    RegExpMatch match = Regular.extractPhoneNumber(text).first;
    String phoneNumber = text.substring(match.start, match.end);
    String realNumber = "tel:$phoneNumber";

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            Material(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                color: Colors.white,
                child: Text(
                  phoneNumber,
                  style:
                      jxTextStyle.textStyle14(color: JXColors.primaryTextBlack),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  if (await canLaunch(realNumber)) {
                    await launch(realNumber);
                  } else {
                    // Handle error
                    Toast.showToast(localized(invalidPhoneNumber));
                  }
                },
                child: Text(
                  localized(callNumber),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed(RouteName.searchUserView,
                      arguments: {'phoneNumber': phoneNumber});
                },
                child: Text(
                  localized(searchUser),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  copyToClipboard(phoneNumber);
                },
                child: Text(
                  localized(copyNumber),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            )
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle16(color: accentColor),
            ),
          ),
        );
      },
    );
  }

  void onMentionTap(int uid) async => Get.toNamed(RouteName.chatInfo,
      arguments: {"uid": uid}, id: objectMgr.loginMgr.isDesktop ? 1 : null);

  void checkExpiredMessage(Message message) =>
      ExpireMessageTask.addIncomingExpireMessages(message);

  void checkDateMessage(Message message) {
    int dateMsgIdx = baseController.previousMessageList
        .indexWhere((element) => element.typ == messageTypeDate);

    if (dateMsgIdx != -1) {
      final dateMsg = baseController.previousMessageList[dateMsgIdx];
      bool allIsNotShow = baseController.previousMessageList.isNotEmpty;

      for (int i = dateMsgIdx; i >= 0; i--) {
        Message msg = baseController.previousMessageList[i];
        if (!msg.isSystemMsg &&
            !msg.isDeleted &&
            !msg.isExpired &&
            msg.create_time >= dateMsg.create_time) {
          allIsNotShow = false;
          break;
        }
      }
      if (allIsNotShow) {
        baseController.previousMessageList.removeAt(dateMsgIdx);
      }
    }

    dateMsgIdx = baseController.nextMessageList
        .indexWhere((element) => element.typ == messageTypeDate);
    if (dateMsgIdx != -1) {
      final dateMsg = baseController.nextMessageList[dateMsgIdx];
      bool allIsNotShow = baseController.nextMessageList.isNotEmpty;

      for (int i = dateMsgIdx; i < baseController.nextMessageList.length; i++) {
        Message msg = baseController.nextMessageList[i];
        if (!msg.isSystemMsg &&
            !msg.isDeleted &&
            !msg.isExpired &&
            msg.create_time >= dateMsg.create_time) {
          allIsNotShow = false;
          break;
        }
      }

      if (allIsNotShow) {
        baseController.nextMessageList.removeAt(dateMsgIdx);
      }
    }
  }

  void enableFloatingWindow(
    BuildContext context,
    int chatId,
    Message message,
    Widget child,
    GlobalKey childKey,
    Offset tapDetails,
    Widget bottomWidget, {
    Widget? topWidget,
    BubbleType? bubbleType,
    double menuHeight = 0.0,
  }) {
    if (!message.isSendOk) return;

    final controller = Get.find<ChatContentController>(tag: chatId.toString());
    controller.chatController.onCancelFocus();
    controller.chatController.popupEnabled = true;
    controller.inputController.isVoiceMode.value = false;
    controller.chatController.chatPopEntry = OverlayEntry(
      builder: (BuildContext context) => GestureDetector(
        onTap: controller.chatController.resetPopupWindow,
        onSecondaryTap: controller.chatController.resetPopupWindow,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: ChatPopAnimation(
              child,
              childKey,
              tapDetails,
              bubbleType: bubbleType,
              menuHeight: menuHeight,
              bottomWidget: bottomWidget,
              topWidget: !objectMgr.userMgr.isMe(message.send_id) ||
                      (objectMgr.userMgr.isMe(message.send_id) &&
                          message.isSendOk)
                  ? topWidget
                  : null,
            ),
          ),
        ),
      ),
    );

    HapticFeedback.mediumImpact();
    Overlay.of(context).insert(controller.chatController.chatPopEntry!);
  }
}
/// 检查当前消息和上一条消息是否是同一条
bool firstMessageShowFunc(BaseChatController baseController, Message message) {
  if (baseController.chat.isSaveMsg || baseController.isPinnedOpened) {
    return true;
  }

  final messageIdx = baseController.visibleMessageList.indexWhere((element) =>
  element.send_time == message.send_time && element.chat_idx == message.chat_idx,);
  if (messageIdx + 1 == baseController.visibleMessageList.length) return true;

  if (messageIdx != -1 &&
      messageIdx + 1 < baseController.visibleMessageList.length) {
    final currMsg = baseController.visibleMessageList[messageIdx];
    final prevMsg = baseController.visibleMessageList[messageIdx + 1];
    var currSendTime = currMsg.send_time;
    var prevSendTime = prevMsg.send_time;
    if (currSendTime.toString().length == 10) {
      currSendTime = currSendTime *1000;
    }
    if (prevSendTime.toString().length == 10) {
      prevSendTime = prevSendTime *1000;
    }
    var diffTime = currSendTime - prevSendTime;
    if (diffTime >= 120 * 1000) {
      return true;
    }

    if (message.typ == 20001) {
      for (int i = baseController.normalMessageList.length - 1; i >=0; i --) {
        List<Message> list = baseController.normalMessageList[i];
        if (list.first.chat_idx == message.chat_idx) {
          return true;
        }
      }
    }

    if (baseController.gameMessageIds.contains(message.typ)) {
      for (int i = baseController.gameMessageList.length - 1; i >=0; i --) {
        List<Message> list = baseController.gameMessageList[i];
        if (list.first.chat_idx == message.chat_idx) {
          return true;
        }
      }
    }

    if (prevMsg.send_id != currMsg.send_id) {
      return true;
    }
  }

  return false;
}
bool lastMessageShowFunc(BaseChatController baseController, Message message) {
  if (baseController.chat.isSaveMsg || baseController.isPinnedOpened) {
    return true;
  }

  final messageIdx = baseController.visibleMessageList.indexWhere((element) =>
  element.send_time == message.send_time && element.chat_idx == message.chat_idx,);
  if (messageIdx != -1 && messageIdx - 1 >= 0) {
    final currMsg = baseController.visibleMessageList[messageIdx];
    final nextMsg = baseController.visibleMessageList[messageIdx - 1];
    var nextSendTime = nextMsg.send_time;
    var currSendTime = currMsg.send_time;
    if (nextSendTime.toString().length == 10) {
      nextSendTime = nextSendTime *1000;
    }
    if (currSendTime.toString().length == 10) {
      currSendTime = currSendTime *1000;
    }
    var diffTime = nextSendTime - currSendTime;
    if (diffTime >= 120 * 1000) {
      return true;
    }

    if (baseController.gameMessageIds.contains(message.typ)) {
      for (int i = baseController.gameMessageList.length - 1; i >=0; i --) {
        List<Message> list = baseController.gameMessageList[i];
        if (list.last.chat_idx == message.chat_idx) {
          return true;
        }
      }
    }

    if (nextMsg.send_id == currMsg.send_id) {
      return false;
    }
  }

  return true;
}