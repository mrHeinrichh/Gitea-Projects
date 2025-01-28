import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/main.dart';

class GroupReplyItem extends StatelessWidget {
  const GroupReplyItem({
    Key? key,
    required this.replyModel,
    required this.message,
    required this.chat,
    required this.maxWidth,
    required this.controller,
  }) : super(key: key);

  final ReplyModel replyModel;
  final Message message;
  final Chat chat;
  final double maxWidth;
  final ChatContentController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: !objectMgr.userMgr.isMe(message.send_id)
            ? groupMemberColor(replyModel.userId).withOpacity(0.08)
            : JXColors.chatBubbleMeReplyLabelColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 3,
            color: !objectMgr.userMgr.isMe(message.send_id)
                ? groupMemberColor(replyModel.userId)
                : JXColors.chatBubbleMeReplyLabelColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8),
              child: _replyMsg(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyMsg(BuildContext context) {
    switch (replyModel.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// reply nickname
              NicknameText(
                uid: replyModel.userId,
                fontWeight: MFontWeight.bold5.value,
                isRandomColor: !objectMgr.userMgr.isMe(message.send_id),
                color: JXColors.chatBubbleMeReplyTitleColor,
                isTappable: false,
              ),

              /// reply message
              Linkify(
                text: replyModel.text,
                style: jxTextStyle.replyBubbleTextStyle(
                  isSender: !objectMgr.userMgr.isMe(message.send_id),
                ),
                linkStyle: jxTextStyle.replyBubbleLinkTextStyle(
                  isSender: !objectMgr.userMgr.isMe(message.send_id),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

      case messageTypeFile:
      case messageTypeVoice:
      case messageTypeRecommendFriend:
        return _buildReplyContent();
      case messageTypeImage:
      case messageTypeFace:
      case messageTypeLocation:
      case messageTypeGif:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeNewAlbum:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: replyModel.typ == messageTypeFace
                    ? Colors.transparent
                    : hexColor(0xF4F4F4),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: RemoteImage(
                src: replyModel.url,
                width: 40,
                height: 40,
                mini: Config().headMin,
                fit: BoxFit.cover,
                shouldAnimate: replyModel.typ != messageTypeFace,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(child: _buildReplyContent()),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildReplyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NicknameText(
          uid: replyModel.userId,
          isRandomColor: !objectMgr.userMgr.isMe(message.send_id),
          color: JXColors.chatBubbleMeReplyTitleColor,
          fontWeight: MFontWeight.bold5.value,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
        ),
        Text(
          replyMessageContent(),
          style: jxTextStyle.replyBubbleTextStyle(
            isSender: !objectMgr.userMgr.isMe(message.send_id),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  String replyMessageContent() {
    switch (replyModel.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return replyModel.text;
      case messageTypeImage:
        return replyModel.text.isNotEmpty
            ? '${localized(replyPhoto)} ${replyModel.text}'
            : localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return replyModel.text.isNotEmpty
            ? '${localized(replyVideo)} ${replyModel.text}'
            : localized(replyVideo);
      case messageTypeNewAlbum:
        return replyModel.text.isNotEmpty
            ? '${localized(chatTagAlbum)} ${replyModel.text}'
            : localized(chatTagAlbum);
      case messageTypeFile:
        return localized(chatTagFile);
      case messageTypeVoice:
        return localized(replyVoice);
      case messageTypeLiveVideo:
        return localized(chatTagLiveVideo);
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);

      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeLocation:
        return localized(chatTagLocation);
      default:
        return '';
    }
  }
}
