import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_call.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_custom.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_favourite.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_friend_link.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_auto_delete_interval.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_chat_black.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_chat_contact.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_encrypted.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_file.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_gif.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_image.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_link.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_location.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_mini_app.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_new_album.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_ping_message.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_record.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_red_packet.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_red_packet_received.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_secretary_recommend.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_sticker.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_system.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_text.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_video.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_link_text.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_markdown.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_task_created.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_temp_group_system.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_time_item.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_transfer_money.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_unreadbar.dart';
import 'package:jxim_client/object/chat/message.dart';

import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_mini_app_share.dart';

class MessageItemFactory {
  static Widget createComponent({
    required Message message,
    required int index,
    bool isPrevious = true,
    required String tag,
    bool isPinOpen = false,
  }) {
    if (message.isDeleted ||
        message.isExpired ||
        message.typ == messageStartCall) {
      return const SizedBox();
    }

    if (message.isEncrypted && !message.isSystemMsg) {
      //消息为加密状态，大于所有的信息类型 //系统消息不列入考量
      return MessageItemUIGroupEncrypted(
        key: ValueKey('chat_${message.create_time}_${message.id}'),
        message: message,
        index: index,
        isPrevious: isPrevious,
        tag: tag,
      );
    }
    switch (message.typ) {
      case messageTypeDate:
        return MessageItemUITimeItem(
          message: message,
          index: index,
          isPrevious: isPrevious,
          isPinOpen: isPinOpen,
          tag: tag,
        );
      case messageTypeText:
      case messageTypeReply:
      case messageTypeReplyWithdraw:
        return MessageItemUIGroupText(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );

      case messageTypeLink:
        return MessageItemUILinkText(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );

      case messageTypeSysmsg:
      case messageTypeCreateGroup:
      case messageTypeBeingFriend:
      case messageTypeExitGroup:
      case messageTypeGroupAddAdmin:
      case messageTypeGroupRemoveAdmin:
      case messageTypeGroupMute:
      case messageTypeGroupChangeInfo:
      case messageTypeGroupJoined:
      case messageTypeKickoutGroup:
      case messageTypeAudioChatOpen:
      case messageTypeAudioChatInvite:
      case messageTypeAudioChatClose:
      case messageTypeGroupOwner:
      case messageTypeChatScreenshot:
      case messageTypeChatScreenshotEnable:
      case messageTypeEncryptionSettingChange:
        return MessageItemUIGroupSystem(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeImage:
        return MessageItemUIGroupImage(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeVideo:
      case messageTypeReel:
        return MessageItemUIGroupVideo(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeFile:
        return MessageItemUIGroupFile(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeVoice:
        return MessageItemUIGroupRecord(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeSendRed:
        return MessageItemUIGroupRedPacket(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeTransferMoneySuccess:
        return MessageItemUITransferMoney(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          tag: tag,
        );
      case messageTypeGetRed:
        return MessageItemUIGroupRedPacketReceived(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeNewAlbum:
        return Hero(
          tag: 'hero_${message.create_time}_${message.id}',
          child: MessageItemUIGroupNewAlbum(
            key: ValueKey('chat_${message.create_time}_${message.id}'),
            message: message,
            index: index,
            isPrevious: isPrevious,
            tag: tag,
          ),
        );
      case messageTypePin:
      case messageTypeUnPin:
        return MessageItemUIGroupPinMessage(
          message: message,
          isPrevious: isPrevious,
          index: index,
          tag: tag,
        );
      case messageTypeRecommendFriend:

      /// 成员名片
        return MessageItemUIGroupChatContact(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeFriendLink:
        return MessageItemUIFriendLink(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeGroupLink:
        return MessageItemUIGroupLink(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeBlack:
        return MessageItemUIGroupChatBlack(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeSecretaryRecommend:
        return MessageItemUIGroupSecretaryRecommend(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          tag: tag,
        );
      case messageEndCall:
      case messageRejectCall:
      case messageCancelCall:
      case messageMissedCall:
      case messageBusyCall:
        return MessageItemUICall(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          index: index,
          isPrevious: isPrevious,
          message: message,
          tag: tag,
        );
      case messageTypeFace:
        return MessageItemUIGroupSticker(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeGif:
        return MessageItemUIGroupGif(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeAutoDeleteInterval:
        return MessageItemUIGroupAutoDeleteInterval(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          isPrevious: isPrevious,
          index: index,
          tag: tag,
        );
      case messageTypeUnreadBar:
        return MessageItemUIUnreadBar(
          message: message,
          isPrevious: isPrevious,
          index: index,
          tag: tag,
          key: ValueKey('chat_${message.create_time}_${message.id}'),
        );
      case messageTypeLocation:
        return MessageItemUIGroupLocation(
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeTaskCreated:
        return MessageItemUITaskCreated(
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeExpiryTimeUpdate:
      case messageTypeExpiredSoon:
        return MessageItemUITempGroupSystem(
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeInBlock:
      case messageTypeNotFriend:
        return MessageItemUICustom(message: message, index: index, tag: tag);
      case messageTypeMarkdown:
        return MessageItemUIMarkdown(
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeNote:
      case messageTypeChatHistory:
        return MessageItemUIFavourite(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeShareChat:
        return MessageItemUIGroupMiniAppShare(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeMiniAppDetail:
        return MessageItemUIGroupMiniApp(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      default:
        return const SizedBox();
    }
  }
}
