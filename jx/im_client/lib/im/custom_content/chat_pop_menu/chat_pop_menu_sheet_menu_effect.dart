import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';

class ChatPopMenuSheetMenuEffect extends StatefulWidget {
  const ChatPopMenuSheetMenuEffect({
    super.key,
    required this.child,
    required this.num,
    required this.index,
    this.itemHeight = 44,
    this.itemTouch,
    this.isShowSeen = false,
    this.isSubList = false,
    this.isNeedVibrate = true,
    this.isShowMore = false,
    this.itemTouchEnd,
    this.itemTouchUpDown,
  });
  final Widget child;
  final int num;
  final int index;
  final double? itemHeight;
  final bool? isShowSeen;
  final bool? isSubList;
  final bool? isNeedVibrate;
  final bool? isShowMore;
  final ValueChanged<int>? itemTouchUpDown;
  final ValueChanged<int>? itemTouch;
  final ValueChanged<int>? itemTouchEnd;

  @override
  State<ChatPopMenuSheetMenuEffect> createState() =>
      _ChatPopMenuSheetMenuEffectState();
}

class _ChatPopMenuSheetMenuEffectState
    extends State<ChatPopMenuSheetMenuEffect> {
  bool isHighLight = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        int index = touchAreaIndex(event.localPosition);
        if (index != widget.index) {
          if (widget.isNeedVibrate!) {
            vibrate();
          }
          widget.itemTouch?.call(index);
        }
        widget.itemTouchUpDown?.call(index);
      },
      onPointerMove: (event) {
        int index = touchAreaIndex(event.localPosition);
        if (index != widget.index) {
          if (widget.isNeedVibrate!) {
            vibrate();
          }
          widget.itemTouch?.call(index);
        }
        // isSameIndex(event.localPosition);
      },
      onPointerUp: (event) {
        int index = touchAreaIndex(event.localPosition);
        widget.itemTouchEnd?.call(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: (isHighLight)
              ? colorTextPrimary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
        child: widget.child,
      ),
    );
  }

  void isSameIndex(Offset offset) {
    int index = touchAreaIndex(offset);
    if (index != widget.index) {
      if (widget.isNeedVibrate!) {
        vibrate();
      }
      widget.itemTouch?.call(index);
    }
  }

  int touchAreaIndex(Offset offset) {
    int index = -1;
    for (int i = 0; i < widget.num; i++) {
      double touchAreaMin = getAreaHeight(i);
      double touchAreaMax = getAreaHeight(i + 1);
      if (offset.dy >= touchAreaMin && offset.dy < touchAreaMax) {
        if (offset.dx >= 0 && offset.dx <= 240) {
          index = i;
          break;
        }
      }
    }
    return index;
  }

  double getAreaHeight(int index) {
    double totalHeight = 0;
    List<double> listItemHeights = List.filled(widget.num, widget.itemHeight!);
    if (widget.isShowSeen! || widget.isSubList!) {
      listItemHeights.first = 51.0;
    }
    if (widget.isShowMore!) {
      listItemHeights.last = 51.0;
    }
    for (int i = 0; i < index; i++) {
      totalHeight = totalHeight + listItemHeights[i];
    }

    return totalHeight;
  }
}
