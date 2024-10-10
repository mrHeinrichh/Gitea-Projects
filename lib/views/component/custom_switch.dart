import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final Function(bool value) onChanged;

  const CustomSwitch({super.key, required this.value, required this.onChanged});

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    _isEnabled = widget.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isEnabled = !_isEnabled;
        });

        widget.onChanged(_isEnabled);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        width: 52,
        padding: const EdgeInsets.all(4),
        alignment: _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: _isEnabled ? colorGreen : colorTextPlaceholder,
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: const ShapeDecoration(
            color: colorWhite,
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }
}
