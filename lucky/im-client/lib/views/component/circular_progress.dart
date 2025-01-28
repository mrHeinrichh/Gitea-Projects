import 'package:flutter/material.dart';
import '../../utils/color.dart';
import 'circular_loading_bar.dart';

class CircularProgress extends StatelessWidget {
  final double progressValue;
  final VoidCallback? onClosePressed;

  const CircularProgress({super.key,
    required this.progressValue,
    this.onClosePressed,
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
            decoration: const BoxDecoration(
              color: JXColors.chatBubbleFileMeBgColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: JXColors.chatBubbleFileMeIconColor,
              size:20,
            ),
          ),
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            bottom: 2,
            child: CircularLoadingBar(
              value: progressValue,
              color: JXColors.chatBubbleFileLoadingColor,
            ),
          ),
        ],
      ),
    );
  }
}
