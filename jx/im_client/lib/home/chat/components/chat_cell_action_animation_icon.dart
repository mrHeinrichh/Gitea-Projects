import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ChatCellActionAnimationController extends GetxController
    with SingleGetTickerProviderMixin {
  AnimationController? animationController;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void onClose() {
    if (animationController?.isAnimating ?? false) {
      animationController?.stop();
    }
    animationController?.dispose();
    animationController = null;
    super.onClose();
  }

  void startAnimation() {
    var animController = animationController;
    if (animController == null) return;

    if (!animController.isAnimating) {
      animController
        ..reset()
        ..forward();
    }
  }

  void resetAnimation() {
    var animController = animationController;
    if (animController == null) return;

    if (animController.isAnimating) {
      animController.stop();
    }
    animController.reset();
  }
}

class ChatCellActionAnimationIcon extends StatelessWidget {
  final String chatID;
  final String path;
  final double width;
  final double height;

  const ChatCellActionAnimationIcon({
    required this.chatID,
    required this.path,
    this.width = 24.0,
    this.height = 24.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GetBuilder<ChatCellActionAnimationController>(
        tag: 'chat_item_$chatID',
        builder: (controller) {
          return Lottie.asset(
            path,
            controller: controller.animationController,
          );
        },
      ),
    );
  }
}
