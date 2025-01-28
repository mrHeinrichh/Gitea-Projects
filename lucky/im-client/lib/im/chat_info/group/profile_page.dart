import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/persistent_profile_header.dart';
import 'package:jxim_client/main.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'mobile_profile_page_panel.dart';

const double leftPadding = 20.0;
const double initialScrllOffset = 150.0;
const double scrollDesiredPercent = 0.65;
const Duration duration = Duration(milliseconds: 50);
bool oneTimeStretch = false;
bool showBigPicture = false;

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.body,
    required this.stickyTabBar,
    this.uid,
    this.img,
    this.actions,
    // this.promotionFunc,
    required this.defaultImg,
    this.scrollController,
    // required this.smallImg,
    required this.server,
    required this.name,
    required this.description,
    required this.features,
    this.ableEdit = false,
    this.onClickProfile,
  });

  final int? uid;
  final String? img;
  final Widget defaultImg;

  final ScrollController? scrollController;

  // final Widget smallImg;
  final String server;

  final NicknameText name;
  final String description;

  final Widget body;
  final Widget stickyTabBar;
  final Widget features;
  final VoidCallback? actions;

  // final VoidCallback? promotionFunc;
  final bool ableEdit;

  final Function()? onClickProfile;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;
  final description = "".obs;

  void animateToMaxExtent() {
    // scrollController.animateTo(
    //   60,
    //   duration: duration,
    //   curve: Curves.linear,
    // );

    scrollController.jumpTo(60);
    if (!oneTimeStretch && widget.img != '') {
      Future.delayed(duration, () => oneTimeStretch = true);
    }
  }

  void animateToNormalExtent(JumpExtent j) {
    scrollController.jumpTo(initialScrllOffset);
    // j == JumpExtent.middleToFullScreen ? scrollController.jumpTo(initialScrllOffset) :
    // scrollController.animateTo(
    //   initialScrllOffset,
    //   duration: duration,
    //   curve: Curves.linear,
    // );
  }

  void animateToCloseExtent() {
    scrollController.jumpTo(325.0);
    // scrollController.animateTo(
    //   325.0,
    //   duration: duration,
    //   curve: Curves.linear,
    // );
  }

  bool get scrollStopped =>
      !scrollController.position.isScrollingNotifier.value;

  bool get mustExpand =>
      scrollController.offset < initialScrllOffset * scrollDesiredPercent;

  bool get mustRetract =>
      !mustExpand &&
          (scrollController.offset > (initialScrllOffset * scrollDesiredPercent) &&
              scrollController.offset < 230);

  bool get closeBar =>
      !mustExpand &&
          (scrollController.offset >= 230 && scrollController.offset < 325.0);

  void _handleScrollingActivity() {
    Future.delayed(Duration.zero, () {
      if (scrollStopped) {
        if (mustRetract) {
          animateToNormalExtent(JumpExtent.middle);
        } else if (mustExpand) {
          // if (widget.img != '') {
          //   // animateToMaxExtent();
          // } else {
          // }
          animateToNormalExtent(JumpExtent.middle);
        } else if (closeBar) {
          animateToCloseExtent();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
    scrollController = widget.scrollController == null
        ? ScrollController()
        : widget.scrollController!;

    description.value = widget.description;
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   scrollController.position.isScrollingNotifier
    //       .addListener(_handleScrollingActivity);
    // });
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (widget.uid == null) return;
    String? onlineStatus =
        objectMgr.scheduleMgr.onlineTask.onlineDecs[widget.uid!];
    if (notBlank(onlineStatus) && onlineStatus != description.value && onlineStatus != "01/01/1970") {
      description.value = onlineStatus!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // var height = MediaQuery.of(context).size.height;
    // minHeaderExtent = height - (height - 92.w);
    ///頂部SafeArea不要拿掉,否則上滑置頂後UI在ios會跑掉
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(top: 7).w,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is UserScrollNotification) {}
              return false;
            },
            child: NestedScrollView(
              controller: scrollController,
              physics: (widget.scrollController != null)
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              // physics: const ClampingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: MultiSliver(
                      pushPinnedChildren: true,
                      children: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: PersistentProfileHeader(
                              img: widget.img,
                              defaultImg: widget.defaultImg,
                              server: widget.server,
                              name: widget.name,
                              description: description,
                              toMaxImage: animateToMaxExtent,
                              toMiddleImage: animateToNormalExtent,
                              action: widget.actions,
                              ableEdit: widget.ableEdit,
                              onClickProfile: widget.onClickProfile,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            color: ImColor.systemBg,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24).w,
                            child: Column(
                              children: [
                                widget.features,
                              ],
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: ProfileTabBar(widget.stickyTabBar),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: widget.body,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
  }
}

class ProfilePresistentTabBar extends SliverPersistentHeaderDelegate {
  final Widget widget;

  ProfilePresistentTabBar(this.widget);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return widget;
  }

  @override
  double get maxExtent => 50.w;

  @override
  double get minExtent => 50.w;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

enum JumpExtent {
  middle,
  middleToFullScreen,
}
