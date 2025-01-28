import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/larger_photo_data.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoDetail extends StatefulWidget {
  /// Can be [AssetEntity] | [MessageImage] |[AlbumDetailBean]
  final dynamic item;
  final Message message;
  final double height;
  final double width;
  final Function(Function(), int, bool, bool)? onUpdateShowPhotoOriginal;

  final LargerPhotoData photoData;

  const PhotoDetail({
    super.key,
    required this.item,
    required this.message,
    required this.height,
    required this.width,
    required this.photoData,
    this.onUpdateShowPhotoOriginal,
  });

  @override
  State<PhotoDetail> createState() => _PhotoDetailState();
}

class _PhotoDetailState extends State<PhotoDetail> {
  bool _showLoading = false;

  AssetEntity? entity;
  String imageUrl = '';
  int size = 0;

  ConnectivityResult get networkState => connectivityMgr.connectivityResult;

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  double get imageRatio => widget.width / widget.height;

  BoxFit get boxFit =>
      deviceRatio > imageRatio ? BoxFit.fitHeight : BoxFit.fitWidth;
  bool showingOriginal = false;

  @override
  void initState() {
    super.initState();

    getImageInfo();
  }

  void getImageInfo() async {
    _showLoading = true;
    if (mounted) setState(() {});

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
      final String? filePath = cacheMediaMgr.checkLocalFile(imageUrl);
      if (filePath == null) {
        cacheMediaMgr.downloadMedia(
          msgImg.url,
          mini: Config().messageMin,
        );
      }
    }

    if (networkState != ConnectivityResult.wifi &&
        widget.photoData.showOriginal) {
      widget.photoData.shouldShowOriginal = true;
    }

    final String? filePath = cacheMediaMgr.checkLocalFile(imageUrl);
    if (filePath != null || objectMgr.userMgr.isMe(widget.message.send_id)) {
      widget.photoData.shouldShowOriginal = false;
    }

    if (notBlank(filePath)) {
      widget.photoData.loadedOriginMap[imageUrl] = false;
    }

