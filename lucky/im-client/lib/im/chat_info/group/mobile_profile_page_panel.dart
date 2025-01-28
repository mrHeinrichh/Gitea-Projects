import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/profile_controller.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_font_size.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';

import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class MobileProfilePagePanel extends StatefulWidget {
  const MobileProfilePagePanel({
    super.key,
    required this.body,
    required this.stickyTabBar,
    this.img,
    this.actions,
    required this.defaultImg,
    required this.name,
    required this.description,
    required this.features,
    this.ableEdit = false,
    // this.isGroup = false
  });

  final String? img;
  final Widget defaultImg;

  final String name;
  final String description;

  final Widget body;
  final Widget stickyTabBar;
  final Widget features;
  final VoidCallback? actions;

  // final VoidCallback? promotionFunc;
  // final bool isGroup;
  final bool ableEdit;

  @override
  State<MobileProfilePagePanel> createState() => _MobileProfilePagePanelState();
}

class _MobileProfilePagePanelState extends State<MobileProfilePagePanel>
    with SingleTickerProviderStateMixin {
  ScrollController scroll =
      ScrollController(initialScrollOffset: initialScrollOffset);

  bool get noImage => widget.img == null || widget.img == '';

  bool get firstCollapse =>
      ProfileController.extendedHeight < ProfileController.firstHeightAnimation;

  bool get secondCollapse =>
      ProfileController.extendedHeight <
      ProfileController.secondHeightAnimation;

  bool get scrollStopped => !scroll.position.isScrollingNotifier.value;

  bool get mustRetract => firstCollapse && scroll.offset < 55;

  void animateToNormalExtent() {
    scroll.animateTo(
      initialScrollOffset + (widget.img != null ? 20 : 0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.linear,
    );
  }

  void _handleScrollingActivity() {
    if (scrollStopped) {
      if (mustRetract) {
        animateToNormalExtent();
      }
    }
  }

  @override
  void initState() {
    ProfileController.getMaxHeight();
    super.initState();
  }

  getNameWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          firstCollapse ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        ImText(
          widget.name,
          color: firstCollapse ? ImColor.black : ImColor.white,
          fontSize: ImFontSize.title,
          fontWeight: MFontWeight.bold6.value,
        ),
        ImGap.vGap4,
        ImText(
          widget.description,
          color: firstCollapse ? ImColor.black60 : ImColor.white60,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollUpdateNotification) {
              double newExpandedHeight = ProfileController.maxHeight -
                  scrollNotification.metrics.pixels;
              newExpandedHeight =
                  newExpandedHeight.clamp(88, ProfileController.maxHeight);
              if (scrollNotification.depth == 0) {
                if (scrollNotification.scrollDelta! > 0) {
                  setState(() {
                    if (widget.img == null || widget.img == '') {
                      if (ProfileController.extendedHeight >= 295) {
                        ProfileController.extendedHeight = newExpandedHeight;
                      }
                    } else {
                      ProfileController.extendedHeight = newExpandedHeight;
                    }
                  });
                } else {
                  setState(() {
                    if (noImage) {
                      if (ProfileController.extendedHeight >= 295) {
                        ProfileController.extendedHeight = newExpandedHeight;
                      }
                    } else if (ProfileController.extendedHeight >= 300) {
                      if (scrollNotification.metrics.pixels == 0) {
                        HapticFeedback.vibrate();
                      }
                      ProfileController.extendedHeight = 360.w;
                    } else {
                      ProfileController.extendedHeight = newExpandedHeight;
                    }
                  });
                }
              }
            }

            if (scrollNotification is UserScrollNotification) {
              if (scrollNotification.direction == ScrollDirection.idle &&
                  firstCollapse) {
                _handleScrollingActivity();
              }
              if (!noImage) {
                if (scrollNotification.metrics.pixels == 0 &&
                    scrollNotification.direction == ScrollDirection.forward &&
                    ProfileController.extendedHeight >
                        ProfileController.firstHeightAnimation) {
                  showGeneralDialog(
                    context: context,
                    barrierColor: ImColor.black,
                    barrierDismissible: false,
                    // barrierLabel: 'Dialog',
                    // transitionDuration: Duration(milliseconds: 400),
                    pageBuilder: (_, __, ___) {
                      HapticFeedback.vibrate();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ImGap.vGap(36),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(17.w),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: firstCollapse
                                    ? ImColor.black
                                    : ImColor.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                margin: EdgeInsets.only(bottom: 50.w),
                                height: 370.w,
                                width: ProfileController.screenWidth,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10000000),
                                  child: widget.img!.isEmpty
                                      ? widget.defaultImg
                                      : RemoteImage(
                                          src: widget.img!,
                                          fit: BoxFit.fill,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ).then((value) => animateToNormalExtent());
                }
              }
            }

            return false;
          },
          child: NestedScrollView(
            controller: scroll,
            physics: const ClampingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: ImColor.bg,
                  expandedHeight: ProfileController.extendedHeight,
                  stretch: true,
                  pinned: true,
                  forceElevated: innerBoxIsScrolled,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: firstCollapse ? ImColor.black : ImColor.white,
                      ),
                    ),
                  ),
                  actions: [
                    if (widget.ableEdit)
                      GestureDetector(
                        onTap: widget.actions,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: ImText(
                            '编辑',
                            color:
                                firstCollapse ? ImColor.purple : ImColor.white,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
                      )
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            left: firstCollapse
                                ? (ProfileController.screenWidth -
                                        ProfileController.avatarCircleBig) /
                                    2
                                : 0,
                            bottom: firstCollapse ? 70 : 0,
                            right: firstCollapse
                                ? (ProfileController.screenWidth -
                                        ProfileController.avatarCircleBig) /
                                    2
                                : 0,
                            curve: Curves.ease,
                            duration: const Duration(milliseconds: 250),
                            child: widget.img == null || widget.img == ''
                                ? widget.defaultImg
                                : AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.ease,
                                    height: firstCollapse
                                        ? ProfileController.avatarCircleBig
                                        : constraints.biggest.height,
                                    width: firstCollapse
                                        ? ProfileController.avatarCircleBig
                                        : ScreenUtil().screenWidth,
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10000000),
                                      child: RemoteImage(
                                        src: widget.img!,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                          ),
                          AnimatedPositioned(
                            left: firstCollapse ? 0 : 16.w,
                            bottom: firstCollapse ? 10 : 16.w,
                            right: 0,
                            curve: Curves.ease,
                            duration: Duration.zero,
                            child: getNameWidget(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: ImColor.bg,
                    padding: EdgeInsets.all(16.w),
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
              ];
            },
            body: widget.body,
          ),
        ),
      ),
    );
  }
}

class ProfileTabBar extends SliverPersistentHeaderDelegate {
  final Widget widget;

  ProfileTabBar(this.widget);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return widget;
  }

  @override
  double get maxExtent => 46;

  @override
  double get minExtent => 46;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
