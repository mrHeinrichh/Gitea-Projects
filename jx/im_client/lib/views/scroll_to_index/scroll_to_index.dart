library scroll_to_index;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:jxim_client/views/scroll_to_index/util.dart';

const defaultScrollDistanceOffset = 100.0;
const defaultDurationUnit = 40;

const _millisecond = Duration(milliseconds: 1);
const _highlightDuration = Duration(seconds: 3);
const scrollAnimationDuration = Duration(milliseconds: 250);

typedef ViewportBoundaryGetter = Rect Function();
typedef AxisValueGetter = double Function(Rect rect);

Rect defaultViewportBoundaryGetter() => Rect.zero;

abstract class AutoScrollController implements ScrollController {
  factory AutoScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    double? suggestedRowHeight,
    ViewportBoundaryGetter viewportBoundaryGetter =
        defaultViewportBoundaryGetter,
    Axis? axis,
    String? debugLabel,
    AutoScrollController? copyTagsFrom,
  }) {
    return SimpleAutoScrollController(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      suggestedRowHeight: suggestedRowHeight,
      viewportBoundaryGetter: viewportBoundaryGetter,
      beginGetter: axis == Axis.horizontal ? (r) => r.left : (r) => r.top,
      endGetter: axis == Axis.horizontal ? (r) => r.right : (r) => r.bottom,
      copyTagsFrom: copyTagsFrom,
      debugLabel: debugLabel,
    );
  }

  double? get suggestedRowHeight;

  ViewportBoundaryGetter get viewportBoundaryGetter;

  AxisValueGetter get beginGetter;
  AxisValueGetter get endGetter;

  bool get isAutoScrolling;

  Map<int, AutoScrollTagState> get tagMap;

  set parentController(ScrollController parentController);

  bool get hasParentController;

  Future scrollToIndex(
    int index, {
    Duration duration = scrollAnimationDuration,
    AutoScrollPosition? preferPosition,
    double extraOffset = 0,
  });

  Future highlight(
    int index, {
    bool cancelExistHighlights = true,
    Duration highlightDuration = _highlightDuration,
    bool animated = true,
  });

  void cancelAllHighlights();

  bool isIndexStateInLayoutRange(int index);
}

class SimpleAutoScrollController extends ScrollController
    with AutoScrollControllerMixin {
  @override
  final double? suggestedRowHeight;
  @override
  final ViewportBoundaryGetter viewportBoundaryGetter;
  @override
  final AxisValueGetter beginGetter;
  @override
  final AxisValueGetter endGetter;

  SimpleAutoScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    this.suggestedRowHeight,
    this.viewportBoundaryGetter = defaultViewportBoundaryGetter,
    required this.beginGetter,
    required this.endGetter,
    AutoScrollController? copyTagsFrom,
    super.debugLabel,
  }) {
    if (copyTagsFrom != null) tagMap.addAll(copyTagsFrom.tagMap);
  }
}

class PageAutoScrollController extends PageController
    with AutoScrollControllerMixin {
  @override
  final double? suggestedRowHeight;
  @override
  final ViewportBoundaryGetter viewportBoundaryGetter;
  @override
  final AxisValueGetter beginGetter = (r) => r.left;
  @override
  final AxisValueGetter endGetter = (r) => r.right;

  PageAutoScrollController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction,
    this.suggestedRowHeight,
    this.viewportBoundaryGetter = defaultViewportBoundaryGetter,
    AutoScrollController? copyTagsFrom,
    String? debugLabel,
  }) {
    if (copyTagsFrom != null) tagMap.addAll(copyTagsFrom.tagMap);
  }
}

enum AutoScrollPosition { begin, middle, end }

