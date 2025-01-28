import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import '../main.dart';
import '../utils/color.dart';
import '../utils/lang_util.dart';
import '../utils/localization/app_localizations.dart';
import '../views/component/bottom_navigator_item.dart';

class DesktopHomeView extends GetView<HomeController> {
  const DesktopHomeView({Key? key}) : super(key: key);

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
                    width: 320,
                    height: 65,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: JXColors.outlineColor,
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
                          color: surfaceBrightColor,
                          child: Row(
                            children: <Widget>[
                              Obx(
                                () => BottomNavigatorItem(
                                  index: 0,
                                  title: localized(homeChat),
                                  selectIndex: controller.pageIndex.value,
                                  activeIcon: SvgPicture.asset(
                                    'assets/svgs/Chat.svg',
                                    color: accentColor,
                                  ),
                                  inactiveIcon: SvgPicture.asset(
                                    'assets/svgs/Chat.svg',
                                    color: JXColors.iconPrimaryColor,
                                  ),
                                  badge:
                                      objectMgr.chatMgr.totalUnreadCount.value,
                                  onChange: controller.onPageChange,
                                  onDoubleTap: (int index) {},
                                ),
                              ),
                              Obx(
                                () => BottomNavigatorItem(
                                  index: 2,
                                  title: localized(homeContact),
                                  selectIndex: controller.pageIndex.value,
                                  activeIcon: SvgPicture.asset(
                                    'assets/svgs/Contact.svg',
                                    color: accentColor,
                                  ),
                                  inactiveIcon: SvgPicture.asset(
                                    'assets/svgs/Contact.svg',
                                    color: JXColors.iconPrimaryColor,
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
                                  activeIcon: SvgPicture.asset(
                                    'assets/svgs/Settings.svg',
                                    color: accentColor,
                                  ),
                                  inactiveIcon: SvgPicture.asset(
                                    'assets/svgs/Settings.svg',
                                    color: JXColors.iconPrimaryColor,
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
            ],
          );
        },
      ),
    );
  }
}
