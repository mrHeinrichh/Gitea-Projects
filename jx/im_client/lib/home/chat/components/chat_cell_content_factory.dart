import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/home/chat/component/chat_cell_send_status.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_system_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class ChatCellContentFactory {
  static Widget createComponent({
    required Chat chat,
    required Message lastMessage,
    required int messageSendState,
    bool isVoicePlayed = false,
    String searchText = '',
    bool displayNickname = true, //if false -> 不管是单聊还是群聊都隐藏nickname
  }) {
    if (lastMessage.isEncrypted) {
      return _processEncryptedContent(
        chat,
        lastMessage,
        messageSendState,
      );
    }

    switch (lastMessage.typ) {
      case messageTypeImage:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeNewAlbum:
        return _processMediaContent(
            chat, lastMessage, messageSendState, searchText, displayNickname);
      case messageTypeEncryptionSettingChange:
        return _processGroupEncryptionSettingChangeContent(
            chat, lastMessage, messageSendState);
      case messageTypeGroupJoined:
        return _processGroupJoinContent(chat, lastMessage, messageSendState);
      case messageEndCall: // 11001
      case messageRejectCall: //11002
      case messageBusyCall: //1002
      case messageCancelCall: //1003
      case messageMissedCall: //1004
        return _processCallContent(chat, lastMessage, messageSendState);
      case messageTypeVoice:
        return _processVoiceContent(
          chat,
          lastMessage,
          messageSendState,
          displayNickname,
          isVoicePlayed: isVoicePlayed,
        );
      case messageTypeFile:
        return _processFileContent(
          chat,
          lastMessage,
          messageSendState,
          searchText,
          displayNickname,
        );
      default:
        return _processTextContent(
          chat,
          lastMessage,
          messageSendState,
          searchText,
          displayNickname,
        );
    }
  }

  static Widget _processMediaContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
    String searchText,
    bool displayNickname,
  ) {
    String caption = '';
    List<Map<String, dynamic>> urlList = <Map<String, dynamic>>[];
    bool hasForward = false;
    switch (lastMessage.typ) {
      case messageTypeImage:
        MessageImage bean = lastMessage.decodeContent(cl: MessageImage.creator);
        caption = bean.caption.isNotEmpty
            ? lastMessage.textAfterMention
            : localized(chatTagPhoto);
        urlList.add({
          'url': bean.url,
          'filePath': bean.filePath,
          'isVideo': false,
        });
        hasForward = bean.forward_user_id != 0;
        break;
      case messageTypeVideo:
      case messageTypeReel:
        MessageVideo bean = lastMessage.decodeContent(cl: MessageVideo.creator);
        caption = bean.caption.isNotEmpty
            ? lastMessage.textAfterMention
            : localized(chatTagVideoCall);
        urlList.add({
          'url': bean.cover,
          'filePath': bean.coverPath,
          'isVideo': bean.cover.isNotEmpty,
        });
        hasForward = bean.forward_user_id != 0;
        break;
      case messageTypeNewAlbum:
        NewMessageMedia bean =
            lastMessage.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = bean.albumList ?? [];
        bool isImage = true;
        bool isVideo = true;

        for (int i = 0; i < list.length; i++) {
          if (list[i].cover.isNotEmpty || list[i].coverPath.isNotEmpty) {
            isImage = false;
          } else {
            isVideo = false;
          }

          if (urlList.length < 3) {
            urlList.add({
              'url': list[i].cover.isNotEmpty ? list[i].cover : list[i].url,
              'filePath': list[i].coverPath.isNotEmpty
                  ? list[i].coverPath
                  : list[i].filePath,
              'isVideo': list[i].coverPath.isNotEmpty,
            });
          }
        }

        if (!isImage && !isVideo) {
          caption = localized(chatTagAlbum);
        } else if (!isImage) {
          caption = localized(
            chatTagVideoMultiple,
            params: [list.length.toString()],
          );
        } else {
          caption = localized(
            chatTagImageMultiple,
            params: [list.length.toString()],
          );
        }

        if (bean.caption.isNotEmpty) {
          caption = lastMessage.textAfterMention;
        }

        hasForward = bean.forward_user_id != 0;
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
          if (displayNickname && chat.isGroup && lastMessage.send_id != 0)
            TextSpan(
              text:
                  "${objectMgr.userMgr.isMe(lastMessage.send_id) ? localized(chatInfoYou) : objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(lastMessage.send_id), groupId: chat.chat_id)}: ",
            ),
          if (hasForward)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/svgs/chat_forward_fill_icon.svg',
                  height: 20.0,
                  width: 20.0,
                  colorFilter: const ColorFilter.mode(
                    colorTextSupporting,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          if (urlList.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  urlList.length,
                  (i) {
                    bool showFile = false;
                    bool showCover =
                        urlList[i]['isVideo'] != null && urlList[i]['isVideo'];

                    if (urlList[i]['url'].isEmpty) {
                      showFile = true;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (showFile)
                              Image.file(
                                File(urlList[i]['filePath']),
                                key: ValueKey(
                                  '${lastMessage.message_id}_${urlList[i]['filePath']}',
                                ),
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                cacheWidth: 20,
                                cacheHeight: 20,
                              )
                            else
                              RemoteImage(
                                key: ValueKey(
                                  '${lastMessage.message_id}_${urlList[i]['url']}_${Config().headMin}',
                                ),
                                src: urlList[i]['url'],
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                mini: Config().headMin,
                              ),
                            if (showCover)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: colorTextSecondary,
                                ),
                              ),
                            if (showCover)
                              SvgPicture.asset(
                                'assets/svgs/chat_play_icon.svg',
                                width: 12.0,
                                height: 12.0,
                                colorFilter: const ColorFilter.mode(
                                  colorWhite,
                                  BlendMode.srcIn,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          TextSpan(
            children: getHighlightSpanList(
              caption,
              searchText,
              jxTextStyle.chatCellContentStyle(),
              needCut: notBlank(searchText),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processGroupEncryptionSettingChangeContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
  ) {
    final MessageSystem systemMsg =
        lastMessage.decodeContent(cl: MessageSystem.creator);
    String content = localized(systemMsg.isEnabledEncryption
        ? settingConversationTurnedOn
        : settingConversationTurnedOff);
    return DefaultTextStyle(
      style: jxTextStyle.chatCellContentStyle(),
      child: Text(content),
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
        child: Text('$inviter ${localized(
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
          '$inviter ${localized(chatInvite)} ${systemMsg.uids.length} ${localized(chatMemberJoinedThisGroup)}',
        ),
      );
    }
  }

  static String getUserNickName(int? chatId, int? uid) {
    String nickName = "";
    if (uid == null || uid == 0) {
      return nickName;
    }
    bool isMe = objectMgr.userMgr.isMe(uid);
    if (isMe) {
      nickName = localized(you);
    } else {
      nickName =
          objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(uid));
      if (chatId != null) {
        var group = objectMgr.myGroupMgr.getGroupById(chatId);
        if (group != null) {
          nickName = objectMgr.userMgr.getUserTitle(
              objectMgr.userMgr.getUserById(uid),
              groupId: chatId);
        }
      }
      if (nickName == "") {
        nickName = uid.toString();
      }
    }
    return nickName;
  }

  static Widget _processEncryptedContent(
      Chat chat, Message lastMessage, int messageSendState) {
    String content = getEncryptionText(lastMessage, chat);
    int uid = lastMessage.send_id;
    String name = getUserNickName(lastMessage.chat_id, uid);
    if (name.isNotEmpty) {
      name = name + ": ";
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
          if (chat.isGroup) TextSpan(text: name),
          TextSpan(
              text: content.trim(), style: jxTextStyle.chatCellContentStyle()),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processVoiceContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
    bool displayNickname, {
    bool isVoicePlayed = false,
  }) {
    final MessageVoice v = lastMessage.decodeContent(cl: MessageVoice.creator);
    String content = localized(chatTagVoiceCall) +
        " " +
        constructTime(
          v.second ~/ 1000,
          showHour: false,
        );
    String imageName = "icon_voice" + (isVoicePlayed ? "_played" : "");
    bool hasForward = _processForwardStatus(lastMessage);
    int uid = lastMessage.send_id;
    String name = getUserNickName(lastMessage.chat_id, uid);
    if (name.isNotEmpty) {
      name = name + ": ";
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
          if (displayNickname && chat.isGroup) TextSpan(text: name),
          if (hasForward)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/svgs/chat_forward_fill_icon.svg',
                  height: 20.0,
                  width: 20.0,
                  colorFilter: const ColorFilter.mode(
                    colorTextSupporting,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: SvgPicture.asset(
                'assets/svgs/$imageName.svg',
                height: 20.0,
                width: 20.0,
              ),
            ),
          ),
          TextSpan(
              text: content.trim(), style: jxTextStyle.chatCellContentStyle()),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processFileContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
    String searchText,
    bool displayNickname,
  ) {
    int? groupId;
    if (chat.isGroup) {
      groupId = chat.chat_id;
    }
    String content = _processTextMessage(lastMessage, groupId: groupId);

    String name = getUserNickName(lastMessage.chat_id, lastMessage.send_id);
    if (name != "") {
      name = name + ": ";
    }

    bool hasForward = _processForwardStatus(lastMessage);

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
          if (displayNickname && chat.isGroup) TextSpan(text: name),
          if (hasForward)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/svgs/chat_forward_fill_icon.svg',
                  height: 20.0,
                  width: 20.0,
                  colorFilter: const ColorFilter.mode(
                    colorTextSupporting,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SvgPicture.asset(
              'assets/svgs/attachment_file.svg',
              width: 16.0,
              height: 16.0,
              colorFilter: const ColorFilter.mode(
                colorTextSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          TextSpan(
            children: getHighlightSpanList(
              content.trim(),
              searchText,
              jxTextStyle.chatCellContentStyle(),
            ),
          )
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processCallContent(
      Chat chat, Message lastMessage, int messageSendState) {
    final MessageCall c = lastMessage.decodeContent(cl: MessageCall.creator);
    String content = "";
    String imageName = c.is_videocall == 1 ? "icon_video_call" : "icon_call";
    String callerReceiver =
        objectMgr.userMgr.isMe(c.inviter) ? "_caller" : "_receiver";
    String takenCallOrRejected = "";

    switch (lastMessage.typ) {
      case messageEndCall: //通话完成
        content = c.is_videocall == 1
            ? localized(attachmentCallVideo)
            : localized(attachmentCallVoice);
        break;
      case messageBusyCall: // 占线
      case messageCancelCall: // 拒接？
      case messageMissedCall: // 未接
      case messageRejectCall: // 拒接
      default:
        content = localized(missedCall);
        takenCallOrRejected =
            objectMgr.userMgr.isMe(c.inviter) ? "" : "_rejected";
        break;
    }

    String imageFull = "$imageName$takenCallOrRejected$callerReceiver";

    return RichText(
      text: TextSpan(
        style: jxTextStyle.chatCellContentStyle(),
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: SvgPicture.asset(
                'assets/svgs/$imageFull.svg',
                height: 20.0,
                width: 20.0,
                // colorFilter: const ColorFilter.mode(
                //   colorTextSupporting,
                //   BlendMode.srcIn,
                // ),
              ),
            ),
          ),
          TextSpan(
              text: content.trim(), style: jxTextStyle.chatCellContentStyle()),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _processTextContent(
    Chat chat,
    Message lastMessage,
    int messageSendState,
    String searchText,
    bool displayNickname,
  ) {
    int uid = 0;
    String content = '';
    int? extraUid;

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
        String nickname = '';
        if (!chat.isGroup) {
          nickname = '${getUserNickName(lastMessage.chat_id, uid)} ';
        }
        final isMe = objectMgr.userMgr.isMe(messagePin.sendId);
        if (isMe) {
          content = "$nickname${localized(
            messagePin.isPin == 1 ? havePinParamMessage : haveUnpinParamMessage,
            params: [
              '${messagePin.messageIds.length}',
            ],
          )}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
        } else {
          content = "$nickname${localized(
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
        String nickname = '';
        if (!chat.isGroup) {
          nickname = getUserNickName(lastMessage.chat_id, uid);
        }
        if (msgInterval.interval == 0) {
          content = '$nickname ${localized(turnOffAutoDeleteMessage)}';
        } else if (msgInterval.interval < 60) {
          bool isSingular = msgInterval.interval == 1;
          content = '$nickname ${localized(
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
          content = '$nickname ${localized(
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
          content = '$nickname ${localized(
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
          content = '$nickname ${localized(
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
          content = '$nickname ${localized(
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
        switch (msgRed.rpType.value) {
          case 'LUCKY_RP':
            content = "[${localized(luckyRedPacket)}] ${msgRed.remark}";
            break;
          case 'STANDARD_RP':
            content = "[${localized(normalRedPacket)}] ${msgRed.remark}";
            break;
          case 'SPECIFIED_RP':
            content = "[${localized(exclusiveRedPacket)}] ${msgRed.remark}";
            break;
          default:
            content = "[${localized(none)}] ${msgRed.remark}";
            break;
        }
        break;
      case messageTypeGetRed:
        MessageRed msgRed = lastMessage.decodeContent(cl: MessageRed.creator);
        uid = msgRed.userId;
        extraUid = msgRed.userId;
        final isMe = objectMgr.userMgr.isMe(msgRed.userId);
        String message =
            isMe ? localized(haveReceivedA) : localized(hasReceivedA);

        switch (msgRed.rpType.value) {
          case 'LUCKY_RP':
            content =
                "$message [${localized(luckyRedPacket)}] ${msgRed.remark}";
            break;
          case 'STANDARD_RP':
            content =
                "$message [${localized(normalRedPacket)}] ${msgRed.remark}";
            break;
          case 'SPECIFIED_RP':
            content =
                "$message [${localized(exclusiveRedPacket)}] ${msgRed.remark}";
            break;
          default:
            content = "$message [${localized(none)}] ${msgRed.remark}";
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
        final MessageTransferMoney c =
            lastMessage.decodeContent(cl: MessageTransferMoney.creator);
        content = '${localized(chatTagTransferMoney)} ${c.remark}';
        break;
      case messageTypeExpiredSoon:
        MessageTempGroupSystem systemMsg =
            lastMessage.decodeContent(cl: MessageTempGroupSystem.creator);
        content = localized(
          thisGroupWillBeAutoDisbanded,
          params: [formatToLocalTime(systemMsg.expire_time)],
        );
        break;
      case messageTypeExpiryTimeUpdate:
        MessageTempGroupSystem systemMsg =
            lastMessage.decodeContent(cl: MessageTempGroupSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(systemMsg.uid);
        if (isMe) {
          content = localized(
            youHaveChangedTheGroupExpiryDate,
            params: [
              localized(you),
              formatToLocalTime(systemMsg.expire_time),
            ],
          );
        } else {
          int? groupId;
          if (chat.isGroup) {
            groupId = chat.chat_id;
          }
          String name = objectMgr.userMgr.getUserTitle(
              objectMgr.userMgr.getUserById(systemMsg.uid),
              groupId: groupId);
          content = localized(
            youHaveChangedTheGroupExpiryDate,
            params: [name, formatToLocalTime(systemMsg.expire_time)],
          );
        }
        break;
      default:
        uid = lastMessage.send_id;
        int? groupId;
        if (chat.isGroup) {
          groupId = chat.chat_id;
        }
        content = _processTextMessage(lastMessage, groupId: groupId);
        break;
    }
    String name = getUserNickName(lastMessage.chat_id, uid);
    if (name == "") {
      //处理其他特例 比如谁收到了红包 取的不是send_id字段而是其他字段
      name = getUserNickName(lastMessage.chat_id, extraUid ?? 0);
    }
    if (name != "") {
      name = name + ": ";
    }

    bool hasForward = _processForwardStatus(lastMessage);

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
          if (displayNickname && chat.isGroup) TextSpan(text: name),
          if (hasForward)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/svgs/chat_forward_fill_icon.svg',
                  height: 20.0,
                  width: 20.0,
                  colorFilter: const ColorFilter.mode(
                    colorTextSupporting,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          TextSpan(
            children: getHighlightSpanList(
              content.trim(),
              searchText,
              jxTextStyle.chatCellContentStyle(),
              needCut: notBlank(searchText),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static bool _processForwardStatus(Message lastMessage) {
    switch (lastMessage.typ) {
      case messageTypeText:
      case messageTypeReply:
        final MessageText c =
            lastMessage.decodeContent(cl: MessageText.creator);

        return c.forward_user_id != 0;
      case messageTypeLink:
        final MessageLink c =
            lastMessage.decodeContent(cl: MessageLink.creator);

        return c.forwardUserId != 0;
      case messageTypeVoice:
        final MessageVoice c =
            lastMessage.decodeContent(cl: MessageVoice.creator);
        return c.forward_user_id != 0;
      case messageTypeFile:
        final MessageFile c =
            lastMessage.decodeContent(cl: MessageFile.creator);
        return c.forward_user_id != 0;
      case messageTypeRecommendFriend:
        final MessageJoinGroup c =
            lastMessage.decodeContent(cl: MessageJoinGroup.creator);
        return c.forward_user_id != 0;
      case messageTypeLocation:
        final MessageMyLocation c =
            lastMessage.decodeContent(cl: MessageMyLocation.creator);
        return c.forward_user_id != 0;
      case messageTypeFace:
      case messageTypeGif:
        final MessageImage c =
            lastMessage.decodeContent(cl: MessageImage.creator);
        return c.forward_user_id != 0;
      default:
        return false;
    }
  }

  static String _processTextMessage(Message lastMessage, {int? groupId}) {
    switch (lastMessage.typ) {
      case messageTypeText:
      case messageTypeReply:
      // show translated message
        String? translatedContent = lastMessage.getTranslationFromMessage();

        final MessageText textData =
            lastMessage.decodeContent(cl: MessageText.creator);
        return ChatHelp.formalizeMentionContent(
          translatedContent ?? textData.text,
          lastMessage,
          groupId: groupId,
        );
      case messageTypeLink:
        // show translated message
        String? translatedContent = lastMessage.getTranslationFromMessage();

        final MessageLink textData =
            lastMessage.decodeContent(cl: MessageLink.creator);
        return ChatHelp.formalizeMentionContent(
          translatedContent ?? textData.text,
          lastMessage,
          groupId: groupId,
        );
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeFriendLink:
        final MessageFriendLink textData =
            lastMessage.decodeContent(cl: MessageFriendLink.creator);
        return textData.short_link;
      case messageTypeGroupLink:
        final MessageGroupLink textData =
            lastMessage.decodeContent(cl: MessageGroupLink.creator);
        return textData.short_link;
      case messageTypeFile:
        final MessageFile c =
            lastMessage.decodeContent(cl: MessageFile.creator);
        return c.file_name.isEmpty ? localized(chatTagFile) : c.file_name;
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeTaskCreated:
        return localized(taskComing);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);
      case messageTypeAudioChatOpen:
        return localized(groupCallStart);
      case messageStartCall:
        return localized(incomingCall);
      case messageTypeBeingFriend:
        return ' ${localized(weAreNowFriendStartChatting)}';
      case messageTypeMarkdown:
        final MessageMarkdown m =
            lastMessage.decodeContent(cl: MessageMarkdown.creator);
        return "${localized(publishTag)} ${m.title}";
      case messageTypeNote:
      case messageTypeChatHistory:
        final MessageFavourite m =
            lastMessage.decodeContent(cl: MessageFavourite.creator);
        String title = m.title;
        if (lastMessage.typ == messageTypeNote) {
          return "[${localized(noteEditTitle)}] $title";
        } else {
          return "[${localized(chatHistory)}] $title";
        }
      case messageTypeMiniAppDetail:
        String str =lastMessage.content;
        Map<String,dynamic> map =  jsonDecode(str);
        return map["title"];
      case messageTypeShareChat:
        String str =lastMessage.content;
        Map<String,dynamic> map =  jsonDecode(str);
        String title =map['mini_app_title']??"--";
        return title;
      default:
        return '';
    }
  }
}