mixin AutoScrollControllerMixin on ScrollController
    implements AutoScrollController {
  @override
  final Map<int, AutoScrollTagState> tagMap = <int, AutoScrollTagState>{};
  @override
  double? get suggestedRowHeight;
  @override
  ViewportBoundaryGetter get viewportBoundaryGetter;
  @override
  AxisValueGetter get beginGetter;
  @override
  AxisValueGetter get endGetter;

  bool __isAutoScrolling = false;
  set _isAutoScrolling(bool isAutoScrolling) {
    __isAutoScrolling = isAutoScrolling;
    if (!isAutoScrolling && hasClients) {
      notifyListeners();
    }
  }

  @override
  bool get isAutoScrolling => __isAutoScrolling;

  ScrollController? _parentController;
  @override
  set parentController(ScrollController parentController) {
    if (_parentController == parentController) return;

    final isNotEmpty = positions.isNotEmpty;
    if (isNotEmpty && _parentController != null) {
      for (final p in _parentController!.positions) {
        if (positions.contains(p)) _parentController!.detach(p);
      }
    }

    _parentController = parentController;

    if (isNotEmpty && _parentController != null) {
      for (final p in positions) {
        _parentController!.attach(p);
      }
    }
  }

  @override
  bool get hasParentController => _parentController != null;

  @override
  void attach(ScrollPosition position) {
    super.attach(position);

    _parentController?.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    _parentController?.detach(position);

    super.detach(position);
  }

  static const maxBound = 30;
  @override
  Future scrollToIndex(
    int index, {
    Duration duration = scrollAnimationDuration,
    AutoScrollPosition? preferPosition,
    double extraOffset = 0,
  }) async {
    return co(
      this,
      () => _scrollToIndex(
        index,
        duration: duration,
        preferPosition: preferPosition,
        extraOffset: extraOffset,
      ),
    );
  }

  Future _scrollToIndex(
    int index, {
    Duration duration = scrollAnimationDuration,
    AutoScrollPosition? preferPosition,
    double extraOffset = 0,
  }) async {
    final isAnim = duration > Duration.zero;

    Future makeSureStateIsReady() async {
      for (var count = 0; count < maxBound; count++) {
        if (_isEmptyStates) {
          await _waitForWidgetStateBuild();
          assert(isAnim);
        } else {
          return null;
        }
      }

      return null;
    }

    await makeSureStateIsReady();

    if (!hasClients) return null;

    if (isIndexStateInLayoutRange(index)) {
      _isAutoScrolling = true;

      await _bringIntoViewportIfNeed(index, preferPosition,
          (double offset) async {
        isAnim
            ? await animateTo(offset, duration: duration, curve: Curves.ease)
            : jumpTo(offset + extraOffset);
        await _waitForWidgetStateBuild();
        return null;
      });

      _isAutoScrolling = false;
    } else {
      double prevOffset = offset - 1;
      double currentOffset = offset;
      bool contains = false;
      Duration spentDuration = const Duration();
      double lastScrollDirection = 0.5;
      final moveDuration =
          isAnim ? duration ~/ defaultDurationUnit : Duration.zero;

      _isAutoScrolling = true;

      bool usedSuggestedRowHeightIfAny = true;
      while (prevOffset != currentOffset &&
          !(contains = isIndexStateInLayoutRange(index))) {
        prevOffset = currentOffset;
        final nearest = _getNearestIndex(index);

        if (tagMap[nearest ?? 0] == null) return null;

        final moveTarget =
            _forecastMoveUnit(index, nearest, usedSuggestedRowHeightIfAny)!;

        final suggestedDuration =
            usedSuggestedRowHeightIfAny && suggestedRowHeight != null
                ? duration
                : null;
        usedSuggestedRowHeightIfAny = false;
        lastScrollDirection = moveTarget - prevOffset > 0 ? 1 : 0;
        currentOffset = moveTarget;
        spentDuration += suggestedDuration ?? moveDuration;
        final oldOffset = offset;
        if (isAnim) {
          await animateTo(
            currentOffset,
            duration: suggestedDuration ?? moveDuration,
            curve: Curves.ease,
          );
        } else {
          jumpTo(currentOffset);
        }
        await _waitForWidgetStateBuild();
        if (!hasClients || offset == oldOffset) {
          contains = isIndexStateInLayoutRange(index);
          break;
        }
      }
      _isAutoScrolling = false;

      if (contains && hasClients) {
        await _bringIntoViewportIfNeed(
            index, preferPosition ?? _alignmentToPosition(lastScrollDirection),
            (finalOffset) async {
          if (finalOffset != offset) {
            _isAutoScrolling = true;
            final remaining = duration - spentDuration;
            if (isAnim) {
              await animateTo(
                finalOffset,
                duration: remaining <= Duration.zero ? _millisecond : remaining,
                curve: Curves.ease,
              );
            } else {
              jumpTo(finalOffset);
            }
            await _waitForWidgetStateBuild();

            if (hasClients && offset != finalOffset) {
              const count = 3;
              for (var i = 0;
                  i < count && hasClients && offset != finalOffset;
                  i++) {
                if (isAnim) {
                  await animateTo(
                    finalOffset,
                    duration: _millisecond,
                    curve: Curves.ease,
                  );
                } else {
                  jumpTo(finalOffset);
                }
                await _waitForWidgetStateBuild();
              }
            }
            _isAutoScrolling = false;
          }
        });
      }
    }

    return null;
  }

  @override
  Future highlight(
    int index, {
    bool cancelExistHighlights = true,
    Duration highlightDuration = _highlightDuration,
    bool animated = true,
  }) async {
    final tag = tagMap[index];
    return tag == null
        ? null
        : await tag.highlight(
            cancelExisting: cancelExistHighlights,
            highlightDuration: highlightDuration,
            animated: animated,
          );
  }

  @override
  void cancelAllHighlights() {
    _cancelAllHighlights();
  }

  @override
  bool isIndexStateInLayoutRange(int index) => tagMap[index] != null;

  bool get _isEmptyStates => tagMap.isEmpty;

  Future _waitForWidgetStateBuild() => SchedulerBinding.instance.endOfFrame;

  double? _forecastMoveUnit(
    int targetIndex,
    int? currentNearestIndex,
    bool useSuggested,
  ) {
    assert(targetIndex != currentNearestIndex);
    currentNearestIndex = currentNearestIndex ?? 0;

    final alignment = targetIndex > currentNearestIndex ? 1.0 : 0.0;
    double? absoluteOffsetToViewport;

    if (useSuggested && suggestedRowHeight != null) {
      final indexDiff = (targetIndex - currentNearestIndex);
      final offsetToLastState = _offsetToRevealInViewport(
        currentNearestIndex,
        indexDiff <= 0 ? 0 : 1,
      )!;
      absoluteOffsetToViewport = math.max(
        offsetToLastState.offset + indexDiff * suggestedRowHeight!,
        0,
      );
    } else {
      final offsetToLastState =
          _offsetToRevealInViewport(currentNearestIndex, alignment);

      absoluteOffsetToViewport = offsetToLastState?.offset;
      absoluteOffsetToViewport ??= defaultScrollDistanceOffset;
    }

    return absoluteOffsetToViewport;
  }

  int? _getNearestIndex(int index) {
    final list = tagMap.keys;
    if (list.isEmpty) return null;

    final sorted = list.toList()
      ..sort((int first, int second) => first.compareTo(second));
    final min = sorted.first;
    final max = sorted.last;
    return (index - min).abs() < (index - max).abs() ? min : max;
  }

  Future _bringIntoViewportIfNeed(
    int index,
    AutoScrollPosition? preferPosition,
    Future Function(double offset) move,
  ) async {
    if (preferPosition != null) {
      double targetOffset = _directionalOffsetToRevealInViewport(
        index,
        _positionToAlignment(preferPosition),
      );

      targetOffset = targetOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      await move(targetOffset);
    } else {
      final begin = _directionalOffsetToRevealInViewport(index, 0);
      final end = _directionalOffsetToRevealInViewport(index, 1);

      final alreadyInViewport = offset < begin && offset > end;
      if (!alreadyInViewport) {
        double value;
        if ((end - offset).abs() < (begin - offset).abs()) {
          value = end;
        } else {
          value = begin;
        }

        await move(value > 0 ? value : 0);
      }
    }
  }

  double _positionToAlignment(AutoScrollPosition position) {
    return position == AutoScrollPosition.begin
        ? 0
        : position == AutoScrollPosition.end
            ? 1
            : 0.5;
  }

  AutoScrollPosition _alignmentToPosition(double alignment) => alignment == 0
      ? AutoScrollPosition.begin
      : alignment == 1
          ? AutoScrollPosition.end
          : AutoScrollPosition.middle;

  double _directionalOffsetToRevealInViewport(int index, double alignment) {
    assert(alignment == 0 || alignment == 0.5 || alignment == 1);

    final tagOffsetInViewport = _offsetToRevealInViewport(index, alignment);

    if (tagOffsetInViewport == null) {
      return -1;
    } else {
      double absoluteOffsetToViewport = tagOffsetInViewport.offset;
      if (alignment == 0.5) {
        return absoluteOffsetToViewport;
      } else if (alignment == 0) {
        return absoluteOffsetToViewport - beginGetter(viewportBoundaryGetter());
      } else {
        return absoluteOffsetToViewport + endGetter(viewportBoundaryGetter());
      }
    }
  }

  RevealedOffset? _offsetToRevealInViewport(int index, double alignment) {
    final ctx = tagMap[index]?.context;
    if (ctx == null) return null;

    final renderBox = ctx.findRenderObject()!;
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(renderBox);
    final revealedOffset = viewport.getOffsetToReveal(renderBox, alignment);

    return revealedOffset;
  }
}

