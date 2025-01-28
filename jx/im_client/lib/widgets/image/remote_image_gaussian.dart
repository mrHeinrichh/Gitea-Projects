part of 'image_libs.dart';

class RemoteGaussianImage extends RemoteImageBase {
  final bool isFile;
  final bool enableShimmer;
  final Color shimmerColor;
  final int? cacheWidth;
  final int? cacheHeight;

  const RemoteGaussianImage({
    super.key,
    required super.src,
    super.gaussianPath,
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
  _RemoteImageGaussianState createState() => _RemoteImageGaussianState();
}

class _RemoteImageGaussianState
    extends RemoteImageBaseState<RemoteGaussianImage> {
  @override
  initRemoteImageData() {
    imgData = RemoteImageData(
      src: widget.src,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      mini: widget.mini,
      shouldAnimate: widget.shouldAnimate,
    );
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

    if(notBlank(widget.gaussianPath)) {
      return RemoteImageV2(
        src: widget.src,
        gaussianPath: widget.gaussianPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        mini: widget.mini,
        enableShimmer: widget.enableShimmer,
      );
    } else {
      return null;
    }
  }

  @override
  Widget buildLoadingWidget() {
    if (imgData.isGaus) {
      return RemoteImageV2(
        src: widget.src,
        gaussianPath: widget.gaussianPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        mini: widget.mini,
        enableShimmer: widget.enableShimmer,
      );
    } else {
      if (widget.enableShimmer) {
        return Shimmer(
          enabled: true,
          color: widget.shimmerColor,
          colorOpacity: 0.2,
          duration: const Duration(seconds: 2),
          child: buildEmptyBox(),
        );
      } else {
        return buildEmptyBox();
      }
    }
  }
}
