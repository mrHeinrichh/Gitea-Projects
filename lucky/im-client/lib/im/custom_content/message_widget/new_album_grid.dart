import 'package:flutter/material.dart';
import 'package:jxim_client/managers/utils.dart';
import '../../../main.dart';
import '../../../object/chat/message.dart';
import '../../../utils/new_album_util.dart';

class NewAlbumGridView extends StatelessWidget {
  final Message assetMessage;
  final NewMessageMedia messageMedia;
  final double maxWidthRatio;
  final void Function(int index) onShowAlbum;
  final bool isSender;
  final bool isForwardMessage;
  final bool isBorderRadius;

  NewAlbumGridView({
    Key? key,
    required this.assetMessage,
    required this.messageMedia,
    required this.onShowAlbum,
    this.isSender = false,
    this.isForwardMessage = false,
    this.isBorderRadius = false,
    this.maxWidthRatio = 1,
  }) : super(key: key);

  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  @override
  Widget build(BuildContext context) {
    if (!notBlank(messageMedia.albumList)) return const SizedBox();

    return Container(
      width: NewAlbumUtil.getMaxWidth(
          messageMedia.albumList?.length ?? 0, maxWidthRatio),
      constraints: BoxConstraints(
        maxHeight: NewAlbumUtil.getMaxHeight(
            messageMedia.albumList!.length, maxWidthRatio),
      ),
      child: NewAlbumUtil.buildGrid(
        items: messageMedia.albumList!,
        isDesktop: isDesktop,
        isSender: isSender,
        assetMessage: assetMessage,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      ),
    );
  }
}
