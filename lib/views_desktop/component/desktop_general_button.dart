import 'package:flutter/material.dart';

class DesktopGeneralButton extends StatelessWidget {
  const DesktopGeneralButton({
    super.key,
    this.onPressed,
    required this.child,
    this.horizontalPadding = 10,
  });

  final Function()? onPressed;
  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ButtonStyle(
      overlayColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.transparent;
          }
          return Colors.white;
        },
      ),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: MaterialStateProperty.all<Size>(Size.zero),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: TextButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}
