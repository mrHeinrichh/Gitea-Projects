import 'package:flutter/material.dart';

class CustomImageButton extends StatelessWidget {
  const CustomImageButton({
    super.key,
    required this.width,
    required this.height,
    required this.bgColor,
    required this.radius,
    required this.imageWidth,
    required this.imageName,
    required this.onClick,
  });
  final double width;
  final double height;
  final Color bgColor;
  final double radius;
  final double imageWidth;
  final String imageName;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          imageName,
          width: imageWidth,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
