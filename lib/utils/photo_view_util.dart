import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

typedef LoadingItemBuilder = Widget Function();
typedef FailItemBuilder = Widget Function(PhotoViewState state);

PhotoViewGestureConfig initGestureConfigHandler(PhotoViewState state) {
  return PhotoViewGestureConfig(
    minScale: 1.0,
    maxScale: 3.0,
    animationMinScale: 0.2,
    animationMaxScale: 5.0,
    inPageView: true,
  );
}

Widget photoLoadStateChanged(
  PhotoViewState state, {
  bool isTransition = false,
  LoadingItemBuilder loadingItemBuilder = defaultLoadingItemBuilder,
  FailItemBuilder failedItemBuilder = defaultFailedItemBuilder,
}) {
  return switch (state.extendedImageLoadState) {
    PhotoViewLoadState.completed => isTransition
        ? FadeImageBuilder(child: state.completedWidget)
        : state.completedWidget,
    PhotoViewLoadState.failed => failedItemBuilder(state),
    PhotoViewLoadState.loading => loadingItemBuilder(),
  };
}

Widget defaultLoadingItemBuilder() {
  return Center(
    child: CircularProgressIndicator(
      backgroundColor: Colors.white.withOpacity(0.3),
      color: Colors.white.withOpacity(0.35),
    ),
  );
}

Widget defaultFailedItemBuilder(PhotoViewState state) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red),
        const SizedBox(height: 8),
        const Text(
          '加载失败',
          style: TextStyle(color: Colors.white),
        ),
        ElevatedButton(
          onPressed: () {
            state.reLoadImage();
          },
          child: const Text('重试'),
        ),
      ],
    ),
  );
}

class FadeImageBuilder extends StatelessWidget {
  const FadeImageBuilder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (_, double value, Widget? w) => Opacity(
        opacity: value,
        child: w,
      ),
      child: child,
    );
  }
}
