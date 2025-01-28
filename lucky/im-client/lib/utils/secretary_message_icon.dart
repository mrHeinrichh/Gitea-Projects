import 'package:flutter/material.dart';

class SecretaryMessageIcon extends StatelessWidget {
  final double size;

  const SecretaryMessageIcon({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/message_new/secretary.png',
      width: size,
      height: size,
    );
  }
}
