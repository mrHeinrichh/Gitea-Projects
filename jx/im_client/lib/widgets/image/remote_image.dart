part of 'image_libs.dart';

class RemoteImage extends RemoteImageBase {
  final Function(File file)? onLoadCallback;
  final VoidCallback? onLoadError;
  final String? errorImage;

  const RemoteImage({
    super.key,
    required super.src,
    super.width,
    super.height,
    super.fit,
    super.mini,
    super.gaussianPath,
    super.shouldAnimate,
    this.onLoadCallback,
    this.onLoadError,
    this.errorImage,
  });

  @override
  _RemoteImageState createState() => _RemoteImageState();
}

class _RemoteImageState extends RemoteImageBaseState<RemoteImage> {
  @override
  Widget? buildInitWidget() {
    if (imgData.init_local_file != null) {
      return Image.file(
        imgData.init_local_file!,
        width: imgData.width,
        height: imgData.height,
        fit: imgData.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            widget.onLoadCallback?.call(File(widget.src));
            return child;
          }
          return buildEmptyBox();
        },
        errorBuilder: (context, error, stackTrace) {
          widget.onLoadError?.call();
          imgData.retry();
          return buildEmptyBox();
        },
      );
    }

    return null;
  }

  @override
  Widget buildLoadingWidget() {
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        child: Shimmer(
          enabled: true,
          color: Colors.black26,
          colorOpacity: 0.2,
          duration: const Duration(seconds: 2),
          child: SizedBox(width: imgData.width, height: imgData.height),
        ));
  }

  @override
  Widget buildImage(File? file) {
    return Image.file(
      file!,
      width: imgData.width,
      height: imgData.height,
      fit: imgData.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          widget.onLoadCallback?.call(file);
          return child;
        }
        return buildEmptyBox();
      },
      errorBuilder: (context, error, stackTrace) {
        widget.onLoadError?.call();
        imgData.retry();
        return buildEmptyBox();
      },
    );
  }

  @override
  Widget buildWebpWidget(File? file) {
    if (imgData.shouldAnimate) {
      return buildImage(file);
    } else {
      return super.buildWebpWidget(file);
    }
  }

  @override
  Widget buildGifWidget(File? file) {
    if (imgData.shouldAnimate) {
      return buildImage(file);
    } else {
      return super.buildGifWidget(file);
    }
  }

  @override
  Widget buildErrorBox() {
    widget.onLoadError?.call();
    return SizedBox(width: widget.width, height: widget.height);
  }
}
