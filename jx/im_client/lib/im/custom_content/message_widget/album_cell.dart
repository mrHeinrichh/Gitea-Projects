import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 相册状态更新cell
class AlbumCell extends StatefulWidget {
  final double height;
  final double width;
  final int index;
  final Message msg;
  final void Function(int index) onShowAlbum;
  final ChatContentController controller;

  const AlbumCell({
    super.key,
    required this.msg,
    required this.height,
    required this.width,
    required this.index,
    required this.onShowAlbum,
    required this.controller,
  });

  @override
  AlbumCellState createState() => AlbumCellState();
}

class AlbumCellState extends State<AlbumCell> {
  late NewMessageMedia messageMedia;

  late AlbumDetailBean bean;

  RxBool showDoneIcon = false.obs;

  //图片资源src
  RxString source = ''.obs;
  RxBool isDownloading = false.obs;
  RxDouble downloadPercentage = 0.0.obs;
  CancelToken thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    messageMedia = widget.msg.decodeContent(cl: NewMessageMedia.creator);

    showDoneIcon.value = widget.msg.showDoneIcon;

    if (messageMedia.albumList != null) {
      bean = messageMedia.albumList![widget.index];

      if (bean.mimeType?.contains('video') ?? bean.cover.isNotEmpty) {
        // 预加载视频m3u8以及ts第一片

        if (widget.msg.message_id != 0) {
          videoMgr.preloadVideo(
            bean.url,
            width: bean.aswidth ?? 0,
            height: bean.asheight ?? 0,
          );
        }
      }
    }

    _preloadImageSync();

