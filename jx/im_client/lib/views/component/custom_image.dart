import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomImage extends StatelessWidget {
  final String path;
  final bool isAsset;
  final Color? color;
  final double size;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final BoxFit fit;
  final Function()? onClick;

  const CustomImage(
    this.path, {
    super.key,
    this.isAsset = false,
    this.color,
    this.size = 16,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.fit = BoxFit.fill,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    double iconWidth = width ?? size;
    double iconHeight = height ?? size;
    BoxFit iconFit = fit;

    Widget child = Padding(
      padding: padding,
      child: isAsset
          ? Image.asset(
              path,
              width: iconWidth,
              height: iconHeight,
              fit: iconFit,
            )
          : SvgPicture.asset(
              path,
              width: iconWidth,
              height: iconHeight,
              clipBehavior: Clip.none,
              colorFilter: color != null
                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                  : null,
              fit: iconFit,
            ),
    );

    return onClick != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClick,
              behavior: HitTestBehavior.opaque,
              child: OpacityEffect(child: child),
            ),
          )
        : child;
  }
}
