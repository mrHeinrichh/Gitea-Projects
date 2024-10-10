import 'dart:math' as math;
import 'dart:ui';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';

typedef SwipeableTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  // ignore: avoid_positional_boolean_parameters
  bool isSwipeGesture,
  Widget child,
);

class SwipeCustomPageRoute<T> extends GetPageRoute<T> {
  /// Whether the user can swipe to navigate back.
  ///
  /// Set this to `false` to disable swiping completely.
  final bool canSwipe;

  /// Whether only back gestures close to the left (LTR) or right (RTL) screen
  /// edge are counted.
  ///
  /// This only takes effect if [canSwipe] ist set to `true`.
  ///
  /// If set to `true`, this distance can be controlled via
  /// [backGestureDetectionWidth].
  /// If set to `false`, the user can start dragging anywhere on the screen.
  bool canOnlySwipeFromEdge;

  /// If [canOnlySwipeFromEdge] is set to `true`, this value controls the width
  /// of the gesture detection area.
  ///
  /// For comparison, in [CupertinoPageRoute] this value is `20`.
  double backGestureDetectionWidth;

  /// If [canOnlySwipeFromEdge] is set to `true`, this value controls how far
  /// away from the left (LTR) or right (RTL) screen edge a gesture must start
  /// to be recognized for back navigation.
  double backGestureDetectionStartOffset;

  /// Custom builder to wrap the child widget.
  ///
  /// By default, this wraps the child in a [CupertinoPageTransition], or, if
  /// it's a full-screen dialog, in a [CupertinoFullscreenDialogTransition].
  ///
  /// You can override this to, e.g., customize the position or shadow
  /// animations.
  final SwipeableTransitionBuilder transitionBuilder;

  SwipeCustomPageRoute({
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.backGestureDetectionWidth = kMinInteractiveDimension,
    this.backGestureDetectionStartOffset = 0.0,
    super.opaque,
    super.page,
    super.routeName,
    super.settings,
    super.curve,
    super.fullscreenDialog,
    super.binding,
    super.customTransition,
    super.popGesture,
    SwipeableTransitionBuilder? transitionBuilder,
  }) : transitionBuilder =
            transitionBuilder ?? _defaultTransitionBuilder(fullscreenDialog);

  static SwipeableTransitionBuilder _defaultTransitionBuilder(
    bool fullscreenDialog,
  ) {
    if (fullscreenDialog) {
      return (context, animation, secondaryAnimation, isSwipeGesture, child) {
        return CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: isSwipeGesture,
          child: child,
        );
      };
    } else {
      return (context, animation, secondaryAnimation, isSwipeGesture, child) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: isSwipeGesture,
          child: child,
        );
      };
    }
  }

  @override
  bool get popGestureEnabled => _isPopGestureEnabled(this, canSwipe);

  // Copied and modified from `CupertinoRouteTransitionMixin`
  static bool _isPopGestureEnabled<T>(PageRoute<T> route, bool canSwipe) {
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst) return false;
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal routes), so disallow it.
    if (route.willHandlePopInternally) return false;
    // If attempts to dismiss this route might be vetoed such as in a page
    // with forms, then do not allow the user to dismiss the route with a swipe.
    if (route.hasScopedWillPopCallback) return false;
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog) return false;
    // If we're in an animation already, we cannot be manually swiped.
    if (route.animation!.status != AnimationStatus.completed) return false;
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    // If we're in a gesture already, we cannot start another.
    if (CupertinoRouteTransitionMixin.isPopGestureInProgress(route)) {
      return false;
    }

    // Added
    if (!canSwipe) return false;

    // Looks like a back gesture would be welcome!
    return true;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
      canSwipe: () => canSwipe,
      canOnlySwipeFromEdge: () => canOnlySwipeFromEdge,
      backGestureDetectionWidth: () => backGestureDetectionWidth,
      backGestureDetectionStartOffset: () => backGestureDetectionStartOffset,
      transitionBuilder: transitionBuilder,
    );
  }

  static Widget buildPageTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    ValueGetter<bool> canSwipe = _defaultCanSwipe,
    ValueGetter<bool> canOnlySwipeFromEdge = _defaultCanOnlySwipeFromEdge,
    ValueGetter<double> backGestureDetectionWidth =
        _defaultBackGestureDetectionWidth,
    ValueGetter<double> backGestureDetectionStartOffset =
        _defaultBackGestureDetectionStartOffset,
    SwipeableTransitionBuilder? transitionBuilder,
  }) {
    final Widget wrappedChild;
    if (route.fullscreenDialog) {
      wrappedChild = child;
    } else {
      wrappedChild = _FancyBackGestureDetector<T>(
        enabledCallback: () => _isPopGestureEnabled(route, canSwipe()),
        onStartPopGesture: () {
          assert(_isPopGestureEnabled(route, canSwipe()));
          return _startPopGesture(route);
        },
        canOnlySwipeFromEdge: canOnlySwipeFromEdge,
        backGestureDetectionWidth: backGestureDetectionWidth,
        backGestureDetectionStartOffset: backGestureDetectionStartOffset,
        routeController: route.controller!,
        navigator: route.navigator!,
        child: child,
      );
    }

    transitionBuilder ??= _defaultTransitionBuilder(route.fullscreenDialog);
    return transitionBuilder(
      context,
      animation,
      secondaryAnimation,
      /* isSwipeGesture: */ CupertinoRouteTransitionMixin
          .isPopGestureInProgress(route),
      wrappedChild,
    );
  }

  // Called by `_FancyBackGestureDetector` when a pop ("back") drag start
  // gesture is detected. The returned controller handles all of the subsequent
  // drag events.
  static _CupertinoBackGestureController<T> _startPopGesture<T>(
    PageRoute<T> route,
  ) {
    return _CupertinoBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!, // protected access
    );
  }

  static bool _defaultCanSwipe() => true;

  static bool _defaultCanOnlySwipeFromEdge() => false;

  static double _defaultBackGestureDetectionWidth() => kMinInteractiveDimension;

  static double _defaultBackGestureDetectionStartOffset() => 0;
}

