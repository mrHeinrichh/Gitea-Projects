import 'package:flutter/material.dart';

/// 加载动画
class LoadingLottie extends StatefulWidget {
  final String text;

  const LoadingLottie({super.key, required this.text});

  @override
  _LoadingLottieState createState() => _LoadingLottieState();
}

class _LoadingLottieState extends State<LoadingLottie> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(9),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'packages/im_common/assets/img/lottie_loading.gif',
            height: 30,
          ),
          const SizedBox(height: 6,),
          Text(
            widget.text != "" ? widget.text : "loading",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
