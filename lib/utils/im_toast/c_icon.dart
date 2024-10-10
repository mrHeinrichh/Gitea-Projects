import 'package:flutter/material.dart';

class CIcon extends StatelessWidget {
  const CIcon({
    super.key,
    required this.icon,
    this.width = 14,
    this.onClick,
    this.colorFilter,
    this.height,
    this.padding,
  });

  final Color? colorFilter;
  final String icon;
  final double width;
  final GestureTapCallback? onClick;
  final double? height;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Container(
          height: height ?? width,
          width: width,
          decoration: BoxDecoration(
            color: Colors.transparent,
            image: DecorationImage(
              image: AssetImage('packages/im_common/assets/img/$icon.png'),
              fit: BoxFit.fill,
              colorFilter: colorFilter != null
                  ? ColorFilter.mode(colorFilter!, BlendMode.srcIn)
                  : null,
            ),
          ),
          // ),
          // child: Image.asset('assets/$icon.png'),
        ),
      ),
    );
  }
}
