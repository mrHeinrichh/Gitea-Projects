import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_item.dart';
import 'package:jxim_client/reel/services/preload_page_view.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../reel_profile/reel_profile_view.dart';

class ReelView extends GetView<ReelController> {
  const ReelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: SafeArea(
        top: Platform.isAndroid ? true : false,
        child: Obx(
          () => Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            body: Column(
              children: <Widget>[
                Expanded(
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      Stack(
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            child: Obx(
                              () => PreloadPageView.builder(
                                controller: controller.pageController,
                                scrollDirection: Axis.vertical,
                                onPageChanged: controller.onPageChanged,
                                preloadPagesCount: 2,
                                itemCount: controller.postList.length,
                                itemBuilder: (context, index) {
                                  return ReelItem(
                                    reelData: controller.postList[index],
                                    index: index,
                                    controller: controller,
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned.fill(
                            top: Platform.isAndroid
                                ? 10.0
                                : MediaQuery.of(context).viewPadding.top,
                            left: 0.0,
                            right: 0.0,
                            child: Stack(
                              children: <Widget>[
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          controller.onClickTitleTab(1),
                                      child: OpacityEffect(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: controller
                                                            .currentTab.value ==
                                                        1
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                width:
                                                    2.0, // Underline thickness
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4.0),
                                            child: Text(
                                              localized(subscribeButton),
                                              style:
                                                  jxTextStyle.textStyleBold17(
                                                      color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          controller.onClickTitleTab(2),
                                      child: OpacityEffect(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: controller
                                                            .currentTab.value ==
                                                        2
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                width:
                                                    2.0, // Underline thickness
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4.0),
                                            child: Text(
                                              localized(friendsRecommended),
                                              style:
                                                  jxTextStyle.textStyleBold17(
                                                      color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  left: 8,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: controller.onSearchTap,
                                    child: OpacityEffect(
                                      child: SvgPicture.asset(
                                        'assets/svgs/Search.svg',
                                        width: 24,
                                        height: 24,
                                        colorFilter: const ColorFilter.mode(
                                            Colors.white, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 2,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(100)),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: controller.onRefresh,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                              horizontal: 8,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/svgs/refresh_icon.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 18,
                                          width: 2,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        GestureDetector(
                                          onTap: Get.back,
                                          behavior: HitTestBehavior.translucent,
                                          child: OpacityEffect(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                                horizontal: 8,
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/svgs/reel_icon.svg',
                                                width: 18,
                                                height: 18,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                        Colors.white,
                                                        BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(),
                      const ReelProfileView(),
                    ],
                  ),
                ),
                Container(
                  height: kToolbarHeight,
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => controller.onBottomTap(0),
                          child: Text(
                            localized(home),
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight:MFontWeight.bold6.value,
                              color: controller.selectedBottomIndex.value == 0
                                  ? Colors.white
                                  : JXColors.secondaryTextWhite,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.onBottomTap(1),
                          child: const Icon(
                            Icons.add_circle_outline_outlined,
                            color: JXColors.white,
                            size: 30.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.onBottomTap(2),
                          child: Text(
                            localized(me),
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight:MFontWeight.bold6.value,
                              color: controller.selectedBottomIndex.value == 2
                                  ? Colors.white
                                  : JXColors.secondaryTextWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