    if (showDoneIcon.value) {
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 -
              widget.msg.create_time <=
          3) {
        Future.delayed(const Duration(seconds: 1), () {
          showDoneIcon.value = false;
          widget.msg.showDoneIcon = false;
          if (mounted) setState(() {});
        });
      } else {
        showDoneIcon.value = false;
        widget.msg.showDoneIcon = false;
      }
    }

    widget.msg.on(Message.eventSendState, refreshState);
    widget.msg.on(Message.eventAlbumUploadProgress, refreshState);
    widget.msg.on(Message.eventAlbumBeanUpdate, albumBeanUpdate);
    widget.msg
        .on(Message.eventAlbumAssetProcessComplete, albumCellProcessComplete);
  }

  @override
  void dispose() {
    widget.msg.off(Message.eventSendState, refreshState);
    widget.msg.off(Message.eventAlbumUploadProgress, refreshState);
    widget.msg.off(Message.eventAlbumBeanUpdate, albumBeanUpdate);
    widget.msg
        .off(Message.eventAlbumAssetProcessComplete, albumCellProcessComplete);

    super.dispose();
  }

  void refreshState(Object sender, Object type, Object? data) async {
    if (sender != widget.msg || showDoneIcon.value) {
      if (data is Message && data.isSendFail) {
        showDoneIcon.value = false;
      }

      if (data is Message && data.isSendOk) {
        if (mounted) setState(() {});
      }
      return;
    }
    if ((data is Message && data.isSendFail) ||
        (data is Map && data.containsKey('index'))) {
      if (mounted) setState(() {});
    }
  }

  void albumBeanUpdate(Object sender, Object type, Object? data) {
    if (sender != widget.msg || data == null) return;

    final Map<String, dynamic> map = data as Map<String, dynamic>;
    if (map['index'] != widget.index) return;

    bean = map['bean'] as AlbumDetailBean;
    if (mounted) setState(() {});
  }

  void albumCellProcessComplete(
    Object sender,
    Object type,
    Object? data,
  ) async {
    if (sender != widget.msg || data == null) return;

    if (data is Map<String, dynamic> &&
        data['index'] == widget.index &&
        data.containsKey('success') &&
        data['success']) {
      if (data.containsKey('url')) {
        bean.url = data['url'] as String;
        bean.gausPath = data['gausPath'];
        bean.cover = data['cover'];

        _preloadImageSync();
      }

      if (data['index'] == messageMedia.albumList!.length - 1) {
        for (int i = 0; i < messageMedia.albumList!.length; i++) {
          widget.msg.event(
            widget.msg,
            type,
            data: {
              'index': i,
              'removeShowDoneIcon': true,
            },
          );
        }
      }
      if (mounted) setState(() {});
    }

    if (data is Map<String, dynamic> &&
        data['index'] == widget.index &&
        data.containsKey('removeShowDoneIcon') &&
        data['removeShowDoneIcon']) {
      Future.delayed(const Duration(seconds: 1), () {
        showDoneIcon.value = false;
      });
    }
  }

  _preloadImageSync() {
    if (source.value.isEmpty) {
      if (bean.gausPath.isEmpty) {
        source.value = bean.isVideo ? bean.cover : bean.url;
      } else {
        source.value = imageMgr.getBlurHashSavePath(
          bean.isVideo ? bean.cover : bean.url,
        );

        if (source.value.isNotEmpty && !File(source.value).existsSync()) {
          imageMgr.genBlurHashImage(
            bean.gausPath,
            bean.isVideo ? bean.cover : bean.url,
          );
        }
      }
    }

    if (source.value.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      bean.isVideo ? bean.cover : bean.url,
      mini: Config().messageMin,
    );

    if (thumbPath != null) {
      source.value = bean.isVideo ? bean.cover : bean.url;
      return;
    }

    if (showDoneIcon.value) {
      downloadMgrV2
          .download(
        bean.isVideo ? bean.cover : bean.url,
        mini: Config().messageMin,
        cancelToken: thumbCancelToken,
      )
          .then((v) {
        if (v != null) source.value = bean.isVideo ? bean.cover : bean.url;
        if (mounted) setState(() {});
      });

      return;
    }

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    String filePath = isVideo ? bean.coverPath : bean.filePath;
    if (!File(filePath).existsSync()) isDownloading.value = true;

    DownloadResult result = await downloadMgrV2.download(
      bean.isVideo ? bean.cover : bean.url,
      mini: Config().messageMin,
      cancelToken: thumbCancelToken,
      onReceiveProgress: (received, total) {
        downloadPercentage.value = received / total;
      },
    );
    final thumbPath = result.localPath;
    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = bean.isVideo ? bean.cover : bean.url;
    }

    isDownloading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onShowAlbum(widget.index),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          buildContent(
            widget.index,
            height: widget.height,
            width: widget.width,
          ),
          _buildProgress(context),
          _buildStatus(),
        ],
      ),
    );
  }

  Widget buildContent(
    int index, {
    double? height,
    double? width,
  }) {
    String filePath = isVideo ? bean.coverPath : bean.filePath;
    final remoteFileExist = downloadMgrV2.getLocalPath(
          isVideo ? bean.cover : bean.url,
          mini: Config().messageMin,
        ) !=
        null;
    final fileExist = objectMgr.userMgr.isMe(widget.msg.send_id) &&
        filePath.isNotEmpty &&
        File(filePath).existsSync() &&
        !remoteFileExist;

    if (filePath.isEmpty && bean.asset != null && bean.asset is AssetEntity) {
      return ExtendedImage(
        image: AssetEntityImageProvider(
          bean.asset,
          isOriginal: false,
        ),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return Obx(() {
      return RemoteImageV2(
        src: fileExist ? filePath : source.value,
        width: width,
        height: height,
        mini: source.value ==
                    imageMgr.getBlurHashSavePath(
                      bean.isVideo ? bean.cover : bean.url,
                    ) ||
                fileExist
            ? null
            : Config().messageMin,
        fit: BoxFit.cover,
        enableShimmer: false,
      );
    });
  }

  Widget _buildStatus() {
    final uploadStatus =
        widget.msg.albumUpdateStatus[widget.index.toString()] ?? 0;

    if (uploadStatus == 0 && widget.msg.isSendSlow) {
      return Positioned(
        top: 6.0,
        left: 6.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorTextSecondary,
          ),
          child: const DotLoadingView(
            dotColor: colorWhite,
            size: 8,
          ),
        ),
      );
    }

    if (isVideo) {
      return Positioned(
        left: 6,
        top: 6,
        child: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorTextSecondary,
          ),
          child: Text(
            formatVideoDuration(bean.seconds),
            style: const TextStyle(
              fontSize: 12,
              color: colorWhite,
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildProgress(BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        Widget child = const SizedBox();

        if (showDoneIcon.value) {
          child = SvgPicture.asset(
            key: ValueKey('showDoneIcon_${widget.msg.id}_${widget.index}'),
            'assets/svgs/done_upload_icon.svg',
            width: 40,
            height: 40,
          );
        } else if (widget.msg.isSendOk) {
          if (isDownloading.value) {
            child = _buildDownloadProgress(context);
          } else {
            if (bean.asset == null &&
                downloadMgrV2.getLocalPath(
                      isVideo ? bean.cover : bean.url,
                      mini: Config().messageMin,
                    ) ==
                    null &&
                !isDownloading.value) {
              child = _buildDownload(context);
            } else if (isVideo) {
              child = SvgPicture.asset(
                key: ValueKey('videoPlayIcon_${widget.msg.id}_${widget.index}'),
                'assets/svgs/video_play_icon.svg',
                width: 40,
                height: 40,
              );
            }
          }
        } else if (widget.msg.isSendSlow) {
          child = _buildUploadProgress();
        } else {
          if (isVideo) {
            child = SvgPicture.asset(
              key: ValueKey('videoPlayIcon_${widget.msg.id}_${widget.index}'),
              'assets/svgs/video_play_icon.svg',
              width: 40,
              height: 40,
            );
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      }),
    );
  }

  Widget _buildUploadProgress() {
    final uploadStatus =
        widget.msg.albumUpdateStatus[widget.index.toString()] ?? 0;

    if (uploadStatus == 0) {
      return const SizedBox();
    }

    final uploadProgress =
        widget.msg.albumUpdateProgress[widget.index.toString()] ?? 1;
    double progress = 0.0;

    switch (uploadStatus) {
      case 3:
        progress = min(uploadProgress * 0.95, 0.95);
        break;
      case 4:
        progress = 1.0;
        if (!showDoneIcon.value && widget.msg.isSendSlow) {
          showDoneIcon.value = true;
        }
        break;
      default:
        progress = 0.0;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      child: showDoneIcon.value
          ? SvgPicture.asset(
              key: ValueKey('showDoneIcon_${widget.msg.id}_${widget.index}'),
              'assets/svgs/done_upload_icon.svg',
              width: 40,
              height: 40,
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorTextSecondary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularLoadingBarRotate(
                    key: ValueKey(widget.index),
                    value: progress,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: colorWhite,
                    ),
                    onPressed: () {
                      if (widget.msg.sendState != MESSAGE_SEND_SUCCESS) {
                        widget.msg.sendState = MESSAGE_SEND_FAIL;
                        widget.msg.resetUploadStatus();
                        objectMgr.chatMgr.localDelMessage(widget.msg);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    return Container(
      key: UniqueKey(),
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2.0),
      child: Stack(
        children: <Widget>[
          CircularLoadingBarRotate(
            key: ValueKey(widget.index),
            value: downloadPercentage.value,
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () {
              thumbCancelToken.cancel();
              thumbCancelToken = CancelToken();
              isDownloading.value = false;
              downloadPercentage.value = 0.0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownload(BuildContext context) {
    return GestureDetector(
      onTap: _preloadImageSync,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: UniqueKey(),
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(2.0),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/svgs/download_file_icon.svg',
          width: 20.0,
          height: 20.0,
          colorFilter: const ColorFilter.mode(
            colorWhite,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  bool get isVideo => bean.mimeType?.contains('video') ?? false;
}
