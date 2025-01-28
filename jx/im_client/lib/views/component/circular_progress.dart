import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';

class CircularProgress extends StatelessWidget {
  final double progressValue;
  final VoidCallback? onClosePressed;
  final Color? color;

  const CircularProgress({
    super.key,
    required this.progressValue,
    this.onClosePressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClosePressed,
      child: Stack(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color ?? bubblePrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: colorWhite,
              size: 20,
            ),
          ),
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            bottom: 2,
            child: CircularLoadingBar(
              value: progressValue,
              color: colorWhite,
            ),
          ),
        ],
      ),
    );
  }
}
