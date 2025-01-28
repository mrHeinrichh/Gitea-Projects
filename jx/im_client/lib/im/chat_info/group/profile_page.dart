import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/chat_info_nickname_text.dart';
import 'package:jxim_client/im/chat_info/group/mobile_profile_page_panel.dart';
import 'package:jxim_client/im/chat_info/group/persistent_profile_header.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
    this.isStranger = false,
    this.isModalBottomSheet = false,
    this.luckyContainer,
  });

  final int? uid;
  final String? img;
  final Widget defaultImg;

  final ScrollController? scrollController;

  // final Widget smallImg;
  final String server;

  final ChatInfoNicknameText name;
  final String description;

  final Widget body;
  final Widget stickyTabBar;
  final Widget features;
  final VoidCallback? actions;
  final bool isStranger;
  final bool isModalBottomSheet;

  //lucky 预留container
  final Widget? luckyContainer;

  // final VoidCallback? promotionFunc;
  final bool ableEdit;

  final Function()? onClickProfile;

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;

  String _lastSeenDescription = "";

  String get description =>
      widget.uid == null ? widget.description : _lastSeenDescription;

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

  @override
  void initState() {
    super.initState();
    objectMgr.onlineMgr.on(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    scrollController = widget.scrollController == null
        ? ScrollController()
        : widget.scrollController!;
    _lastSeenDescription = widget.description;
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (widget.uid == null) return;

    String desc = objectMgr.onlineMgr.friendOnlineString[widget.uid] ?? '';
    if (notBlank(desc) && desc != description && desc != "01/01/1970") {
      _lastSeenDescription = desc;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      context,
                    ),
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
                            isModalBottomSheet: widget.isModalBottomSheet,
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
                        if (widget.luckyContainer != null)
                          SliverToBoxAdapter(
                            child: Container(
                              color: ImColor.systemBg,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 24).w,
                              child: widget.luckyContainer,
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
    objectMgr.onlineMgr.off(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    super.dispose();
  }
}

class ProfilePresistentTabBar extends SliverPersistentHeaderDelegate {
  final Widget widget;

  ProfilePresistentTabBar(this.widget);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
