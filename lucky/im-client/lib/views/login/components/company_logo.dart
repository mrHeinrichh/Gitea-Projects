import 'package:flutter/material.dart';

class CompanyLogo extends StatelessWidget {
  final double width;
  final double? radius;

  const CompanyLogo({
    Key? key,
    this.width = 90,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? width * 0.4),
        child: Image.asset(
          'assets/icons/img.png',
          width: width,
        ),
      ),
    );
  }
}