void _cancelAllHighlights([AutoScrollTagState? state]) {
  for (final tag in _highlights.keys) {
    tag._cancelController(reset: tag != state);
  }

  _highlights.clear();
}

typedef TagHighlightBuilder = Widget Function(
  BuildContext context,
  Animation<double> highlight,
);

class AutoScrollTag extends StatefulWidget {
  final AutoScrollController controller;
  final int index;
  final Widget? child;
  final TagHighlightBuilder? builder;
  final Color? color;
  final Color? highlightColor;
  final bool disabled;

  const AutoScrollTag({
    required Key key,
    required this.controller,
    required this.index,
    this.child,
    this.builder,
    this.color,
    this.highlightColor,
    this.disabled = false,
  })  : assert(child != null || builder != null),
        super(key: key);

  @override
  AutoScrollTagState createState() {
    return AutoScrollTagState<AutoScrollTag>();
  }
}

Map<AutoScrollTagState, AnimationController?> _highlights =
    <AutoScrollTagState, AnimationController?>{};

class AutoScrollTagState<W extends AutoScrollTag> extends State<W>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.disabled) {
      register(widget.index);
    }
  }

  @override
  void dispose() {
    _cancelController();
    if (!widget.disabled) {
      unregister(widget.index);
    }
    _controller = null;
    _highlights.remove(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.key != widget.key ||
        oldWidget.disabled != widget.disabled) {
      if (!oldWidget.disabled) unregister(oldWidget.index);

      if (!widget.disabled) register(widget.index);
    }
  }

  void register(int index) {
    widget.controller.tagMap[index] = this;
  }

  void unregister(int index) {
    _cancelController();
    _highlights.remove(this);

    if (widget.controller.tagMap[index] == this) {
      widget.controller.tagMap.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = _controller ?? kAlwaysDismissedAnimation;
    return widget.builder?.call(context, animation) ??
        buildHighlightTransition(
          context: context,
          highlight: animation,
          child: widget.child!,
          background: widget.color,
          highlightColor: widget.highlightColor,
        );
  }

  DateTime? _startKey;

  Future highlight({
    bool cancelExisting = true,
    Duration highlightDuration = _highlightDuration,
    bool animated = true,
  }) async {
    if (!mounted) return null;

    if (cancelExisting) {
      _cancelAllHighlights(this);
    }

    if (_highlights.containsKey(this)) {
      assert(_controller != null);
      _controller!.stop();
    }

    if (_controller == null) {
      _controller = AnimationController(vsync: this);
      _highlights[this] = _controller;
    }

    final startKey0 = _startKey = DateTime.now();
    const animationShow = 1.0;
    setState(() {});
    if (animated) {
      await catchAnimationCancel(
        _controller!
            .animateTo(animationShow, duration: scrollAnimationDuration),
      );
    } else {
      _controller!.value = animationShow;
    }
    await Future.delayed(highlightDuration);

    if (startKey0 == _startKey) {
      if (mounted) {
        setState(() {});
        const animationHide = 0.0;
        if (animated) {
          await catchAnimationCancel(
            _controller!
                .animateTo(animationHide, duration: scrollAnimationDuration),
          );
        } else {
          _controller!.value = animationHide;
        }
      }

      if (startKey0 == _startKey) {
        _controller = null;
        _highlights.remove(this);
      }
    }
    return null;
  }

  void _cancelController({bool reset = true}) {
    if (_controller != null) {
      if (_controller!.isAnimating) _controller!.stop();

      if (reset && _controller!.value != 0.0) _controller!.value = 0.0;
    }
  }
}

Widget buildHighlightTransition({
  required BuildContext context,
  required Animation<double> highlight,
  required Widget child,
  Color? background,
  Color? highlightColor,
}) {
  return DecoratedBoxTransition(
    decoration: DecorationTween(
      begin: background != null
          ? BoxDecoration(color: background)
          : const BoxDecoration(),
      end: background != null
          ? BoxDecoration(color: background)
          : BoxDecoration(color: highlightColor),
    ).animate(highlight),
    child: child,
  );
}
