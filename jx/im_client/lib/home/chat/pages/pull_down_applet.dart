import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/widgets/image/draggable_image_icon.dart';

/// 自定义小程序组件，支持滚动回调和滚动结束回调。
class PullDownApplet extends StatefulWidget {
  const PullDownApplet({
    super.key,
    required this.controller,
    required this.onScroll,
    required this.onScrollEnd,
  });

  /// 控制器，用于管理小程序状态。
  final ChatListController controller;

  /// 滚动过程中的回调函数。
  final void Function(double offset, BuildContext context) onScroll;

  /// 滚动结束的回调函数。
  final void Function(double offset) onScrollEnd;

  @override
  State<PullDownApplet> createState() => _PullDownAppletState();
}

class _PullDownAppletState extends State<PullDownApplet> {
  /// 滚动控制器，用于监听和控制外层滚动视图。
  final ScrollController _singleChildScrollController = ScrollController();
  late final PullDownAppletController _miniAppController;
  double _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _miniAppController = Get.find<PullDownAppletController>();

    _singleChildScrollController.addListener(() {
      if (widget.controller.isBackingToMainPage) {
        return;
      }
      if (widget.controller.isShowingApplet.value &&
          _singleChildScrollController.position.pixels >=
              _singleChildScrollController.position.maxScrollExtent) {
        _currentOffset = _singleChildScrollController.position.pixels -
            _singleChildScrollController.position.maxScrollExtent;
        // widget.onScroll(_currentOffset, context);
      }

      if (widget.controller.isShowingApplet.value &&
          _singleChildScrollController.position.pixels <=
              _singleChildScrollController.position.maxScrollExtent) {
        _currentOffset = 0;
        // widget.onScroll(_currentOffset, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          /// 用于辅助实现设计需要的动画效果，仅此而已
          Visibility(visible: widget.controller.isMiniAppletDraggingIcon.value, child: Positioned(bottom: 0, left: 0, right: 0, child: SizedBox(width: double.infinity,height: ChatListController.appletAppBarHeight,child: const BottomBar(),),)),
          Visibility(
              visible: !_miniAppController.isMoreApps.value, child: Opacity(opacity: widget.controller.miniAppIconOpacity.value,child: mainPage())),
          Visibility(
              visible: _miniAppController.isMoreApps.value, child: Opacity(opacity: widget.controller.miniAppIconOpacity.value,child: morePage())),
        ],
      ),
    );
  }

  double _calculateMyAppsHeight(int itemCount) {
    const double itemHeight = 74.0;
    const double rowSpacing = 16.0;
    const int itemsPerRow = 4;

    if (itemCount <= 0) {
      return 0;
    }

    // 總行數
    int rowCount = (itemCount / itemsPerRow).ceil();

    // 總高度 = 行數 * 項目高度 + (行數 - 1) * 行間距
    return rowCount * itemHeight + (rowCount - 1) * rowSpacing;
  }

  Widget mainPage() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PrimaryAppBar(
        isBackButton: false,
        backButtonColor: Colors.white,
        title: localized(miniApp),
        titleColor: Colors.white,
        bgColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Opacity(
        // 根据控制器中的值动态调整小程序的透明度。
        opacity: 1,
        child: Listener(
          // 监听手指抬起事件，触发滚动结束回调。
          onPointerUp: (event) {
            widget.onScrollEnd(_currentOffset);
          },
          // on
          child: Stack(
            children: [
              CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                // 使用自定义滚动物理效果。
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: true, // 确保即使内容不足时也支持滚动。
                    child: SingleChildScrollView(
                      physics: const CustomAlwaysScrollablePhysics(),
                      controller: _singleChildScrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(context),
                          Obx((){
                            return _miniAppController.recentApps.isNotEmpty ? Padding(
                                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                                child: DraggableImageIcon(
                                  instanceId: 'recent_1',  // 最近使用的小程序
                                  hasMoreButton: true,
                                  list: _miniAppController.recentApps,
                                  title: localized(miniAppRecentlyUsedApp),
                                  onTapMore: () {
                                    _miniAppController.setIsMoreApps(true);
                                  },
                                  onDragStarted: () {
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(true);
                                    _miniAppController.dragFromRecent.value = true;
                                  },
                                  onDragUpdate: (data) {},
                                  onDraggableCanceled: (_,__){
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                    _miniAppController.dragFromRecent.value = false;
                                  },
                                  onDragEnd: (_) {
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                    _miniAppController.dragFromRecent.value = false;
                                  },
                                  onTapItem: (app) {
                                    _miniAppController.joinMiniApp(
                                      app,
                                      context,
                                    );
                                  },
                                ),
                              ) : const SizedBox.shrink();
                          }),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Obx(
                              () {
                                if (_miniAppController.myApps.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return DraggableImageIcon(
                                  instanceId: 'favorite_1',  // 收藏的小程序
                                  hasMoreButton: false,
                                  title: localized(myMiniApp),
                                  list: _miniAppController.myApps,
                                  onTapMore: () {
                                    _miniAppController.setIsMoreApps(true);
                                  },
                                  onDragStarted: () {
                                    littleVibrate();
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(true);
                                  },
                                  onDragUpdate: (data) {},
                                  onDragCompleted: (app) {
                                    _miniAppController.removeFavorite(app);
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onDraggableCanceled: (_,__){
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onDragEnd: (_) {
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onTapItem: (app) {
                                    _miniAppController.joinMiniApp(
                                      app,
                                      context,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 85,
                          ),
                          // const Spacer(),
                          // DeleteBottomBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.controller.isMiniAppletDraggingIcon.value)
                ...[
                  if(_miniAppController.dragFromRecent.value)
                    Positioned(
                      top: 242,
                      left: 32,
                      right: 32,
                      child: DragTarget(
                        onAccept: (data) async {
                          dynamic app = _miniAppController.recentApps[data as int];
                          _miniAppController.recentAddToFavourite(app);
                          widget.controller
                              .setIsMiniAppletDraggingIcon(false);
                          _miniAppController.dragFromRecent.value = false;
                        },
                        onWillAccept: (data) {
                          return true;
                          }, onMove: (DragTargetDetails details) {
                          if (!widget.controller.isAddMiniAppIsBeingHovered.value) {
                            widget.controller.isAddMiniAppIsBeingHovered.value = true;
                            littleVibrate();
                          }
                        }, onLeave: (data) {
                          widget.controller.isAddMiniAppIsBeingHovered.value = false;
                        }, onAcceptWithDetails: (DragTargetDetails<int> details) {
                          widget.controller.isAddMiniAppIsBeingHovered.value = false;
                        },
                        builder: (
                            BuildContext context,
                            List<dynamic> accepted,
                            List<dynamic> rejected,
                            ) {
                          return AddToFavouriteMiniApp(
                            isHover: widget.controller.isAddMiniAppIsBeingHovered.value,
                            myRecentListHeight: _calculateMyAppsHeight(_miniAppController.myApps.length)
                          );
                        }
                      ),
                    ),

                  Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DragTarget(
                          onAccept: (data){
                            if(_miniAppController.dragFromRecent.value){
                              dynamic app = _miniAppController.recentApps[data as int];
                              _miniAppController.removeRecent(app);
                              widget.controller
                                  .setIsMiniAppletDraggingIcon(false);
                              _miniAppController.dragFromRecent.value = false;
                            }
                          },
                          onWillAccept: (data) {
                            return true;
                          },
                          onMove: (DragTargetDetails details) {
                            // 物件正在範圍內移動
                            if (!widget.controller.isBeingHovered.value) {
                              widget.controller.isBeingHovered.value = true;
                              littleVibrate();
                            }
                          },
                          onLeave: (data) {
                            // 物件離開範圍
                            widget.controller.isBeingHovered.value = false;
                          },
                          onAcceptWithDetails: (DragTargetDetails<int> details) {
                            widget.controller.isBeingHovered.value = false;
                          },
                          builder: (
                            BuildContext context,
                            List<dynamic> accepted,
                            List<dynamic> rejected,
                            ) {
                          return DeleteBottomBar(
                            isHovered: widget.controller.isBeingHovered.value,
                          );
                      }))
                ]
            ],
          ),
        ),
      ),
    );
  }

  Widget morePage() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PrimaryAppBar(
        isBackButton: true,
        onPressedBackBtn: () {
          _miniAppController.setIsMoreApps(false);
        },
        backButtonColor: Colors.white,
        title: localized(miniAppRecentlyUsedApp) ,
        titleColor: Colors.white,
        bgColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Opacity(
        // 根据控制器中的值动态调整小程序的透明度。
        opacity: 1,
        child: Listener(
          // 监听手指抬起事件，触发滚动结束回调。
          onPointerUp: (event) {
            widget.onScrollEnd(_currentOffset);
          },
          // on
          child: Stack(
            children: [
              CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                // 使用自定义滚动物理效果。
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: true, // 确保即使内容不足时也支持滚动。
                    child: SingleChildScrollView(
                      controller: _singleChildScrollController, // 更多页面如果需要支持上拉回到主页，这里的注释去掉就可以了
                      physics: const CustomAlwaysScrollablePhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(context),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 24, right: 24, bottom: 24, top: 12),
                            child: Obx(
                              () {
                                if (_miniAppController.allRecentApps.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return DraggableImageIcon(
                                  instanceId: 'search_1',  // 搜索结果的小程序
                                  hasTitle: false,
                                  list: _miniAppController.allRecentApps,
                                  onDragStarted: () {
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(true);
                                  },
                                  onDragUpdate: (data) {},
                                  onDragCompleted: (app) {
                                    switch(_miniAppController.recentMorePageAddDelToggleHover.value){
                                      case MiniAppRecentBtnType.add:
                                        _miniAppController.recentAddToFavourite(app);
                                        _miniAppController.recentMorePageAddDelToggleHover.value = MiniAppRecentBtnType.idle;
                                        break;
                                      case MiniAppRecentBtnType.delete:
                                        _miniAppController.removeRecent(app);
                                        _miniAppController.recentMorePageAddDelToggleHover.value = MiniAppRecentBtnType.idle;
                                        break;
                                      case MiniAppRecentBtnType.idle:
                                        break;
                                    }
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onDraggableCanceled: (_,__){
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onDragEnd: (_) {
                                    widget.controller
                                        .setIsMiniAppletDraggingIcon(false);
                                  },
                                  onTapItem: (app) {
                                    _miniAppController.joinMiniApp(
                                      app,
                                      context,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            height: 85,
                          ),
                          // const Spacer(),
                          // DeleteBottomBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if(widget.controller.isMiniAppletDraggingIcon.value)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DragTarget(
                      onWillAccept: (data) {
                        return true;
                      }, onMove: (DragTargetDetails details) {
                    // 物件正在範圍內移動
                    if (!widget.controller.isBeingHovered.value) {
                      widget.controller.isBeingHovered.value = true;
                      littleVibrate();
                    }
                    MiniAppRecentBtnType oldType = _miniAppController.recentMorePageAddDelToggleHover.value;

                    _miniAppController.recentMorePageAddDelToggleHover.value = details.offset.dx
                        <= ((MediaQuery.of(context).size.width - 72) / 2) ?
                    MiniAppRecentBtnType.add
                        : MiniAppRecentBtnType.delete;

                    if(oldType != _miniAppController.recentMorePageAddDelToggleHover.value && oldType != MiniAppRecentBtnType.idle){
                      littleVibrate();
                    }

                  }, onLeave: (data) {
                    // 物件離開範圍
                    widget.controller.isBeingHovered.value = false;
                    _miniAppController.recentMorePageAddDelToggleHover.value = MiniAppRecentBtnType.idle;
                  }, onAcceptWithDetails: (DragTargetDetails<int> details) {
                    widget.controller.isBeingHovered.value = false;
                  }, builder: (
                      BuildContext context,
                      List<dynamic> accepted,
                      List<dynamic> rejected,
                      ) {
                    return Obx(()=>BottomBarRecentMorePage(
                      selectedButtonToggleHover: _miniAppController.recentMorePageAddDelToggleHover.value,
                    ));
                  }),
                )
            ],
          ),
        ),
      ),
    );
  }

  double _maxOffset() {
    return 100;
  }

  double bottomBarOpacity() {
    double opacity = 1;
    double maxOffset = _maxOffset();
    double offset = widget.controller.appletBottomOffset.value;
    if (offset <= 0) {
      opacity = 1;
    } else if (offset <= maxOffset) {
      opacity = (maxOffset - offset) / maxOffset;
    } else {
      opacity = 1;
    }
    if (opacity > 1 || opacity < 0) {
      opacity = 1;
    }
    return opacity;
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _miniAppController.goPullDownSearch();
      },
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorWhite.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: OpacityEffect(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImage(
                'assets/svgs/search_outlined.svg',
                size: 24,
                padding: const EdgeInsets.only(right: 4),
                color: colorWhite.withOpacity(0.5),
              ),
              Text(
                localized(search),
                style: jxTextStyle.textStyle17(
                  color: colorWhite.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 释放滚动控制器资源。
    _singleChildScrollController.dispose();
    super.dispose();
  }
}

/// 自定义的滚动物理行为，支持一定的越界滚动。
class CustomAlwaysScrollablePhysics extends AlwaysScrollableScrollPhysics {
  const CustomAlwaysScrollablePhysics({super.parent});

  @override
  CustomAlwaysScrollablePhysics applyTo(ScrollPhysics? ancestor) {
    // 生成新的物理行为实例，并关联父级物理行为。
    return CustomAlwaysScrollablePhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 自定义边界条件，允许越界滚动逻辑。
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return 0.0; // 允许向上越界。
    }
    if (value > position.pixels &&
        position.pixels >= position.maxScrollExtent) {
      return 0.0; // 允许向下越界。
    }
    // 使用默认逻辑处理其他情况。
    return super.applyBoundaryConditions(position, value);
  }
}

class AddToFavouriteMiniApp extends StatefulWidget {
  const AddToFavouriteMiniApp({
    super.key,
    this.isHover = false,
    this.myRecentListHeight = 178
  });
  final bool isHover;
  final double myRecentListHeight;

  @override
  State<AddToFavouriteMiniApp> createState() => _AddToFavouriteMiniAppState();
}

class _AddToFavouriteMiniAppState extends State<AddToFavouriteMiniApp> {
  @override
  Widget build(BuildContext context) {
    if(widget.myRecentListHeight==0) return const SizedBox();

    return Stack(
      children: [
        DottedBorder(
          strokeCap: StrokeCap.round,
          dashPattern: const [10,10],
          color: Colors.white.withOpacity(0.2),
          strokeWidth: 2,
          radius: const Radius.circular(10),
          borderType: BorderType.RRect,
          child: SizedBox(height: widget.myRecentListHeight,
            width: 326,),
        ),
        Container(
          height: widget.myRecentListHeight,
          alignment: Alignment.center,
          decoration:  BoxDecoration(
              color: widget.isHover ? const Color(0xE61B1A23) : const Color(0xE5231F38),
              borderRadius: const BorderRadius.all(Radius.circular(10))
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add,
                size: 34,
                color: Colors.white,
              ),
              const SizedBox(height: 1),
              Text(
                widget.isHover ? localized(miniAppReleaseToAdd) :  localized(miniAppAddNewApps),
                style: jxTextStyle.textStyle13(color: Colors.white),
              )
            ],
          ),
        )
      ],
    );
  }
}

class BottomBarRecentMorePage extends StatefulWidget {
  const BottomBarRecentMorePage({
    super.key,
    this.selectedButtonToggleHover = MiniAppRecentBtnType.idle,
  });
  final MiniAppRecentBtnType selectedButtonToggleHover;
  @override
  State<BottomBarRecentMorePage> createState() => _BottomBarRecentMorePageState();
}

class _BottomBarRecentMorePageState extends State<BottomBarRecentMorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 從畫面底部外部開始
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 開始播放進場動畫
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Widget child({required String image,required String title})=> Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 15),
        SvgPicture.asset(
          image,
          width: 24,
          height: 24,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );

    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          Expanded(child: Container(
            height: ChatListController.appletAppBarHeight,
            decoration: BoxDecoration(
              color: (widget.selectedButtonToggleHover == MiniAppRecentBtnType.add
                  ? const Color(0xFF474747)
                  : const Color(0xFF515151)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
              ),
            ),
            child: child(
                image: widget.selectedButtonToggleHover == MiniAppRecentBtnType.add
                    ? 'assets/svgs/mini_app_add_open.svg'
                    : 'assets/svgs/mini_app_add_close.svg',
                title: widget.selectedButtonToggleHover == MiniAppRecentBtnType.add
                    ? localized(miniAppReleaseToAdd) : localized(miniAppAddNewApps)
            ),
          )),
          Expanded(
              child: Container(
                  height: ChatListController.appletAppBarHeight,
                  decoration: BoxDecoration(
                    color: (widget.selectedButtonToggleHover == MiniAppRecentBtnType.delete
                        ? const Color.fromARGB(255, 228, 74, 74)
                        : const Color.fromARGB(255, 250, 81, 81)),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: child(
                      image: widget.selectedButtonToggleHover == MiniAppRecentBtnType.delete
                      ? 'assets/svgs/mini_app_trash_open.svg'
                          : 'assets/svgs/mini_app_trash.svg',
                      title: widget.selectedButtonToggleHover == MiniAppRecentBtnType.delete
                          ? localized(miniAppReleaseToDelete)
                          : localized(dragHereToDelete)
                  )
              )
          )
        ],
      ),
    );
  }
}


class DeleteBottomBar extends StatefulWidget {
  final bool isHovered;

  const DeleteBottomBar({super.key, required this.isHovered});

  @override
  _DeleteBottomBarState createState() => _DeleteBottomBarState();
}

class _DeleteBottomBarState extends State<DeleteBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 從畫面底部外部開始
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 開始播放進場動畫
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: ChatListController.appletAppBarHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: (widget.isHovered
              ? const Color.fromARGB(255, 228, 74, 74)
              : const Color.fromARGB(255, 250, 81, 81)),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 13),
            SvgPicture.asset(
              widget.isHovered
                  ? 'assets/svgs/mini_app_trash_open.svg'
                  : 'assets/svgs/mini_app_trash.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 2),
            Text(
              widget.isHovered
                  ? localized(miniAppReleaseToDelete)
                  : localized(dragHereToDelete),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      // 充满整个高度
      alignment: Alignment.topCenter,
      // 内容居上对齐
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 95, 92, 107),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // 子元素顶部对齐
          children: [
            // 第一个 Text
            SizedBox(
              height: 20,
              width: 35,
              child: Text(
              localized(edit),
              style: TextStyle(
                color: colorWhite.withOpacity(0.6),
                fontSize: 16,
              ),
            ),),
            // 中间 Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Config().appName,
                    style: TextStyle(
                      color: colorWhite.withOpacity(0.6),
                      fontSize: 17,
                      fontWeight: GetPlatform.isIOS ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // 最后一个 Icon
            Container(
              width: 35,
              height: 20,
              alignment: Alignment.centerRight, // 内容右对齐
              child: SvgPicture.asset(
                'assets/svgs/add.svg',
                width: 20,
                height: 20,
                color: colorWhite.withOpacity(0.6),
                fit: BoxFit.fitWidth,
              ),
            )
          ],
        ),
      ),
    );
  }
}
