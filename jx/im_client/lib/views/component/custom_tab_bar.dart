import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabList;

  const CustomTabBar({
    super.key,
    required this.tabController,
    required this.tabList,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      splashFactory: NoSplash.splashFactory,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      controller: tabController,
      dividerColor: Colors.transparent,
      isScrollable: true,
      indicator: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: jxTextStyle
          .normalSmallText(fontWeight: MFontWeight.bold5.value)
          .copyWith(
            leadingDistribution: TextLeadingDistribution.even,
          ),
      labelColor: colorTextPrimary,
      unselectedLabelColor: colorTextPrimary,
      unselectedLabelStyle: jxTextStyle
          .normalSmallText(fontWeight: MFontWeight.bold4.value)
          .copyWith(
            leadingDistribution: TextLeadingDistribution.even,
          ),
      labelPadding: EdgeInsets.zero,
      tabs: tabList.map((title) {
        return Tab(
          child: OpacityEffect(
            child: Container(
              alignment: Alignment.center,
              width: 75,
              child: Text(title),
            ),
          ),
        );
      }).toList(),
    );
  }
}
