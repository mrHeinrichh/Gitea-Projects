import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/webp_first_fram.dart';
import 'package:jxim_client/widgets/image/remote_image_data.dart';
import 'package:lottie_tgs/lottie.dart';

abstract class RemoteImageBase extends StatefulWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? mini;
  final bool shouldAnimate;

  const RemoteImageBase({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit,
    this.mini,
    this.shouldAnimate = false,
  });

  @override
  RemoteImageBaseState<RemoteImageBase> createState();
}

abstract class RemoteImageBaseState<T extends RemoteImageBase>
    extends State<T> {
  late final RemoteImageData imgData;
  Widget? _lastChild;
  bool isUserScrolling = false;
  bool _isTgs = false;

  @override
  void initState() {
    super.initState();
    imgData = RemoteImageData(
      src: widget.src,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      mini: widget.mini,
      shouldAnimate: widget.shouldAnimate,
    );

    _isTgs = imgData.file_extension == '.tgs';
    if (_isTgs) {
      objectMgr.chatMgr.on(ChatMgr.eventScrolling, onUserScrolling);
    }
  }

  void onUserScrolling(Object sender, Object type, Object? data) {
    if (data is Map<String, dynamic> &&
        data.containsKey('isScrolling') &&
        isUserScrolling != data['isScrolling']) {
      // 滚动的是否停掉动画
      isUserScrolling = data['isScrolling'];
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    if (_isTgs) {
      objectMgr.chatMgr.off(ChatMgr.eventScrolling, onUserScrolling);
    }
    super.dispose();
  }

  Widget buildErrorWidget() {
    return Image.asset(
      'assets/images/common/picture_loading_failed.jpg',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  Widget buildTgsWidget(File? file) {
    return Lottie.file(
      file!,
      width: 100,
      height: 100,
      animate: isUserScrolling ? false : imgData.shouldAnimate,
      frameRate: FrameRate(240),
      errorBuilder: (context, error, stackTrace) {
        imgData.retry();
        return buildEmptyBox();
      },
    );
  }

  Widget buildWebpWidget(File? file) {
    return WebpWidget(
      imgBytes: file!.readAsBytesSync(),
      width: imgData.width,
      height: imgData.height,
      callBack: (b) {
        if (b) imgData.retry();
      },
    );
  }

  Widget buildImage(File? file);

  Widget? buildInitWidget();
  Widget buildLoadingWidget();

  Widget buildEmptyBox() {
    return SizedBox(width: widget.width, height: widget.height);
  }

  Widget buildFutureImage() {
    return FutureBuilder<File?>(
      future: imgData.localFile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _lastChild ?? buildInitWidget() ?? buildLoadingWidget();
        } else if (snapshot.hasData && snapshot.data != null) {
          if (imgData.file_extension == '.tgs') {
            _lastChild = buildTgsWidget(snapshot.data);
          } else if (['.webp', '.gif'].contains(imgData.file_extension)) {
            _lastChild = buildWebpWidget(snapshot.data);
          } else {
            _lastChild = buildImage(snapshot.data);
          }
          return _lastChild!;
        } else {
          _lastChild ??= buildInitWidget();
          return _lastChild ?? buildEmptyBox();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildFutureImage();
  }
}
