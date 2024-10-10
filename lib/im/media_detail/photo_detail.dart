import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/larger_photo_data.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoDetail extends StatefulWidget {
  /// Can be [AssetEntity] | [MessageImage] |[AlbumDetailBean]
  final dynamic item;
  final Message message;
  final double height;
  final double width;
  final LargerPhotoData photoData;

  const PhotoDetail({
    super.key,
    required this.item,
    required this.message,
    required this.height,
    required this.width,
    required this.photoData,
  });

  @override
  State<PhotoDetail> createState() => _PhotoDetailState();
}

class _PhotoDetailState extends State<PhotoDetail> {
  bool _isOriLoaded = false;

  AssetEntity? entity;
  String imageUrl = '';
  int size = 0;

  ConnectivityResult get networkState => connectivityMgr.connectivityResult;

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  double get imageRatio => widget.width / widget.height;

  BoxFit get boxFit =>
      deviceRatio > imageRatio ? BoxFit.fitHeight : BoxFit.fitWidth;

  bool get isThumbnailLoading {
    return !_isOriLoaded &&
        !(widget.photoData.loadedOriginMap[imageUrl] ?? false);
  }

  @override
  void initState() {
    super.initState();
    getImageInfo();
  }

  Future<void> getImageInfo() async {
    if (widget.item is AlbumDetailBean) {
      AlbumDetailBean bean = widget.item;
      if (bean.asset != null && bean.asset is AssetEntity) {
        entity = bean.asset;
      }

      widget.photoData.showOriginal = bean.showOriginal;
      size = bean.size;

      imageUrl = bean.url;
    }

    if (widget.item is MessageImage) {
      MessageImage msgImg = widget.item;
      widget.photoData.showOriginal = msgImg.showOriginal;
      size = msgImg.size;
      imageUrl = msgImg.url;
    }

    if (widget.item is AssetEntity) {
      entity = widget.item;
      if (imageUrl.isEmpty && widget.message.typ == messageTypeImage) {
        MessageImage msgImg =
            widget.message.decodeContent(cl: MessageImage.creator);
        imageUrl = msgImg.url;
      }
    }

    if (widget.item is File) {
      MessageImage msgImg =
          widget.message.decodeContent(cl: MessageImage.creator);
      imageUrl = msgImg.url;
      final String? filePath = downloadMgr.checkLocalFile(imageUrl);
      if (filePath == null) {
        await cacheMediaMgr.downloadMedia(
          msgImg.url,
          mini: Config().messageMin,
        );
      }
    }

    if (widget.item is MessageMarkdown) {
      imageUrl = widget.item.image;
      final String? filePath = downloadMgr.checkLocalFile(imageUrl);
      if (filePath == null) {
        await cacheMediaMgr.downloadMedia(imageUrl);
      }
    }

    final String? filePath = downloadMgr.checkLocalFile(imageUrl);
    if (filePath != null || objectMgr.userMgr.isMe(widget.message.send_id)) {
      widget.photoData.shouldShowOriginal = false;
    }

    if (notBlank(filePath)) {
      widget.photoData.loadedOriginMap[imageUrl] = true;
    }
  }

