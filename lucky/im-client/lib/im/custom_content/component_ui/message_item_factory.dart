import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_call.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_auto_delete_interval.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_chat_black.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_chat_contact.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_file.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_gif.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_image.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_location.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_ping_message.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_record.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_new_album.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_red_packet.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_red_packet_received.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_secretary_recommend.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_sticker.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_system.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_text.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_video.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_group_video_attachment.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_task_created.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_time_item.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_transfer_money.dart';
import 'package:jxim_client/im/custom_content/component_ui/message_item_ui_unreadbar.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'message_item_ui_type_bet_closed.dart';
import 'message_item_ui_type_bet_opening.dart';
import 'message_item_ui_type_bet_statistics.dart';
import 'message_item_ui_type_follow_bet.dart';
import 'message_item_ui_type_group_text.dart';
import 'message_item_ui_type_win_lottery.dart';

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
        !message.isShow ||
        message.typ == messageStartCall) {
      return const SizedBox();
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
      case messageTypeLink:
        return MessageItemUIGroupText(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
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
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeVideo:
      case messageTypeReel:
        return MessageItemUIGroupVideo(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
        );
      case messageTypeLiveVideo:
        return MessageItemUIGroupVideoAttachment(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          index: index,
          message: message,
          isPrevious: isPrevious,
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
        return MessageItemUIGroupNewAlbum(
          key: ValueKey('chat_${message.create_time}_${message.id}'),
          message: message,
          index: index,
          isPrevious: isPrevious,
          tag: tag,
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
      case messageTypeBetClosed:
        return MessageItemUITypeBetClosed(
          key: ValueKey('chat_${message.send_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeBetOpening:
        return MessageItemUITypeBetOpening(
          key: ValueKey('chat_${message.send_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeFollowBet:
        return MessageItemUITypeFollowBet(
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeBetStatistics:
        return MessageItemUITypeBetStatistics(
          key: ValueKey('chat_${message.send_time}_${message.id}'),
          message: message,
          index: index,
          tag: tag,
        );
      case messageTypeWinLottery:
        return MessageItemUITypeWinLottery(
          message: message,
          index: index,
          tag: tag,
        );

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
        return MessageItemUITypeGroupText(
          message: message,
          index: index,
          tag: tag,
        );

      default:
        return const SizedBox();
    }
  }
}
