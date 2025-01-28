import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import '../../../utils/loading/ball_circle_loading.dart';
import '../../../utils/loading/ball.dart';
import '../../../utils/loading/ball_style.dart';
import '../../../utils/theme/text_styles.dart';

class PurpleButton extends StatelessWidget {
  const PurpleButton(
      {Key? key, required this.title, this.onPressed, this.color})
      : super(key: key);
  final String title;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: color ?? accentColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: title != ""
                ? FittedBox(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:MFontWeight.bold4.value,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox(
                    height: 20,
                    width: 20,
                    child: BallCircleLoading(
                      radius: 8,
                      ballStyle: BallStyle(
                        size: 4,
                        color: Colors.white,
                        ballType: BallType.solid,
                        borderWidth: 1,
                        borderColor: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