// Mostly copies and modified variations of the private widgets related to
// [CupertinoPageRoute].

const double _kMinFlingVelocity = 1; // Screen widths per second.

// An eyeballed value for the maximum time it takes for a page to animate
// forward if the user releases a page mid swipe.
const int _kMaxDroppedSwipePageForwardAnimationTime = 800; // Milliseconds.

// The maximum time for a page to get reset to it's original position if the
// user releases a page mid swipe.
const int _kMaxPageBackAnimationTime = 300; // Milliseconds.

// An adapted version of `_CupertinoBackGestureDetector`.
class _FancyBackGestureDetector<T> extends StatefulWidget {
  const _FancyBackGestureDetector({
    super.key,
    required this.canOnlySwipeFromEdge,
    required this.backGestureDetectionWidth,
    required this.backGestureDetectionStartOffset,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
    required this.routeController,
    required this.navigator,
  });

  final ValueGetter<bool> canOnlySwipeFromEdge;
  final ValueGetter<double> backGestureDetectionWidth;
  final ValueGetter<double> backGestureDetectionStartOffset;

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_CupertinoBackGestureController<T>> onStartPopGesture;

  final AnimationController routeController;
  final NavigatorState navigator;

  @override
  _FancyBackGestureDetectorState<T> createState() =>
      _FancyBackGestureDetectorState<T>();
}

class _FancyBackGestureDetectorState<T>
    extends State<_FancyBackGestureDetector<T>> {
  _CupertinoBackGestureController<T>? _backGestureController;
  late FancyGestureController controller;
  bool disableGesture = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FancyGestureController());
    controller.dragStartDetails = _handleDragStart;
    controller.dragUpdateDetails = _handleDragUpdate;
    controller.dragEndDetails = _handleDragEnd;
    controller.dragCancelDetails = _handleDragCancel;
    controller.event
        .on(FancyGestureEvent.ON_EDGE_SWIPE_UPDATE, _disableSwipeBack);
  }

  @override
  void dispose() {
    controller.event
        .off(FancyGestureEvent.ON_EDGE_SWIPE_UPDATE, _disableSwipeBack);
    Get.findAndDelete<FancyGestureController>();
    super.dispose();
  }

  void _disableSwipeBack(Object sender, Object type, Object? data) {
    if (data == FancyGestureEventType.disable) {
      disableGesture = true;
    } else if (data == FancyGestureEventType.enable) {
      disableGesture = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final gestureDetector = RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _DirectionDependentDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _DirectionDependentDragGestureRecognizer>(
          _gestureRecognizerConstructor,
          (instance) {
            instance
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel;
          },
        ),
      },
    );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (!disableGesture) Positioned.fill(child: gestureDetector),
      ],
    );
  }

  _DirectionDependentDragGestureRecognizer _gestureRecognizerConstructor() {
    final directionality = context.directionality;
    return _DirectionDependentDragGestureRecognizer(
      debugOwner: this,
      directionality: directionality,
      checkStartedCallback: () => _backGestureController != null,
      enabledCallback: widget.enabledCallback,
      detectionArea: () => widget.canOnlySwipeFromEdge()
          ? DetectionArea(
              startOffset: widget.backGestureDetectionStartOffset(),
              width: _dragAreaWidth(context),
            )
          : null,
    );
  }

  void _handleDragStart(DragStartDetails _) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController?.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController?.dragEnd(
      _convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width,
      ),
    );

    if (widget.navigator.userGestureInProgress) {
      widget.navigator.didStopUserGesture();
    }
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    if (_backGestureController == null &&
        widget.navigator.userGestureInProgress) {
      final droppedPageForwardAnimationTime = math.min(
        lerpDouble(
          _kMaxDroppedSwipePageForwardAnimationTime,
          0,
          widget.routeController.value,
        )!
            .floor(),
        _kMaxPageBackAnimationTime,
      );

      widget.routeController.animateTo(
        1.0,
        duration: Duration(milliseconds: droppedPageForwardAnimationTime),
        curve: Curves.fastLinearToSlowEaseIn,
      );

      widget.navigator.didStopUserGesture();
    }
    // This can be called even if start is not called, paired with the "down"
    // event that we don't consider here.
    _backGestureController?.dragEnd(0);
    _backGestureController = null;
  }

  double _convertToLogical(double value) {
    switch (context.directionality) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
      default:
        return value;
    }
  }

  double _dragAreaWidth(BuildContext context) {
    // For devices with notches, the drag area needs to be larger on the side
    // that has the notch.
    final double dragAreaWidth;
    switch (context.directionality) {
      case TextDirection.ltr:
        dragAreaWidth = context.mediaQuery.padding.left;
        break;
      case TextDirection.rtl:
        dragAreaWidth = context.mediaQuery.padding.right;
        break;
      default:
        dragAreaWidth = context.mediaQuery.padding.left;
        break;
    }

    return math.max(dragAreaWidth, widget.backGestureDetectionWidth());
  }
}

