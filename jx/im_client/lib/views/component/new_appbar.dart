import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    super.key,
    this.title = '',
    this.titleSpacing,
    this.leading,
    this.leadingWidth,
    this.leadingSpacing,
    this.titleColor = colorTextPrimary,
    this.bgColor,
    this.elevation = 0.0,
    this.centerTitle = true,
    this.titleWidget,
    this.isBackButton = true,
    this.withBackTxt = true,
    this.backButtonColor,
    this.onPressedBackBtn,
    this.trailing,
    this.bottom,
    this.isSearchingMode = false,
    this.height = 44,
    this.systemOverlayStyle,
    this.withBottomBorder = true,
  });

  final String title;
  final double? titleSpacing;
  final Widget? leading;
  final double? leadingWidth;
  final double? leadingSpacing;
  final Color? bgColor;
  final Color titleColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? titleWidget;
  final bool isBackButton;
  final bool withBackTxt;
  final Color? backButtonColor;
  final void Function()? onPressedBackBtn;
  final List<Widget>? trailing;
  final PreferredSizeWidget? bottom;
  final bool isSearchingMode;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double height;
  final bool withBottomBorder;

  @override
  Widget build(BuildContext context) {
    return objectMgr.loginMgr.isDesktop
        ? Container(
            height: preferredSize.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor ?? colorBackground,
              border: withBottomBorder ? customBorder : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: leading != null ? leading! : isBackButton
                      ? CustomLeadingIcon(
                          buttonOnPressed: onPressedBackBtn,
                          backButtonColor: backButtonColor,
                          withBackTxt: withBackTxt,
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: MFontWeight.bold5.value,
                      height: jxTextStyle.textHeight,
                      color: titleColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: trailing ?? [],
                  ),
                ),
              ],
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isSearchingMode
                ? MediaQuery.of(context).viewPadding.top
                : ((MediaQuery.of(context).viewPadding.top) +
                    height +
                    (bottom?.preferredSize.height ?? 0)),
            child: AppBar(
              systemOverlayStyle: systemOverlayStyle,
              elevation: elevation,
              toolbarHeight: height,
              backgroundColor: bgColor ?? colorBackground,
              centerTitle: centerTitle,
              automaticallyImplyLeading: false,
              leadingWidth: leadingWidth ?? 90.w,
              leading: isBackButton
                  ? CustomLeadingIcon(
                      buttonOnPressed: onPressedBackBtn,
                      backButtonColor: backButtonColor,
                      withBackTxt: withBackTxt,
                    )
                  : leading,
              titleSpacing: titleSpacing,
              title: isSearchingMode
                  ? const SizedBox()
                  : Padding(
                      padding: EdgeInsets.only(left: leadingSpacing ?? 0),
                      child: titleWidget ??
                          Text(
                            title,
                            style: jxTextStyle.appTitleStyle(color: titleColor),
                          ),
                    ),
              actions: trailing,
              bottom: bottom,
            ),
          );
  }

  @override
  Size get preferredSize => Size.fromHeight(objectMgr.loginMgr.isDesktop
      ? 50
      : kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class CustomLeadingIcon extends StatelessWidget {
  const CustomLeadingIcon({
    super.key,
    this.buttonOnPressed,
    this.backButtonColor,
    this.childIcon = 'assets/svgs/Back.svg',
    this.withBackTxt = true,
    this.badgeView,
    this.needPadding = true,
  });

  final void Function()? buttonOnPressed;
  final Color? backButtonColor;
  final String childIcon;
  final bool withBackTxt;
  final bool needPadding;
  final Widget? badgeView;

  @override
  Widget build(BuildContext context) {
    bool isDesktop = objectMgr.loginMgr.isDesktop;
    Color color = backButtonColor ?? themeColor;

    return OpacityEffect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: buttonOnPressed ?? Get.back,
        child: Padding(
          padding: EdgeInsets.only(left: needPadding ? isDesktop ? 16 : 8 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                childIcon,
                width: isDesktop ? 20 : 24,
                height: isDesktop ? 20 : 24,
                color: color,
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              badgeView != null
                  ? badgeView!
                  : withBackTxt
                      ? Text(
                          localized(buttonBack),
                          style: TextStyle(
                            fontSize: MFontSize.size17.value,
                            color: color,
                            height: 1.5,
                          ),
                        )
                      : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
