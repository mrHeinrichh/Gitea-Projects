import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/chat_cell_send_status.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:get/get.dart';

class ChatCellContentText extends StatefulWidget {
  final Chat chat;

  const ChatCellContentText({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => ChatCellContentTextState();
}

class ChatCellContentTextState extends State<ChatCellContentText> {
  int msgSendState = MESSAGE_SEND_SUCCESS;

  int curUID = 0;
  String content = '';
  Message? lastMessage;
  String? url;

  ChatListController get controller => Get.find<ChatListController>();

  /// 解决因异步加载lastMessage慢导致的nickname为0的情况，即使之后收到lastmessageloaded通知，但nickname的uid没有变，不会rebuild nickname组件
  // final _nameState = GlobalKey<NicknameTextState>();

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr
        .on(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onMessageDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _onMessageEdit);

    objectMgr.chatMgr.on(ChatMgr.eventChatDisband, _onChatDisband);
    objectMgr.chatMgr.on(ChatMgr.eventChatIsTyping, _onChatInput);
    objectMgr.chatMgr
        .on(ChatMgr.eventChatLastMessageChanged, _onChatLastMessageLoaded);
    updateContent();
  }

  updateContent() {
    String newContent = "";
    if (!widget.chat.isDisband) {
      lastMessage = objectMgr.chatMgr.getLatestMessage(widget.chat.id);

      if (lastMessage != null &&
          lastMessage!.chat_idx > widget.chat.hide_chat_msg_idx) {
        msgSendState = lastMessage!.sendState;
        if (mounted) setState(() {});

        if (lastMessage!.sendState != MESSAGE_SEND_SUCCESS) {
          lastMessage!.on(Message.eventSendState, eventMsgSendStateChange);
        }

        url = getUrl(lastMessage);
        curUID = getCurUID(lastMessage!);
        newContent = prepareContentString(lastMessage!, curUID);
      } else {
        curUID = 0;
        url = '';
        newContent = '';
      }
    } else {
      curUID = 0;
      newContent = localized(chatThisGroupIsDisbanded);
      url = getUrl(lastMessage);
    }

    if (newContent != content) {
      content = newContent;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void eventMsgSendStateChange(_, __, Object? data) {
    if (data is Message && data.sendState != msgSendState) {
      msgSendState = data.sendState;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.chat.typ == chatTypePostNotify
        ? Container()
        : _buildMsgContent();
  }

  _onNewMessage(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat.id) {
      updateContent();
    }
  }

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message &&
        !widget.chat.isDisband &&
        data.chat_id == widget.chat.id) {
      Chat? chat = objectMgr.chatMgr.getChatById(widget.chat.id);
      if (chat != null) {
        if (chat.msg_idx == data.chat_idx) {
          setState(() {
            curUID = data.send_id;

            ///目前需求是不需要有移除emoji的消息
            content = localized(hasReactToAMessage, params: ['']);
            // if (data.typ == messageTypeAddReactEmoji) {
            //   content = '${localized(hasReactToAMessage, params: [''])}';
            // } else {
            //   content = '${localized(hasRemoveEmojiToAMessage)}';
            // }
          });
        }
      }
    }
  }

  void _onLastMessageLoaded(sender, type, data) async {
    if (widget.chat.isDisband) return;
    if (objectMgr.chatMgr.lastChatMessageMap.containsKey(widget.chat.id)) {
      updateContent();
    }
  }

  void _onChatLastMessageLoaded(sender, type, data) {
    if (widget.chat.isDisband ||
        (data is Message && data.chat_id != widget.chat.id)) return;
    _onLastMessageLoaded(sender, type, data);
  }

  void _onChatDisband(Object sender, Object type, Object? data) {
    if (data is Chat && data.id == widget.chat.id) {
      updateContent();
    }
  }

  void _onMessageDeleted(sender, type, data) async {
    if (data['id'] == widget.chat.chat_id) {
      updateContent();
      // _nameState.currentState?.updateUid(curUID);
    }
  }

  void _onMessageEdit(sender, type, data) async {
    if (data['id'] == widget.chat.chat_id) {
      updateContent();
    }
  }

  void _onChatInput(sender, type, data) {
    if (data is ChatInput && data.chatId != widget.chat.chat_id) return;
    updateContent();
  }

  String prepareContentString(Message message, int curUID) {
    bool isMe = objectMgr.userMgr.isMe(curUID);
    if (message.isEncrypted) {
      return localized(messageEncrypted);
    }

    switch (message.typ) {
      case messageTypeAddReactEmoji:
      case messageTypeRemoveReactEmoji:
        return localized(hasReactToAMessage, params: ['']);
      case messageTypePin:
      case messageTypeUnPin:
        MessagePin messagePin = message.decodeContent(cl: MessagePin.creator);
        return getPinUnpinContent(messagePin);
      case messageTypeAutoDeleteInterval:
        MessageInterval msgInterval =
            message.decodeContent(cl: MessageInterval.creator);
        return getIntervalContent(msgInterval);
      case messageTypeCreateGroup:
        return isMe
            ? localized(haveCreatedANewGroup)
            : localized(hasCreatedANewGroup);
      case messageTypeExitGroup:
        return isMe ? localized(haveLeftTheGroup) : localized(hasLeftTheGroup);
      case messageTypeGroupAddAdmin:
        return isMe
            ? localized(haveBeenPromotedToGroupAdmin)
            : localized(hasBeenPromotedToGroupAdmin);
      case messageTypeKickoutGroup:
        MessageSystem msgKickoutGroup =
            message.decodeContent(cl: MessageSystem.creator);
        return getKickoutGroupContent(msgKickoutGroup);
      case messageTypeGroupRemoveAdmin:
        return isMe
            ? localized(haveBeenDemotedToNormalMember)
            : localized(hasBeenDemotedToNormalMember);
      case messageTypeGroupJoined:
        final MessageSystem msgJoined =
            message.decodeContent(cl: MessageSystem.creator);
        String uidsStr =
            '${msgJoined.uids.length} ${localized(chatMemberJoinedThisGroup)}';
        _getInviteeName(msgJoined);
        return uidsStr;
      case messageTypeBeingFriend:
        return ' ${localized(weAreNowFriendStartChatting)}';
      case messageTypeGroupOwner:
        MessageSystem msgMultipleUid =
            message.decodeContent(cl: MessageSystem.creator);
        return getTransferOwnershipContent(msgMultipleUid);
      case messageTypeGroupChangeInfo:
        return isMe
            ? localized(haveChangedTheGroupInformation)
            : localized(hasChangedTheGroupInformation);
      case messageTypeSendRed:
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        return getSentRedPacketContent(msgRed);
      case messageTypeGetRed:
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        return getGetRedPacketContent(msgRed);
      case messageTypeGroupMute:
        return isMe
            ? localized(haveEnabledTheGroupToMute)
            : localized(hasEnabledTheGroupToMute);
      case messageTypeSysmsg:
        if (widget.chat.isGroup) {
          MessageSystem msg = message.decodeContent(cl: MessageSystem.creator);
          return msg.text;
        } else {
          return ': ${ChatHelp.lastMsg(widget.chat, message).breakWord}';
        }
      case messageBusyCall:
      case messageCancelCall:
      case messageMissedCall:
      case messageEndCall:
      case messageRejectCall:
        return ChatHelp.callMsgContent(message);
      case messageTypeAudioChatOpen:
        return localized(groupCallStart);
      case messageTypeAudioChatInvite:
        return getGroupAudioChatInvite(message.content);
      case messageTypeAudioChatClose:
        return getGroupAudioChatClose(message.content);
      case messageStartCall:
        return localized(incomingCall);
      case messageTypeNewAlbum:
        return localized(chatTagAlbum);
      case messageTypeImage:
        return localized(image);
      case messageTypeVideo:
      case messageTypeReel:
        return localized(chatVideo);
      case messageTypeTaskCreated:
        return localized(taskComing);
      case messageTypeChatScreenshotEnable:
        MessageSystem messageSystem =
            message.decodeContent(cl: MessageSystem.creator);
        if (messageSystem.isEnabled == 1) {
          return localized(screenshotTurnedOn);
        } else {
          return localized(screenshotTurnedOff);
        }
      case messageTypeChatScreenshot:
        return localized(tookScreenshotNotification);
      case messageTypeEncryptionSettingChange:
        final MessageSystem systemMsg =
        message.decodeContent(cl: MessageSystem.creator);
        String content = localized(systemMsg.isEnabledEncryption ? settingConversationTurnedOn : settingConversationTurnedOff);
        return content;
      default:
        final msg = ChatHelp.lastMsg(widget.chat, message);
        if (msg.contains(':|')) {
          return msg;
        } else {
          String str = msg.breakWord;
          return str;
        }
      // if (widget.chat.isGroup) {
      //   return '${ChatHelp.lastMsg(widget.chat, message).breakWord}';
      // } else {
      //   return ChatHelp.lastMsg(widget.chat, message).breakWord;
      // }
    }
  }

  int getCurUID(Message? lastMessage) {
    if (lastMessage != null) {
      switch (lastMessage.typ) {
        case messageTypeAddReactEmoji:
        case messageTypeRemoveReactEmoji:
          MessageReactEmoji msg =
              lastMessage.decodeContent(cl: MessageReactEmoji.creator);
          return msg.userId;
        case messageTypeSendRed:
          MessageRed msg = lastMessage.decodeContent(cl: MessageRed.creator);
          msg.senderUid = lastMessage.send_id;
          return msg.senderUid;
        case messageTypeGetRed:
          MessageRed msg = lastMessage.decodeContent(cl: MessageRed.creator);
          return msg.userId;
        case messageTypePin:
        case messageTypeUnPin:
          MessagePin msg = lastMessage.decodeContent(cl: MessagePin.creator);
          return msg.sendId;
        case messageTypeAutoDeleteInterval:
          MessageInterval msg =
              lastMessage.decodeContent(cl: MessageInterval.creator);
          return msg.owner;
        case messageTypeSysmsg:
        case messageTypeCreateGroup:
        case messageTypeBeingFriend:
        case messageTypeAudioChatOpen:
        case messageTypeAudioChatInvite:
        case messageTypeAudioChatClose:
          return lastMessage.send_id;
        case messageTypeGroupOwner:
        case messageTypeGroupAddAdmin:
        case messageTypeGroupRemoveAdmin:
        case messageTypeKickoutGroup:
        case messageTypeGroupChangeInfo:
        case messageTypeGroupMute:
          try {
            if (widget.chat.isGroup) {
              MessageSystem msg =
                  lastMessage.decodeContent(cl: MessageSystem.creator);
              return msg.uid;
            } else {
              return lastMessage.send_id;
            }
          } catch (e) {
            return lastMessage.send_id;
          }

        case messageTypeExitGroup:
          MessageSystem msg =
              lastMessage.decodeContent(cl: MessageSystem.creator);
          return msg.uid;
        case messageTypeGroupJoined:
          MessageSystem messageJoined =
              lastMessage.decodeContent(cl: MessageSystem.creator);
          return messageJoined.inviter;
        default:
          return lastMessage.send_id;
      }
    }
    return 0;
  }

  void _getInviteeName(MessageSystem messageJoined) async {
    final joinedNum = messageJoined.uids.length;

    if (joinedNum < 6) {
      String uidsStr = '';
      List<Future<User?>> futures = [];
      for (final uid in messageJoined.uids) {
        String userTitle =
            objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(uid));
        if (userTitle.isEmpty) {
          futures.add(objectMgr.userMgr.loadUserById(uid));
        } else {
          uidsStr +=
              '${(objectMgr.userMgr.isMe(uid)) ? localized(you) : userTitle}, ';
        }
      }

      List<User?> users = await Future.wait(futures);
      for (int i = 0; i < users.length; i++) {
        if (i == users.length - 1) {
          // Last item
          uidsStr +=
              '${(objectMgr.userMgr.isMe(users[i]!.uid)) ? localized(you) : users[i]?.nickname}';
        } else {
          // Not the last item
          uidsStr +=
              '${(objectMgr.userMgr.isMe(users[i]!.uid)) ? localized(you) : users[i]?.nickname}, ';
        }
      }

      if (uidsStr.endsWith(', ')) {
        uidsStr = uidsStr.substring(0, uidsStr.length - 2);
      }

      /// getInviteeName takes longer time to process
      /// double confirm if last message has been changed
      if (mounted && lastMessage?.typ == messageTypeGroupJoined) {
        setState(() {
          content = localized(chatInvited, params: [uidsStr]);
        });
      }
    }
  }

