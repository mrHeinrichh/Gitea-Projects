import 'package:flutter/material.dart';

class SystemMessageIcon extends StatelessWidget {
  final double size;

  const SystemMessageIcon({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset('assets/images/message_new/system.png',
        width: size,
        height: size,
      ),
    );
  }
}
