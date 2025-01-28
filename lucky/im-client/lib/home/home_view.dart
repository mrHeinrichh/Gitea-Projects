import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/version_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/bottom_navigator_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import 'chat/controllers/chat_list_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  ChatListController get chatController => Get.find<ChatListController>();

  CallLogController get callController => Get.find<CallLogController>();

  @override
  Widget build(BuildContext context) {
    objectMgr.callMgr.context = context;
    return WillPopScope(
      onWillPop: () async {
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
        int _nowTime = DateTime.now().millisecondsSinceEpoch;
        if (_nowTime - controller.clickTime > 2000) {
          controller.clickCount = 1;
        } else {
          controller.clickCount++;
        }
        controller.clickTime = _nowTime;
        // if (controller.clickCount == 1) {
        //   Toast.showToast(localized(toastExit));
        //   return false;
        // }
        controller.clickTime = 0;
        controller.clickCount = 0;
        return true;
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.tabController,
                children: controller.pageWidget,
              ),
              /// 版本号更新提示
              VersionView(),
            ],
          ),
          bottomNavigationBar: Stack(
            children: [
              GetBuilder(
                init: controller,
                id: 'bottomNav',
                builder: (context) {
                  return BottomAppBar(
                    padding: EdgeInsets.zero,
                    elevation: 0.0,
                    color: surfaceBrightColor,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: JXColors.borderPrimaryColor,
                            width: 0.5.w,
                          ),
                        ),
                      ),
                      padding:
                          EdgeInsets.only(bottom: Platform.isAndroid ? 5.0 : 0),
                      child: Obx(
                        () => AbsorbPointer(
                          absorbing: chatController.isEditing.value ||
                              callController.isEditing.value,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Obx(() => BottomNavigatorItem(
                                    index: 0,
                                    selectIndex: controller.pageIndex.value,
                                    title: localized(homeChat),
                                    activeIcon: SvgPicture.asset(
                                      'assets/svgs/Chat.svg',
                                      color: accentColor,
                                      width: 26,
                                      height: 23,
                                    ),
                                    badge: objectMgr
                                        .chatMgr.totalUnreadCount.value,
                                    inactiveIcon: SvgPicture.asset(
                                      'assets/svgs/Chat.svg',
                                      color: JXColors.iconSecondaryColor,
                                      width: 26,
                                      height: 23,
                                    ),
                                    // badge: objectMgr.chatMgr.unreadTotalCount,
                                    onChange: controller.onPageChange,
                                    onDoubleTap: (int index) {
                                      controller.onDoubleTap(index);
                                    },
                                  )),
                              Obx(() => BottomNavigatorItem(
                                    index: 1,
                                    selectIndex: controller.pageIndex.value,
                                    title: localized(discovery),
                                    activeIcon: SvgPicture.asset(
                                      'assets/svgs/discovery.svg',
                                      color: accentColor,
                                      width: 25,
                                      height: 25,
                                    ),
                                    inactiveIcon: SvgPicture.asset(
                                      'assets/svgs/discovery.svg',
                                      color: JXColors.iconSecondaryColor,
                                      width: 25,
                                      height: 25,
                                    ),
                                    badge:0,
                                    onChange: controller.onPageChange,
                                    onDoubleTap: (int index) {},
                                  )),
                              Obx(
                                () => BottomNavigatorItem(
                                  index: 2,
                                  selectIndex: controller.pageIndex.value,
                                  title: localized(homeContact),
                                  activeIcon: SvgPicture.asset(
                                    'assets/svgs/Contact.svg',
                                    width: 25,
                                    height: 25,
                                    color: accentColor,
                                  ),
                                  inactiveIcon: SvgPicture.asset(
                                    'assets/svgs/Contact.svg',
                                    color: JXColors.iconSecondaryColor,
                                    width: 25,
                                    height: 25,
                                  ),
                                  badge: controller.requestCount.value ?? 0,
                                  onChange: controller.onPageChange,
                                ),
                              ),
                              Obx(() => BottomNavigatorItem(
                                    index: 3,
                                    selectIndex: controller.pageIndex.value,
                                    title: localized(homeSetting),
                                    activeIcon: SvgPicture.asset(
                                      'assets/svgs/Settings.svg',
                                      color: accentColor,
                                      width: 25,
                                      height: 23.6,
                                    ),
                                    inactiveIcon: SvgPicture.asset(
                                      'assets/svgs/Settings.svg',
                                      color: JXColors.iconSecondaryColor,
                                      width: 25,
                                      height: 23.6,
                                    ),
                                    onChange: controller.onPageChange,
                                    redDot: controller.isShowRedDot.value,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Obx(() {
                bool hasSelect =
                    chatController.selectedChatIDForEdit.isNotEmpty;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: chatController.isEditing.value ? 1.0 : 0.0,
                  curve: Curves.easeOut,
                  child: BottomAppBar(
                    elevation: 0.0,
                    color: surfaceBrightColor,
                    child: AnimatedPadding(
                      duration: Duration(
                          milliseconds:
                              chatController.isEditing.value ? 50 : 500),
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
                                    ? () =>
                                        chatController.hideChat(context, null)
                                    : null,
                                child: Text(localized(chatOptionsHide),
                                    style: TextStyle(
                                      color: hasSelect
                                          ? accentColor
                                          : JXColors.secondaryTextBlack,
                                      fontSize: 17,
                                      fontFamily: appFontfamily,
                                    ))),
                          ),
                          OpacityEffect(
                            child: GestureDetector(
                                onTap: () {
                                  if (hasSelect) {
                                    chatController.onDeleteChat(context, null);
                                  }
                                },
                                child: Text(localized(delete),
                                    style: TextStyle(
                                      color: hasSelect
                                          ? errorColor
                                          : JXColors.secondaryTextBlack,
                                      fontSize: 17,
                                      fontFamily: appFontfamily,
                                    ))),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          )),
    );
  }
}
