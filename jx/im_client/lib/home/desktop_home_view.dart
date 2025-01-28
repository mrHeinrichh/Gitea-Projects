import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/bottom_navigator_item.dart';

class DesktopHomeView extends GetView<HomeController> {
  const DesktopHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              ///actual view for different tab
              TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.tabController,
                children: controller.pageWidget,
              ),

              ///bottom navigation bar
              if (constraints.maxWidth > 675)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: 300,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorBackground6,
                          width: 1,
                        ),
                      ),
                    ),
                    child: GetBuilder(
                      init: controller,
                      id: 'bottomNav',
                      builder: (context) => BottomAppBar(
                        elevation: 0,
                        child: Container(
                          color: colorBackground,
                          child: SizedBox(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 0),
                              child: Row(
                                children: <Widget>[
                                  Obx(
                                    () => BottomNavigatorItem(
                                      index: 0,
                                      title: localized(homeChat),
                                      selectIndex: controller.pageIndex.value,
                                      width: 30,
                                      height: 26,
                                      activeIcon: SvgPicture.asset(
                                        'assets/svgs/Chat.svg',
                                        color: themeColor,
                                        width: 30,
                                        height: 26,
                                      ),
                                      inactiveIcon: SvgPicture.asset(
                                        'assets/svgs/Chat.svg',
                                        color: colorTextSecondary,
                                        width: 30,
                                        height: 26,
                                      ),
                                      badge: objectMgr
                                          .chatMgr.totalUnreadCount.value,
                                      onChange: controller.onPageChange,
                                      onDoubleTap: (int index) {},
                                    ),
                                  ),
                                  Obx(
                                    () => BottomNavigatorItem(
                                      index: 1,
                                      title: localized(homeContact),
                                      selectIndex: controller.pageIndex.value,
                                      width: 30,
                                      height: 26,
                                      activeIcon: SvgPicture.asset(
                                        'assets/svgs/Contact.svg',
                                        color: themeColor,
                                      ),
                                      inactiveIcon: SvgPicture.asset(
                                        'assets/svgs/Contact.svg',
                                        color: colorTextSecondary,
                                      ),
                                      onChange: controller.onPageChange,
                                      badge: controller.requestCount.value == 0
                                          ? null
                                          : controller.requestCount.value,
                                    ),
                                  ),
                                  Obx(
                                    () => BottomNavigatorItem(
                                      index: 3,
                                      title: localized(homeSetting),
                                      selectIndex: controller.pageIndex.value,
                                      width: 30,
                                      height: 26,
                                      activeIcon: SvgPicture.asset(
                                        'assets/svgs/Settings.svg',
                                        color: themeColor,
                                      ),
                                      inactiveIcon: SvgPicture.asset(
                                        'assets/svgs/Settings.svg',
                                        color: colorTextSecondary,
                                      ),
                                      onChange: controller.onPageChange,
                                      redDot: controller.isShowRedDot.value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
