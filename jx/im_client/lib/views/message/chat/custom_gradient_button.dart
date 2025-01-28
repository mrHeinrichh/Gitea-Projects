import 'package:jxim_client/utils/color.dart';
import 'package:flutter/material.dart';

class CustomGradientButton extends StatelessWidget {
  const CustomGradientButton({
    super.key,
    required this.onPress,
    required this.width,
    required this.height,
    required this.gradientColor,
    required this.textColor,
    required this.fontSize,
    required this.radius,
    required this.title,
    required this.enable,
    this.type = 0,
    this.enableColor = const [Color(0xffcccccc), Color(0xffcccccc)],
    this.fontWeight = FontWeight.normal,
  });
  final VoidCallback onPress;
  final double width;
  final double height;
  final List<Color> gradientColor;
  final Color textColor;
  final double fontSize;
  final double radius;
  final String title;
  final bool enable;
  final List<Color> enableColor;
  final int type;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enable ? onPress : () {},
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: enable ? gradientColor : enableColor,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            type == 1
                ? BoxShadow(
                    color: enable ? hexColor(0xDD5E0B) : Colors.transparent,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 0),
                  )
                : const BoxShadow(
                    color: Colors.transparent,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, 0),
                  ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            decoration: TextDecoration.none,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
