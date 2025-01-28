import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';

class CompassBtn extends StatelessWidget {
  final Function()? onPressed;

  const CompassBtn({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 44,
          width: 44,
          margin: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                spreadRadius: 0,
                blurRadius: 16,
                offset: const Offset(0, 0),
              )
            ],
            color: JXColors.compassBg,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                'assets/icons/icon_compass.png',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
