import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_video_me_item.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 相册状态更新cell
class AlbumCell extends StatefulWidget {
  final bool isDesktop;
  final bool isSender;
  final bool isForwardMessage;
  final BorderRadius borderRadius;
  final double? height;
  final double? width;
  final int index;
  final Message msg;
  final void Function(int index) onShowAlbum;
  final double maxWidthRatio;

  const AlbumCell({
    Key? key,
    required this.isDesktop,
    required this.borderRadius,
    required this.msg,
    required this.height,
    required this.width,
    required this.index,
    required this.onShowAlbum,
    required this.maxWidthRatio,
    this.isSender = false,
    this.isForwardMessage = false,
  }) : super(key: key);

  @override
  AlbumCellState createState() => AlbumCellState();
}

class AlbumCellState extends State<AlbumCell> {
  late NewMessageMedia messageMedia;

  late AlbumDetailBean bean;

  bool showDoneIcon = false;

  // 假消息的完成标记
  bool sendDone = false;

  // 缩略图是否准备好
  RxBool onThumbnailReady = false.obs;

  @override
  void initState() {
    super.initState();
    messageMedia = widget.msg.decodeContent(cl: NewMessageMedia.creator);

    if (messageMedia.albumList != null) {
      bean = messageMedia.albumList![widget.index];

      if (bean.mimeType?.contains('video') ?? bean.cover.isNotEmpty) {
        // 预加载视频m3u8以及ts第一片

        if (widget.msg.message_id != 0) {
          unawaited(videoMgr.preloadVideo(bean.url));
        }
      }
    }

    if (widget.msg.showDoneIcon) {
      showDoneIcon = true;
    }

    if (showDoneIcon) {
      Future.delayed(const Duration(seconds: 2), () {
        showDoneIcon = false;
        widget.msg.showDoneIcon = false;
        if (mounted) setState(() {});
      });
    }

    widget.msg.on(Message.eventSendState, refreshState);
    widget.msg.on(Message.eventAlbumUpdateState, albumStateChange);
    widget.msg.on(Message.eventAlbumUploadProgress, refreshState);
    widget.msg.on(Message.eventAlbumBeanUpdate, albumBeanUpdate);
    widget.msg
        .on(Message.eventAlbumAssetProcessComplete, albumCellProcessComplete);
  }

  @override
  void dispose() {
    widget.msg.off(Message.eventSendState, refreshState);
    widget.msg.off(Message.eventAlbumUpdateState, albumStateChange);
    widget.msg.off(Message.eventAlbumUploadProgress, refreshState);
    widget.msg.off(Message.eventAlbumBeanUpdate, albumBeanUpdate);
    widget.msg
        .off(Message.eventAlbumAssetProcessComplete, albumCellProcessComplete);

    super.dispose();
  }

