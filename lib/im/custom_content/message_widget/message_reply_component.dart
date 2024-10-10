// ignore_for_file: must_be_immutable

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class MessageReplyComponent extends StatefulWidget {
  const MessageReplyComponent({
    super.key,
    required this.replyModel,
    required this.message,
    required this.chat,
    required this.maxWidth,
    required this.controller,
  });

  final ReplyModel replyModel;
  final Message message;
  final Chat chat;
  final double maxWidth;
  final ChatContentController controller;

  @override
  State<MessageReplyComponent> createState() => _MessageReplyComponentState();
}

class _MessageReplyComponentState extends State<MessageReplyComponent> {
  BoxConstraints? _constraints;

  Uint8List? gausPath;

  @override
  void initState() {
    super.initState();

    _constraints = BoxConstraints(maxWidth: widget.maxWidth - 24.w);

    if (widget.message.isMediaType) {
      _preloadImageSync();
    }
  }

  _preloadImageSync() {
    switch (widget.message.typ) {
      case messageTypeImage:
        final MessageImage imgC =
            widget.message.decodeContent(cl: MessageImage.creator);
        gausPath = imgC.gausBytes;
        break;
      case messageTypeVideo:
        final MessageVideo videoC =
            widget.message.decodeContent(cl: MessageVideo.creator);
        gausPath = videoC.gausBytes;
        break;
      default:
        break;
    }

    String? thumbPath = downloadMgr.checkLocalFile(
      widget.replyModel.url,
      mini: Config().headMin,
    );

    if (thumbPath != null) {
      gausPath = null;
      if (mounted) setState(() {});
      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    final thumbPath = await downloadMgr.downloadFile(
      widget.replyModel.url,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      gausPath = null;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var body = _replyMsg(context);
    return Container(
      // width: maxWidth,
      clipBehavior: Clip.hardEdge,
      constraints: _constraints,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.chat.isGroup &&
                !objectMgr.userMgr.isMe(widget.message.send_id)
            ? groupMemberColor(widget.replyModel.userId).withOpacity(0.08)
            : objectMgr.userMgr.isMe(widget.message.send_id)
                ? bubblePrimary.withOpacity(0.08)
                : themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 3,
            color: widget.chat.isGroup &&
                    !objectMgr.userMgr.isMe(widget.message.send_id)
                ? groupMemberColor(widget.replyModel.userId)
                : objectMgr.userMgr.isMe(widget.message.send_id)
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
    switch (widget.replyModel.typ) {
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
                uid: widget.replyModel.userId,
                fontWeight: MFontWeight.bold5.value,
                isRandomColor: widget.chat.isGroup &&
                    !objectMgr.userMgr.isMe(widget.message.send_id),
                color: objectMgr.userMgr.isMe(widget.message.send_id)
                    ? bubblePrimary
                    : themeColor,
                isTappable: false,
                fontSize: bubbleNicknameSize,
                groupId: widget.chat.isGroup ? widget.chat.id : null,
              ),

              /// reply message
              Linkify(
                text: widget.replyModel.text,
                style: jxTextStyle.replyBubbleTextStyle(),
                linkStyle: jxTextStyle.replyBubbleLinkTextStyle(
                  isSender: !objectMgr.userMgr.isMe(widget.message.send_id),
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
      case messageTypeNote:
      case messageTypeChatHistory:
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
        final msgType = widget.replyModel.typ;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msgType != messageTypeSendRed &&
                msgType != messageTypeFriendLink &&
                msgType != messageTypeGroupLink &&
                msgType != messageTypeTransferMoneySuccess)
              Stack(
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 50),
                    switchInCurve: Curves.easeOut,
                    child: gausPath != null
                        ? Container(
                            key: ValueKey('reply_gaus_${widget.replyModel.id}'),
                            width: 40,
                            height: 40,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: widget.replyModel.typ == messageTypeFace
                                  ? Colors.transparent
                                  : hexColor(0xF4F4F4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Image.memory(
                              gausPath!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            key: ValueKey('reply_${widget.replyModel.id}'),
                            width: 40,
                            height: 40,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: widget.replyModel.typ == messageTypeFace
                                  ? Colors.transparent
                                  : hexColor(0xF4F4F4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: RemoteImage(
                              src: widget.replyModel.url,
                              width: 40,
                              height: 40,
                              mini: Config().headMin,
                              fit: BoxFit.cover,
                              shouldAnimate:
                                  widget.replyModel.typ != messageTypeFace,
                            ),
                          ),
                  )
                ],
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
          uid: widget.replyModel.userId,
          isRandomColor: widget.chat.isGroup &&
              !objectMgr.userMgr.isMe(widget.message.send_id),
          color: objectMgr.userMgr.isMe(widget.message.send_id)
              ? bubblePrimary
              : themeColor,
          fontWeight: MFontWeight.bold5.value,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
          groupId: widget.chat.isGroup ? widget.chat.id : null,
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
    switch (widget.replyModel.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return widget.replyModel.text;
      case messageTypeImage:
        return widget.replyModel.text.isNotEmpty
            ? '${localized(replyPhoto)} ${widget.replyModel.text}'
            : localized(replyPhoto);
      case messageTypeVideo:
      case messageTypeReel:
        return widget.replyModel.text.isNotEmpty
            ? '${localized(replyVideo)} ${widget.replyModel.text}'
            : localized(replyVideo);
      case messageTypeNewAlbum:
        return widget.replyModel.text.isNotEmpty
            ? '${localized(chatTagAlbum)} ${widget.replyModel.text}'
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
      case messageTypeNote:
        return localized(noteEditTitle);
      case messageTypeChatHistory:
        return localized(chatHistory);
      default:
        return '';
    }
  }
}
