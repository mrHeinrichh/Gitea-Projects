import 'package:flutter/material.dart';

class SavedMessageIcon extends StatelessWidget {
  final double size;

  const SavedMessageIcon({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset('assets/images/message_new/saved.png',
        width: size,
        height: size,
      ),
    );
  }
}
