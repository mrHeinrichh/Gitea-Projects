import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/game_persistent_profile_header.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import '../../../utils/im_toast/im_text.dart';
import 'mobile_profile_page_panel.dart';

const double leftPadding = 20.0;
const double initialScrllOffset = 150.0;
const double scrollDesiredPercent = 0.65;
const Duration duration = Duration(milliseconds: 50);
bool oneTimeStretch = false;
bool showBigPicture = false;

class GameProfilePage extends StatefulWidget {
  const GameProfilePage({
    super.key,
    required this.body,
    required this.stickyTabBar,
    this.img,
    this.actions,
    // this.promotionFunc,
    required this.defaultImg,
    this.scrollController,
    // required this.smallImg,
    required this.server,
    required this.name,
    this.ableEdit = false,
    required this.onlineCount,
    required this.membersCount,
    required this.features,
    this.isShowTab=true,
    this.isGroupCertified = false,
  });

  final String? img;
  final Widget defaultImg;

  final ScrollController? scrollController;

  // final Widget smallImg;
  final String server;

  final NicknameText name;

  final Widget body;
  final Widget stickyTabBar;
  final Widget features;
  final VoidCallback? actions;

  // final VoidCallback? promotionFunc;
  final bool ableEdit;

  final int onlineCount;
  final int membersCount;
  final bool isShowTab;
  final bool isGroupCertified;

  @override
  _GameProfilePageState createState() => _GameProfilePageState();
}

class _GameProfilePageState extends State<GameProfilePage>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;

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

  void animateToNormalExtent(GameJumpExtent j) {
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
          animateToNormalExtent(GameJumpExtent.middle);
        } else if (mustExpand) {
          // if (widget.img != '') {
          //   // animateToMaxExtent();
          // } else {
          // }
          animateToNormalExtent(GameJumpExtent.middle);
        } else if (closeBar) {
          animateToCloseExtent();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    scrollController = widget.scrollController == null
        ? ScrollController()
        : widget.scrollController!;

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   scrollController.position.isScrollingNotifier
    //       .addListener(_handleScrollingActivity);
    // });
  }

  @override
  Widget build(BuildContext context) {
    // var height = MediaQuery.of(context).size.height;
    // minHeaderExtent = height - (height - 92.w);
    ///頂部SafeArea不要拿掉,否則上滑置頂後UI在ios會跑掉
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: ImColor.systemBg,
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is UserScrollNotification) {}
            return false;
          },
          child: NestedScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: GamePersistentProfileHeader(
                      onlineCount: widget.onlineCount,
                      membersCount: widget.membersCount,
                      img: widget.img,
                      defaultImg: widget.defaultImg,
                      server: widget.server,
                      name: widget.name,
                      toMaxImage: animateToMaxExtent,
                      toMiddleImage: animateToNormalExtent,
                      action: widget.actions,
                      ableEdit: widget.ableEdit,
                    activateGame: widget.isGroupCertified,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0).w,
                    child: widget.features,
                  ),
                ),

                // SliverPersistentHeader(
                //     pinned: false,
                //     delegate: MemberStatus(
                //         onlineCount: widget.onlineCount,
                //         membersCount: widget.membersCount)),
                if(widget.isShowTab)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: ProfileTabBar(widget.stickyTabBar),
                ),
              ];
            },
            body: widget.isShowTab? widget.body : const SizedBox(),
          ),
        ),
      ),
    );
  }
}

class MemberStatus extends SliverPersistentHeaderDelegate {
  final int onlineCount;
  final int membersCount;

  MemberStatus({required this.onlineCount, required this.membersCount});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ImText(
      '$membersCount位成员，$onlineCount在线',
      color: ImColor.white60,
      textAlign: TextAlign.center,
    );
  }

  @override
  double get maxExtent => 50.w;

  @override
  double get minExtent => 50.w;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
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

enum GameJumpExtent {
  middle,
  middleToFullScreen,
}