    _showLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.onUpdateShowPhotoOriginal != null)
        widget.onUpdateShowPhotoOriginal!(onOriginalShow, size, showingOriginal,
            widget.photoData.shouldShowOriginal);
    });
    if (mounted) setState(() {});
  }

  void onLoadCallback(CacheFile? f, {bool? showOri}) async {
    bool isLoaded = widget.photoData.loadedOriginMap[imageUrl] ?? false;
    if (showOri != null && showingOriginal != showOri) {
      showingOriginal = showOri;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (widget.onUpdateShowPhotoOriginal != null)
          widget.onUpdateShowPhotoOriginal!(onOriginalShow, size, showOri,
              widget.photoData.shouldShowOriginal);
        setState(() {});
      });
    }

    if (f != null && !isLoaded) {
      Future.delayed(
          const Duration(milliseconds: 300), () => onFullImageLoaded());
    }
  }

  onFullImageLoaded() async {
    if (!(widget.photoData.loadedOriginMap[imageUrl] ?? false)) {
      widget.photoData.loadedOriginMap[imageUrl] = true;
      if (mounted) setState(() {});
    }
  }

  Widget onFrameBuilderCallback(_, child, frame, __, String path) {
    if (frame != null) {
      Future.delayed(
          const Duration(milliseconds: 300), () => onFullImageLoaded());
      return child;
    }

    return SizedBox(
      width: widget.width,
    );
  }

  void onOriginalShow() {
    widget.photoData.shouldShowOriginal = false;
    showingOriginal = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.onUpdateShowPhotoOriginal != null)
        widget.onUpdateShowPhotoOriginal!(onOriginalShow, size, showingOriginal,
            widget.photoData.shouldShowOriginal);
    });

    if (mounted) setState(() {});
  }

  void onScaleEnd(_, __, PhotoViewControllerValue controllerValue) {
    widget.photoData.scale = clampDouble(controllerValue.scale!, 1.0, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

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

      oriImageChild = Container(
        alignment: Alignment.center,
        child: Image(
          image: AssetEntityImageProvider(
            entity!,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
          ),
          alignment: Alignment.center,
          width: widget.width,
          fit: boxFit,
          frameBuilder: (context, child, frame, s) => onFrameBuilderCallback(
            context,
            child,
            frame,
            s,
            entity!.id,
          ),
        ),
      );
    }

    if (widget.item is File) {
      oriImageChild = Container(
        alignment: Alignment.center,
        child: Image.file(
          widget.item,
          alignment: Alignment.center,
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          fit: boxFit,
          frameBuilder: (context, child, frame, s) => onFrameBuilderCallback(
            context,
            child,
            frame,
            s,
            widget.item.path,
          ),
          errorBuilder: (context, error, stackTrace) {
            pdebug('error');
            return const SizedBox();
          },
        ),
      );
    }

    if (widget.item is AssetPreviewDetail) {
      if (widget.item.editedFile != null) {
        oriImageChild = Image.file(
          widget.item.editedFile!,
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          height:
              boxFit == BoxFit.fitHeight && widget.height < screenSize.height
                  ? screenSize.height
                  : null,
          fit: boxFit,
          frameBuilder: (context, child, frame, s) => onFrameBuilderCallback(
            context,
            child,
            frame,
            s,
            widget.item.editedFile!.path,
          ),
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

        oriImageChild = Image(
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
          frameBuilder: (context, child, frame, s) => onFrameBuilderCallback(
            context,
            child,
            frame,
            s,
            widget.item.entity.id,
          ),
        );
      }
    }

    if (widget.item is AlbumDetailBean || widget.item is MessageImage) {
      final filePath = widget.item.filePath;
      final fileExist = File(filePath).existsSync();
      if (filePath.isNotEmpty && fileExist) {
        oriImageChild = Image.file(
          File(filePath),
          width: boxFit == BoxFit.fitWidth && widget.width < screenSize.width
              ? screenSize.width
              : widget.width,
          height:
              boxFit == BoxFit.fitHeight && widget.height < screenSize.height
                  ? screenSize.height
                  : null,
          fit: boxFit,
          frameBuilder: (context, child, frame, s) => onFrameBuilderCallback(
            context,
            child,
            frame,
            s,
            filePath,
          ),
        );
      }
    }

    if (_showLoading) {
      Toast.show();
      return const SizedBox();
    }

    Toast.hide();

    Widget child = const SizedBox();
    if (imageUrl.isNotEmpty &&
        oriImageChild.key == const ValueKey('emptyImageChild')) {
      child = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (!widget.photoData.shouldShowOriginal)
            RemoteImage(
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
              onLoadCallback: (f) => onLoadCallback(f, showOri: false),
            ),
          if (widget.photoData.shouldShowOriginal || showingOriginal)
            RemoteImage(
              key: ValueKey('${imageUrl}_${Config().maxOriImageMin}_detail'),
              src: imageUrl,
              mini: Config().maxOriImageMin,
              fit: boxFit,
              width:
                  boxFit == BoxFit.fitWidth && widget.width < screenSize.width
                      ? screenSize.width
                      : widget.width,
              height: boxFit == BoxFit.fitHeight &&
                      widget.height < screenSize.height
                  ? screenSize.height
                  : null,
              onLoadCallback: onLoadCallback,
            ),
          if (!(widget.photoData.loadedOriginMap[imageUrl] ?? false))
            RemoteImage(
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
            ),
        ],
      );
    } else {
      child = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          oriImageChild,
          if (!(widget.photoData.loadedOriginMap[imageUrl] ?? false))
            Container(
              alignment: Alignment.center,
              child: RemoteImage(
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
              ),
            ),
        ],
      );
    }

    return child;
  }
}
