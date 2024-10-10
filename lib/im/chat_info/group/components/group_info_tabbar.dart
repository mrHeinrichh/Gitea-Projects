import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/group/components/group_info_more_select_widget.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupInfoTabBar extends StatelessWidget {
  const GroupInfoTabBar({
    super.key,
    required this.controller,
  });

  final GroupChatInfoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final shouldAlignStart = controller.setScrollable();
      return Container(
        key: controller.tabBarKey,
        margin: jxDimension.infoViewTabBarPadding(),
        width: double.infinity,
        height: 46.0,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: controller.groupTabOptions.isEmpty
              ? ImColor.systemBg
              : controller.scrollTabColors.value == 0
                  ? colorWhite
                  : ImColor.systemBg,
          // borderRadius: jxDimension.infoViewTabBarBorder(),
          border: customBorder,
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstChild: DecoratedBox(
            decoration: BoxDecoration(
              border: customBorder,
            ),
            child: controller.groupTabOptions.isNotEmpty
                ? Container(
                    alignment: shouldAlignStart ? Alignment.centerLeft : null,
                    child: TabBar(
                      //只有一個tab去掉左邊多餘offset
                      // tabAlignment: controller.groupTabOptions.length == 1 || controller.setScrollable()
                      //     ? TabAlignment.start : null,
                      onTap: controller.onTabChange,
                      isScrollable: shouldAlignStart,
                      indicatorColor: themeColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: themeColor,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      unselectedLabelColor: colorTextSecondary,
                      unselectedLabelStyle: jxTextStyle.textStyle14(),
                      labelColor: themeColor,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      labelStyle: jxTextStyle.textStyleBold14(),
                      controller: controller.tabController,
                      tabs: [
                        if (controller.groupTabOptions.isNotEmpty)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[0].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 1)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[1].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 2)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[2].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 3)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[3].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 4)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[4].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 5)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[5].stringKey,
                            ),
                          ),
                        if (controller.groupTabOptions.length > 6)
                          Tab(
                            text: localized(
                              controller.groupTabOptions[6].stringKey,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
          secondChild: GroupInfoMoreSelectWidget(controller: controller),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          crossFadeState: controller.onMoreSelect.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      );
    });
  }
}
