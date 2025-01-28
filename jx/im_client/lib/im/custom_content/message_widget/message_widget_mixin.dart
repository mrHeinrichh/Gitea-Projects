import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_pop_animation.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/read_more_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/expire_message_task.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/unescape_util.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/group/item/double_message_view.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class MessageWidgetMixin<T extends StatefulWidget> extends State<T> {
  bool _hasInitListener = false;

  @override
  void dispose() {
    if (_hasInitListener) {
      objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _getEditedTranslation);
      if (message != null) {
        message.off("eventMessageTranslate", _updateMessageTranslation);
        message.off(Message.eventReadMoreText, _updateMessageReadMore);
        if (message.typ != messageTypeVoice) {
          objectMgr.chatMgr
              .off(ChatMgr.messagePlayingSound, _messagePlayingSound);
          objectMgr.chatMgr.off(ChatMgr.messageStopSound, _messageStopSound);
          objectMgr.chatMgr
              .off(ChatMgr.messageWaitingRead, _messageWaitingReading);
          objectMgr.chatMgr
              .off(ChatMgr.messageStopAllReading, _messageStopAllReading);
          objectMgr.chatMgr
              .off(ChatMgr.messagePauseReading, _messagePauseReading);
          objectMgr.chatMgr
              .off(ChatMgr.messageContinueRead, _messageContinueRead);
        }
      }
    }

    super.dispose();
  }

  void initMessage(
      BaseChatController baseController, int index, Message message) {
    if (_hasInitListener) return;
    this.baseController = baseController;
    this.index = index;
    this.message = message;
    this.message.on("eventMessageTranslate", _updateMessageTranslation);
    this.message.on(Message.eventReadMoreText, _updateMessageReadMore);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _getEditedTranslation);
    _initMessageTranslation();
    _messageTranslateElement(this.message.getTranslationModel(), this.message);
    if (message.typ != messageTypeVoice) {
      _checkIsReading();
      objectMgr.chatMgr.on(ChatMgr.messagePlayingSound, _messagePlayingSound);
      objectMgr.chatMgr.on(ChatMgr.messageStopSound, _messageStopSound);
      objectMgr.chatMgr.on(ChatMgr.messageWaitingRead, _messageWaitingReading);
      objectMgr.chatMgr
          .on(ChatMgr.messageStopAllReading, _messageStopAllReading);
      objectMgr.chatMgr.on(ChatMgr.messagePauseReading, _messagePauseReading);
      objectMgr.chatMgr.on(ChatMgr.messageContinueRead, _messageContinueRead);
    }
    _hasInitListener = true;
  }

  final isExpired = false.obs;
  final isDeleted = false.obs;

  // 翻译相关
  final translationText = "".obs;
  final translationLocale = "".obs;
  final showOriginalContent = false.obs;
  final showTranslationContent = false.obs;

  // 消息被点击
  final isPressed = false.obs;

  Offset tapPosition = Offset.zero;

  late final BaseChatController baseController;
  late final Message message;
  late final int index;

  bool get isFirstMessage => message.isFirst;

  bool get isLastMessage => message.isLast;

  RxBool get isExpandReadMore => message.isReadMore.obs;
  final width = 0.0.obs;
  final height = 0.0.obs;

  /// 文字转语音相关
  final isPlayingSound = false.obs;
  final isWaitingRead = false.obs;
  final isPauseRead = false.obs;

  bool popupEnabled = false;
  OverlayEntry? chatPopEntry;

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

          String key = emojiMessage.emoji;
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
  ) async =>
      Get.to(() => DoubleMessageView(messageText: messageText));

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
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (childKey.currentContext == null) return;
    final controller = Get.find<ChatContentController>(tag: chatId.toString());
    if (controller.chatController.popupEnabled) return;
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
              isGroup: controller.chatController.chat.isGroup,
            ),
          ),
        ),
      ),
    );

    HapticFeedback.mediumImpact();
    Overlay.of(context).insert(controller.chatController.chatPopEntry!);
  }

  void enableFloatingWindowInfo(
    BuildContext context,
    int chatId,
    Message message,
    Widget child,
    GlobalKey childKey,
    Offset tapDetails,
    Widget bottomWidget, {
    Widget? topWidget,
    ChatPopAnimationType? chatPopAnimationType,
    double menuHeight = 0.0,
  }) {
    popupEnabled = true;
    chatPopEntry = OverlayEntry(
      builder: (BuildContext context) => GestureDetector(
        onTap: resetPopupWindow,
        onSecondaryTap: resetPopupWindow,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: Container(
            color: Colors.black.withOpacity(0.35),
            child: ChatPopAnimationInfo(
              child,
              childKey,
              tapDetails,
              chatPopAnimationType: chatPopAnimationType,
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
    Overlay.of(context).insert(chatPopEntry!);
  }

  void resetPopupWindow() {
    popupEnabled = false;
    chatPopEntry?.remove();
    chatPopEntry = null;
  }

  void enableFloatingWindowInfoMember(
    BuildContext context,
    int chatId,
    Widget child,
    GlobalKey childKey,
    Offset tapDetails,
    Widget bottomWidget, {
    Widget? topWidget,
    ChatPopAnimationType? chatPopAnimationType,
    double menuHeight = 0.0,
  }) {
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
            color: Colors.black.withOpacity(0.35),
            child: ChatPopAnimationInfo(
              child,
              childKey,
              tapDetails,
              chatPopAnimationType: chatPopAnimationType,
              menuHeight: menuHeight,
              bottomWidget: bottomWidget,
            ),
          ),
        ),
      ),
    );

    HapticFeedback.mediumImpact();
    Overlay.of(context).insert(controller.chatController.chatPopEntry!);
  }

  /// 翻译相关
  _initMessageTranslation() {
    if (message.chat_idx <= baseController.oriChatIdx) {
      Chat chat = baseController.chat;
      if (chat.read_chat_msg_idx >= message.chat_idx) return;
      if (!chat.isAutoTranslateIncoming) return;
      if (objectMgr.userMgr.isMe(message.send_id)) return;

      if (message.isTranslatableType) {
        if (message.typ != messageTypeVoice) {
          String content = message.messageContent;
          if (EmojiParser.hasOnlyEmojis(content)) return;
        }

        objectMgr.scheduleMgr.translateMessageTask.addTranslateTask(
          message,
          chat.currentLocaleIncoming == 'auto'
              ? getAutoLocale(chat: chat, isMe: false)
              : chat.currentLocaleIncoming,
          chat.visualTypeIncoming,
        );
      }
    }
  }

  _messageTranslateElement(TranslationModel? model, Message msg) {
    showOriginalContent.value = false;
    showTranslationContent.value = false;
    if (model != null && model.showTranslation) {
      if (model.visualType == 0) {
        showOriginalContent.value = true;
        showTranslationContent.value = true;
      } else {
        showTranslationContent.value = true;
      }
      translationLocale.value = model.currentLocale;
      // 特殊字符替換
      translationText.value = UnescapeUtil.encodedString(model.getContent());
    } else {
      showOriginalContent.value = true;
    }
    _getMessageDimension(msg);
  }

  _getEditedTranslation(sender, type, data) async {
    if (data['message'] is Message) {
      if (data['message'].message_id == message.message_id &&
          showTranslationContent.value) {
        TranslationModel? model = data['message'].getTranslationModel();
        if (model != null) {
          translationText.value = model.getContent();
          translationLocale.value = model.currentLocale;
        }
      }
    }
  }

  _updateMessageTranslation(_, __, data) {
    if (data is Message) {
      if (data.message_id == message.message_id) {
        TranslationModel? translationModel = data.getTranslationModel();
        if (translationModel != null && translationModel.showTranslation) {
          translationLocale.value = translationModel.currentLocale;
          // 特殊字符替換
          translationText.value =
              UnescapeUtil.encodedString(translationModel.getContent());
          _messageTranslateElement(translationModel, data);
        } else {
          showOriginalContent.value = true;
          showTranslationContent.value = false;
          _getMessageDimension(data);
        }
      }
    }
  }

  _updateMessageReadMore(_, __, data) {
    if (data is ReadMoreModel) {
      if (data.messageId == message.message_id) {
        message.isReadMore = data.isReadMore!;
      }
    }
  }

  _getMessageDimension(Message msg) {
    if (msg.typ == messageTypeImage) {
      MessageImage messageImage = msg.decodeContent(cl: MessageImage.creator);
      String caption = messageImage.caption;
      if (showTranslationContent.value) {
        if (translationText.value.length > caption.length) {
          caption = translationText.value;
        }
      }
      Size size = ChatHelp.getMediaRenderSize(
        messageImage.width,
        messageImage.height,
        caption: caption,
      );
      width.value = jxDimension.senderImageWidth(size.width);
      height.value = jxDimension.senderImageHeight(size.height);
    } else if (msg.typ == messageTypeVideo || msg.typ == messageTypeReel) {
      MessageVideo messageVideo = msg.decodeContent(cl: MessageVideo.creator);
      String caption = messageVideo.caption;
      if (showTranslationContent.value) {
        if (translationText.value.length > caption.length) {
          caption = translationText.value;
        }
      }
      Size size = ChatHelp.getMediaRenderSize(
        messageVideo.width,
        messageVideo.height,
        caption: caption,
      );
      width.value = jxDimension.videoSenderWidth(size).abs();
      height.value = jxDimension.videoSenderHeight(size).abs();
    } else if (msg.typ == messageTypeMarkdown) {
      MessageMarkdown messageMarkdown =
          msg.decodeContent(cl: MessageMarkdown.creator);
      Size size = ChatHelp.getMediaRenderSize(
        messageMarkdown.width,
        messageMarkdown.height,
      );
      width.value = jxDimension.videoSenderWidth(size).abs();
      height.value = jxDimension.videoSenderHeight(size).abs();
    }
  }

  /// 文字转语音相关
  _messagePlayingSound(_, __, data) {
    if (data is Message) {
      isPauseRead.value = false;
      if (data.message_id == message.message_id) {
        isWaitingRead.value = false;
        isPlayingSound.value = true;
      } else {
        isPlayingSound.value = false;
        isWaitingRead.value = false;
      }
    }
  }

  _messageStopSound(_, __, data) {
    if (data is Message) {
      if (data.message_id == message.message_id) {
        isPlayingSound.value = false;
        isWaitingRead.value = false;
      }
    }
  }

  _messageWaitingReading(_, __, data) {
    if (data is Message) {
      if (data.message_id == message.message_id) {
        isWaitingRead.value = !isWaitingRead.value;
      } else {
        isWaitingRead.value = false;
        isPlayingSound.value = false;
      }
    }
  }

  _messageStopAllReading(_, __, ___) {
    isWaitingRead.value = false;
    isPlayingSound.value = false;
  }

  _messagePauseReading(_, __, ___) {
    isPauseRead.value = true;
  }

  _messageContinueRead(_, __, ___) {
    isPauseRead.value = false;
  }

  _checkIsReading() {
    final VolumePlayerService playerService =
        VolumePlayerService.sharedInstance;
    if (notBlank(playerService.currentPlayingFile) &&
        playerService.currentMessage!.message_id == message.message_id) {
      isWaitingRead.value = false;
      isPlayingSound.value = true;
      if (!playerService.isPlaying) {
        isPauseRead.value = true;
      }
    }
  }
}

