import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/chat_cell_send_status.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

import 'package:jxim_client/im/custom_content/message_widget/group_system_item.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';

class NotificationCellContentFactory {
  static Widget createTitle(Chat? chat, String title, String name) {
    String displayName =
        "${(chat?.isGroup ?? false) ? "$name@" : ""}${chat?.name ?? title}";
    if ((chat?.typ ?? 0) == chatTypeSmallSecretary) {
      displayName = localized(chatSecretary);
    } else if ((chat?.typ ?? 0) == chatTypeSystem) {
      displayName = localized(homeSystemMessage);
    } else if ((chat?.typ ?? 0) == chatTypeSaved) {
      displayName = localized(homeSavedMessage);
    }
    return NicknameText(
      uid: chat?.friend_id ?? 0,
      displayName: displayName,
      fontSize: MFontSize.size16.value,
      fontWeight: MFontWeight.bold5.value,
      color: colorTextPrimary.withOpacity(1),
      isTappable: false,
      overflow: TextOverflow.ellipsis,
      fontSpace: 0,
    );
  }

  static Widget createSubtitle(String content, {int maxLine = 1}) {
    return RichText(
      text: TextSpan(
        style: jxTextStyle.chatCellContentStyle(color: colorTextSecondarySolid),
        children: <InlineSpan>[
          TextSpan(
            text: content,
          ),
        ],
      ),
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget createAvatar(Chat? chat, double iconSize) {
    if (chat == null) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
      );
    } else if (chat.typ == chatTypeSystem) {
      return SystemMessageIcon(
        size: iconSize,
      );
    } else if (chat.typ == chatTypeSmallSecretary) {
      return SecretaryMessageIcon(
        size: iconSize,
      );
    } else if (chat.typ == chatTypeSaved) {
      return SavedMessageIcon(
        size: iconSize,
      );
    } else {
      return CustomAvatar.chat(
        chat,
        size: iconSize,
        headMin: Config().headMin,
        fontSize: 24.0,
        shouldAnimate: false,
      );
    }
  }

  static Widget createComponent({
    required Chat chat,
    required Message lastMessage,
    required int messageSendState,
    required double mediaContentSize,
  }) {
    switch (lastMessage.typ) {
      case messageTypeImage:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeFace:
      case messageTypeGif:
      case messageTypeNewAlbum:
        return _processMediaContent(
          chat,
          lastMessage,
          messageSendState,
          mediaContentSize,
        );
      case messageTypeGroupJoined:
        return _processGroupJoinContent(chat, lastMessage, messageSendState);
      default:
        return _processTextContent(chat, lastMessage, messageSendState);
    }
  }

