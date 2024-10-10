import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomBottomSheetContent extends StatelessWidget {
  final bool showHeader;
  final Color? bgColor;
  final double topRadius;
  final String title;
  final Color? titleColor;
  final EdgeInsetsGeometry? titlePadding;
  final double? height;
  final bool showDivider;
  final Widget? topChild;
  final Widget middleChild;
  final Widget? bottomChild;
  final Widget? leading;
  final Widget? trailing;
  final bool showCancelButton;
  final VoidCallback? onCancelClick;
  final bool useTopSafeArea;
  final bool useBottomSafeArea;
  final double headerHeight;

  const CustomBottomSheetContent({
    super.key,
    this.showHeader = true,
    this.bgColor,
    this.topRadius = 12,
    this.title = '',
    this.titleColor,
    this.height,
    this.showDivider = false,
    this.topChild,
    required this.middleChild,
    this.bottomChild,
    this.leading,
    this.trailing,
    this.showCancelButton = false,
    this.onCancelClick,
    this.useTopSafeArea = false,
    this.useBottomSafeArea = true,
    this.headerHeight = 60,
    this.titlePadding,
  });

  @override
  Widget build(BuildContext context) {
    final double topMargin =
        useTopSafeArea ? MediaQuery.of(Get.context!).viewPadding.top : 0;
    final double bottomPadding =
        useBottomSafeArea ? MediaQuery.of(context).padding.bottom : 0;

    return Container(
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.only(top: topMargin),
      padding: EdgeInsets.only(bottom: bottomPadding),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor ?? colorBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: showHeader ? headerHeight : 0,
              child: _buildHeader(context),
            ),
            if (topChild != null) topChild!,
            if (showDivider) const CustomDivider(),
            Flexible(child: middleChild),
            if (bottomChild != null) bottomChild!,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget? leadingWidget = leading;

    if (showCancelButton) {
      leadingWidget = CustomTextButton(
        localized(cancel),
        padding: const EdgeInsets.only(right: 16),
        onClick: onCancelClick ?? Get.back,
      );
    }

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Padding(
          padding: titlePadding ?? const EdgeInsets.all(0),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jxTextStyle.textStyleBold17(color: titleColor),
          ),
        ),
        if (leadingWidget != null)
          Align(
            alignment: Alignment.centerLeft,
            child: leadingWidget,
          ),
        if (trailing != null)
          Align(
            alignment: Alignment.centerRight,
            child: trailing,
          ),
      ],
    );
  }
}
