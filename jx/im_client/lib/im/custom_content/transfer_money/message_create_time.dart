import 'package:flutter/cupertino.dart';
import 'package:im_common/im_common.dart';

class MessageCreateTime extends StatelessWidget {
  final String createTime;
  final Color? color;

  const MessageCreateTime({super.key, required this.createTime, this.color});

  @override
  Widget build(BuildContext context) {
    return ImText(
      createTime,
      color: color ?? ImColor.black48,
      fontSize: ImFontSize.small,
    );
  }
}
