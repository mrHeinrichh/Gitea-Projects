import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_item.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_view.dart';
import 'package:jxim_client/reel/services/preload_page_view.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelView extends GetView<ReelController> {
  const ReelView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Platform.isIOS
          ? SystemUiOverlayStyle.light
          : const SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.light,
            ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: WillPopScope(
          onWillPop: () async {
            var a = controller.shouldPop();
            if (a) Get.back();
            return a;
          },
          child: Stack(
            children: [
              Positioned.fill(
                top: 0,
                left: 0,
                right: 0,
                bottom: 52 + MediaQuery.of(context).padding.bottom,
                child: TabBarView(
                  controller: controller.tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black,
                            child: Obx(
                              () => PreloadPageView.builder(
                                controller: controller.pageController,
                                scrollDirection: Axis.vertical,
                                onPageChanged: controller.onPageChanged,
                                onScrollNotification:
                                    controller.onScrollNotification,
                                preloadPagesCount: 2,
                                itemCount: controller.postList.length,
                                itemBuilder: (context, index) {
                                  return ReelItem(
                                    post: controller.postList[index],
                                    index: index,
                                    controller: controller,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Obx(
                            () => Offstage(
                              offstage: !controller.isLoading.value,
                              child: Center(
                                child: Container(
                                  width: 56.0,
                                  height: 56.0,
                                  decoration: BoxDecoration(
                                    color: colorTextPrimary.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const CupertinoActivityIndicator(
                                    radius: 12.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: _buildTopNavigationBar(context),
                          //   ReelSearchInput(
                          //   isDarkMode: true,
                          //   onClearClick: () {},
                          //   onSearchClick: () {},
                          // ),
                        ),
                      ],
                    ),
                    const SizedBox(),
                    Obx(() {
                      if (controller.profileController.value == null) {
                        return const SizedBox();
                      }
                      return ReelMyProfileView(
                        controller: controller.profileController.value!,
                        showBack: false,
                        onBack: () {
                          controller.onBottomTap(0);
                          controller.onReturnNavigation();
                        },
                      );
                    }),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNavigationBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleTab({required int index, required String title}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.onClickTitleTab(index),
      child: OpacityEffect(
        child: Obx(
          () => Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: MFontSize.size17.value,
                      fontWeight: MFontWeight.bold6.value,
                      color: controller.currentTab.value == index
                          ? colorWhite
                          : colorWhite.withOpacity(0.6),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 3,
                right: 3,
                child: Offstage(
                  offstage: controller.currentTab.value != index,
                  child:  Container(
                    height: 3,
                    decoration:  BoxDecoration(
                      color: colorWhite,
                      borderRadius:  BorderRadius.circular(3),
                      boxShadow:  [
                         BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildTitleTab(
                  index: 1,
                  title: localized(subscribeButton),
                ),
                const SizedBox(width: 30),
                _buildTitleTab(
                  index: 2,
                  title: localized(friendsRecommended),
                ),
              ],
            ),
            Positioned(
              left: 0.0,
              child: CustomImage(
                'assets/svgs/reel_search_outlined_shadow.svg',
                size: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onClick: controller.onSearchTap,
              ),
            ),
            Positioned(
              right: 12.0,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: OpacityEffect(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const CustomImage(
                      'assets/svgs/shutdown.svg',
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: (controller.selectedBottomIndex.value == 2)
              ? colorBackground
              : Colors.black,
          border: Border(
            top: BorderSide(
              color: colorTextPrimary.withOpacity(0.2),
              width: 0.33,
            ),
          ),
        ),
        width: double.infinity,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: CustomTextButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                localized(home),
                color: (controller.selectedBottomIndex.value == 2)
                    ? colorTextSupporting
                    : colorWhite,
                isBold: true,
                onClick: () => controller.onBottomTap(0),
              ),
            ),
            CustomImage(
              'assets/svgs/add_circle.svg',
              size: 32,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: (controller.selectedBottomIndex.value == 2)
                  ? colorTextPrimary
                  : colorWhite,
              onClick: () => controller.onBottomTap(1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CustomTextButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                localized(me),
                color: (controller.selectedBottomIndex.value == 2)
                    ? colorTextPrimary
                    : colorWhite.withOpacity(0.6),
                isBold: true,
                onClick: () => controller.onBottomTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