  static Widget _processMediaContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
    double mediaContentSize,
  ) {
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

    return RichText(
      text: TextSpan(
        style: jxTextStyle.chatCellContentStyle(),
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
          if (url.isEmpty)
            TextSpan(text: _processTextMessage(lastMessage).trim())
          else
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RemoteImage(
                        key: ValueKey(
                          '${lastMessage.message_id}_${url}_${Config().headMin}',
                        ),
                        src: url,
                        width: mediaContentSize,
                        height: mediaContentSize,
                        fit: BoxFit.cover,
                        mini: Config().headMin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processGroupJoinContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
  ) {
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
        child: Text('$inviter${localized(
          chatInvited,
          params: [
            memberName.join(", "),
          ],
        )}'),
      );
    } else {
      return DefaultTextStyle(
        style: jxTextStyle.chatCellContentStyle(),
        child: Text(
          '$inviter${localized(chatInvite)}${systemMsg.uids.length} ${localized(chatMemberJoinedThisGroup)}',
        ),
      );
    }
  }

  static String getUserNickName(chatId, uid) {
    String nickName = "";
    if (uid == 0) {
      return nickName;
    }
    bool isMe = objectMgr.userMgr.isMe(uid);
    if (isMe) {
      nickName = localized(you);
    } else {
      nickName =
          objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(uid));
    }
    if (nickName == "") {
      var group = objectMgr.myGroupMgr.getGroupById(chatId);
      if (group != null) {
        var member = group.getGroupMemberByMemberID(uid);
        if (member != null) {
          nickName = member.userName;
        }
      }
    }
    if (nickName == "") {
      nickName = uid.toString();
    }
    return nickName;
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
        content = localized(hasReactToAMessage, params: ['']);
        break;
      case messageTypePin:
      case messageTypeUnPin:
        MessagePin messagePin =
            lastMessage.decodeContent(cl: MessagePin.creator);
        uid = messagePin.sendId;
        final isMe = objectMgr.userMgr.isMe(messagePin.sendId);
        if (isMe) {
          content = "${localized(
            messagePin.isPin == 1 ? havePinParamMessage : haveUnpinParamMessage,
            params: [
              '${messagePin.messageIds.length}',
            ],
          )}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
        } else {
          content = "${localized(
            messagePin.isPin == 1 ? hasPinParamMessage : hasUnpinParamMessage,
            params: [
              '${messagePin.messageIds.length}',
            ],
          )}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
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
          content = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? secondParam : secondsParam,
                params: [
                  "${msgInterval.interval}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 3600) {
          bool isSingular = msgInterval.interval ~/ 60 == 1;
          content = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? minuteParam : minutesParam,
                params: [
                  "${msgInterval.interval ~/ 60}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 86400) {
          bool isSingular = msgInterval.interval ~/ 3600 == 1;
          content = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? hourParam : hoursParam,
                params: [
                  "${msgInterval.interval ~/ 3600}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 2592000) {
          bool isSingular = msgInterval.interval ~/ 86400 == 1;
          content = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? dayParam : daysParam,
                params: [
                  "${msgInterval.interval ~/ 86400}",
                ],
              )),
            ],
          )}';
        } else {
          bool isSingular = msgInterval.interval ~/ 2592000 == 1;
          content = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? monthParam : monthsParam,
                params: [
                  "${msgInterval.interval ~/ 2592000}",
                ],
              )),
            ],
          )}';
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

      case messageTypeCreateGroup:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String createName = getUserNickName(lastMessage.chat_id, uid);
        bool isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? createName + localized(haveCreatedANewGroup)
            : createName + localized(hasCreatedANewGroup);
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
        String addAdminName = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? addAdminName + localized(haveBeenPromotedToGroupAdmin)
            : addAdminName + localized(hasBeenPromotedToGroupAdmin);
        break;
      case messageTypeGroupRemoveAdmin:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String movAdminName = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? movAdminName + localized(haveBeenDemotedToNormalMember)
            : movAdminName + localized(hasBeenDemotedToNormalMember);
        break;
      case messageTypeGroupChangeInfo:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String changeInfoName = getUserNickName(lastMessage.chat_id, uid);
        final isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? changeInfoName + localized(msgGroupInfoHaveChanged)
            : changeInfoName + localized(msgGroupInfoChanged);
        break;
      case messageTypeKickoutGroup:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        String kickname = getUserNickName(lastMessage.chat_id, systemMsg.uid);

        var isMe = objectMgr.userMgr.isMe(systemMsg.owner);
        if (isMe) {
          content = localized(
            sysHaveBeenRemovedBy,
            params: [
              kickname,
              objectMgr.userMgr.isMe(systemMsg.owner)
                  ? localized(you)
                  : getUserNickName(lastMessage.chat_id, systemMsg.owner),
            ],
          );
        } else {
          content = localized(
            sysHasBeenRemovedBy,
            params: [
              kickname,
              getUserNickName(lastMessage.chat_id, systemMsg.owner),
            ],
          );
        }
        break;
      case messageTypeGroupOwner:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String oldOwnerName = getUserNickName(lastMessage.chat_id, uid);
        var isMe = objectMgr.userMgr.isMe(uid);
        String alias = getUserNickName(lastMessage.chat_id, systemMsg.owner);
        content = isMe
            ? oldOwnerName + localized(haveTransferOwnershipTo, params: [alias])
            : oldOwnerName + localized(hasTransferOwnershipTo, params: [alias]);
        break;
      case messageTypeGroupMute:
        MessageSystem systemMsg =
            lastMessage.decodeContent(cl: MessageSystem.creator);
        uid = systemMsg.uid;
        String muteName = getUserNickName(lastMessage.chat_id, uid);
        bool isMe = objectMgr.userMgr.isMe(uid);
        content = isMe
            ? muteName + localized(haveEnabledTheGroupToMute)
            : muteName + localized(hasEnabledTheGroupToMute);
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
      case messageTypeAudioChatOpen:
        content = localized(groupCallStart);
      case messageTypeAudioChatInvite:
        content = getGroupAudioChatInvite(lastMessage.content);
      case messageTypeAudioChatClose:
        content = getGroupAudioChatClose(lastMessage.content);
      case messageTypeTransferMoneySuccess:
        content = localized(transferMoney);
        break;
      default:
        uid = lastMessage.send_id;
        content = _processTextMessage(lastMessage);
        break;
    }
    String name = getUserNickName(lastMessage.chat_id, lastMessage.send_id);
    if (name != "") {
      name = "$name: ";
    }

    return RichText(
      text: TextSpan(
        style: jxTextStyle.chatCellContentStyle(color: colorTextSecondarySolid),
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
          TextSpan(
            text: content.trim(),
            // style: EmojiParser.hasOnlyEmojis(content.trim()) ?
            //     jxTextStyle.chatCellContentStyle(color: colorTextPrimary) : null
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _processTextMessage(Message lastMessage) {
    switch (lastMessage.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:

        // show translated message
        String? translatedContent = lastMessage.getTranslationFromMessage();

        MessageText textData =
            lastMessage.decodeContent(cl: MessageText.creator);
        return ChatHelp.formalizeMentionContent(
          translatedContent ?? textData.text,
          lastMessage,
        );
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
