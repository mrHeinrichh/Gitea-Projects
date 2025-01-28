import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

ReelItemWidget reelItemWidget = ReelItemWidget();

class ReelItemWidget {
  //點讚動畫
  Widget buildAnimation() {
    return Transform.scale(
      scale: 0.6,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Lottie.asset(
          'assets/lottie/double_tap_like_animation.json',
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {});
          },
        ),
      ),
    );
  }
}