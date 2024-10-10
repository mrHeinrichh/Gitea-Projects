part of 'image_libs.dart';

typedef OnLoadStateCallback = void Function(
  PhotoViewLoadState? state,
  File? f,
);

class ExtendedPhotoView extends RemoteImageBase {
  final OnLoadStateCallback? onLoadStateCallback;
  final PhotoViewMode? mode;
  final BoxConstraints? constraint;
  final bool noSimmerEffect;

  const ExtendedPhotoView({
    super.key,
    required super.src,
    super.width,
    super.height,
    super.fit,
    super.mini,
    super.shouldAnimate,
    this.onLoadStateCallback,
    this.mode = PhotoViewMode.none,
    this.constraint,
    this.noSimmerEffect = false,
  });

  @override
  _ExtendedPhotoViewState createState() => _ExtendedPhotoViewState();
}

class _ExtendedPhotoViewState extends RemoteImageBaseState<ExtendedPhotoView> {
  late final BoxConstraints looseConstraint;
  @override
  void initState() {
    super.initState();
    Size screenSize = ObjectMgr.screenMQ!.size;
    looseConstraint = BoxConstraints.loose(
      Size(screenSize.width * 2, screenSize.height * 2),
    );
  }

  @override
  Widget buildImage(File? file) {
    return Center(
      child: widget.mode == PhotoViewMode.gesture
          ? PhotoView.file(
              file!,
              width: imgData.width,
              height: imgData.height,
              fit: imgData.fit,
              enableSlideOutPage: true,
              mode: PhotoViewMode.gesture,
              constraints: widget.constraint ?? looseConstraint,
              initGestureConfigHandler: initGestureConfigHandler,
              loadStateChanged: (PhotoViewState state) {
                return _onPhotoViewLoadStateChanged(state, file);
              },
            )
          : PhotoView.file(
              file!,
              width: imgData.width,
              height: imgData.height,
              fit: imgData.fit,
              loadStateChanged: (PhotoViewState state) {
                return _onPhotoViewLoadStateChanged(state, file);
              },
            ),
    );
  }

  @override
  Widget? buildInitWidget() {
    if (imgData.init_local_file != null) {
      return Center(
        child: widget.mode == PhotoViewMode.gesture
            ? PhotoView.file(
                imgData.init_local_file!,
                width: imgData.width,
                height: imgData.height,
                fit: imgData.fit,
                enableSlideOutPage: true,
                mode: PhotoViewMode.gesture,
                constraints: widget.constraint ?? looseConstraint,
                initGestureConfigHandler: initGestureConfigHandler,
                loadStateChanged: (PhotoViewState state) {
                  return _onPhotoViewLoadStateChanged(
                      state, imgData.init_local_file!);
                },
              )
            : PhotoView.file(
                imgData.init_local_file!,
                width: imgData.width,
                height: imgData.height,
                fit: imgData.fit,
                loadStateChanged: (PhotoViewState state) {
                  return _onPhotoViewLoadStateChanged(
                      state, imgData.init_local_file!);
                },
              ),
      );
    }

    return null;
  }

  Widget _onPhotoViewLoadStateChanged(PhotoViewState state, File file) {
    final isLoading =
        state.extendedImageLoadState == PhotoViewLoadState.loading;
    if (isLoading) {
      widget.onLoadStateCallback?.call(state.extendedImageLoadState, null);
    }

    final hasLoaded =
        state.extendedImageLoadState == PhotoViewLoadState.completed;
    if (hasLoaded) {
      widget.onLoadStateCallback?.call(state.extendedImageLoadState, file);
      return state.completedWidget;
    }

    final hasError = state.extendedImageLoadState == PhotoViewLoadState.failed;
    if (hasError) {
      widget.onLoadStateCallback?.call(state.extendedImageLoadState, null);
      imgData.retry();
      return SizedBox(
        width: imgData.width,
        height: imgData.height,
      );
    }

    return SizedBox(
      width: imgData.width,
      height: imgData.height,
    );
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
}