// Copied from `flutter/cupertino`.
class _CupertinoBackGestureController<T> {
  _CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

  /// The drag gesture has changed by [delta]. The total range of the
  /// drag should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of [velocity] as a
  /// fraction of screen width per second.
  void dragEnd(double velocity) {
    // Fling in the appropriate direction.
    // AnimationController.fling is guaranteed to
    // take at least one frame.
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations.
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    final bool animateForward;

    // If the user releases the page before mid screen with sufficient velocity,
    // or after mid screen, we should animate the page out. Otherwise, the page
    // should be animated back in.
    if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      // The closer the panel is to dismissing, the shorter the animation is.
      // We want to cap the animation time, but we want to use a linear curve
      // to determine it.
      final droppedPageForwardAnimationTime = math.min(
        lerpDouble(
          _kMaxDroppedSwipePageForwardAnimationTime,
          0,
          controller.value,
        )!
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(
        1,
        duration: Duration(milliseconds: droppedPageForwardAnimationTime),
        curve: animationCurve,
      );
    } else {
      // This route is destined to pop at this point. Reuse navigator's pop.
      navigator.pop();

      // The popping may have finished inline if already at the target
      // destination.
      if (controller.isAnimating) {
        // Otherwise, use a custom popping animation duration and curve.
        final droppedPageBackAnimationTime = lerpDouble(
          0,
          _kMaxDroppedSwipePageForwardAnimationTime,
          controller.value,
        )!
            .floor();
        controller.animateBack(
          0,
          duration: Duration(milliseconds: droppedPageBackAnimationTime),
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        if (navigator.userGestureInProgress) {
          navigator.didStopUserGesture();
        }
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      if (navigator.userGestureInProgress) {
        navigator.didStopUserGesture();
      }
    }
  }
}

class _DirectionDependentDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  _DirectionDependentDragGestureRecognizer({
    required this.directionality,
    required this.enabledCallback,
    required this.detectionArea,
    required this.checkStartedCallback,
    super.debugOwner,
  });

  final TextDirection directionality;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<DetectionArea?> detectionArea;
  final ValueGetter<bool> checkStartedCallback;

  @override
  void handleEvent(PointerEvent event) {
    if (_shouldHandle(event)) {
      super.handleEvent(event);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  bool _shouldHandle(PointerEvent event) {
    if (checkStartedCallback()) return true;
    if (!enabledCallback()) return false;

    bool isCorrectDirection;
    if (directionality == TextDirection.ltr && event.delta.dx > 0) {
      isCorrectDirection = true;
    } else if (directionality == TextDirection.rtl && event.delta.dx < 0) {
      isCorrectDirection = true;
    } else if (event.delta.dx == 0) {
      isCorrectDirection = true;
    } else {
      isCorrectDirection = false;
    }

    if (!isCorrectDirection) return false;

    final detectionArea = this.detectionArea();
    final x = event.localPosition.dx;
    if (detectionArea != null &&
        event is PointerDownEvent &&
        (x < detectionArea.startOffset ||
            x > detectionArea.startOffset + detectionArea.width)) {
      return false;
    }

    // 支持IOS打开键盘区域时可以左滑，例如打开sticker
    final y = event.localPosition.dy;
    if (y > Get.height - getBottomInputAreaRealHeight) {
      return false;
    }

    return true;
  }
}

class DetectionArea {
  final double startOffset;
  final double width;

  const DetectionArea({
    required this.startOffset,
    required this.width,
  });
}

extension FancyContext on BuildContext {
  /// Shortcut for `Directionality.of(context)`.
  TextDirection get directionality => Directionality.of(this);
}

class FancyGestureController extends GetxController {
  GestureDragStartCallback? dragStartDetails;
  GestureDragUpdateCallback? dragUpdateDetails;
  GestureDragEndCallback? dragEndDetails;
  GestureDragCancelCallback? dragCancelDetails;
  FancyGestureEvent event = FancyGestureEvent.instance;
}

class FancyGestureEvent extends EventDispatcher {
  static const String ON_EDGE_SWIPE_UPDATE = 'ON_EDGE_SWIPE_UPDATE';

  FancyGestureEvent._();

  static FancyGestureEvent get instance => FancyGestureEvent._();
}

enum FancyGestureEventType {
  disable,
  enable,
}
