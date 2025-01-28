import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class SearchOverlay extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onTapCallback;
  final Color? overlayColor;

  const SearchOverlay({
    super.key,
    required this.isVisible,
    required this.onTapCallback,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          if (onTapCallback != null) {
            onTapCallback!();
          }
        },
        child: Container(
          color: overlayColor ?? colorOverlay40,
        ),
      ),
    );
  }
}