  String getPinUnpinContent(MessagePin messagePin) {
    if (objectMgr.userMgr.isMe(messagePin.sendId)) {
      return "${localized(messagePin.isPin == 1 ? havePinParamMessage : haveUnpinParamMessage, params: [
            '${messagePin.messageIds.length}'
          ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
    } else {
      return "${localized(messagePin.isPin == 1 ? hasPinParamMessage : hasUnpinParamMessage, params: [
            '${messagePin.messageIds.length}'
          ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
    }
  }

  String getIntervalContent(MessageInterval msgInterval) {
    if (msgInterval.interval == 0) {
      return ' ${localized(turnOffAutoDeleteMessage)}';
    } else if (msgInterval.interval < 60) {
      bool isSingular = msgInterval.interval == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? secondParam : secondsParam,
                params: ["${msgInterval.interval}"]))
          ])}';
    } else if (msgInterval.interval < 3600) {
      bool isSingular = msgInterval.interval ~/ 60 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? minuteParam : minutesParam,
                params: ["${msgInterval.interval ~/ 60}"]))
          ])}';
    } else if (msgInterval.interval < 86400) {
      bool isSingular = msgInterval.interval ~/ 3600 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? hourParam : hoursParam,
                params: ["${msgInterval.interval ~/ 3600}"]))
          ])}';
    } else if (msgInterval.interval < 2592000) {
      bool isSingular = msgInterval.interval ~/ 86400 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? dayParam : daysParam,
                params: ["${msgInterval.interval ~/ 86400}"]))
          ])}';
    } else {
      bool isSingular = msgInterval.interval ~/ 2592000 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? monthParam : monthsParam,
                params: ["${msgInterval.interval ~/ 2592000}"]))
          ])}';
    }
  }

  String getTransferOwnershipContent(MessageSystem msgMultipleUid) {
    bool isMe = objectMgr.userMgr.isMe(msgMultipleUid.uid);
    User? data = objectMgr.userMgr.getUserById(msgMultipleUid.owner);
    String alias = objectMgr.userMgr.getUserTitle(data);

    return isMe
        ? localized(haveTransferOwnershipTo, params: [alias])
        : localized(hasTransferOwnershipTo, params: [alias]);
  }

  String getKickoutGroupContent(MessageSystem msgKickoutGroup) {
    bool isMe = objectMgr.userMgr.isMe(curUID);

    User? user = objectMgr.userMgr.getUserById(msgKickoutGroup.owner);
    if (isMe) {
      return localized(haveBeenRemovedBy, params: [
        objectMgr.userMgr.isMe(msgKickoutGroup.owner)
            ? localized(you)
            : objectMgr.userMgr.getUserTitle(user)
      ]);
    } else {
      return localized(hasBeenRemovedBy,
          params: [objectMgr.userMgr.getUserTitle(user)]);
    }
  }

  String getSentRedPacketContent(MessageRed msgRed) {
    String message = objectMgr.userMgr.isMe(curUID)
        ? localized(haveSentA)
        : localized(hasSentA);

    switch (msgRed.rpType.value) {
      case 'LUCKY_RP':
        return "$message ${localized(luckyRedPacket)}";
      case 'STANDARD_RP':
        return "$message ${localized(normalRedPacket)}";
      case 'SPECIFIED_RP':
        return "$message ${localized(exclusiveRedPacket)}";
      default:
        return "$message ${localized(none)}";
    }
  }

  String getGetRedPacketContent(MessageRed msgRed) {
    String message = objectMgr.userMgr.isMe(msgRed.userId)
        ? localized(haveReceivedA)
        : localized(hasReceivedA);

    switch (msgRed.rpType.value) {
      case 'LUCKY_RP':
        return "$message ${localized(luckyRedPacket)}";
      case 'STANDARD_RP':
        return "$message ${localized(normalRedPacket)}";
      case 'SPECIFIED_RP':
        return "$message ${localized(exclusiveRedPacket)}";
      default:
        return "$message ${localized(none)}";
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr
        .off(ChatMgr.eventChatLastMessageChanged, _onChatLastMessageLoaded);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onMessageDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _onMessageEdit);
    objectMgr.chatMgr.off(ChatMgr.eventChatDisband, _onChatDisband);
    objectMgr.chatMgr.off(ChatMgr.eventChatIsTyping, _onChatInput);
    super.dispose();
  }

  String? getUrl(Message? lastMessage) {
    Message? msg = lastMessage;
    if (msg != null) {
      int type = msg.typ;
      switch (type) {
        case messageTypeImage:
          MessageImage bean = msg.decodeContent(cl: MessageImage.creator);
          return bean.url;
        case messageTypeVideo:
        case messageTypeReel:
          MessageVideo bean = msg.decodeContent(cl: MessageVideo.creator);
          return bean.cover;
        case messageTypeNewAlbum:
          return buildAlbum(lastMessage!);
        case messageTypeFace:
          return getTypeFace(lastMessage!);
        default:
          return null;
      }
    }
    return null;
  }

  String? buildAlbum(Message lastMessage) {
    NewMessageMedia bean =
        lastMessage.decodeContent(cl: NewMessageMedia.creator);
    List<AlbumDetailBean> list = bean.albumList ?? [];
    if (list.isNotEmpty) {
      AlbumDetailBean bean = list[0];
      if (bean.cover.isNotEmpty) {
        return bean.cover;
      }
      return bean.url;
      // String mimeType = list[0].mimeType ?? "";
      // if (mimeType.contains("image")) {
      // } else if (mimeType.contains("video")) {
      //   return getImageUrl(false, bean);
      // }
    }
    return null;
  }

  Widget _buildMsgContent() {
    final isTyping = notBlank(ChatTypingTask.whoIsTyping[widget.chat.id]);
    bool firstNameIsMe = objectMgr.userMgr.isMe(curUID);
    final textStyle = jxTextStyle.chatCellContentStyle(
        color: controller.desktopSelectedChatID.value == widget.chat.id &&
                objectMgr.loginMgr.isDesktop
            ? colorWhite
            : null,
    fontSize: 13);
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: <InlineSpan>[
          if (msgSendState != MESSAGE_SEND_SUCCESS)
            WidgetSpan(
              alignment: PlaceholderAlignment.bottom,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: ChatCellSendStatus(
                  sendState: msgSendState,
                  sendId: curUID,
                ),
              ),
            )
          else if (isTyping)
            WidgetSpan(
              child: whoIsTypingWidget(
                ChatTypingTask.whoIsTyping[widget.chat.id]!,
                jxTextStyle.chatCellContentStyle(
                    color: controller.desktopSelectedChatID.value ==
                                widget.chat.id &&
                            objectMgr.loginMgr.isDesktop
                        ? colorWhite
                        : null),
                isSingleChat: widget.chat.isSingle,
                mainAlignment: MainAxisAlignment.start,
              ),
            ),
          if (widget.chat.isGroup && curUID != 0 && !isTyping)
            TextSpan(
              text:
                  "${firstNameIsMe ? localized(chatInfoYou) : objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(curUID))}: ",
              style: textStyle,
            ),
          if (!notBlank(url) && !isTyping)
            TextSpan(
              text: content.trim(),
              style: jxTextStyle.chatCellContentStyle(
                  color: controller.desktopSelectedChatID.value ==
                              widget.chat.id &&
                          objectMgr.loginMgr.isDesktop
                      ? colorWhite
                      : null),
            )
          else if (!isTyping)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                  child: RemoteImage(
                    key: ValueKey(
                        '${lastMessage!.message_id}_${url}_${Config().headMin}'),
                    src: url!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    mini: Config().headMin,
                  ),
                ),
              ),
            )
        ],
      ),
      maxLines: 1,
      // widget.chat.typ == chatTypeSmallSecretary ||
      //         widget.chat.typ == chatTypeSingle
      //     ? 2
      //     : 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String? getTypeFace(Message message) {
    String url = json.decode(message.content)['url'];
    return url;
  }
}

String getGroupAudioChatInvite(String content) {
  final data = json.decode(content);
  String inviter = data['inviters'] ?? "";
  List invitee = data['invitee'] ?? [];
  String visitor = invitee.join(",");
  return localized(groupCallInvite, params: [inviter, visitor]);
}

String getGroupAudioChatClose(String content) {
  final data = json.decode(content);
  int totalSec = data['seconds'];
  int h = totalSec ~/ 3600;
  int m = (totalSec % 3600) ~/ 60;
  int s = totalSec % 60;
  return localized(groupCallEnd, params: ["$h", "$m", "$s"]);
}
