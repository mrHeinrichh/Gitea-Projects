import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_profile/draft_post_view.dart';
import 'package:jxim_client/reel/reel_profile/like_post_view.dart';
import 'package:jxim_client/reel/reel_profile/my_post_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_header_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_info_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_tab_header_view.dart';
import 'package:jxim_client/reel/reel_profile/save_post_view.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ReelMyProfileView extends StatefulWidget {
  final ReelMyProfileController controller;
  final Function(bool)? onBack;
  final bool showBack;

  const ReelMyProfileView({
    super.key,
    this.onBack,
    this.showBack = true,
    required this.controller,
  });

  @override
  State<ReelMyProfileView> createState() => _ReelMyProfileViewState();
}

class _ReelMyProfileViewState extends State<ReelMyProfileView> with TickerProviderStateMixin {
  RxInt selectedBottomIndex = 0.obs;
  late ReelMyProfileController controller;
  RxBool justSeenTap = false.obs;
  ReelController reelController = Get.find<ReelController>();
  RxBool transited = false.obs;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;

    controller.tabController = TabController(
      length: controller.tabBarList.length,
      vsync: this,
      initialIndex: controller.selectedTab,
    );

    controller.tabController!.addListener(controller.handleTabSelection);
    Future.delayed(const Duration(milliseconds: 300), () {
      transited.value = true;
    });
  }

  @override
  dispose() {
    reelNavigationMgr.onCloseMyProfile(controller);
    _handleBackNavigation(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget w = Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: widget.showBack ? 0 : 52 + MediaQuery.of(context).padding.bottom,
            child: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: MultiSliver(
                      pushPinnedChildren: true,
                      children: [
                        Obx(
                          () => SliverPersistentHeader(
                            pinned: true,
                            delegate: ReelProfileHeaderView(
                              context,
                              showBack: widget.showBack,
                              userId: controller.userId.value,
                              profile: controller.reelProfile.value,
                              onBack: () {
                                widget.onBack?.call(true);
                              },
                            ),
                          ),
                        ),
                        Obx(
                          () => SliverToBoxAdapter(
                            child: ReelProfileInfoView(
                              isMe: true,
                              controller: controller,
                              profile: controller.reelProfile.value,
                              userId: controller.userId.value,
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: ReelProfileTabBar(
                            isMe: true,
                            tabController: controller.tabController,
                            tabBarList: controller.tabBarList,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: Stack(
                children: [
                  TabBarView(
                    controller: controller.tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      controller.tabBarList.length,
                      (index) => getTabView(index),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(context),
          )
        ],
      ),
    );

    if (Platform.isAndroid) {
      w = WillPopScope(
        onWillPop: () async {
          return _handleBackNavigation(true);
        },
        child: w,
      );
    }

    return w;

    // WillPopScope(
    //   onWillPop: () async => _handleBackNavigation(),
    //   child:
    // );
  }

  Widget getTabView(int index) {
    switch (index) {
      case 0:
        return MyPostView(
          isOwner: true,
          controller: controller,
        );
      case 1:
        return const DraftPostView();
      case 2:
        return SavePostView(controller: controller);
      case 3:
        return LikePostView(controller: controller);
      default:
        return MyPostView(
          controller: controller,
          isOwner: true,
        );
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorBackground,
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
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              localized(home),
              color: colorTextSupporting,
              isBold: true,
              onClick: () {
                if (transited.value) {
                  reelController.onBottomTap(0);
                }
              },
            ),
          ),
          CustomImage(
            'assets/svgs/add_circle.svg',
            size: 32,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: colorTextPrimary,
            onClick: () {
              if (transited.value) {
                reelController.onBottomTap(1);
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CustomTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              localized(me),
              color: colorTextPrimary,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  bool _handleBackNavigation(bool toDismiss) {
    if (widget.onBack != null) {
      widget.onBack!(toDismiss);
    }
    return false;
  }
}
