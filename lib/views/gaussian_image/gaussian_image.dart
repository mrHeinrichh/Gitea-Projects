import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';

class GaussianImage extends StatefulWidget {
  /// 图片路径
  final String src;

  /// 图片样式
  final double? width;
  final double? height;
  final BoxFit? fit;

  /// 图片缩略图
  /// 只有 [isFile] == false 才会生效
  final int? mini;

  /// 是否开启骨架
  final bool enableShimmer;

  /// 骨架背景颜色
  final Color shimmerColor;

  /// 缓存图片压缩尺寸参数
  final int? cacheWidth;
  final int? cacheHeight;
  final String? gaussianPath;

  const GaussianImage({
    super.key,
    required this.src,
    this.gaussianPath,
    this.width,
    this.height,
    this.fit,
    this.mini,
    this.enableShimmer = true,
    this.shimmerColor = Colors.black26,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<GaussianImage> createState() => _GaussianImageState();
}

class _GaussianImageState extends State<GaussianImage> {
  RxString source = ''.obs;

  RxBool isDownloading = false.obs;

  final thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    _preloadImageSync();
  }

  @override
  void dispose() {
    if (!thumbCancelToken.isCancelled) {
      thumbCancelToken.cancel();
    }
    super.dispose();
  }

  _preloadImageSync() {
    if (widget.gaussianPath == null || widget.gaussianPath!.isEmpty) {
      //没高斯，使用原图
      source.value = widget.src;
      return;
    }

    _startFFILogic();
  }

  _startFFILogic() async {
    String? thumbPath = downloadMgr.checkLocalFile(
      widget.src,
      mini: widget.mini,
    );

    if (thumbPath != null) {
      //有原图，不展示高斯
      source.value = widget.src;
      return;
    }

    String? smallestThumbPath =
        downloadMgr.checkLocalFile(widget.src, mini: Config().xsMessageMin);
    if (smallestThumbPath != null) {}

    String hashPath = imageMgr.getBlurHashSavePath(widget.src);

    if (hashPath.isNotEmpty && !File(hashPath).existsSync()) {
      source.value = "";
      await imageMgr.genBlurHashImage(
        widget.gaussianPath!,
        widget.src,
      );
    }

    source.value = hashPath;

    _preloadImageAsync();
  }

  _preloadImageAsync() async {
    isDownloading.value = true;
    final thumbPath = await downloadMgr.downloadFile(
      widget.src,
      mini: widget.mini,
      priority: 10,
      cancelToken: thumbCancelToken,
    );

    if (thumbPath != null && !thumbCancelToken.isCancelled) {
      source.value = widget.src;
    }

    isDownloading.value = false;
  }

  @override
  void didUpdateWidget(GaussianImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _preloadImageSync();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (source.value.isEmpty) {
        return const SizedBox();
      }

      return RemoteImageV2(
        src: source.value,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        mini: source.value == imageMgr.getBlurHashSavePath(widget.src)
            ? null
            : widget.mini,
        isFile: source.value == imageMgr.getBlurHashSavePath(widget.src),
        enableShimmer: widget.enableShimmer,
        shimmerColor: widget.shimmerColor,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
      );
    });
  }
}
