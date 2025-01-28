import 'package:flutter/cupertino.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';

class ScrollEventDispatcher extends BouncingScrollPhysics {
  final ChatContentController controller;

  const ScrollEventDispatcher(this.controller, {super.parent});

  static final List<Function> funcList = [];

  static double diff = -1;

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ScrollEventDispatcher(controller, parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((position.pixels <= position.minScrollExtent && velocity < 0) ||
        (position.pixels >= position.maxScrollExtent && velocity > 0)) {
      // 當速度接近停止時，直接微弱回彈
      if (velocity.abs() < 50.0) {  //50 是自訂的速度閾值
        return BouncingScrollSimulation(
          spring: const SpringDescription(
            mass: 30.0,
            stiffness: 100.0,
            damping: 1.0,
          ),
          position: position.pixels,
          velocity: 0.1,
          leadingExtent: position.minScrollExtent,
          trailingExtent: position.maxScrollExtent,
        );
      }

      return BouncingScrollSimulation(
        spring: const SpringDescription(
          mass: 20.0,
          stiffness: 200.0,
          damping: 5.0,
        ),
        position: position.pixels,
        velocity: velocity * 0.8, // 減弱回彈速度
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }


  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
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
        velocity: 0.0,
      );
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }

  @override
  bool recommendDeferredLoading(
    double velocity,
    ScrollMetrics metrics,
    BuildContext context,
  ) =>
      false;
}
