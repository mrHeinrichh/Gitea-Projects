part of 'image_libs.dart';

class RemoteImageV2 extends RemoteImageBase {
  final bool isFile;
  final bool enableShimmer;
  final Color shimmerColor;
  final int? cacheWidth;
  final int? cacheHeight;

  const RemoteImageV2({
    super.key,
    required super.src,
    super.width,
    super.height,
    super.fit,
    super.mini,
    super.shouldAnimate,
    this.isFile = false,
    this.enableShimmer = true,
    this.shimmerColor = Colors.black26,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  _RemoteImageV2State createState() => _RemoteImageV2State();
}

class _RemoteImageV2State extends RemoteImageBaseState<RemoteImageV2> {
  @override
  void didUpdateWidget(RemoteImageV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.src != oldWidget.src) {
      imgData.reflush(widget.src, widget.mini);
    }
    if (widget.width != oldWidget.width || widget.height != oldWidget.height) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget buildImage(File? file) {
    return Image.file(
      file!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
    );
  }

  @override
  Widget? buildInitWidget() {
    if (imgData.init_local_file != null) {
      return Image.file(
        imgData.init_local_file!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
      );
    }

    return null;
  }

  @override
  Widget buildLoadingWidget() {
    return Shimmer(
      enabled: true,
      color: widget.shimmerColor,
      colorOpacity: 0.2,
      duration: const Duration(seconds: 2),
      child: buildEmptyBox(),
    );
  }
}
