import 'dart:io';

import 'package:flutter/material.dart';
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
  final String? gaussianPath;

  const RemoteImageBase({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit,
    this.gaussianPath,
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

  /// 用户滑动监听注释, 避免贴纸刷新BUG
  // bool isUserScrolling = false;
  // bool _isScrollEnable = false;

  initRemoteImageData() {
    imgData = RemoteImageData(
      src: widget.src,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaussianPath: widget.gaussianPath,
      mini: widget.mini,
      shouldAnimate: widget.shouldAnimate,
    );
  }

  @override
  void initState() {
    super.initState();
    initRemoteImageData();

    // _isScrollEnable =
    //     imgData.file_extension == '.tgs' || imgData.file_extension == '.webp';
    // if (_isScrollEnable) {
    //   objectMgr.chatMgr.on(ChatMgr.eventScrolling, onUserScrolling);
    // }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.src != oldWidget.src) {
      imgData.reflush(widget.src, widget.mini);
    }
    if (widget.width != oldWidget.width || widget.height != oldWidget.height) {
      if (mounted) setState(() {});
    }
  }

  // void onUserScrolling(Object sender, Object type, Object? data) {
  //   if (data is Map<String, dynamic> &&
  //       data.containsKey('isScrolling') &&
  //       data['isScrolling'] is bool &&
  //       isUserScrolling != data['isScrolling']) {
  //     // 滚动的是否停掉动画
  //     isUserScrolling = data['isScrolling'];
  //     if (mounted) setState(() {});
  //   }
  // }

  @override
  void dispose() {
    // if (_isScrollEnable) {
    //   objectMgr.chatMgr.off(ChatMgr.eventScrolling, onUserScrolling);
    // }
    super.dispose();
  }

  @mustCallSuper
  Widget buildErrorWidget() {
    return Image.asset(
      'assets/images/common/picture_loading_failed.jpg',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  @mustCallSuper
  Widget buildTgsWidget(File? file) {
    return Lottie.file(
      file!,
      width: imgData.width,
      height: imgData.height,
      // animate: isUserScrolling ? false : imgData.shouldAnimate,
      frameRate: FrameRate(240),
      errorBuilder: (context, error, stackTrace) {
        imgData.retry();
        return buildEmptyBox();
      },
    );
  }

  @mustCallSuper
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

  Widget buildGifWidget(File? file) {
    return buildWebpWidget(file);
  }

  Widget buildImage(File? file) {
    throw UnimplementedError();
  }

  Widget? buildInitWidget() {
    throw UnimplementedError();
  }

  Widget buildLoadingWidget() {
    throw UnimplementedError();
  }

  @mustCallSuper
  Widget buildEmptyBox() {
    return SizedBox(width: widget.width, height: widget.height);
  }

  Widget buildErrorBox() {
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
          } else if (imgData.file_extension == '.gif') {
            _lastChild = buildGifWidget(snapshot.data);
          } else if (imgData.file_extension == '.webp') {
            _lastChild = buildWebpWidget(snapshot.data);
          } else {
            _lastChild = buildImage(snapshot.data);
          }
          return _lastChild!;
        } else {
          _lastChild ??= buildInitWidget();
          return _lastChild ?? buildErrorBox();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildFutureImage();
  }
}
