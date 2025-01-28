import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';

class MiniAppIcon extends StatelessWidget {
  final double size;

  const MiniAppIcon({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.0,
      height: 60.0,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3596FF),
            colorReadColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: const Icon(
        Icons.category,
        size: 36.0,
        color: colorWhite,
      ),
    );
  }
}
