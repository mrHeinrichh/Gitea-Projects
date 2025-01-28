import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupSystemItem extends StatefulWidget {
  const GroupSystemItem({
    super.key,
    required this.message,
    required this.messageSystem,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  final Message message;
  final MessageSystem messageSystem;
  final Chat chat;
  final int index;
  final bool isPrevious;

  @override
  State<GroupSystemItem> createState() => _GroupSystemItemState();
}

class _GroupSystemItemState extends MessageWidgetMixin<GroupSystemItem> {
  late ChatContentController controller;

  bool get isGroup => controller.chatController.chat.isGroup;

  bool get isTempGroup => controller.chatController.chat.isTmpGroup;

  bool get showTempFirstSysMsg {
    if (widget.chat.isTmpGroup) {
      if (widget.message.typ == messageTypeCreateGroup) {
        if (objectMgr.userMgr.isMe(widget.messageSystem.uid)) return true;
      } else if (widget.message.typ == messageTypeGroupJoined) {
        if (widget.messageSystem.uids
            .contains(objectMgr.userMgr.mainUser.uid)) {
          return true;
        }
      }
    }

    return false;
  }

  SystemMessage? systemMessage;
  String msg = "";

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
    systemMessage = SystemMessage(
      widget.messageSystem.uid,
      widget.message.typ,
      objectMgr.userMgr.isMe(widget.messageSystem.uid),
      widget.messageSystem.owner,
      widget.messageSystem.uids,
      widget.messageSystem.isEnabled,
      widget.chat.chat_id,
      widget.chat.isGroup,
    );
    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    if (widget.message.typ == messageTypeAudioChatOpen) {
      msg = localized(groupCallStart);
    } else if (widget.message.typ == messageTypeAudioChatInvite) {
      msg = getGroupAudioChatInvite(widget.message.content);
    } else if (widget.message.typ == messageTypeAudioChatClose) {
      msg = getGroupAudioChatClose(widget.message.content);
    } else if (widget.message.typ == messageTypeEncryptionSettingChange) {
      msg = getEncryptionSettingChange(widget.message);
    }
  }

  String getEncryptionSettingChange(Message message) {
    final MessageSystem systemMsg =
        message.decodeContent(cl: MessageSystem.creator);
    String content = localized(systemMsg.isEnabledEncryption
        ? chatTurnOnEncryption
        : chatTurnOffEncryption);
    return content;
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

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['isClear'] == true) {
      return;
    }

    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    super.dispose();
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      if (data.uid == widget.messageSystem.uid ||
          data.uid == widget.messageSystem.inviter ||
          data.uid == widget.messageSystem.owner ||
          widget.messageSystem.uids.contains(data.uid)) {
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool firstNameIsMe = objectMgr.userMgr.isMe(
      widget.messageSystem.inviter != 0
          ? widget.messageSystem.inviter
          : widget.messageSystem.uid,
    );
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Column(
              children: [
                Visibility(
                  visible: showTempFirstSysMsg,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: jxDimension.systemMessageMargin(context),
                      padding: jxDimension.systemMessagePadding(),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        color: colorTextPrimary.withOpacity(0.65),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 3.0),
                                child: SvgPicture.asset(
                                  'assets/svgs/temporary_indicator.svg',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.fill,
                                  color: colorWhite,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: localized(
                                afterLeavingTheGroup,
                                params: [
                                  controller.getExpireTime(widget.chat.chat_id),
                                ],
                              ),
                              style: jxTextStyle.normalSmallText(
                                  color: colorBrightPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: jxDimension.systemMessageMargin(context),
                    padding: jxDimension.systemMessagePadding(),
                    decoration: const ShapeDecoration(
                      shape: StadiumBorder(),
                      color: colorTextSupporting,
                    ),
                    child: Text(
                      '${firstNameIsMe ? localized(you) : getPrefixText()} ${widget.message.typ == messageTypeAudioChatOpen || widget.message.typ == messageTypeAudioChatInvite || widget.message.typ == messageTypeAudioChatClose || widget.message.typ == messageTypeEncryptionSettingChange ? msg : systemMessage!.getMessageContent()}',
                      style: jxTextStyle.normalSmallText(
                        color: colorBrightPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String getPrefixText() {
    if (widget.message.typ == messageTypeBeingFriend) {
      return "";
    }
    return objectMgr.userMgr.getUserTitle(
      objectMgr.userMgr.getUserById(
        widget.messageSystem.inviter != 0
            ? widget.messageSystem.inviter
            : widget.messageSystem.uid,
      ),
      groupId: isGroup ? widget.chat.chat_id : null,
    );
  }
}

abstract class SystemMessage {
  factory SystemMessage(
    int senderId,
    int type,
    bool isMe,
    int owner,
    List<int> uids,
    int isEnabled,
    int chatId,
    bool isGroup,
  ) {
    switch (type) {
      case messageTypeCreateGroup:
        return CreateGroupMessage(isMe);
      case messageTypeExitGroup:
        return ExitGroupMessage(isMe);
      case messageTypeGroupAddAdmin:
        return GroupAddAdminMessage(isMe);
      case messageTypeGroupRemoveAdmin:
        return GroupRemoveAdminMessage(isMe);
      case messageTypeBeingFriend:
        return BeingFriendMessage(isMe);
      case messageTypeGroupChangeInfo:
        return GroupChangeInfo(isMe);
      case messageTypeGroupMute:
        return GroupMuteMessage(isMe);
      case messageTypeKickoutGroup:
        return GroupKickOutMemberMessage(owner, isMe, chatId, isGroup);
      case messageTypeGroupJoined:
        return GroupJoinedMessage(isMe, uids, chatId, isGroup);
      case messageTypeGroupOwner:
        return GroupTransferOwnershipMessage(isMe, owner, chatId, isGroup);
      case messageTypeChatScreenshot:
        return ScreenshotMessage();
      case messageTypeChatScreenshotEnable:
        return ScreenshotSettingMessage(isEnabled == 1);
      default:
        return CreateGroupMessage(isMe);
    }
  }

  String getMessageContent();
}

class CreateGroupMessage implements SystemMessage {
  final bool isMe;

  CreateGroupMessage(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(haveCreatedANewGroup);
    } else {
      return localized(hasCreatedANewGroup);
    }
  }
}

class ExitGroupMessage implements SystemMessage {
  final bool isMe;

  ExitGroupMessage(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(haveLeftTheGroup);
    } else {
      return localized(hasLeftTheGroup);
    }
  }
}

class GroupAddAdminMessage implements SystemMessage {
  final bool isMe;

  GroupAddAdminMessage(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(haveBeenPromotedToGroupAdmin);
    } else {
      return localized(hasBeenPromotedToGroupAdmin);
    }
  }
}

class GroupRemoveAdminMessage implements SystemMessage {
  final bool isMe;

  GroupRemoveAdminMessage(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(haveBeenDemotedToNormalMember);
    } else {
      return localized(hasBeenDemotedToNormalMember);
    }
  }
}

class BeingFriendMessage implements SystemMessage {
  final bool isMe;

  BeingFriendMessage(this.isMe);

  @override
  String getMessageContent() {
    return localized(weAreNowFriendStartChatting);
  }
}

class GroupChangeInfo implements SystemMessage {
  final bool isMe;

  GroupChangeInfo(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(msgGroupInfoHaveChanged);
    } else {
      return localized(msgGroupInfoChanged);
    }
  }
}

class GroupMuteMessage implements SystemMessage {
  final bool isMe;

  GroupMuteMessage(this.isMe);

  @override
  String getMessageContent() {
    if (isMe) {
      return localized(haveEnabledTheGroupToMute);
    } else {
      return localized(hasEnabledTheGroupToMute);
    }
  }
}

class GroupKickOutMemberMessage implements SystemMessage {
  final int senderId;
  final bool isMe;
  final int chatId;
  final bool isGroup;

  GroupKickOutMemberMessage(
      this.senderId, this.isMe, this.chatId, this.isGroup);

  @override
  String getMessageContent() {
    User? user = objectMgr.userMgr.getUserById(senderId);
    if (user == null) {
      objectMgr.userMgr.loadUserById2(senderId);
    }
    if (isMe) {
      return localized(
        haveBeenRemovedBy,
        params: [
          objectMgr.userMgr.isMe(user?.uid ?? -1)
              ? localized(you)
              : objectMgr.userMgr.getUserTitle(
                  user,
                  groupId: isGroup ? chatId : null,
                ),
        ],
      );
    } else {
      return localized(
        hasBeenRemovedBy,
        params: [
          objectMgr.userMgr.isMe(user?.uid ?? -1)
              ? localized(you)
              : objectMgr.userMgr.getUserTitle(
                  user,
                  groupId: isGroup ? chatId : null,
                ),
        ],
      );
    }
  }
}

class GroupTransferOwnershipMessage implements SystemMessage {
  final bool isMe;
  final int owner;
  final int chatId;
  final bool isGroup;

  GroupTransferOwnershipMessage(
      this.isMe, this.owner, this.chatId, this.isGroup);

  @override
  String getMessageContent() {
    User? user = objectMgr.userMgr.getUserById(owner);
    if (user == null) {
      objectMgr.userMgr.loadUserById2(owner);
    }
    if (isMe) {
      return localized(
        haveTransferOwnershipTo,
        params: [
          objectMgr.userMgr.getUserTitle(
            user,
            groupId: isGroup ? chatId : null,
          )
        ],
      );
    } else {
      return localized(
        hasTransferOwnershipTo,
        params: [
          objectMgr.userMgr.getUserTitle(
            user,
            groupId: isGroup ? chatId : null,
          )
        ],
      );
    }
  }
}

class GroupJoinedMessage implements SystemMessage {
  final bool isMe;
  final List<int> uids;
  final int chatId;
  final bool isGroup;

  GroupJoinedMessage(this.isMe, this.uids, this.chatId, this.isGroup);

  /// xxx has been removed by yyy from the group
  @override
  String getMessageContent() {
    String uidsStr = '';
    if (uids.length < 6) {
      for (final uid in uids) {
        if (objectMgr.userMgr.getUserById(uid) == null) {
          objectMgr.userMgr.loadUserById2(uid, notify: true);
        } else {
          uidsStr +=
              '${(objectMgr.userMgr.isMe(uid)) ? localized(you) : objectMgr.userMgr.getUserTitle(
                  objectMgr.userMgr.getUserById(uid),
                  groupId: isGroup ? chatId : null,
                )}, ';
        }
      }
    } else {
      uidsStr = ' ${uids.length} ${localized(chatMemberJoinedThisGroup)}';
    }

    if (uidsStr.endsWith(', ')) {
      uidsStr = uidsStr.substring(0, uidsStr.length - 2);
    }

    return localized(chatInvited, params: [uidsStr]);
  }
}

class ScreenshotMessage implements SystemMessage {
  ScreenshotMessage();

  @override
  String getMessageContent() {
    return localized(tookScreenshot);
  }
}

class ScreenshotSettingMessage implements SystemMessage {
  final bool isEnable;

  ScreenshotSettingMessage(this.isEnable);

  @override
  String getMessageContent() {
    return localized(isEnable ? screenshotTurnedOn : screenshotTurnedOff);
  }
}
