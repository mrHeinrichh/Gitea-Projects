import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

class FriendRequestList extends GetWidget<ContactController> {
  const FriendRequestList(this.requestList, {super.key});

  final RxList<FriendShipItem> requestList;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          ListView.separated(
            itemCount: requestList.length,
            itemBuilder: (BuildContext context, int index) {
              FriendShipItem item = requestList[index];
              if (item.isUser) {
                User user = item.user;
                MessageState userState = item.state;
                return Column(
                  children: [
                    LeftSlideActions(
                      key: Key("${user.uid}"),
                      actionsWidth: 60,
                      actionsBuilder: (hide) {
                        return [
                          InkWell(
                            onTap: () {
                              userState == MessageState.sentFriendRequest
                                  ? controller.withdrawRequest(user)
                                  : controller
                                      .deleteFriendRequestPageFriend(user);
                              hide();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 1, bottom: 1),
                              alignment: Alignment.center,
                              width: 60,
                              height: double.infinity,
                              color: Colors.red,
                              child: Text(
                                localized(
                                  userState == MessageState.sentFriendRequest
                                      ? withdraw
                                      : chatDelete,
                                ),
                                style: jxTextStyle.textStyleBold12(
                                  color: colorWhite,
                                ),
                              ),
                            ),
                          ),
                        ];
                      },
                      childBuilder: (_) {
                        return Obx(() {
                          return Container(
                            color: Colors.white,
                            child: ContactCard(
                              isSelectMode: controller.isSelectMode.value,
                              isDisabled: false,
                              onTap: null,
                              user: user,
                              subTitle: subTitle(user),
                              subTitleColor: colorTextSecondary,
                              trailing: trailing(user),
                              gotoChat: false,
                            ),
                          );
                        });
                      },
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(0)),
                      ),
                      actionsWillShow: () {},
                    ),
                    Visibility(
                      visible: index == requestList.length - 1,
                      child: Padding(
                        padding: EdgeInsets.only(left: 60.w),
                        child: const CustomDivider(),
                      ),
                    ),
                  ],
                );
              } else {
                return buildHeader(item.title);
              }
            },
            separatorBuilder: (BuildContext context, int index) => Padding(
              padding: EdgeInsets.only(left: 60.w),
              child: const CustomDivider(),
            ),
          ),
          requestList.isNotEmpty
              ? Positioned(
                  child: Container(
                    height: 0.33,
                    color: colorTextPrimary.withOpacity(0.2),
                  ),
                )
              : const SizedBox(
                  height: 0.1,
                ),
        ],
      );
    });
  }

  Widget buildAnimaion(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          ListViewWithSwipeAction(
            itemCount: requestList.length,
            swipeItemWidth: 60.w,
            supportSwipe: (BuildContext context, int index) {
              FriendShipItem item = requestList[index];
              return item.isUser;
            },
            swipeItemBuilder: (
              BuildContext context,
              int index,
              Function(bool) resetSwipeItem,
            ) {
              FriendShipItem item = requestList[index];
              User user = item.user;
              MessageState userState = item.state;
              return GestureDetector(
                onTap: () {
                  // 滑动后漏出的按钮 删除 或者 撤销
                  resetSwipeItem(true); // 恢复删除按钮
                  userState == MessageState.sentFriendRequest
                      ? controller.withdrawRequest(user)
                      : controller.deleteFriendRequestPageFriend(user);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 1, bottom: 1),
                  alignment: Alignment.center,
                  width: 60.w,
                  height: 50,
                  color: Colors.red,
                  child: Text(
                    localized(
                      userState == MessageState.sentFriendRequest
                          ? withdraw
                          : chatDelete,
                    ),
                    style: jxTextStyle.textStyleBold12(color: colorWhite),
                  ),
                ),
              );
            },
            itemBuilder: (
              BuildContext context,
              int index,
              bool Function() isShowActions,
              Function(bool) resetSwipeItem,
            ) {
              FriendShipItem item = requestList[index];
              User user = item.user;
              if (item.isUser) {
                return Obx(() {
                  return Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ContactCard(
                          isSelectMode: controller.isSelectMode.value,
                          isDisabled: false,
                          onTap: () {
                            resetSwipeItem(false);
                            Get.toNamed(
                              RouteName.chatInfo,
                              arguments: {"uid": user.uid, "id": user.uid},
                            );
                          },
                          user: user,
                          subTitle: subTitle(user),
                          subTitleColor: colorTextSecondary,
                          trailing: trailing(user),
                          gotoChat: false,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 60.w),
                          child: const CustomDivider(),
                        ),
                      ],
                    ),
                  );
                });
              } else {
                return GestureDetector(
                  onTap: () {},
                  child: buildHeader(item.title),
                );
              }
            },
          ),
          Positioned(
            child: Container(
              height: 1,
              color: colorTextPrimary.withOpacity(0.2),
            ),
          ),
        ],
      );
    });
  }

  String? subTitle(User user) {
    String result = user.remark;
    MessageState state = FriendShipUtils.getMessageState(user.uid);
    var latestHistoryInfo = FriendShipUtils.getLastestHistoryRemark(user.uid);
    if (state == MessageState.recievedFriendRequest ||
        state == MessageState.rejectedFriendRequestByMe ||
        state == MessageState.acceptedFriendRequestByMe) {
      if (result.isEmpty) {
        result = latestHistoryInfo['received'];
      }
    }
    if (state == MessageState.sentFriendRequest ||
        state == MessageState.rejectedFriendRequestByHer ||
        state == MessageState.acceptedFriendRequestByHer ||
        state == MessageState.withdrewFriendRequestByMe) {
      if (result.isEmpty) {
        result = latestHistoryInfo['sent'];
      }
      if (result.isNotEmpty) {
        result = "${localized(contactMe)}：$result";
      }
    }
    return result;
  }

  List<Widget>? trailing(User user) {
    MessageState state = FriendShipUtils.getMessageState(user.uid);
    List<Widget> trailingList = [];
    Widget? textWidget;
    double imageSize = 16;
    if (state == MessageState.recievedFriendRequest) {
      textWidget = Text(
        localized(groupCheck),
        style: jxTextStyle.textStyleBold14(color: themeColor),
      );
    } else if (state == MessageState.sentFriendRequest) {
      textWidget = Text(
        localized(contactVerifying),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
    } else if (state == MessageState.acceptedFriendRequestByMe) {
      textWidget = Text(
        localized(addedStickerBtn),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
      trailingList.add(
        Container(
          margin: const EdgeInsets.only(right: 10),
          height: imageSize,
          width: imageSize,
          child: Image.asset("assets/images/received_arrow.png"),
        ),
      );
    } else if (state == MessageState.acceptedFriendRequestByHer) {
      textWidget = Text(
        localized(addedStickerBtn),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
      trailingList.add(
        Container(
          margin: const EdgeInsets.only(right: 10),
          height: imageSize,
          width: imageSize,
          child: Image.asset("assets/images/sent_arrow.png"),
        ),
      );
    } else if (state == MessageState.rejectedFriendRequestByMe) {
      textWidget = Text(
        localized(rejected),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
      trailingList.add(
        Container(
          margin: const EdgeInsets.only(right: 10),
          height: imageSize,
          width: imageSize,
          child: Image.asset("assets/images/received_arrow.png"),
        ),
      );
    } else if (state == MessageState.rejectedFriendRequestByHer) {
      textWidget = Text(
        localized(rejected),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
      trailingList.add(
        Container(
          margin: const EdgeInsets.only(right: 10),
          height: imageSize,
          width: imageSize,
          child: Image.asset("assets/images/sent_arrow.png"),
        ),
      );
    } else if (state == MessageState.withdrewFriendRequestByMe) {
      textWidget = Text(
        localized(withdrawn),
        style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
      );
    }
    trailingList.add(
      Container(
        alignment: Alignment.center,
        width: 77,
        height: 32,
        decoration: BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.circular(5),
        ),
        child: textWidget,
      ),
    );
    return trailingList;
  }

  Widget buildHeader(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 30,
      color: colorBackground,
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        softWrap: false,
        style: jxTextStyle.textStyle12(
          color: colorTextSecondary,
        ),
      ),
    );
  }
}

/// 这个动画效果在性能不好的机器会有点卡
class ListViewWithSwipeAction extends StatefulWidget {
  /// 需要创建多少个item
  final int itemCount;

  /// 创建 item  isShowActions 调用这个方法可以知道当前的左滑出来的view 是不是展示的， reset是让 左滑出来的view  复原
  /// 比如当前左滑出来的view 是展示的，你点击了这个item 可以不去执行事件，而是先复位左滑出来的view，下次点击再执行相印动作
  final Widget Function(
    BuildContext context,
    int index,
    bool Function() isShowActions,
    Function(bool) resetSwipeItem,
  ) itemBuilder;

  /// 创建左滑后展示的内容
  final Widget Function(
    BuildContext context,
    int index,
    Function(bool) resetSwipeItem,
  ) swipeItemBuilder;

  /// actions 的宽度
  final double swipeItemWidth;

  /// 某个item是否支持左滑
  final bool Function(BuildContext context, int index) supportSwipe;

  const ListViewWithSwipeAction({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.swipeItemBuilder,
    required this.supportSwipe,
    this.swipeItemWidth = 100,
  });

  @override
  ListViewWithSwipeActionState createState() => ListViewWithSwipeActionState();
}

class ListViewWithSwipeActionState extends State<ListViewWithSwipeAction>
    with SingleTickerProviderStateMixin {
  int? revealedIndex;
  double revealedOffset = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {
          revealedOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void resetRevealed({bool animate = true}) {
    if (revealedIndex != null) {
      if (animate) {
        _animation =
            Tween<double>(begin: revealedOffset, end: 0.0).animate(_controller);
        _controller.forward(from: 0.0).then((_) {
          setState(() {
            revealedIndex = null;
            revealedOffset = 0.0;
          });
        });
      } else {
        setState(() {
          revealedIndex = null;
          revealedOffset = 0.0;
        });
      }
    }
  }

  void goDestination({bool animate = true}) {
    if (revealedIndex != null) {
      if (animate) {
        _animation =
            Tween<double>(begin: revealedOffset, end: widget.swipeItemWidth)
                .animate(_controller);
        _controller.forward(from: 0).then((_) {
          setState(() {
            revealedOffset = widget.swipeItemWidth;
          });
        });
      } else {
        setState(() {
          revealedOffset = widget.swipeItemWidth;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: null,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // 开始滚动就复位
          if (scrollInfo is ScrollStartNotification) {
            resetRevealed();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return GestureDetector(
              onHorizontalDragUpdate: !widget.supportSwipe(context, index)
                  ? null
                  : (details) {
                      if (details.primaryDelta! < 0) {
                        // Left swipe
                        setState(() {
                          if (revealedIndex != index) {
                            resetRevealed(
                              animate: false,
                            ); // Reset previously revealed item
                          }
                          revealedIndex = index;
                          revealedOffset =
                              (revealedOffset - details.primaryDelta!)
                                  .clamp(0.0, widget.swipeItemWidth);
                        });
                      } else if (details.primaryDelta! > 0) {
                        // Right swipe
                        setState(() {
                          revealedOffset =
                              (revealedOffset - details.primaryDelta!)
                                  .clamp(0.0, widget.swipeItemWidth);
                          if (revealedOffset == 0) {
                            revealedIndex = null;
                          }
                        });
                      }
                    },
              onHorizontalDragEnd: !widget.supportSwipe(context, index)
                  ? null
                  : (details) {
                      if (revealedOffset < widget.swipeItemWidth * 0.6) {
                        resetRevealed();
                      } else {
                        goDestination();
                      }
                    },
              child: Stack(
                children: [
                  if (revealedIndex == index)
                    Positioned(
                      left: screenWidth - revealedOffset,
                      child: widget.swipeItemBuilder(context, index,
                          (bool animate) {
                        resetRevealed(animate: animate);
                      }),
                    ),
                  Transform.translate(
                    offset:
                        Offset(revealedIndex == index ? -revealedOffset : 0, 0),
                    child: widget.itemBuilder(context, index, () {
                      return revealedIndex != null;
                    }, (bool animate) {
                      resetRevealed(animate: animate);
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 用来实现左滑的
class LeftSlideActions extends StatefulWidget {
  final double actionsWidth;
  final List<Widget> Function(Function()) actionsBuilder;
  final Widget Function(Function()) childBuilder;
  final Decoration? decoration;
  final VoidCallback? actionsWillShow;

  const LeftSlideActions({
    super.key,
    required this.actionsWidth,
    required this.actionsBuilder,
    required this.childBuilder,
    this.decoration,
    this.actionsWillShow,
  });

  @override
  LeftSlideActionsState createState() => LeftSlideActionsState();
}

class LeftSlideActionsState extends State<LeftSlideActions>
    with TickerProviderStateMixin {
  double _translateX = 0;
  late AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      lowerBound: -widget.actionsWidth,
      upperBound: 0,
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        _translateX = _controller.value;
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actionsBuilder(_hide),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (v) {
              _onHorizontalDragUpdate(v);
            },
            onHorizontalDragEnd: (v) {
              _onHorizontalDragEnd(v);
            },
            child: Transform.translate(
              offset: Offset(_translateX, 0),
              child: Row(
                children: [
                  Expanded(flex: 1, child: widget.childBuilder(_hide)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _translateX =
        (_translateX + details.delta.dx).clamp(-widget.actionsWidth, 0.0);
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _controller.value = _translateX;
    if (details.velocity.pixelsPerSecond.dx > 200) {
      _hide();
    } else if (details.velocity.pixelsPerSecond.dx < -200) {
      _show();
    } else {
      if (_translateX.abs() > widget.actionsWidth / 2) {
        _show();
      } else {
        _hide();
      }
    }
  }

  void _show() {
    if (widget.actionsWillShow != null) {
      widget.actionsWillShow!();
    }
    if (_translateX != -widget.actionsWidth) {
      _controller.animateTo(-widget.actionsWidth);
    }
  }

  void _hide() {
    if (_translateX != 0) {
      _controller.animateTo(0);
    }
  }
}
