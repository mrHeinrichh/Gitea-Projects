import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/chat_cell_send_status.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/message_extension.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

import '../../../im/custom_content/message_widget/group_system_item.dart';
import 'chat_cell_content_text.dart';

class ChatCellContentFactory {
  static Widget createComponent({
    required Chat chat,
    required Message lastMessage,
    required int messageSendState,
  }) {
    switch (lastMessage.typ) {
      case messageTypeImage:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeFace:
      case messageTypeGif:
      case messageTypeNewAlbum:
        return _processMediaContent(chat, lastMessage, messageSendState);
      case messageTypeGroupJoined:
        return _processGroupJoinContent(chat, lastMessage, messageSendState);
      default:
        return _processTextContent(chat, lastMessage, messageSendState);
    }
  }

  static Widget _processMediaContent(
      Chat chat, Message lastMessage, int messageSendState) {
    String url = '';
    switch (lastMessage.typ) {
      case messageTypeImage:
        MessageImage bean = lastMessage.decodeContent(cl: MessageImage.creator);
        url = bean.url;
        break;
      case messageTypeVideo:
      case messageTypeReel:
        MessageVideo bean = lastMessage.decodeContent(cl: MessageVideo.creator);
        url = bean.cover;
        break;
      case messageTypeNewAlbum:
        NewMessageMedia bean =
            lastMessage.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = bean.albumList ?? [];
        if (list.isNotEmpty) {
          url = list[0].cover.isNotEmpty ? list[0].cover : list[0].url;
        }
        break;
      case messageTypeFace:
      case messageTypeGif:
        url = jsonDecode(lastMessage.content)['url'];
        break;
      default:
        return const SizedBox();
    }

    return DefaultTextStyle(
      style: jxTextStyle.chatCellContentStyle(),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            if (lastMessage.sendState != MESSAGE_SEND_SUCCESS)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: ChatCellSendStatus(
                    sendState: messageSendState,
                    sendId: lastMessage.send_id,
                  ),
                ),
              ),
            if (chat.isGroup && lastMessage.send_id != 0)
              TextSpan(
                text:
                    "${objectMgr.userMgr.isMe(lastMessage.send_id) ? localized(chatInfoYou) : objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(lastMessage.send_id))}: ",
              ),
            if (url.isEmpty)
              TextSpan(text: _processTextMessage(lastMessage).trim())
            else
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    child: RemoteImage(
                      key: ValueKey(
                          '${lastMessage.message_id}_${url}_${Config().headMin}'),
                      src: url,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                      mini: Config().headMin,
                    ),
                  ),
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget _processGroupJoinContent(
      Chat chat, Message lastMessage, int messageSendState) {
    final MessageSystem systemMsg =
        lastMessage.decodeContent(cl: MessageSystem.creator);
    int uid = systemMsg.inviter;
    String inviter = getUserNickName(lastMessage.chat_id, uid);
    final joinedNum = systemMsg.uids.length;
    if (joinedNum < 6) {
      List<String> memberName = [];
      for (final uid in systemMsg.uids) {
        String name = getUserNickName(lastMessage.chat_id, uid);
        memberName.add(name);
      }

      return DefaultTextStyle(
        style: jxTextStyle.chatCellContentStyle(),
        child: Text('$inviter${localized(chatInvited, params: [
              memberName.join(", ")
            ])}'),
      );
    } else {
      return DefaultTextStyle(
        style: jxTextStyle.chatCellContentStyle(),
        child: Text(inviter +
            localized(chatInvite) +
            '${systemMsg.uids.length} ${localized(chatMemberJoinedThisGroup)}'),
      );
    }
  }

  static String getUserNickName(chat_id, uid) {
    String nick_name = "";
    if (uid == 0) {
      return nick_name;
    }
    bool isMe = objectMgr.userMgr.isMe(uid);
    if (isMe) {
      nick_name = localized(you);
    } else {
      nick_name =
          objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(uid));
    }
    if (nick_name == "") {
      var group = objectMgr.myGroupMgr.getGroupById(chat_id);
      if (group != null) {
        var member = group.getGroupMemberByMemberID(uid);
        if (member != null) {
          nick_name = member.user_name;
        }
      }
    }
    if (nick_name == "") {
      nick_name = uid.toString();
    }
    return nick_name;
  }

  static Widget _processTextContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
  ) {
    int uid = 0;
    String content = '';

    switch (lastMessage.typ) {
      case messageTypeAddReactEmoji:
      case messageTypeRemoveReactEmoji:
        MessageReactEmoji messageEmoji =
            lastMessage.decodeContent(cl: MessageReactEmoji.creator);
        uid = messageEmoji.userId;
        content = '${localized(hasReactToAMessage, params: [''])}';
        break;
      case messageTypePin:
      case messageTypeUnPin:
        MessagePin messagePin =
            lastMessage.decodeContent(cl: MessagePin.creator);
        uid = messagePin.sendId;
        final isMe = objectMgr.userMgr.isMe(messagePin.sendId);
        if (isMe) {
          content =
              "${localized(messagePin.isPin == 1 ? havePinParamMessage : haveUnpinParamMessage, params: [
                '${messagePin.messageIds.length}'
              ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
        } else {
          content =
              "${localized(messagePin.isPin == 1 ? hasPinParamMessage : hasUnpinParamMessage, params: [
                '${messagePin.messageIds.length}'
              ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
        }
        break;
      case messageTypeAutoDeleteInterval:
        MessageInterval msgInterval =
            lastMessage.decodeContent(cl: MessageInterval.creator);
        uid = msgInterval.owner;
        if (msgInterval.interval == 0) {
          content = ' ${localized(turnOffAutoDeleteMessage)}';
        } else if (msgInterval.interval < 60) {
          bool isSingular = msgInterval.interval == 1;
          content = ' ${localized(turnOnAutoDeleteMessage, params: [
                "${localized(isSingular ? secondParam : secondsParam, params: [
                      "${msgInterval.interval}"
                    ])}"
              ])}';
        } else if (msgInterval.interval < 3600) {
          bool isSingular = msgInterval.interval ~/ 60 == 1;
          content = ' ${localized(turnOnAutoDeleteMessage, params: [
                "${localized(isSingular ? minuteParam : minutesParam, params: [
                      "${msgInterval.interval ~/ 60}"
                    ])}"
              ])}';
        } else if (msgInterval.interval < 86400) {
          bool isSingular = msgInterval.interval ~/ 3600 == 1;
          content = ' ${localized(turnOnAutoDeleteMessage, params: [
                "${localized(isSingular ? hourParam : hoursParam, params: [
                      "${msgInterval.interval ~/ 3600}"
                    ])}"
              ])}';
        } else if (msgInterval.interval < 2592000) {
          bool isSingular = msgInterval.interval ~/ 86400 == 1;
          content = ' ${localized(turnOnAutoDeleteMessage, params: [
                "${localized(isSingular ? dayParam : daysParam, params: [
                      "${msgInterval.interval ~/ 86400}"
                    ])}"
              ])}';
        } else {
          bool isSingular = msgInterval.interval ~/ 2592000 == 1;
          content = ' ${localized(turnOnAutoDeleteMessage, params: [
                "${localized(isSingular ? monthParam : monthsParam, params: [
                      "${msgInterval.interval ~/ 2592000}"
                    ])}"
              ])}';
        }
        break;

      case messageTypeSendRed:
        MessageRed msgRed = lastMessage.decodeContent(cl: MessageRed.creator);
        uid = lastMessage.send_id;
        String message = objectMgr.userMgr.isMe(uid)
            ? localized(haveSentA)
            : localized(hasSentA);

        switch (msgRed.rpType.value) {
          case 'LUCKY_RP':
            content = "$message ${localized(luckyRedPacket)}";
            break;
          case 'STANDARD_RP':
            content = "$message ${localized(normalRedPacket)}";
            break;
          case 'SPECIFIED_RP':
            content = "$message ${localized(exclusiveRedPacket)}";
            break;
          default:
            content = "$message ${localized(none)}";
            break;
        }
        break;
      case messageTypeGetRed:
        MessageRed msgRed = lastMessage.decodeContent(cl: MessageRed.creator);
        uid = msgRed.userId;
        final isMe = objectMgr.userMgr.isMe(msgRed.userId);
        String message =
            isMe ? localized(haveReceivedA) : localized(hasReceivedA);

        switch (msgRed.rpType.value) {
          case 'LUCKY_RP':
            content = "$message ${localized(luckyRedPacket)}";
            break;
          case 'STANDARD_RP':
            content = "$message ${localized(normalRedPacket)}";
            break;
          case 'SPECIFIED_RP':
            content = "$message ${localized(exclusiveRedPacket)}";
            break;
          default:
            content = "$message ${localized(none)}";
            break;
        }
        break;

      // todo: 整合到一起
      case messageTypeCreateGroup:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String create_name = getUserNickName(lastMessage.chat_id, uid);
        bool isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? create_name + localized(haveCreatedANewGroup)
            : create_name + localized(hasCreatedANewGroup);
        break;
      case messageTypeExitGroup:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        final isMe = objectMgr.userMgr.isMe(uid);
        String nickname = getUserNickName(lastMessage.chat_id, uid);
        content = isMe
            ? localized(you) + localized(haveLeftTheGroup)
            : nickname + localized(hasLeftTheGroup);
        break;
      case messageTypeGroupAddAdmin:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String add_admin_name = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? add_admin_name + localized(haveBeenPromotedToGroupAdmin)
            : add_admin_name + localized(hasBeenPromotedToGroupAdmin);
        break;
      case messageTypeGroupRemoveAdmin:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String mov_admin_name = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? mov_admin_name + localized(haveBeenDemotedToNormalMember)
            : mov_admin_name + localized(hasBeenDemotedToNormalMember);
        break;
      case messageTypeGroupChangeInfo:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String change_info_name = getUserNickName(lastMessage.chat_id, uid);
        final isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? change_info_name + localized(msgGroupInfoHaveChanged)
            : change_info_name + localized(msgGroupInfoChanged);
        break;
      case messageTypeKickoutGroup:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        String kickname = getUserNickName(lastMessage.chat_id, systemMsg.uid);

        var isMe = objectMgr.userMgr.isMe(systemMsg.owner);
        if (isMe) {
          content = localized(sysHaveBeenRemovedBy, params: [
            kickname,
            objectMgr.userMgr.isMe(systemMsg.owner)
                ? localized(you)
                : getUserNickName(lastMessage.chat_id, systemMsg.owner)
          ]);
        } else {
          content = localized(sysHasBeenRemovedBy, params: [
            kickname,
            getUserNickName(lastMessage.chat_id, systemMsg.owner)
          ]);
        }
        break;
      case messageTypeGroupOwner:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String old_owner_name = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        String alias = getUserNickName(lastMessage.chat_id, systemMsg.owner);
        content = isMe
            ? old_owner_name +
                localized(haveTransferOwnershipTo, params: [alias])
            : old_owner_name +
                localized(hasTransferOwnershipTo, params: [alias]);
        break;
      case messageTypeGroupMute:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String mute_name = getUserNickName(lastMessage.chat_id, uid);
        bool isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? mute_name + localized(haveEnabledTheGroupToMute)
            : mute_name + localized(hasEnabledTheGroupToMute);
        break;
      case messageTypeChatScreenshot:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String name = getUserNickName(lastMessage.chat_id, uid);
        ScreenshotMessage screenshotMessageMsg = ScreenshotMessage();
        content = name + screenshotMessageMsg.getMessageContent();
        break;
      case messageTypeChatScreenshotEnable:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String name = getUserNickName(lastMessage.chat_id, uid);
        ScreenshotSettingMessage screenshotSettingMessageMsg =
            ScreenshotSettingMessage(systemMsg.isEnabled == 1);
        content = name + screenshotSettingMessageMsg.getMessageContent();
        break;
      case messageTypeBetOpening:
        content = ChatHelp.formalizeMentionBetOpening(lastMessage);
        break;
      case messageTypeBetClosed:
        content = ChatHelp.formalizeMentionBetClosed(lastMessage);
        break;
      case messageTypeBetStatistics:
        content = localized(betStats);
        break;
      case messageTypeTransferMoneySuccess:
        content = localized(transferMoney);
        break;
      case messageTypeFollowBet:
        content = localized(chatTypeFollowBet);
        break;
      case messageTypeOpenLottery:
        content = localized(chatTypeOpenLottery);
        break;
      case messageTypeWinLottery:
        content = localized(chatTypeWinLottery);
        break;
      case messageTypeIpo:
      case messageTypeAddShareholders:
      case messageTypeKickShareholders:
      case messageTypeTransferToGroup:
      case messageTypeReduceShareholder:
      case messageTypeTransferToApp:
      case messageTypeIpoUser:
      case messageTypeProfit:
      case messageTypeAddOperator:
      case messageTypeDelOperator:
      case messageTypeAddFinancier:
      case messageTypeDelFinancier:
      case messageTypeGroupAppStateChange:
      case messageTypeGroupMessageChange:
      case messageTypeGroupAutoTurnChange:
      case messageTypeAddShareholder:
        content = lastMessage.extractVipGroupContent();
        break;
      case messageTypeAudioChatOpen:
        content = localized(groupCallStart);
      case messageTypeAudioChatInvite:
        content = getGroupAudioChatInvite(lastMessage.content);
      case messageTypeAudioChatClose:
        content = getGroupAudioChatClose(lastMessage.content);
      default:
        uid = lastMessage.send_id;
        content = _processTextMessage(lastMessage);
        break;
    }
    String name = getUserNickName(lastMessage.chat_id, lastMessage.send_id);
    if (name != "") {
      name = name + ": ";
    }

    return DefaultTextStyle(
      style: jxTextStyle.chatCellContentStyle(color: JXColors.secondaryTextBlackSolid),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            if (lastMessage.sendState != MESSAGE_SEND_SUCCESS)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: ChatCellSendStatus(
                    sendState: messageSendState,
                    sendId: lastMessage.send_id,
                  ),
                ),
              ),
            if (chat.isGroup) TextSpan(text: "$name"),
            TextSpan(
              text: content.trim(),
              // style: EmojiParser.hasOnlyEmojis(content.trim()) ?
              //     jxTextStyle.chatCellContentStyle(color: JXColors.black) : null
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static String _processTextMessage(Message lastMessage) {
    switch (lastMessage.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        MessageText _textData =
            lastMessage.decodeContent(cl: MessageText.creator);
        return ChatHelp.formalizeMentionContent(_textData.text, lastMessage);
      case messageTypeImage:
        return localized(chatTagPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return localized(chatTagVideoCall);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);
      case messageTypeNewAlbum:
        return localized(chatTagAlbum);
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeVoice:
        return localized(chatTagVoiceCall);
      case messageTypeFile:
        return localized(chatTagFile);
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeTaskCreated:
        return localized(taskComing);

      case messageTypeAudioChatOpen:
        return localized(groupCallStart);
      case messageStartCall:
        return localized(incomingCall);
      case messageBusyCall:
      case messageCancelCall:
      case messageMissedCall:
      case messageEndCall:
      case messageRejectCall:
        return ChatHelp.callMsgContent(lastMessage);
      case messageTypeBeingFriend:
        return ' ${localized(weAreNowFriendStartChatting)}';

      default:
        return '';
    }
  }
}