// 以下公共方法

void onLinkOpen(String text) async {
  String url = text;
  url = url[0].toLowerCase() + url.substring(1);
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              color: Colors.white,
              child: Text(
                url,
                style: jxTextStyle.textStyle14(color: colorTextPrimary),
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
                style: jxTextStyle.textStyle16(color: themeColor),
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
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localized(buttonCancel),
            style: jxTextStyle.textStyle16(color: themeColor),
          ),
        ),
      );
    },
  );
}

void onMentionTap(int uid) async => Get.toNamed(RouteName.chatInfo,
    arguments: {"uid": uid}, id: objectMgr.loginMgr.isDesktop ? 1 : null);

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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              color: Colors.white,
              child: Text(
                phoneNumber,
                style: jxTextStyle.textStyle14(color: colorTextPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                if (await canLaunchUrl(Uri.parse(realNumber))) {
                  await launchUrl(Uri.parse(realNumber));
                } else {
                  // Handle error
                  Toast.showToast(localized(invalidPhoneNumber));
                }
              },
              child: Text(
                localized(callNumber),
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(RouteName.searchUserView, arguments: {
                  'phoneNumber': phoneNumber,
                  'isModalBottomSheet': false
                });
              },
              child: Text(
                localized(searchUser),
                style: jxTextStyle.textStyle16(color: themeColor),
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
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localized(buttonCancel),
            style: jxTextStyle.textStyle16(color: themeColor),
          ),
        ),
      );
    },
  );
}
