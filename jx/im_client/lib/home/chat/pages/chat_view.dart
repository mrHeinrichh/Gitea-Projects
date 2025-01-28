import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_factory.dart';
import 'package:jxim_client/home/chat/components/chat_category/empty_chat_category_placeholder.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/bouncy_balls.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/component/home_network_bar.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/search/search_chat_ui.dart';
import 'package:jxim_client/search/search_file_ui.dart';
import 'package:jxim_client/search/search_link_ui.dart';
import 'package:jxim_client/search/search_media_ui.dart';
import 'package:jxim_client/search/search_voice_ui.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:reorderable_tabbar/reorderable_tabbar.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<StatefulWidget> createState() => ChatViewState();
}

class SlowScrollPhysics extends BouncingScrollPhysics {
  const SlowScrollPhysics({super.parent});

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(position, velocity * 0.9); // 减缓滚动速度
  }
}

class ChatViewState extends State<ChatView> with AutomaticKeepAliveClientMixin {
  ChatListController get controller => Get.find<ChatListController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () {
        final searchBar = Container(
          margin: EdgeInsets.only(
            top: controller.isSearching.value ? 0 : kSearchHeight.value / 4.5,
            bottom: kSearchHeight.value / 4.5,
          ),
          child: Row(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.centerRight,
                curve: Curves.decelerate,
                widthFactor: controller.isSearching.value ? 1 : 0,
                heightFactor: controller.isSearching.value ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    controller.searchFocus.unfocus();
                    controller.clearSearching();
                  },
                  child: OpacityEffect(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: SvgPicture.asset(
                        'assets/svgs/Back.svg',
                        width: 24,
                        height: 24,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: controller.isSearching.value ? 0 : 16.0),
                  child: SearchingAppBar(
                    onTap: () {
                      if (!controller.isSearching.value) {
                        controller.isSearching(true);
                        // controller.onInitSearch();
                      }
                    },
                    onChanged: controller.onSearchChanged,
                    onCancelTap: () {
                      controller.searchFocus.unfocus();
                      controller.clearSearching();
                    },
                    searchBarHeight: kSearchHeight.value,
                    isSearchingMode: controller.isSearching.value,
                    isAutoFocus: false,
                    focusNode: controller.searchFocus,
                    controller: controller.searchController,
                    suffixIcon: Visibility(
                      visible: controller.searchParam.value.isNotEmpty,
                      child: IconButton(
                        onPressed: () {
                          controller.searchController.clear();
                          controller.searchParam.value = '';
                          // controller.searchLocal();
                        },
                        icon: SvgPicture.asset(
                          'assets/svgs/close_round_icon.svg',
                          color: colorTextSupporting,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    isShowCancelText: false,
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.centerLeft,
                curve: Curves.decelerate,
                widthFactor: controller.isSearching.value ? 1 : 0,
                heightFactor: controller.isSearching.value ? 1 : 0,
                child: GestureDetector(
                  onTap: () => controller.enterSecretaryChat(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 16),
                    child: OpacityEffect(
                      child: ClipOval(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: Image.asset(
                            'assets/images/message_new/secretary.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: colorBackground,
          resizeToAvoidBottomInset: false,

          /// 如果是搜索页面，appbar 还是放在这里，另外个appbar会隐藏 [appbar 1]
          appBar: controller.isSearching.value ||
                  controller.showAppBarInAppBarPosition.value ||
                  !controller.isShowMiniApp
              ? ChatViewAppBar(
                  height: getTopBarHeight() +
                      (controller.chatCategoryList.length > 1 ||
                              controller.isSearching.value
                          ? 48.0
                          : 0.0),
                  titleWidget: connectView(),
                  leading: CustomTextButton(
                    controller.isEditing.value
                        ? localized(buttonDone)
                        : localized(buttonEdit),
                    onClick: controller.onChatEditTap,
                  ),
                  trailing: Visibility(
                    visible: !controller.isEditing.value,
                    child: OpacityEffect(
                      child: GestureDetector(
                        key: controller.notificationKey,
                        onTap: () async {
                          controller.showPopUpMenu(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 20, right: 16),
                          color: colorBackground,
                          child: SvgPicture.asset(
                            'assets/svgs/add.svg',
                            width: 20,
                            height: 20,
                            color: themeColor,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                  isSearchingMode: controller.isSearching.value,
                  searchWidget: searchBar,
                  bottomWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// 展示聊天室文件夹Tab
                      _buildAppBottomTab(context),
                      const ChatPinContainer(isFromHome: true),
                    ],
                  ),
                )
              : null,
          body: Stack(
            children: <Widget>[
              ///不要再拿掉,底部上滑bouncing要看到白色背景色
              Positioned(
                top: -1.sh,
                bottom: 0,
                left: 0,
                // 设置左侧边界,不可拿掉
                right: 0,
                // 设置右侧边界,不可拿掉
                child: Container(
                  color: colorWhite,
                ),
              ),

              /// 小程序页面的相关内容
              ...buildMiniAppWidgets(),

              Visibility(
                  visible: controller.showFakeAppbarInMiniApp.value,
                  child: AnimatedPositioned(
                      top: controller.offset.value,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                          width: 1.sw,
                          height: ChatListController.appletAppBarHeight,
                          child: const BottomBar()))),

              /// 如果是搜索页面展示的情况，就展示 AnimatedSwitcher 这里是没有margin 和 appbar的
              /// 反之展示的 AnimatedContainer 需要在滑动的过程中 随之动起来的
              AnimatedContainer(
                padding: EdgeInsets.only(
                    top: controller.showListViewTopBar.value
                        ? controller.offset.value
                        : 0),
                duration: Duration(
                    milliseconds: controller.mainListViewDuration.value),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: controller.isInitializing.value
                      ? _buildRemainingChatState(context)
                      : _buildContent(context, searchBar),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBottomTab(BuildContext context) {
    return Obx(() {
      if (controller.isSearching.value) {
        return _buildSearchTab(context);
      } else {
        if (controller.chatCategoryList.length <= 1) {
          return const SizedBox();
        } else {
          return _buildChatCategoryTab(context);
        }
      }
    });
  }

  Widget _buildSearchTab(BuildContext context) {
    return TabBar(
      isScrollable: false,
      // onTap: controller.onSearchTabChange,
      controller: controller.searchTabController,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      labelColor: themeColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      labelStyle: jxTextStyle.normalText(fontWeight: MFontWeight.bold5.value),
      unselectedLabelColor: colorTextSecondary,
      unselectedLabelStyle:
          jxTextStyle.normalText(fontWeight: MFontWeight.bold5.value),
      indicatorColor: themeColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          width: 2,
          color: themeColor,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      tabs: List.generate(SearchTab.values.length, (index) {
        String title = '';
        switch (SearchTab.values[index]) {
          case SearchTab.chat:
            title = localized(homeChat);
            break;
          case SearchTab.media:
            title = localized(mediaTab);
            break;
          case SearchTab.link:
            title = localized(linkTab);
            break;
          case SearchTab.file:
            title = localized(fileTab);
            break;
          case SearchTab.voice:
            title = localized(voiceTab);
            break;
          default:
            title = '';
            break;
        }

        return Tab(
          child: OpacityEffect(
            child: Text(title),
          ),
        );
      }),
    );
  }

  Widget _buildChatCategoryTab(BuildContext context) {
    final child = Obx(() {
      final List<Widget> tabChildren = List<Widget>.generate(
        controller.chatCategoryList.length,
        (int index) {
          return AbsorbPointer(
            absorbing: controller.isChatCategoryEditing.value,
            child: GestureDetector(
              key: controller.chatCategoryList[index].isAllChatRoom
                  ? UniqueKey()
                  : controller.getChatCategoryKey(index),
              behavior: HitTestBehavior.opaque,
              onLongPress: () => controller.onChatCategoryLongPress(
                context,
                index,
                controller.chatCategoryList[index],
              ),
              child: OpacityEffect(
                child: controller.buildChatCategoryTab(
                  context,
                  controller.chatCategoryList[index],
                ),
              ),
            ),
          );
        },
      );

      Widget tab = const SizedBox();

      if (controller.isChatCategoryEditing.value) {
        tab = ReorderableTabBar(
          isScrollable: true,
          onTap: (v) => controller.toggleChatCategoryStatus(v, false),
          controller: controller.chatCategoryController,
          labelColor: themeColor,
          // labelPadding: const EdgeInsets.only(right: 12.0),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelStyle: jxTextStyle.textStyleBold14().copyWith(
                fontFamily: appFontfamily,
                letterSpacing: -0.2,
              ),
          unselectedLabelColor: colorTextSecondary,
          unselectedLabelStyle: jxTextStyle.textStyleBold14().copyWith(
                fontFamily: appFontfamily,
                letterSpacing: -0.2,
              ),
          indicatorColor: themeColor,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 6.0),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 2,
              color: themeColor,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          tabs: tabChildren,
          onReorder: controller.onChatCategoryReorder,
        );
      } else {
        tab = TabBar(
          isScrollable: true,
          onTap: controller.onChatCategoryTabChange,
          controller: controller.chatCategoryController,
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelColor: themeColor,
          labelPadding: EdgeInsets.zero,
          labelStyle: jxTextStyle.textStyleBold14().copyWith(
                fontFamily: appFontfamily,
                letterSpacing: -0.2,
              ),
          unselectedLabelColor: colorTextSecondary,
          unselectedLabelStyle: jxTextStyle.textStyleBold14().copyWith(
                fontFamily: appFontfamily,
                letterSpacing: -0.2,
              ),
          indicatorColor: themeColor,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: EdgeInsets.only(
            left: !controller.isChatCategoryEditing.value ? 12.0 : 0.0,
            right: 12.0,
          ),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 2,
              color: themeColor,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          tabs: tabChildren,
        );
      }
      return tab;
    });

    return Container(
      height: 48.0,
      margin: const EdgeInsets.only(left: 4.0),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  List<Widget> buildMiniAppWidgets() {
    // 判断是否显示小程序
    if (!controller.isShowMiniApp) return []; // 如果不显示，则返回空列表

    return [
      /// 小程序页面背景
      Positioned(
        top: -1.sh,
        bottom: 0,
        left: 0,
        // 设置左侧边界,不可拿掉
        right: 0,
        // 设置右侧边界,不可拿掉
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10101C)
                    .withOpacity(controller.appletBackgroudAlpha.value),
                const Color(0xFF10101C)
                    .withOpacity(controller.appletBackgroudAlpha.value),
                const Color(0xFF3C384D)
                    .withOpacity(controller.appletBackgroudAlpha.value),
                const Color(0xFF3C384D)
                    .withOpacity(controller.appletBackgroudAlpha.value),
              ],
              stops: const [0.0, 0.5, 0.95, 1.0], // 每個顏色的比例位置
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      /// 小程序widget
      AnimatedPositioned(
        left: 0,
        right: 0,
        bottom: controller.appletBottomOffset.value,
        duration: Duration(milliseconds: controller.appletViewDuration.value),
        child: SizedBox(
          height: controller.screenHeight(),
          child: Visibility(
            visible: controller.isShowingApplet.value,
            child: PullDownApplet(
              controller: controller,
              onScroll: (offset, context) {
                controller.onAppletScroll(offset);
              },
              onScrollEnd: (offset) {
                controller.onAppletScrollEnd(offset: offset);
              },
            ),
          ),
        ),
      ),

      /// 小程序下拉 三个点部件
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: BouncyBalls(
          offset: controller.offset.value /
              (controller.isShowingApplet.value ? 1 : 0.4),
          dragging: true,
        ),
      ),
    ];
  }

  Widget _buildRemainingChatState(BuildContext context) {
    Widget child = const SizedBox();
    if (controller.isInitializing.value) {
      if (controller.isShowSkeleton.value) {
        child = Skeletonizer(
          effect: const ShimmerEffect(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            duration: Duration(milliseconds: 2000),
            highlightColor: colorWhite,
          ),
          textBoneBorderRadius:
              const TextBoneBorderRadius.fromHeightFactor(0.5),
          containersColor: colorBackground3,
          ignorePointers: false,
          enabled: true,
          child: SingleChildScrollView(
            child: Column(
              children: List<Widget>.generate(
                MediaQuery.of(context).size.height ~/ 76 + 1,
                (_) {
                  return Container(
                    height: 76,
                    width: MediaQuery.of(context).size.width,
                    padding: jxDimension.messageCellPadding(),
                    child: Row(
                      children: <Widget>[
                        Bone.circle(
                          indent: 2.0,
                          indentEnd: 10.0,
                          size: jxDimension.chatListAvatarSize(),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Bone.text(width: 60.0, fontSize: 10.0),
                                    Spacer(),
                                    Bone.text(width: 30.0, fontSize: 10.0),
                                  ],
                                ),
                                SizedBox(height: 12.0),
                                Wrap(
                                  children: <Widget>[
                                    Bone.text(width: 120.0, fontSize: 10.0),
                                    SizedBox(width: 10.0),
                                    Bone.text(width: 60.0, fontSize: 10.0),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    return Container(
      key: ValueKey('Initialize_${controller.isInitializing.value}'),

      ///這個是為了聊天列表底部數量不足一頁時,用白色填滿空間,請不要再拿掉了～
      color: colorWhite,
      child: Align(
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  Widget _buildContent(BuildContext context, Widget searchBar) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: controller.isSearching.value
          ? chatSearchView()
          : chatListView(context, searchBar),
    );
  }

  Widget chatListView(BuildContext context, Widget searchBar) {
    return RefreshIndicator(
      edgeOffset: -100.0,
      displacement: 0.0,
      onRefresh: () => controller.onRefresh(),
      child: Listener(
        onPointerUp: (event) {
          controller.touchUpDown = true;
          controller.hasVibrated = false; // 松手的时候，就恢复可以震动
          controller.mainPageScrollEnd();
        },
        onPointerDown: (event) {
          controller.touchUpDown = false;
        },
        child: NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollNotification) {
                if (controller.isBackingToMiniAppPage) {
                  return false;
                }
                controller.onScroll(-notification.metrics.pixels);
              }
              return false;
            },
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                overscroll: false, // 禁用默认效果
              ),
              child: GlowingOverscrollIndicator(
                axisDirection: AxisDirection.down, // 滚动方向
                color: const Color.fromARGB(255, 52, 49, 68), // 设置拉伸效果的颜色
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: controller.isShowingApplet.value
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(
                          parent: SlowScrollPhysics(),
                        ),
                  slivers: [
                    /// Bad network
                    HomeNetworkBar(controller: controller),

                    ///chatListView 顶部的一个  appbar 2
                    _buildAppBarAboveChatList(searchBar),

                    _buildChatList(context),

                    //SliverFillRemaining
                    Obx(
                      () => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          ///這個是為了聊天列表底部數量不足一頁時,用白色填滿空間,請不要再拿掉了～
                          color: colorSurface,
                          child: Visibility(
                            visible: controller.messageList.isEmpty &&
                                controller.chatList.isEmpty,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: controller.isSearching.value
                                  ? SearchEmptyState(
                                      searchText: controller.searchParam.value,
                                      emptyMessage: localized(
                                        oppsNoResultFoundTryNewSearch,
                                        params: [
                                          (controller.searchParam.value)
                                        ],
                                      ),
                                    )
                                  : controller.chatCategoryList.isNotEmpty &&
                                          (controller.currentChatCategoryIdx !=
                                                  0 &&
                                              controller.chatList.isEmpty)
                                      ? EmptyChatCategoryPlaceholder(
                                          controller: controller,
                                          category: controller.chatCategoryList[
                                              controller
                                                  .currentChatCategoryIdx],
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 60,
                                          ),
                                          child: Text(
                                            localized(noChatsAtThisMoment),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget chatSearchView() {
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      child: TabBarView(
        controller: controller.searchTabController,
        children: [
          SearchChatUI(
            controller: controller,
            isSearching: controller.isTyping.value,
            searchText: controller.searchController.text,
          ),
          SearchMediaUI(
            controller: controller,
            isSearching: controller.isTyping.value,
            searchText: controller.searchController.text,
          ),
          SearchLinkUI(
            controller: controller,
            isSearching: controller.isTyping.value,
            searchText: controller.searchController.text,
          ),
          SearchFileUI(
            controller: controller,
            isSearching: controller.isTyping.value,
            searchText: controller.searchController.text,
          ),
          SearchVoiceUI(
            controller: controller,
            isSearching: controller.isTyping.value,
            searchText: controller.searchController.text,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAboveChatList(Widget searchBar) {
    return controller.showListViewTopBar.value &&
            !controller.isSearching.value &&
            controller.isShowMiniApp
        ? SliverToBoxAdapter(
            child: Obx(
              () {
                final double appBarHeight = getTopBarHeight() +
                    (controller.chatCategoryList.length > 1 ? 48.0 : 0.0);

                return Stack(
                  children: [
                    ///这里是为了让search区域和聊天分类bar 有个白色的底
                    Visibility(
                        visible: !controller.showFakeAppbarInMiniApp.value,
                        child: Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.white,
                            height: kSearchHeightMax +
                                kSearchVerticalSpacing * 2 -
                                1 +
                                (controller.chatCategoryList.length > 1
                                    ? 48.0
                                    : 0.0),
                            child: const Center(),
                          ),
                        )),

                    /// 因为ChatViewAppBar的背景色是透明度
                    /// 这里是控制appbar 上半部分背景色的，还控制小程序底部appbar的展示的
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: AnimatedContainer(
                        // height: controller.isShowingApplet.value ? ChatListController.appletAppBarHeight - controller.appbarAdjustHeight() : ChatListController.appletAppBarHeight,
                        height: ChatListController.appletAppBarHeight,
                        duration: const Duration(milliseconds: 100),
                        child: Opacity(
                          opacity: controller.isOriginalAppBar.value
                              ? 0
                              : controller.appletAppBarOpacity.value,
                          child: GestureDetector(
                            onVerticalDragStart: (details) {
                              // 手势开始时重置距离
                              controller.miniAppBottomOffset = 0.0;
                            },
                            onVerticalDragUpdate: (details) {
                              // 累加滑动距离（注意：向上滑动 delta.dy 为负值，所以这里取反）
                              controller.miniAppBottomOffset -=
                                  details.delta.dy;

                              // 调用控制器更新高度或透明度
                              // controller.adjustAppBarHeight(_totalDelta);

                              controller.onAppletScroll(
                                  controller.miniAppBottomOffset);
                            },
                            onVerticalDragEnd: (details) {
                              // 滑动结束后可以处理吸附、回弹等逻辑
                              // controller.finishSliding();
                              controller.onAppletScrollEnd(
                                  fromDragAppbar: true,
                                  barOffset: controller.miniAppBottomOffset);
                              controller.miniAppBottomOffset = 0.0;
                            },
                            child: InkWell(
                              onTap: () {
                                controller.backToMainPageByAnimation();
                              },
                              child: Opacity(
                                opacity:
                                    controller.showFakeAppbarInMiniApp.value
                                        ? 0
                                        : 1,
                                child: const BottomBar(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// ChatViewAppBar 当展示小程序的appbar时，这里虽然不展示，但是位置要占者，
                    /// 然后在下拉过程中，文字需要渐变直到小时，这里有写相关控制逻辑
                    Opacity(
                      opacity: controller.appletBottomOffset.value > 0 ? 1 : 0,
                      child: IgnorePointer(
                        /// 当有在移动的时候，不能点击appbar的搜索框和上面的button
                        ignoring: controller.offset.value != 0,
                        child: ChatViewAppBar(
                          height: appBarHeight,
                          titleWidget: Opacity(
                            opacity: controller.isOriginalAppBar.value
                                ? controller.appletAppBarOpacity.value
                                : 0,
                            child: connectView(),
                          ),
                          leading: Opacity(
                              opacity: controller.isOriginalAppBar.value
                                  ? controller.appletAppBarOpacity.value
                                  : 0,
                              child: CustomTextButton(
                                controller.isEditing.value
                                    ? localized(buttonDone)
                                    : localized(buttonEdit),
                                onClick: controller.onChatEditTap,
                                color: themeColor,
                              )),
                          trailing: Opacity(
                            opacity: controller.isOriginalAppBar.value
                                ? controller.appletAppBarOpacity.value
                                : 0,
                            child: Visibility(
                              visible: !controller.isEditing.value,
                              child: OpacityEffect(
                                child: GestureDetector(
                                  key: controller.notificationKey,
                                  onTap: () async {
                                    controller.showPopUpMenu(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 16),
                                    child: SvgPicture.asset(
                                      'assets/svgs/add.svg',
                                      width: 20,
                                      height: 20,
                                      color: themeColor,
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          isSearchingMode: controller.isSearching.value,
                          searchWidget: Opacity(
                            opacity: controller.mainListOpacity.value,
                            child: searchBar,
                          ),
                          bottomWidget: Opacity(
                            opacity: controller.mainListOpacity.value,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Obx(
                                  () => controller.chatCategoryList.length <= 1
                                      ? const SizedBox()
                                      : _buildChatCategoryTab(context),
                                ),
                                const ChatPinContainer(isFromHome: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        : SliverToBoxAdapter(
            child: Container(), // 空组件，隐藏 AppBar
          );
  }

  Widget _buildChatList(BuildContext context) {
    return SlidableAutoCloseBehavior(
      child: Obx(() => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final Chat chat = controller.chatList[index];

                final bool isLastPin = chat.sort > 0 &&
                    (index < controller.chatList.length - 1 &&
                        controller.chatList[index + 1].sort == 0);
                if (chat.typ == chatTypePostNotify) {
                  return const SizedBox();
                }

                return Container(
                  key: ValueKey('${chat.id}'),
                  color: colorSurface,
                  child: Column(
                    children: <Widget>[
                      Opacity(
                        opacity: controller.mainListOpacity.value,
                        child: ChatUIFactory.createComponent(
                          chat: chat,
                          tag: chat.id.toString(),
                          index: index,
                          controller: controller,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: isLastPin ? 0 : jxDimension.chatCellPadding(),
                        ),
                        child: const CustomDivider(),
                      )
                    ],
                  ),
                );
              },
              childCount: controller.chatList.length,
              addRepaintBoundaries: false,
            ),
          )),
    );
  }

  Widget connectView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Obx(
          () => Visibility(
            visible: objectMgr.appInitState.value == AppInitState.fetching,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                color: themeColor,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (Widget child, Animation<double> animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              key: ValueKey(objectMgr.appInitState.value),
              objectMgr.appInitState.value.toName,
              textAlign: TextAlign.center,
              style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
            ), // THIS CHANGES THE IMAGE FINE, BUT DOESNT ANIMATE
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
