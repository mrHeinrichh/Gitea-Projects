import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CircularCountdown extends StatefulWidget {
  final int? countDownSec;
  final double? animationProgress;
  final bool isInfinity;
  final ValueChanged<int>? onChanged;
  final Color? progressColor;
  final Color? progressBgColor;

  const CircularCountdown({
    super.key,
    this.countDownSec = 0,
    this.animationProgress = 1.0,
    this.isInfinity = false,
    this.onChanged,
    this.progressColor = colorGreen,
    this.progressBgColor = const Color(0xFFcaedc0),
  });

  @override
  CircularCountdownState createState() => CircularCountdownState();
}

class CircularCountdownState extends State<CircularCountdown>
    with TickerProviderStateMixin {
  late AnimationController controller;

  bool isPlaying = true;

  String get countText {
    Duration count = controller.duration! * controller.value;
    return _getCountText(count);
  }

  _getCountText(count) {
    int hour = count.inHours;
    int min = count.inMinutes % 60;

    if (hour != 0) {
      return '${count.inHours + 1}h';
    } else if (count.inMinutes != 0) {
      return '${min + 1}';
    } else {
      return '1';
    }
  }

  double progress = 1.0;

  void notify() {
    Duration count = controller.duration! * controller.value;
    if (controller.isDismissed) {
      widget.onChanged?.call(0);
    }
    if (controller.isAnimating) {
      widget.onChanged?.call(count.inSeconds);
    }
  }

  @override
  void initState() {
    super.initState();

    if (!widget.isInfinity) {
      controller = AnimationController(
        vsync: this,
        value: widget.animationProgress,
        duration: Duration(seconds: widget.countDownSec as int),
      );

      controller.reverse(from: controller.value == 0 ? 1.0 : controller.value);

      controller.addListener(animationListener);
    }
  }

  void animationListener() {
    notify();
    if (controller.isAnimating) {
      setState(() {
        progress = controller.value;
      });
    } else {
      setState(() {
        progress = 1.0;
        isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(animationListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Transform.flip(
                flipX: true,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: widget.progressColor,
                  backgroundColor: widget.progressBgColor,
                  strokeCap: StrokeCap.round,
                  value: progress,
                ),
              ),
            ),
            widget.isInfinity
                ? SvgPicture.asset(
                    'assets/svgs/infinity.svg',
                    width: 16,
                    height: 16,
                  )
                : AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) => Text(
                      countText,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