  void onOriginLoadCallback(PhotoViewLoadState? state, File? f) {
    if (state == PhotoViewLoadState.completed) {
      if (!_isOriLoaded) {
        _isOriLoaded = true;
        onThumbnailLoadCallback(state, f);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void onThumbnailLoadCallback(PhotoViewLoadState? state, File? f) {
    final isCacheLoaded = widget.photoData.loadedOriginMap[imageUrl] ?? false;

    if (f != null && !isCacheLoaded) {
      onFullImageLoaded();
    }
  }

  onFullImageLoaded() {
    if (!(widget.photoData.loadedOriginMap[imageUrl] ?? false)) {
      widget.photoData.loadedOriginMap[imageUrl] = true;
    }
  }

  Widget onOriginLoadStateChanged(PhotoViewState state) {
    if (state.extendedImageLoadState == PhotoViewLoadState.completed) {
      if (!_isOriLoaded) {
        _isOriLoaded = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() {});
        });
      }
    }
    return photoLoadStateChanged(
      state,
      loadingItemBuilder: () => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final looseConstraint = BoxConstraints.loose(
      Size(screenSize.width * 2, screenSize.height * 2),
    );

    Widget oriImageChild = const SizedBox(
      key: ValueKey('emptyImageChild'),
    );

    if (entity != null) {
      final isOriginal = entity!.width < 3000 && entity!.height < 3000;
      ThumbnailSize? thumbnailSize;
      if (!isOriginal) {
        final ratio = entity!.width / entity!.height;
        if (entity!.width > entity!.height) {
          thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
        } else {
          thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
        }
      }

      oriImageChild = PhotoView(
        key: ValueKey('${imageUrl}_ori_detail'),
        enableSlideOutPage: true,
        mode: PhotoViewMode.gesture,
        constraints: looseConstraint,
        initGestureConfigHandler: initGestureConfigHandler,
        image: AssetEntityImageProvider(
          entity!,
          isOriginal: isOriginal,
          thumbnailSize: thumbnailSize,
        ),
        width: widget.width,
        fit: boxFit,
        loadStateChanged: onOriginLoadStateChanged,
      );
    }

    if (widget.item is File) {
      oriImageChild = PhotoView.file(
        widget.item,
        key: ValueKey('${imageUrl}_ori_detail'),
        enableSlideOutPage: true,
        mode: PhotoViewMode.gesture,
        constraints: looseConstraint,
        initGestureConfigHandler: initGestureConfigHandler,
        width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
            ? screenSize.width
            : widget.width,
        fit: boxFit,
        loadStateChanged: onOriginLoadStateChanged,
      );
    }

    if (widget.item is AssetPreviewDetail) {
      if (widget.item.editedFile != null) {
        oriImageChild = PhotoView.file(
          widget.item.editedFile!,
          key: ValueKey('${imageUrl}_ori_detail'),
          enableSlideOutPage: true,
          mode: PhotoViewMode.gesture,
          constraints: looseConstraint,
          initGestureConfigHandler: initGestureConfigHandler,
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          height:
              boxFit == BoxFit.fitHeight && widget.height < screenSize.height
                  ? screenSize.height
                  : null,
          fit: boxFit,
          loadStateChanged: onOriginLoadStateChanged,
        );
      } else {
        final isOriginal =
            widget.item.width < 3000 && widget.item.height < 3000;

        ThumbnailSize? thumbnailSize;
        if (!isOriginal) {
          final ratio = widget.item.width / widget.item.height;
          if (widget.item.width > widget.item.height) {
            thumbnailSize = ThumbnailSize(3000, 3000 ~/ ratio);
          } else {
            thumbnailSize = ThumbnailSize((3000 * ratio).toInt(), 3000);
          }
        }

        oriImageChild = PhotoView(
          key: ValueKey('${imageUrl}_ori_detail'),
          enableSlideOutPage: true,
          mode: PhotoViewMode.gesture,
          constraints: looseConstraint,
          initGestureConfigHandler: initGestureConfigHandler,
          image: AssetEntityImageProvider(
            widget.item.entity,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          height:
              boxFit == BoxFit.fitHeight && widget.height < screenSize.height
                  ? screenSize.height
                  : widget.height,
          fit: boxFit,
          loadStateChanged: onOriginLoadStateChanged,
        );
      }
    }

    if (widget.item is AlbumDetailBean || widget.item is MessageImage) {
      final filePath = widget.item.filePath;
      final fileExist = File(filePath).existsSync();
      if (filePath.isNotEmpty && fileExist) {
        oriImageChild = PhotoView.file(
          File(filePath),
          key: ValueKey('${imageUrl}_ori_detail'),
          enableSlideOutPage: true,
          mode: PhotoViewMode.gesture,
          constraints: looseConstraint,
          initGestureConfigHandler: initGestureConfigHandler,
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          height:
              boxFit == BoxFit.fitHeight && widget.height < screenSize.height
                  ? screenSize.height
                  : null,
          fit: boxFit,
          loadStateChanged: onOriginLoadStateChanged,
        );
      }
    }

    Widget child = const SizedBox();

    pdebug(
      'check photo detail: ${oriImageChild.key} | $isThumbnailLoading | ${!widget.photoData.shouldShowOriginal}',
    );

    if (imageUrl.isNotEmpty &&
        oriImageChild.key == const ValueKey('emptyImageChild')) {
      child = Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          if (isThumbnailLoading)
            // 加载缩略图
            ExtendedPhotoView(
              key: ValueKey('${imageUrl}_${Config().messageMin}_detail'),
              src: imageUrl,
              mini: Config().messageMin,
              width:
                  boxFit == BoxFit.fitWidth && widget.width < screenSize.width
                      ? screenSize.width
                      : widget.width,
              height: boxFit == BoxFit.fitHeight &&
                      widget.height < screenSize.height
                  ? screenSize.height
                  : null,
              fit: boxFit,
              shouldAnimate: true,
            ),
          if (!widget.photoData.shouldShowOriginal)
            // 加载高清图
            ExtendedPhotoView(
              key: ValueKey('${imageUrl}_ori_detail'),
              src: imageUrl,
              fit: boxFit,
              width:
                  boxFit == BoxFit.fitWidth && widget.width < screenSize.width
                      ? screenSize.width
                      : widget.width,
              height: boxFit == BoxFit.fitHeight &&
                      widget.height < screenSize.height
                  ? screenSize.height
                  : null,
              mode: PhotoViewMode.gesture,
              onLoadStateCallback: onOriginLoadCallback,
              shouldAnimate: true,
            ),
        ],
      );
    } else {
      child = Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          // 加载缩略图
          if (isThumbnailLoading)
            ExtendedPhotoView(
              key: ValueKey('${imageUrl}_${Config().messageMin}_detail'),
              src: imageUrl,
              mini: Config().messageMin,
              width:
                  boxFit == BoxFit.fitWidth && widget.width < screenSize.width
                      ? screenSize.width
                      : widget.width,
              height: boxFit == BoxFit.fitHeight &&
                      widget.height < screenSize.height
                  ? screenSize.height
                  : null,
              fit: boxFit,
              onLoadStateCallback: onThumbnailLoadCallback,
            ),
          // 加载高清图
          oriImageChild,
        ],
      );
    }

    return child;
  }
}
