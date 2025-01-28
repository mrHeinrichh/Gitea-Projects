import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_profile/draft_post_view.dart';
import 'package:jxim_client/reel/reel_profile/my_post_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_header_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_info_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_tab_header_view.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ReelProfileView extends StatefulWidget {
  final ReelProfileController controller;
  final Function(bool)? onBack;

  const ReelProfileView({
    super.key,
    this.onBack,
    required this.controller,
  });

  @override
  State<ReelProfileView> createState() => _ReelProfileViewState();
}

class _ReelProfileViewState extends State<ReelProfileView> with TickerProviderStateMixin {
  TabController? tabController;
  RxInt selectedBottomIndex = 0.obs;

  late RxList<ReelPost> posts;
  RxBool justSeenTap = false.obs;

  @override
  void initState() {
    super.initState();
    posts = widget.controller.posts;

    tabController = TabController(
      length: widget.controller.tabBarList.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController?.dispose();
    reelNavigationMgr.onCloseProfile(widget.controller);
    _handleBackNavigation(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var body = Scaffold(
      backgroundColor: colorBackground,
      body: GestureDetector(
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
                          profile: widget.controller.reelProfile.value,
                          userId: widget.controller.userId.value,
                          onBack: Navigator.of(context).pop,
                        ),
                      ),
                    ),
                    Obx(
                      () => SliverToBoxAdapter(
                        child: ReelProfileInfoView(
                          profile: widget.controller.reelProfile.value,
                          userId: widget.controller.userId.value,
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: ReelProfileTabBar(
                        tabController: tabController,
                        tabBarList: widget.controller.tabBarList,
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
                controller: tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  widget.controller.tabBarList.length,
                  (index) => getTabView(index),
                ),
              ),

              ///隱藏剛剛看過
              // Positioned(
              //   right: 8,
              //   bottom: 34,
              //   child: GestureDetector(
              //     onTap: () {
              //       justSeenTap.value = true;
              //     },
              //     child: ForegroundOverlayEffect(
              //       radius: BorderRadius.circular(4),
              //       child: Container(
              //         padding: const EdgeInsets.all(12),
              //         decoration: BoxDecoration(
              //           color: colorWhite,
              //           borderRadius: BorderRadius.circular(4),
              //         ),
              //         child: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Text(
              //               localized(justSeen),
              //               style: jxTextStyle.textStyleBold17(),
              //             ),
              //             const SizedBox(width: 4),
              //             Obx(
              //               () => justSeenTap.value
              //                   ? SizedBox(
              //                       height: 20,
              //                       width: 20,
              //                       child: Lottie.asset(
              //                           'assets/lottie/animate_success_slow2.json',
              //                           repeat: true, onLoaded: (composition) {
              //                         Future.delayed(const Duration(seconds: 5),
              //                             () {
              //                           justSeenTap.value = false;
              //                         });
              //                       }),
              //                     )
              //                   : SvgPicture.asset(
              //                       'assets/svgs/arrow_drop_down_rounded.svg',
              //                       width: 20,
              //                       height: 20,
              //                       fit: BoxFit.fill,
              //                     ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );

    if (!Platform.isIOS) {
      return willPopScope(body);
    }

    return body;
  }

  Widget willPopScope(Widget child) {
    return WillPopScope(
        // 監聽系統返回手勢or按鈕做事
        onWillPop: () async {
          return _handleBackNavigation(false);
        },
        child: child);
  }

  Widget getTabView(int index) {
    switch (index) {
      case 0:
        return MyPostView(controller: widget.controller);
      case 1:
        return const DraftPostView();
      case 2:
        return const SizedBox();
      case 3:
        return const SizedBox();
      default:
        return MyPostView(
          controller: widget.controller,
        );
    }
  }

  bool _handleBackNavigation(bool toDismiss) {
    if (widget.onBack != null) {
      widget.onBack!(toDismiss);
    }
    return true;
  }
}
