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
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ReelMyProfileView extends StatefulWidget {
  final ReelMyProfileController controller;
  final Function()? onBack;
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

class _ReelMyProfileViewState extends State<ReelMyProfileView>
    with TickerProviderStateMixin {
  RxInt selectedBottomIndex = 0.obs;
  late ReelMyProfileController controller;
  RxBool justSeenTap = false.obs;
  ReelController reelController = Get.find<ReelController>();

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
  }

  @override
  dispose() {
    reelNavigationMgr.onCloseMyProfile(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _handleBackNavigation(),
      child: Scaffold(
        backgroundColor: colorBackground,
        body: GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 5) {
              _handleBackNavigation();
            } else if (details.delta.dx < -5) {}
          },
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
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
                            onBack: widget.onBack,
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
      ),
    );
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

  bool _handleBackNavigation() {
    if (widget.showBack) {
      if (widget.onBack != null) {
        widget.onBack!();
      }
    } else {
      reelController.onBottomTap(0, keepHomeCurrent: true);
      reelController.onReturnNavigation();
    }

    return false;
  }
}
