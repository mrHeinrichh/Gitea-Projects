// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class FavouriteReplyComponent extends StatelessWidget {
  const FavouriteReplyComponent({
    super.key,
    required this.replyModel,
    required this.isGroup,
    required this.sendId,
  });

  final ReplyModel replyModel;
  final bool isGroup;
  final int sendId;

  @override
  Widget build(BuildContext context) {
    var body = _replyMsg(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isGroup && !objectMgr.userMgr.isMe(sendId)
            ? groupMemberColor(replyModel.userId).withOpacity(0.08)
            : objectMgr.userMgr.isMe(sendId)
                ? bubblePrimary.withOpacity(0.08)
                : themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 3,
            color: isGroup && !objectMgr.userMgr.isMe(sendId)
                ? groupMemberColor(replyModel.userId)
                : objectMgr.userMgr.isMe(sendId)
                    ? bubblePrimary
                    : themeColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8),
              child: body,
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
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// reply nickname
              NicknameText(
                uid: replyModel.userId,
                fontWeight: MFontWeight.bold5.value,
                isRandomColor: isGroup && !objectMgr.userMgr.isMe(sendId),
                color:
                    objectMgr.userMgr.isMe(sendId) ? bubblePrimary : themeColor,
                isTappable: false,
                fontSize: bubbleNicknameSize,
              ),

              /// reply message
              Linkify(
                text: replyModel.text,
                style: jxTextStyle.replyBubbleTextStyle(),
                linkStyle: jxTextStyle.replyBubbleLinkTextStyle(
                  isSender: !objectMgr.userMgr.isMe(sendId),
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
      case messageTypeFriendLink:
      case messageTypeGroupLink:
      case messageTypeGif:
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeNewAlbum:
      case messageTypeSendRed:
      case messageTypeTransferMoneySuccess:
        // _constraints = _constraints!.copyWith(minWidth: 150.w);
        final msgType = replyModel.typ;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msgType != messageTypeSendRed &&
                msgType != messageTypeFriendLink &&
                msgType != messageTypeGroupLink &&
                msgType != messageTypeTransferMoneySuccess)
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
          isRandomColor: isGroup && !objectMgr.userMgr.isMe(sendId),
          color: objectMgr.userMgr.isMe(sendId) ? bubblePrimary : themeColor,
          fontWeight: MFontWeight.bold5.value,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
        ),
        Text(
          replyMessageContent(),
          style: jxTextStyle.replyBubbleTextStyle(),
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
      case messageTypeRecommendFriend:
        return localized(chatTagNameCard);
      case messageTypeFace:
        return localized(chatTagSticker);
      case messageTypeGif:
        return localized(chatTagGif);

      case messageTypeSendRed:
        return localized(chatTagRedPacket);
      case messageTypeTransferMoneySuccess:
        return localized(chatTagTransferMoney);
      case messageTypeLocation:
        return localized(chatTagLocation);
      case messageTypeFriendLink:
        return localized(chatTagFriendLink);
      case messageTypeGroupLink:
        return localized(chatTagGroupLink);
      default:
        return '';
    }
  }
}