  void refreshState(Object sender, Object type, Object? data) async {
    if (sender != widget.msg || showDoneIcon) {
      return;
    }
    if ((data is Message && data.isSendFail) ||
        (data is Map && data.containsKey('index'))) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void albumStateChange(Object sender, Object type, Object? data) {
    if (sender == widget.msg && mounted) {
      setState(() {});
    }
  }

  void albumBeanUpdate(Object sender, Object type, Object? data) {
    if (sender != widget.msg || data == null) return;

    final Map<String, dynamic> map = data as Map<String, dynamic>;
    if (map['index'] != widget.index) return;

    bean = map['bean'] as AlbumDetailBean;
    if (mounted) {
      setState(() {});
    }
  }

  void albumCellProcessComplete(Object sender, Object type, Object? data) {
    if (sender != widget.msg || data == null) return;

    if (data is Map<String, dynamic> &&
        data['index'] == widget.index &&
        data.containsKey('success') &&
        data['success']) {
      if (data.containsKey('url')) {
        bean.url = data['url'] as String;

        String? fileExist = cacheMediaMgr.checkLocalFile(
          bean.url,
          mini: Config().messageMin,
        );
        if (fileExist == null) {
          cacheMediaMgr.downloadMedia(bean.url, mini: Config().messageMin);
        }

        if (mounted) setState(() {});
      }

      if (data['index'] == messageMedia.albumList!.length - 1) {
        for (int i = 0; i < messageMedia.albumList!.length; i++) {
          widget.msg.event(widget.msg, type, data: {
            'index': i,
            'removeShowDoneIcon': true,
          });
        }
      }
      if (mounted) setState(() {});
    }

    if (data is Map<String, dynamic> &&
        data['index'] == widget.index &&
        data.containsKey('removeShowDoneIcon') &&
        data['removeShowDoneIcon']) {
      Future.delayed(const Duration(seconds: 1), () {
        showDoneIcon = false;
        if (mounted) setState(() {});
      });
    }
  }

  void onLoadCallback(CacheFile? f) async {
    Future.delayed(
        const Duration(milliseconds: 500), () => onThumbnailReady.value = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onShowAlbum(widget.index),
      child: Stack(
        children: <Widget>[
          buildContent(
            widget.index,
            isDesktop: widget.isDesktop,
            onShowAlbum: widget.onShowAlbum,
            maxWidthRatio: widget.maxWidthRatio,
            isSender: widget.isSender,
            isForwardMessage: widget.isForwardMessage,
            height: widget.height,
            width: widget.width,
            borderRadius: widget.borderRadius,
          ),
          if (isVideo) _buildStatus(),
          Positioned.fill(child: _buildProgress()),
        ],
      ),
    );
  }

  Widget buildContent(
    int index, {
    required bool isDesktop,
    bool isSender = false,
    bool isForwardMessage = false,
    bool isBorderRadius = false,
    required void Function(int index) onShowAlbum,
    required double maxWidthRatio,
    double? height,
    double? width,
    BorderRadius borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    ),
  }) {
    String filePath = isVideo ? bean.coverPath : bean.filePath;
    final fileExist = File(filePath).existsSync();
    final bool assetEmpty = bean.asset == null;

    return Stack(
      children: <Widget>[
        if (!bean.cover.isEmpty || !bean.url.isEmpty)
          RemoteImage(
            key:
                ValueKey('${widget.msg.id}_${bean.url}_${Config().messageMin}'),
            src: isVideo ? bean.cover : bean.url,
            width: (width ??
                    (ObjectMgr.screenMQ!.size.width * (maxWidthRatio / 2))) *
                maxWidthRatio,
            height: (height != null
                    ? height
                    : ObjectMgr.screenMQ!.size.height * 0.4) *
                maxWidthRatio,
            mini: Config().messageMin,
            fit: BoxFit.cover,
            onLoadCallback: onLoadCallback,
          ),
        Obx(() {
          if (!onThumbnailReady.value) {
            if (!assetEmpty) {
              if (bean.asset is File) {
                if (isVideo && bean.coverPath.isNotEmpty) {
                  return Image.file(
                    File(bean.coverPath),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  );
                }

                return Image.file(
                  bean.asset!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                );
              }

              if (bean.asset is AssetPreviewDetail) {
                if (bean.asset.editedFile != null) {
                  return Image.file(
                    bean.asset.editedFile!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Image(
                    image: AssetEntityImageProvider(
                      bean.asset.entity,
                      isOriginal: false,
                      thumbnailSize: ThumbnailSize.square(Config().messageMin),
                    ),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  );
                }
              }

              if (bean.asset is AssetEntity) {
                return Image(
                  image: AssetEntityImageProvider(
                    bean.asset!,
                    isOriginal: false,
                    thumbnailSize: ThumbnailSize.square(
                      max(
                        Config().sMessageMin,
                        Config().maxOriImageMin,
                      ),
                    ),
                  ),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                );
              }
            }

            if (filePath.isNotEmpty && fileExist) {
              return Image.file(
                File(filePath),
                width: width,
                height: height,
                fit: BoxFit.cover,
              );
            }
          }

          return const SizedBox();
        }),
      ],
    );
  }

  Widget _buildStatus() {
    return Positioned(
      left: 6,
      top: 6,
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: JXColors.chatBubbleVideoMeStatusBgColor,
        ),
        child: Text(
          formatVideoDuration(bean.seconds),
          style: const TextStyle(
            fontSize: 12,
            color: JXColors.chatBubbleVideoMeStatusTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final uploadStatus =
        widget.msg.albumUpdateStatus[widget.index.toString()] ?? 0;

    final uploadProgress =
        widget.msg.albumUpdateProgress[widget.index.toString()] ?? 1;
    double progress = 0.0;

    switch (uploadStatus) {
      case 1:
        // progress = min(uploadProgress * 0.4, 0.4);
        break;
      case 2:
        // progress = 0.45;
        break;
      case 3:
        // progress = 0.45 + min(uploadProgress * 0.45, 0.45);
        progress = uploadProgress;
        break;
      case 4:
        progress = 1.0;
        break;
      case 5:
        progress = 1.0;
        if (!showDoneIcon && widget.msg.isSendSlow) {
          showDoneIcon = true;
        }
        break;
      default:
        progress = 0.0;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showDoneIcon
          ? SvgPicture.asset(
              key: UniqueKey(),
              'assets/svgs/done_upload_icon.svg',
              width: 40,
              height: 40,
            )
          : widget.msg.isSendSlow
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: JXColors.secondaryTextBlack,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // CircularLoadingBarRotate(
                      //   key: ValueKey(widget.index),
                      //   value: progress == 0.0 ? 0.05 : progress,
                      // ),
                      CircularProgressIndicator(
                        key: ValueKey(widget.index),
                        value: progress,
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: JXColors.white,
                        ),
                        onPressed: () {
                          if (widget.msg.sendState != MESSAGE_SEND_SUCCESS) {
                            widget.msg.sendState = MESSAGE_SEND_FAIL;

                            widget.msg.resetUploadStatus();
                            objectMgr.chatMgr.mySendMgr
                                .updateLasMessage(widget.msg);
                            objectMgr.chatMgr.saveMessage(widget.msg);
                          }
                        },
                      ),
                    ],
                  ),
                )
              : isVideo
                  ? SvgPicture.asset(
                      key: UniqueKey(),
                      'assets/svgs/video_play_icon.svg',
                      width: 40,
                      height: 40,
                    )
                  : const SizedBox(),
    );
  }

  bool get isVideo => bean.mimeType?.contains('video') ?? false;
}
