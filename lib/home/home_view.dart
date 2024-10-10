import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/version_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/bottom_navigator_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:move_to_background/move_to_background.dart';

import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  ChatListController get chatController => Get.find<ChatListController>();

  CallLogController get callController => Get.find<CallLogController>();

  @override
  Widget build(BuildContext context) {
    objectMgr.callMgr.context = context;
    return WillPopScope(
      onWillPop: () async {
        if (chatController.isEditing.value) {
          chatController.onChatEditTap();
          return false;
        }

        if (controller.tabController!.index != 0) {
          controller.pageIndex.value = 0;
          controller.tabController!.animateTo(0, duration: Duration.zero);
          return false;
        }

        if (chatController.isSearching.isTrue) {
          chatController.isSearching.value = false;
          chatController.searchFocus.unfocus();
          chatController.clearSearching();
          return false;
        }
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        if (nowTime - controller.clickTime > 2000) {
          controller.clickCount = 1;
        } else {
          controller.clickCount++;
        }
        controller.clickTime = nowTime;
        // if (controller.clickCount == 1) {
        //   Toast.showToast(localized(toastExit));
        //   return false;
        // }
        controller.clickTime = 0;
        controller.clickCount = 0;

        MoveToBackground.moveTaskToBack();
        return false;
        // return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Obx(() => AnimatedPadding(
          padding: EdgeInsets.only(top: controller.downOffset.value),
          duration: const Duration(milliseconds: 100),
          child: Stack(
            children: [
              TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.tabController,
                children: controller.pageWidget,
              ),

              /// 版本号更新提示
              const VersionView(),
            ],
          ),)),
        bottomNavigationBar: Stack(
          children: [
            GetBuilder(
              init: controller,
              id: 'bottomNav',
              builder: (context) {
                return BottomAppBar(
                  elevation: 0.0,
                  color: colorBackground,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorTextPrimary.withOpacity(0.2),
                          width: 0.5.w,
                        ),
                      ),
                    ),
                    child: Obx(
                      () => AbsorbPointer(
                        absorbing: chatController.isEditing.value,
                        child: Row(
                          children: <Widget>[
                            Obx(
                              () => BottomNavigatorItem(
                                index: 0,
                                selectIndex: controller.pageIndex.value,
                                title: localized(homeChat),
                                activeIcon: SvgPicture.asset(
                                  'assets/svgs/Chat.svg',
                                  color: themeColor,
                                  width: 26,
                                  height: 23,
                                ),
                                badge: objectMgr.chatMgr.totalUnreadCount.value,
                                inactiveIcon: SvgPicture.asset(
                                  'assets/svgs/Chat.svg',
                                  color: colorTextSupporting,
                                  width: 26,
                                  height: 23,
                                ),
                                // badge: objectMgr.chatMgr.unreadTotalCount,
                                onChange: controller.onPageChange,
                                onDoubleTap: (int index) {
                                  controller.onDoubleTap(index);
                                },
                                onLongPress: (int index) {
                                  controller.onLongPress(
                                      controller.tabController!.index);
                                },
                                onLongPressMoveUpdate:
                                    (LongPressMoveUpdateDetails details) {
                                  controller.onLongPressMoveUpdate(details);
                                },
                                onLongPressUp: () {
                                  controller.onLongPressUp();
                                },
                                badgeGlobalKey: controller.badgeGlobalKey,
                                hideBadge: controller.hideBadge.value,
                              ),
                            ),
                            Obx(
                              () => BottomNavigatorItem(
                                index: 1,
                                selectIndex: controller.pageIndex.value,
                                title: localized(homeContact),
                                activeIcon: SvgPicture.asset(
                                  'assets/svgs/Contact.svg',
                                  width: 25,
                                  height: 25,
                                  color: themeColor,
                                ),
                                inactiveIcon: SvgPicture.asset(
                                  'assets/svgs/Contact.svg',
                                  color: colorTextSupporting,
                                  width: 25,
                                  height: 25,
                                ),
                                badge: controller.requestCount.value,
                                onChange: controller.onPageChange,
                              ),
                            ),
                            Obx(
                              () => BottomNavigatorItem(
                                index: 2,
                                selectIndex: controller.pageIndex.value,
                                title: localized(homeDiscover),
                                activeIcon: SvgPicture.asset(
                                  'assets/svgs/Im_Discover.svg',
                                  color: themeColor,
                                  width: 25,
                                  height: 25,
                                ),
                                inactiveIcon: SvgPicture.asset(
                                  'assets/svgs/Im_Discover.svg',
                                  color: colorTextSupporting,
                                  width: 25,
                                  height: 25,
                                ),
                                // badge: controller.missedCallCount.value,
                                onChange: controller.onPageChange,
                                onDoubleTap: (int index) {},
                                redDot: controller.isMentionRedDot.value,
                              ),
                            ),
                            Obx(
                              () => BottomNavigatorItem(
                                index: 3,
                                selectIndex: controller.pageIndex.value,
                                title: localized(homeSetting),
                                activeIcon: SvgPicture.asset(
                                  'assets/svgs/Settings.svg',
                                  color: themeColor,
                                  width: 25,
                                  height: 23.6,
                                ),
                                inactiveIcon: SvgPicture.asset(
                                  'assets/svgs/Settings.svg',
                                  color: colorTextSupporting,
                                  width: 25,
                                  height: 23.6,
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
                );
              },
            ),
            Obx(() {
              bool hasSelect = chatController.selectedChatIDForEdit.isNotEmpty;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: chatController.isEditing.value ? 1.0 : 0.0,
                curve: Curves.easeOut,
                child: BottomAppBar(
                  elevation: 0.0,
                  color: colorBackground,
                  child: AnimatedPadding(
                    duration: Duration(
                      milliseconds: chatController.isEditing.value ? 50 : 500,
                    ),
                    padding: EdgeInsets.all(
                      chatController.isEditing.value ? 16.0 : 0.0,
                    ),
                    curve: Curves.easeOut,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        OpacityEffect(
                          child: GestureDetector(
                            onTap: hasSelect
                                ? () => chatController.hideChat(context, null)
                                : null,
                            child: Text(
                              localized(chatOptionsHide),
                              style: TextStyle(
                                color:
                                    hasSelect ? themeColor : colorTextSecondary,
                                fontSize: 17,
                                fontFamily: appFontfamily,
                              ),
                            ),
                          ),
                        ),
                        OpacityEffect(
                          child: GestureDetector(
                            onTap: () {
                              if (hasSelect) {
                                chatController.onDeleteChat(context, null);
                              }
                            },
                            child: Text(
                              localized(delete),
                              style: TextStyle(
                                color:
                                    hasSelect ? colorRed : colorTextSecondary,
                                fontSize: 17,
                                fontFamily: appFontfamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
