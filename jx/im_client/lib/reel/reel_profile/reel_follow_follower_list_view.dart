import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_profile/reel_follow.dart';
import 'package:jxim_client/reel/reel_profile/reel_follower.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelFollowFollowerListView extends StatefulWidget {
  final int initTabIndex;

  const ReelFollowFollowerListView({
    super.key,
    required this.initTabIndex,
  });

  @override
  State<ReelFollowFollowerListView> createState() =>
      _ReelFollowFollowerListViewState();
}

class _ReelFollowFollowerListViewState extends State<ReelFollowFollowerListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final tabs = [localized(paramFollowee), localized(paramFollower)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: tabs.length,
      initialIndex: widget.initTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorBackground6,
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: OpacityEffect(
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svgs/Back.svg',
                                width: 12,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  themeColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                localized(buttonBack),
                                style:
                                    jxTextStyle.textStyle17(color: themeColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: colorTextPrimary,
                    unselectedLabelColor: colorTextSecondary,
                    labelStyle: jxTextStyle.textStyleBold17(),
                    unselectedLabelStyle: jxTextStyle.textStyle17(),
                    indicatorColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    tabAlignment: TabAlignment.center,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderRadius: BorderRadius.circular(3),
                      borderSide:
                          const BorderSide(color: colorTextPrimary, width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: List.generate(
                      tabs.length,
                      (i) => Tab(child: Text(tabs[i])),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ReelFollow(),
                  ReelFollower(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
