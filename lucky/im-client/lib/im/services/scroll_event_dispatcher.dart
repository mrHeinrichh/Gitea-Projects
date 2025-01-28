import 'package:flutter/cupertino.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';

class ScrollEventDispatcher extends BouncingScrollPhysics {
  final ChatContentController controller;

  const ScrollEventDispatcher(this.controller, {super.parent});

  static final List<Function> funcList = [];

  static double diff = -1;

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ScrollEventDispatcher(this.controller,
        parent: buildParent(ancestor));
  }

  @override
  double adjustPositionForNewDimensions(
      {required ScrollMetrics oldPosition,
      required ScrollMetrics newPosition,
      required bool isScrolling,
      required double velocity}) {
    if (oldPosition.maxScrollExtent != newPosition.maxScrollExtent &&
        !isScrolling) {
      if (funcList.isNotEmpty) {
        if (diff == -1) {
          diff = oldPosition.maxScrollExtent;
        } else {
          diff = diff - oldPosition.maxScrollExtent;

          if (diff > 0) {
            for (final func in funcList) {
              func(newPosition.maxScrollExtent).call();
            }
          }
          funcList.clear();
        }
      }
    }

    if (newPosition.minScrollExtent != oldPosition.minScrollExtent &&
        !isScrolling) {
      double scrollExtentDiff =
          newPosition.minScrollExtent.abs() - oldPosition.minScrollExtent.abs();
      // if (scrollExtentDiff < 40) {
      //   objectMgr.chatMgr.event(
      //     objectMgr.chatMgr,
      //     ChatMgr.eventScrollExtentChange,
      //     data: newPosition.minScrollExtent,
      //   );
      // }
    }

    if (controller.chatController.popupEnabled) {
      return super.adjustPositionForNewDimensions(
          oldPosition: oldPosition,
          newPosition: oldPosition,
          isScrolling: isScrolling,
          velocity: 0.0);
    }
    return super.adjustPositionForNewDimensions(
        oldPosition: oldPosition,
        newPosition: newPosition,
        isScrolling: isScrolling,
        velocity: velocity);
  }
}
