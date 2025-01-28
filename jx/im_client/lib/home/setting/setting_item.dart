import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class SettingItem extends StatefulWidget {
  final GestureTapCallback? onTap;
  final String? iconName;
  final Color? iconColor;
  final String? title;
  final Color titleColor;
  final Widget? titleWidget;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final bool withBorder;
  final String? rightTitle;
  final int rightTitleFlex;
  final Color rightTitleColor;
  final double rightTitleFontSize;
  final Widget? rightWidget;
  final bool withArrow;
  final Color arrowColor;
  final bool withEffect;
  final Widget? imgWidget;
  final Color bgColor;
  final double paddingVerticalMobile;
  final Widget? badgeWidget;

  const SettingItem({
    super.key,
    this.onTap,
    this.iconName,
    this.iconColor,
    this.title,
    this.titleWidget,
    this.titleColor = colorTextPrimary,
    this.subtitle,
    this.subtitleStyle,
    this.withBorder = true,
    this.rightTitle,
    this.rightTitleFlex = 1,
    this.rightTitleColor = colorTextSecondary,
    this.rightWidget,
    this.withArrow = true,
    this.arrowColor = colorTextSupporting,
    this.withEffect = true,
    this.imgWidget,
    this.bgColor = colorWhite,
    this.rightTitleFontSize = 14,
    this.paddingVerticalMobile = 6,
    this.badgeWidget,
  });

  @override
  State<SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      children: [
        Container(
          constraints: const BoxConstraints(
            minHeight: 44,
          ),
          padding: objectMgr.loginMgr.isDesktop
              ? const EdgeInsets.only(left: 16, top: 8, bottom: 8)
              : EdgeInsets.only(
                  left: 16,
                  top: widget.paddingVerticalMobile,
                  bottom: widget.paddingVerticalMobile),
          child: Row(
            children: [
              if (widget.iconName != null)
                SvgPicture.asset(
                  'assets/svgs/${widget.iconName}.svg',
                  width: 29,
                  height: 29,
                  color: widget.iconColor,
                ),
              if (widget.imgWidget != null) widget.imgWidget!,
              if (widget.iconName != null || widget.imgWidget != null)
                objectMgr.loginMgr.isDesktop
                    ? const SizedBox(width: 16)
                    : ImGap.hGap16,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: widget.badgeWidget != null
                            ? Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.title != null)
                                        Text(
                                          widget.title!,
                                          style: jxTextStyle.headerText(
                                            color: widget.titleColor,
                                          ),
                                        ),
                                      if (widget.titleWidget != null)
                                        widget.titleWidget!,
                                      if (widget.subtitle != null)
                                        Text(
                                          widget.subtitle!,
                                          style: widget.subtitleStyle ??
                                              jxTextStyle.supportText(
                                                color: colorTextSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  widget.badgeWidget!,
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.title != null)
                                    Text(
                                      widget.title!,
                                      style: jxTextStyle.headerText(
                                        color: widget.titleColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (widget.titleWidget != null)
                                    widget.titleWidget!,
                                  if (widget.subtitle != null)
                                    Text(
                                      widget.subtitle!,
                                      style: widget.subtitleStyle ??
                                          jxTextStyle.supportText(
                                            color: colorTextSecondary,
                                          ),
                                    ),
                                ],
                              ),
                      ),
                      if (widget.rightWidget != null) ...[
                        objectMgr.loginMgr.isDesktop
                            ? const SizedBox(width: 8)
                            : ImGap.hGap8,
                        widget.rightWidget!,
                      ],
                      if (widget.rightTitle != null) ...[
                        objectMgr.loginMgr.isDesktop
                            ? const SizedBox(width: 8)
                            : ImGap.hGap8,
                        Expanded(
                          flex: widget.rightTitleFlex,
                          child: Text(
                            textAlign: TextAlign.end,
                            widget.rightTitle!,
                            style: jxTextStyle.headerText(
                                color: widget.rightTitleColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (widget.withArrow) ...[
                        objectMgr.loginMgr.isDesktop
                            ? const SizedBox(width: 8)
                            : ImGap.hGap8,
                        SvgPicture.asset(
                          'assets/svgs/right_arrow_thick.svg',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            widget.arrowColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.withBorder)
          separateDivider(
            indent: widget.iconName != null
                ? 60.0
                : widget.imgWidget != null
                    ? 72.0
                    : 16.0,
          ),
      ],
    );

    if (objectMgr.loginMgr.isDesktop) {
      child = ElevatedButtonTheme(
          data: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.bgColor,
              disabledBackgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              surfaceTintColor: colorBackground6,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0))),
              elevation: 0.0,
            ),
          ),
          child: ElevatedButton(
            onPressed: widget.onTap,
            child: child,
          ));
    } else {
      child = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: OverlayEffect(
          overlayColor:
              !widget.withEffect ? Colors.transparent : colorBackground8,
          child: child,
        ),
      );
    }

    return child;
  }
}
