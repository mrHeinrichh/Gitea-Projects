import 'package:flutter/material.dart' hide BottomAppBar;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/home/component/more_functions_bottom_sheet.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/im_bottom_app_bar.dart';
import 'package:jxim_client/home/version_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/special_container/special_container_overlay.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/bottom_navigator_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:lottie/lottie.dart';
import 'package:move_to_background/move_to_background.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  ChatListController get chatController => Get.find<ChatListController>();

  @override
  Widget build(BuildContext context) {
    objectMgr.callMgr.context = context;
    return WillPopScope(
      onWillPop: () async {
        try {
          /// 小程序在更多状态的时候，点击安卓物理返回键，需要返回到正常状态
          PullDownAppletController? miniAppController =
              Get.find<PullDownAppletController>();
          if (miniAppController != null && miniAppController.isMoreApps.value) {
            miniAppController.isMoreApps.value = false;
            return false;
          }
        } catch (e) {
          debugPrint('Error: $e');
        }

        if (scStatus.value == SpecialContainerStatus.max.index) {
          if (MoreFunctionsBottomSheetTool.isShowing) {
            MoreFunctionsBottomSheetTool.dismiss(null, result);
            return false;
          }

          /// 当前是小程序的全屏
          if (objectMgr.miniAppMgr.currentApp?.isNeedCloseMiniApp ?? false) {
            SpecialContainerOverlay.closeOverlay();
          } else {
            SpecialContainerOverlay.minOverlay();
          }
          return false;
        }
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
              ),
            )),
        bottomNavigationBar: Obx(
          () => chatController.isSearching.value ||
                  chatController.hideBottomBar.value
              ? const SizedBox()
              : Stack(
                  children: [
                    GetBuilder(
                      init: controller,
                      id: 'bottomNav',
                      builder: (context) {
                        return Obx(
                          () => BottomAppBar(
                            isNeedSafeArea: scStatus.value !=
                                SpecialContainerStatus.min.index,
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
                                          selectIndex:
                                              controller.pageIndex.value,
                                          title: localized(homeChat),
                                          activeIcon: Lottie.asset(
                                            'assets/lottie/b-chat.json',
                                            width: 30,
                                            height: 26,
                                            animate: true,
                                            repeat: false,
                                          ),
                                          badge: objectMgr
                                              .chatMgr.totalUnreadCount.value,
                                          inactiveIcon: Lottie.asset(
                                            'assets/lottie/b_all_gray_chatbox.json',
                                            width: 30,
                                            height: 26,
                                            animate: false,
                                          ),
                                          // badge: objectMgr.chatMgr.unreadTotalCount,
                                          onChange: controller.onPageChange,
                                          onDoubleTap: (int index) {
                                            controller.onDoubleTap(index);
                                          },
                                          onLongPress: (int index) {
                                            controller.onLongPress(controller
                                                .tabController!.index);
                                          },
                                          onLongPressMoveUpdate:
                                              (LongPressMoveUpdateDetails
                                                  details) {
                                            controller
                                                .onLongPressMoveUpdate(details);
                                          },
                                          onLongPressUp: () {
                                            controller.onLongPressUp();
                                          },
                                          badgeGlobalKey:
                                              controller.badgeGlobalKey,
                                          hideBadge: controller.hideBadge.value,
                                        ),
                                      ),
                                      Obx(
                                        () => BottomNavigatorItem(
                                          index: 1,
                                          selectIndex:
                                              controller.pageIndex.value,
                                          title: localized(homeContact),
                                          activeIcon: Lottie.asset(
                                            'assets/lottie/b-contacts.json',
                                            width: 30,
                                            height: 26,
                                            animate: true,
                                            repeat: false,
                                          ),
                                          inactiveIcon: Lottie.asset(
                                            'assets/lottie/b_all_gray_profile.json',
                                            width: 30,
                                            height: 26,
                                            animate: false,
                                          ),
                                          badge: controller.requestCount.value,
                                          onChange: controller.onPageChange,
                                        ),
                                      ),
                                      Obx(
                                        () => BottomNavigatorItem(
                                          index: 2,
                                          selectIndex:
                                              controller.pageIndex.value,
                                          title: localized(homeDiscover),
                                          activeIcon: Lottie.asset(
                                            'assets/lottie/b-discover.json',
                                            width: 30,
                                            height: 26,
                                            animate: true,
                                            repeat: false,
                                          ),
                                          inactiveIcon: Lottie.asset(
                                            'assets/lottie/b_all_gray_discover.json',
                                            width: 30,
                                            height: 26,
                                            animate: false,
                                          ),
                                          // badge: controller.missedCallCount.value,
                                          onChange: controller.onPageChange,
                                          onDoubleTap: (int index) {},
                                          redDot:
                                              controller.isMentionRedDot.value,
                                        ),
                                      ),
                                      Obx(
                                        () => BottomNavigatorItem(
                                          index: 3,
                                          selectIndex:
                                              controller.pageIndex.value,
                                          title: localized(homeSetting),
                                          activeIcon: Lottie.asset(
                                            'assets/lottie/b-setting.json',
                                            width: 30,
                                            height: 26,
                                            animate: true,
                                            repeat: false,
                                          ),
                                          inactiveIcon: Lottie.asset(
                                            'assets/lottie/b_all_gray_setting.json',
                                            width: 30,
                                            height: 26,
                                            animate: false,
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
                          isNeedSafeArea: scStatus.value !=
                              SpecialContainerStatus.min.index,
                          elevation: 0.0,
                          color: colorBackground,
                          child: AnimatedPadding(
                            duration: Duration(
                              milliseconds:
                                  chatController.isEditing.value ? 50 : 500,
                            ),
                            padding: EdgeInsets.all(
                              chatController.isEditing.value ? 16.0 : 0.0,
                            ),
                            curve: Curves.easeOut,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                OpacityEffect(
                                  isDisabled: !hasSelect,
                                  child: GestureDetector(
                                    onTap: hasSelect
                                        ? () => chatController.hideChat(
                                            context, null)
                                        : null,
                                    child: Text(
                                      localized(chatOptionsHide),
                                      style: TextStyle(
                                        color: hasSelect
                                            ? themeColor
                                            : colorTextPlaceholder,
                                        fontSize: 17,
                                        fontFamily: appFontfamily,
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasSelect)
                                  OpacityEffect(
                                    isDisabled: !hasSelect,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (hasSelect) {
                                          chatController.onDeleteChat(
                                              context, null);
                                        }
                                      },
                                      child: Text(
                                        localized(delete),
                                        style: TextStyle(
                                          color: hasSelect
                                              ? colorRed
                                              : colorTextPlaceholder,
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
      ),
    );
  }
}
