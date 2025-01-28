import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

const double kTitleHeight = 24.0;
const double kSearchHeightMax = 36.0;
RxDouble kSearchHeight = 0.0.obs;
const double topBarTitleTopGap = 11.0;
const double topBarSearchBarBottomGap = 9.0;

double getTopBarHeight() {
  double height = kTitleHeight + kSearchHeight.value + 16 + getTotalPinHeight() + topBarSearchBarBottomGap + topBarTitleTopGap;
  // print(
  //     'kTitleHeight---> ${kTitleHeight}  kSearchHeight--->${kSearchHeight.value} getAudioPinHeight--->${getAudioPinHeight()}');
  return height;
}

class ChatViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatViewAppBar({
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
    this.withBackTxt = true,
    this.trailing,
    this.bottom,
    this.isSearchingMode = false,
    this.height = 44,
    this.searchWidget,
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
  final bool withBackTxt;
  final List<Widget>? trailing;
  final PreferredSizeWidget? bottom;
  final bool isSearchingMode;

  final double height;
  final Widget? searchWidget;

  double _getChatViewAppBarHeight(BuildContext context) {
    return isSearchingMode
        ? MediaQuery.of(context).viewPadding.top + kSearchHeightMax + topBarSearchBarBottomGap
        : MediaQuery.of(context).viewPadding.top + getTopBarHeight();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _getChatViewAppBarHeight(context),
      child: AppBar(
        elevation: 0.0,
        toolbarHeight: _getChatViewAppBarHeight(context),
        backgroundColor: bgColor ?? backgroundColor,
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        leadingWidth: leadingWidth ?? 90.w,
        leading: leading,
        titleSpacing: 0,
        title: titleWidget,
        actions: trailing,
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(getTopBarHeight());
}
