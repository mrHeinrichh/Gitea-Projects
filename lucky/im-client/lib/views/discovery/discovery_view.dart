import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/discovery/discovery_controller.dart';
import 'package:jxim_client/views/discovery/discovery_tab_bar.dart';

class DiscoveryView extends StatefulWidget {
  const DiscoveryView({super.key});

  @override
  State<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<DiscoveryView> {
  @override
  Widget build(BuildContext context) {
    final DiscoveryController controller = Get.find<DiscoveryController>();
    final tabTextStyle = TextStyle(
      color: ImColor.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ).useSystemChineseFont();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PrimaryAppBar(
        bgColor: backgroundColor,
        isBackButton: false,
        elevation: 0,
        titleSpacing: 44,
        titleWidget: IntrinsicWidth(
          child: Container(
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: ImColor.black3,
              borderRadius: BorderRadius.circular(12),
              shape: BoxShape.rectangle,
            ),
            child: TabBar(
              controller: controller.tabController,
              // isScrollable: true,
              physics: const NeverScrollableScrollPhysics(),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: double.minPositive,
              indicatorPadding: const EdgeInsets.all(2),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: tabTextStyle,
              labelPadding: EdgeInsets.symmetric(horizontal: 24.w),
              unselectedLabelStyle: tabTextStyle,
              tabs: [
                Tab(text: localized(discovery_recommend)),
                Tab(text: localized(discovery_collection)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabHeaderBar(),
          Expanded(
            child: Container(
              color: backgroundColor,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0)),
                ),
                child: TabBarView(
                  controller: controller.tabController,
                  children: controller.tabList,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeaderBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ImColor.bg,
      ),
      alignment: Alignment.center,
      child: Obx(() {
        final DiscoveryController controller = Get.find<DiscoveryController>();
        final tabIndex = controller.currentTabIndex.value;
        return DiscoveryTabBar(
          controller: tabIndex == 0
              ? controller.tagsTabControllerRecommend
              : controller.tagsTabControllerCollection,
          tabTitles: tabIndex == 0
              ? controller.tagsTitleListRecommend
              : controller.tagsTitleListCollection,
          onTabSelected: (index) {
            setState(() {
              tabIndex == 0
                  ? controller.tagIndexRecommend.value = index
                  : controller.tagIndexCollection.value = index;
            });
          },
          isScrollable: true,
        );
      }),
    );
  }
}
