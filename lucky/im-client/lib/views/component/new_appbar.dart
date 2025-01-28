import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import '../../utils/color.dart';
import '../../utils/theme/text_styles.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    Key? key,
    this.title = '',
    this.titleSpacing,
    this.leading,
    this.leadingWidth,
    this.leadingSpacing,
    this.titleColor = JXColors.primaryTextBlack,
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
    this.scrolledUnderElevation,
  }) : super(key: key);

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
  final double? scrolledUnderElevation;

  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearchingMode
          ? MediaQuery.of(context).viewPadding.top
          : ((MediaQuery.of(context).viewPadding.top) +
          height +
          (bottom?.preferredSize.height ?? 0)),
      child: AppBar(
        elevation: elevation,
        toolbarHeight: height,
        backgroundColor: bgColor ?? backgroundColor,
        scrolledUnderElevation: scrolledUnderElevation,
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
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class CustomLeadingIcon extends StatelessWidget {
  const CustomLeadingIcon(
      {Key? key,
        this.buttonOnPressed,
        this.backButtonColor,
        this.childIcon = 'assets/svgs/Back.svg',
        this.withBackTxt = true,
        this.badgeView,
        this.needPadding = true,
      })
      : super(key: key);

  final void Function()? buttonOnPressed;
  final Color? backButtonColor;
  final String childIcon;
  final bool withBackTxt;
  final bool needPadding;
  final Widget? badgeView;

  @override
  Widget build(BuildContext context) {
    Color color = backButtonColor ?? accentColor;

    return OpacityEffect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: buttonOnPressed ?? () => Get.back(),
        child: Padding(
          padding: EdgeInsets.only(left: needPadding ? 8 : 0),
          child: Row(
            // mainAxisSize: MainAxisSize.min,
            // alignment: Alignment.centerLeft,
            children: [
              SvgPicture.asset(
                childIcon,
                width: 24,
                height: 24,
                color: color,
              ),
              const SizedBox(width: 8),
              badgeView != null
                  ? badgeView!
                  : withBackTxt
                  ? Text(
                localized(buttonBack),
                style: TextStyle(
                  fontSize: objectMgr.loginMgr.isDesktop
                      ? MFontSize.size13.value
                      : MFontSize.size17.value,
                  color: color,
                  height: 1.5,
                ),
              )
                  : const SizedBox()
            ],
          ),
        ),
      ),
    );
  }
}
