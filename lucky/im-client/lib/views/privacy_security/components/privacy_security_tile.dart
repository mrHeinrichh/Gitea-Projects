import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../home/component/custom_divider.dart';
import '../../../utils/color.dart';

class PrivacySecurityTile extends StatefulWidget {
  const PrivacySecurityTile({
    Key? key,
    required this.title,
    required this.status,
    this.onTap,
    this.showBorder = true,
  }) : super(key: key);
  final String title;
  final String status;
  final GestureTapCallback? onTap;
  final bool showBorder;

  @override
  State<PrivacySecurityTile> createState() => _PrivacySecurityTileState();
}

class _PrivacySecurityTileState extends State<PrivacySecurityTile> {

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanDown: (_) =>
          setState(() {isPressed = true;}),
      onPanUpdate: (_) =>
          setState(() {isPressed = false;}),
      onPanCancel: () =>
          setState(() {isPressed = false;}),
      child: ColoredBox(
        color: isPressed ? const Color(0xFFf8f8f8) : Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 16,
          ),
          decoration: BoxDecoration(
            border: widget.showBorder ? customBorder : null,
          ),
          child: Row(
            children: [
              Text(
                widget.title,
                style: jxTextStyle.textStyle16(),
              ),
              const Spacer(),
              Text(
                '${widget.status}',
                style:
                jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                'assets/svgs/arrow_right.svg',
                width: 24,
                height: 24,
                color: JXColors.secondaryTextBlack,
              ),
            ],
          ),
        ),
      ),
    );;
  }
}
