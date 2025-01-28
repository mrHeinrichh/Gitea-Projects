import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CustomRoundContainer extends StatelessWidget {
  final String? title;
  final String? rightTitle;
  final String? bottomText;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double? height;
  final double? width;
  final double radius;
  final Color bgColor;
  final BoxConstraints? constraints;
  final Color? titleColor;

  const CustomRoundContainer({
    super.key,
    this.title,
    this.rightTitle,
    this.bottomText,
    this.margin,
    this.padding = EdgeInsets.zero,
    required this.child,
    this.height,
    this.width,
    this.radius = 8,
    this.bgColor = colorWhite,
    this.constraints,
    this.titleColor = colorTextLevelTwo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || rightTitle != null) _buildHeader(),
          Flexible(
            child: Container(
              constraints: constraints,
              height: height,
              width: width ?? double.infinity,
              clipBehavior: Clip.hardEdge,
              padding: padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: child,
            ),
          ),
          if (bottomText != null) _buildBottomTextWidget(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 4, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title ?? '',
            style: jxTextStyle.normalSmallText(
              color: titleColor,
            ),
          ),
          Text(
            rightTitle ?? '',
            style: jxTextStyle.normalSmallText(color: colorTextPlaceholder),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTextWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, right: 16),
      child: Text(
        bottomText!,
        style: jxTextStyle.normalSmallText(
          color: colorTextLevelTwo,
        ),
      ),
    );
  }
}
