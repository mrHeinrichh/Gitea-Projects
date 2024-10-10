import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/tg_album_util.dart';

class NewAlbumGridView extends StatelessWidget {
  final Message assetMessage;
  final NewMessageMedia messageMedia;
  final void Function(int index) onShowAlbum;
  final ChatContentController controller;

  final double maxContentWidth;

  NewAlbumGridView({
    super.key,
    required this.assetMessage,
    required this.messageMedia,
    required this.onShowAlbum,
    required this.controller,
    required this.maxContentWidth,
  });

  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  @override
  Widget build(BuildContext context) {
    if (!notBlank(messageMedia.albumList)) return const SizedBox();
    Size maxSize = TgAlbumUtil.getMaxSize(width: maxContentWidth, height: 380.w)
        .fittedToWidthOrSmaller(maxContentWidth);
    double maxHeight = maxSize.height;
    double maxWidth = maxSize.width;
    dynamic bean = TgAlbumUtil.buildAlbum(
      items: messageMedia.albumList!,
      assetMessage: assetMessage,
      onShowAlbum: onShowAlbum,
      maxSize: maxSize,
      controller: controller,
    );
    Widget child;
    if (bean is WidgetBean) {
      child = bean.albumWidget;
      maxHeight = bean.maxHeight;
      if (bean.maxWidth != 0) {
        maxWidth = bean.maxWidth;
      }
    } else if (bean is Widget) {
      child = bean;
    } else {
      child = const SizedBox();
    }

    return Container(
      width: maxWidth,
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: child,
    );
  }
}
