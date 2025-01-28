import 'package:flutter/cupertino.dart';
import 'package:im_common/im_common.dart';

class CustomCupertinoSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) callBack;

  const CustomCupertinoSwitch({
    super.key,
    required this.value,
    required this.callBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: 48,
      child: CupertinoSwitch(
        value: value,
        activeColor: colorGreen,
        onChanged: (bool value) {
          callBack(value);
        },
      ),
    );
  }
}
