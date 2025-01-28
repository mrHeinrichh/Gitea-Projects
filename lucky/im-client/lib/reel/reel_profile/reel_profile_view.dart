import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/reel/reel_profile/like_post_view.dart';
import 'package:jxim_client/reel/reel_profile/my_post_view.dart';
import 'package:jxim_client/reel/reel_profile/save_post_view.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../api/reel.dart';
import '../../home/component/custom_divider.dart';
import '../../object/reel.dart';
import '../../utils/cache_image.dart';
import '../../utils/config.dart';
import '../../views/component/custom_avatar.dart';
import 'draft_post_view.dart';

class ReelProfileView extends StatefulWidget {
  const ReelProfileView({Key? key}) : super(key: key);

  @override
  State<ReelProfileView> createState() => _ReelProfileViewState();
}

class _ReelProfileViewState extends State<ReelProfileView>
    with TickerProviderStateMixin {
  TabController? tabController;
  ScrollController? scrollController;
  RxInt selectedBottomIndex = 0.obs;
  RxList tabBarList = <String>[
    localized(postParam, params: ["0"]),
    localized(draft),
    localized(saved),
    localized(liked),
  ].obs;
  Rx<ProfileData> profileData = ProfileData().obs;
  Rx<StatisticsData> statisticsData = StatisticsData().obs;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    tabController = TabController(
      length: tabBarList.length,
      vsync: this,
    );
    getProfileData();
    getStatisticsData();
  }

  @override
  void dispose() {
    scrollController?.dispose();
    tabController?.dispose();
    super.dispose();
  }

  Future<void> getProfileData() async {
    profileData.value = await getProfile(objectMgr.userMgr.mainUser.uid);
  }

  Future<void> getStatisticsData() async {
    statisticsData.value = await getMyStatistics();
    tabBarList.first = localized(postParam,
        params: ["${statisticsData.value.totalPostCount}"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
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
                      delegate: ReelProfileSliverPersistentHeaderDelegate(
                        minHeight: Platform.isAndroid ? 40 : 80,
                        maxHeight: Platform.isAndroid ? 200 : 240,
                        profileData:
                            profileData.value, // Maximum height of the header
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 12,
                        right: 12,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Obx(
                                  () => Text(
                                    localized(
                                      paramLike,
                                      params: [
                                        "${statisticsData.value.totalLikesReceived}"
                                      ],
                                    ),
                                    style: jxTextStyle.textStyle14(
                                        color: JXColors.secondaryTextBlack),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Obx(
                                  () => Text(
                                    localized(
                                      paramFollowee,
                                      params: [
                                        "${statisticsData.value.totalFolloweeCount}"
                                      ],
                                    ),
                                    style: jxTextStyle.textStyle14(
                                        color: JXColors.secondaryTextBlack),
                                  ),
                                ),
                              ),
                              Obx(
                                () => Text(
                                  localized(
                                    paramFollower,
                                    params: [
                                      "${statisticsData.value.totalFollowerCount}"
                                    ],
                                  ),
                                  style: jxTextStyle.textStyle14(
                                      color: JXColors.secondaryTextBlack),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 20),
                            child: Obx(
                              () => Text(
                                profileData.value.profile?.bio ?? "",
                                style: jxTextStyle.textStyle14(
                                    color: JXColors.secondaryTextBlack),
                              ),
                            ),
                          ),
                          OverlayEffect(
                            radius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                              bottom: Radius.circular(8),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    JXColors.primaryTextBlack.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                "编辑资料 70%",
                                style: jxTextStyle.textStyleBold17(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ReelProfileTabBar(
                      minHeight: 40,
                      maxHeight: 40,
                      widget: Container(
                        decoration: BoxDecoration(
                          border: customBorder,
                          color: Colors.white,
                        ),
                        child: TabBar(
                          controller: tabController,
                          labelColor: JXColors.primaryTextBlack,
                          unselectedLabelColor: JXColors.secondaryTextBlack,
                          labelStyle: jxTextStyle.textStyleBold17(
                              fontWeight: MFontWeight.bold6.value),
                          unselectedLabelStyle: jxTextStyle.textStyle17(),
                          tabs: List.generate(
                            tabBarList.length,
                            (index) => Tab(text: tabBarList[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: tabController,
          children: List.generate(
            tabBarList.length,
            (index) => getTabView(index),
          ),
        ),
      ),
    );
  }

  Widget getTabView(int index) {
    switch (index) {
      case 0:
        return const MyPostView();
      case 1:
        return const DraftPostView();
      case 2:
        return const SavePostView();
      case 3:
        return const LikePostView();
      default:
        return const MyPostView();
    }
  }
}

class ReelProfileSliverPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final ProfileData profileData;

  ReelProfileSliverPersistentHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.profileData,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    double percent = (shrinkOffset / maxExtent) * 100;
    bool isExpand = percent > 55 ? false : true;

    return SizedBox(
      height: maxHeight,
      child: Stack(
        children: [
          /// 背景图片
          Positioned.fill(
            child: RemoteImage(
              src: profileData.profile?.profilePic ?? "",
              width: MediaQuery.of(context).size.width,
              height: maxHeight,
              fit: BoxFit.cover,
              mini: Config().dynamicMin,
            ),
          ),

          /// Overlay
          Positioned.fill(
            child: Container(
              color: JXColors.primaryTextBlack.withOpacity(percent / 100),
            ),
          ),

          /// Header
          Positioned(
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  AnimatedCrossFade(
                    duration: kThemeAnimationDuration,
                    crossFadeState: isExpand
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: kThemeAnimationDuration,
                            opacity: 1 - percent / 100,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(100)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: notBlank(profileData.profile?.profilePic)
                                    ? RemoteImage(
                                        src: profileData.profile!.profilePic!,
                                        mini: Config().headMin,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      )
                                    : CustomAvatar(
                                        uid: profileData.profile?.userid ?? 0,
                                        size: 80,
                                        headMin: Config().headMin,
                                        fontSize: 24.0,
                                        shouldAnimate: false,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${profileData.profile?.name}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: MFontWeight.bold6.value,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        // Shadow color
                                        offset: const Offset(2, 2),
                                        // Shadow position
                                        blurRadius: 8, // Shadow blur radius
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "ID: ${profileData.profile?.userid}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        // Shadow color
                                        offset: const Offset(2, 2),
                                        // Shadow position
                                        blurRadius: 8, // Shadow blur radius
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: Row(
                      children: [
                        const CustomLeadingIcon(
                          backButtonColor: Colors.white,
                          withBackTxt: false,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${profileData.profile?.name}",
                          style: jxTextStyle.textStyleBold20(
                            color: Colors.white,
                            fontWeight: MFontWeight.bold6.value,
                          ),
                        ),
                      ],
                    ),
                    firstCurve: Curves.easeInOutCubic,
                    secondCurve: Curves.easeInOutCubic,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(ReelProfileSliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class ReelProfileTabBar extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget widget;

  ReelProfileTabBar({
    required this.minHeight,
    required this.maxHeight,
    required this.widget,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return widget;
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
