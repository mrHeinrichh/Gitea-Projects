import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/components/chat_category/chat_category_sub_item.dart';
import 'package:jxim_client/home/chat/components/chat_category/chat_category_tab_item.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_bottom_sheet.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_controller.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/home/chat/pages/pull_down_applet_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_view.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/chat_category_folder/create/chat_category_create.dart';
import 'package:jxim_client/setting/chat_category_folder/create/chat_category_selection.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_container.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synchronized/synchronized.dart';

class ChatListEvent extends EventDispatcher {
  static const String eventChatPinnedUpdate = 'eventChatPinnedUpdate';
  static const String eventMultiSelectStateChange =
      'eventMultiSelectStateChange';
  static const String eventChatEditSelect = 'eventChatEditSelect';
  static const String eventChatEnableEditStateChange =
      'eventChatEnableEditStateChange';

  static final ChatListEvent instance = ChatListEvent._internal();

  factory ChatListEvent() {
    return instance;
  }

  ChatListEvent._internal();
}

class ChatListController extends GetxController
    with GetTickerProviderStateMixin {
  /// VARIABLES
  static const int searchInitState = 1;
  static const int searchSearchingState = 2;
  static const int searchResultState = 3;

  // 提供滑动控制器到聊天列表
  final ScrollController scrollController = ScrollController();

  // 聊天列表事件分发器
  final ChatListEvent chatListEvent = ChatListEvent.instance;

  // 完整聊天列表
  final List<Chat> allChats = [];

  // 展示列表 (响应)
  final chatList = <Chat>[].obs;

  // 记录骨架持续时间timer
  final sw = Stopwatch();

  //  首次初始化加载状态
  final isInitializing = true.obs;

  // 展示骨架加载
  final isShowSkeleton = false.obs;

  /// 小程序相关的控制变量
  bool isShowMiniApp = objectMgr.miniAppMgr.isShowMiniApp;

  /// [offset] 控制主页面的顶部偏移量
  RxDouble offset = 0.0.obs;

  /// [miniAppBottomOffset]小程序页面 手动滑动底部bar的移动距离
  double miniAppBottomOffset = 0;
  /// [appletBottomOffset] 控制小程序的低部距离，默认设置为屏幕高度
  RxDouble appletBottomOffset = 1.sh.obs;

  ///  [isBackingToMainPage] 是否正在回主页
  bool isBackingToMainPage = false;
  ///  [isBackingToMiniAppPage] 是否正在回小程序页面
  bool isBackingToMiniAppPage = false;

  /// [miniAppIconOpacity] 小程序图标的透明度，为了防止小程序页面上滑消失的时候，太快而发白的问题
  RxDouble miniAppIconOpacity = 1.0.obs;

  /// [isShowingApplet] 标志位，表示小程序是否正在展示
  RxBool isShowingApplet = false.obs;

  /// [isMiniAppletDraggingIcon] if user long press and drag the icon to delete
  RxBool isMiniAppletDraggingIcon = false.obs;

  /// [isBeingHovered] if dragged icon is hovered the drag target item
  RxBool isBeingHovered = false.obs;

  ///[isAddMiniAppIsBeingHovered] if add + dragged icon is hovered the drag target item
  RxBool isAddMiniAppIsBeingHovered = false.obs;

  /// [showListViewTopBar] 标志位，表示是否展示首页列表 顶部导航栏，这里有设计2个topBar 具体看它控制的代码
  /// 这里如果不设计2个，就没法实现主页面上拉过程，bar固定在顶部，下拉的过程，bar跟随主页面下移
  RxBool showListViewTopBar = false.obs;

  /// [showAppBarInAppBarPosition] 是否显示appbar位置的appbar
  RxBool showAppBarInAppBarPosition = true.obs;

  /// [mainListViewDuration] 记录主列表动画的持续时间，单位为毫秒，没有这个就会出现UI切换的时候页面跳动
  RxInt mainListViewDuration = 0.obs;

  /// [appletViewDuration] 记录小程序动画的持续时间，单位为毫秒，没有这个就会出现向下拉动，小程序页面没有紧随appbar往下走
  RxInt appletViewDuration = 0.obs;

  /// [stageDistance]  上拉下拉的4个临界值
  final double stageDistance1Scale = 0.5;

  /// [showFakeAppbarInMiniApp] 是否展示一个假的bar用于平滑动画
  RxBool showFakeAppbarInMiniApp = false.obs;

  /// 屏幕高度
  Rx<double> specialScreenHeight = 1.sh.obs;

  double get stage1Distance {
    return 144 * (isShowingApplet.value ? 1 : stageDistance1Scale);
  }

  double get stage2Distance {
    return 280 * (isShowingApplet.value ? 1 : stageDistance1Scale);
  }

  double get stage3Distance {
    return 418 * (isShowingApplet.value ? 1 : stageDistance1Scale);
  }

  double get stage4Distance {
    return 575 * (isShowingApplet.value ? 1 : stageDistance1Scale);
  }

  /// [kAppletAppBarHeight] 小程序漏出来的appbar的高度
  static double appletAppBarHeight = GetPlatform.isIOS ? (kTitleHeight + ScreenUtil().bottomBarHeight + 12) : (kTitleHeight + ScreenUtil().statusBarHeight);

  /// [isOriginalAppBar] false 就是一个新的appbar，和小程序中展示的一样
  Rx<bool> isOriginalAppBar = true.obs;

  /// [appletAppBarOpacity] 下拉出小程序的时候，appbar的内容是有透明度变化的，这个是用来控制透明度的
  Rx<double> appletAppBarOpacity = 1.0.obs;

  /// [mainListOpacity] 下拉出小程序的时候，列表页面的透明度变化
  Rx<double> mainListOpacity = 1.0.obs;

  /// [hasVibrated] 是否震动过,在一次下拉拖动过程中，只需要震动一次
  bool hasVibrated = false;

  /// 背景颜色的控制
  Rx<double> appletBackgroudAlpha = 0.0.obs;

  /// [hideBottomBar] 隐藏底部的tab
  Rx<bool> hideBottomBar = false.obs;

  Timer? _cooldownTimer;
  bool _pendingExecution = false;

  int currentChatCategoryIdx = 0;
  late TabController chatCategoryController;
  RxList<ChatCategory> chatCategoryList = <ChatCategory>[].obs;
  final RxMap<int, Set<int>> chatCategoryUnreadCount = <int, Set<int>>{}.obs;
  List<GlobalKey> chatCategoryKey = <GlobalKey>[];

  RxBool isChatCategoryEditing = false.obs;

  ChatCategory? currentEditCategory;
  OverlayEntry? floatWindowOverlay;
  final LayerLink layerLink = LayerLink();

  final List<ToolOptionModel> chatCategoryMenu = <ToolOptionModel>[
    ToolOptionModel(
      title: ChatCategoryMenuType.editChatCategory.title,
      optionType: ChatCategoryMenuType.editChatCategory.menuType,
      isShow: true,
      tabBelonging: 1,
      imageUrl: 'assets/svgs/home_new_chat.svg',
    ),
    ToolOptionModel(
      title: ChatCategoryMenuType.addChatRoom.title,
      optionType: ChatCategoryMenuType.addChatRoom.menuType,
      isShow: true,
      tabBelonging: 1,
      imageUrl: 'assets/svgs/menu_add.svg',
    ),
    ToolOptionModel(
      title: ChatCategoryMenuType.allRead.title,
      optionType: ChatCategoryMenuType.allRead.menuType,
      isShow: true,
      tabBelonging: 1,
      imageUrl: 'assets/svgs/chat_category_read_all_outlined.svg',
    ),
    ToolOptionModel(
      title: ChatCategoryMenuType.allMuted.title,
      optionType: ChatCategoryMenuType.allMuted.menuType,
      isShow: true,
      tabBelonging: 1,
      imageUrl: 'assets/svgs/chat_category_mute_outlined.svg',
    ),
    ToolOptionModel(
      title: ChatCategoryMenuType.deleteChatCategory.title,
      optionType: ChatCategoryMenuType.deleteChatCategory.menuType,
      isShow: true,
      tabBelonging: 1,
      imageUrl: 'assets/svgs/menu_bin.svg',
      color: colorRed,
      // largeDivider: true,
    ),
    // ToolOptionModel(
    //   title: ChatCategoryMenuType.reorderChatCategory.title,
    //   optionType: ChatCategoryMenuType.reorderChatCategory.menuType,
    //   isShow: true,
    //   tabBelonging: 1,
    //   imageUrl: 'assets/svgs/chat_category_reorder_outlined.svg',
    // ),
  ];

  // 最大置顶值
  static int maxChatSort = 0;

  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();

  // 编辑聊天列表
  RxBool isEditing = false.obs;
  RxBool isSelectMore = true.obs;
  final selectedChatIDForEdit = <int>[].obs;

  // 搜索模块
  final searchDebouncer = Debounce(const Duration(seconds: 1));
  RxBool isSearching = false.obs;
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  RxString searchParam = ''.obs;
  TabController? searchTabController;

  // 搜索开启时的置顶状态栏
  RxBool isPin = false.obs;
  RxBool isShowLabel = true.obs;
  bool touchUpDown = false;
  bool isShowSearch = false;
  RxBool isTyping = false.obs;

  //搜索到的信息列表
  Lock searchMsgLock = Lock();
  RxList<Message> messageList = RxList();

  // 桌面端 变量
  final desktopSelectedChatID = 01010.obs;
  Offset mousePosition = const Offset(0, 0);
  final selectedCellIndex = (-1).obs;

  /// 悬浮小窗参数
  Widget? overlayChild;
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;
  GlobalKey moreVertKey = GlobalKey();
  GlobalKey notificationKey = GlobalKey();
  final List<ToolOptionModel> menuOptions = [
    ToolOptionModel(
      title: localized(createChat),
      optionType: HomePageMenu.createChat.optionType,
      isShow: true,
      tabBelonging: 6,
      imageUrl: 'assets/svgs/create_chat.svg',
    ),
    ToolOptionModel(
      title: localized(addFriendTitle),
      optionType: HomePageMenu.addFriend.optionType,
      isShow: true,
      tabBelonging: 6,
      imageUrl: 'assets/svgs/add_new_friend_icon.svg',
    ),
    ToolOptionModel(
      title: localized(scanTitle),
      optionType: HomePageMenu.scan.optionType,
      isShow: true,
      tabBelonging: 6,
      imageUrl: 'assets/svgs/home_scan.svg',
    ),
    ToolOptionModel(
      title: localized(scanPaymentQr),
      optionType: HomePageMenu.scanPaymentQr.optionType,
      isShow: false,
      tabBelonging: 6,
      imageUrl: 'assets/svgs/wallet_scan.svg',
    ),
  ];

  /// METHODS
  @override
  void onInit() async {
    super.onInit();
    chatCategoryController = TabController(
      length: objectMgr.chatMgr.chatCategoryList.length <= 1
          ? 0
          : objectMgr.chatMgr.chatCategoryList.length,
      vsync: this,
    );

    searchTabController = TabController(
      length: SearchTab.values.length,
      vsync: this,
    );

    resetChatCategoryList();

    await objectMgr.chatMgr.loadLocalLastMessages();
    Future.wait(<Future<dynamic>>[
      loadChatList(),
      showSkeletonTask(),
    ]);

    // 新增聊天室事件
    objectMgr.chatMgr.on(ChatMgr.eventChatJoined, _onChatJoined);

    // 聊天室移除事件
    objectMgr.sharedRemoteDB
        .on("$blockOptDelete:${DBChat.tableName}", _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventChatHide, _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventChatDelete, _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onChatDeleted);

    // 群语音
    objectMgr.chatMgr.on(ChatMgr.eventAudioChat, _onAudioChat);

    objectMgr.chatMgr
        .on(ChatMgr.eventChatLastMessageChanged, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    objectMgr.chatMgr
        .on(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr.on(ChatMgr.eventAddMentionChange, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventDelMentionChange, _onRefreshChatList);
    objectMgr.chatMgr
        .on(ChatMgr.eventChatCategoryLoaded, _onChatCategoryLoaded);
    objectMgr.chatMgr
        .on(ChatMgr.eventChatCategoryChanged, _onChatCategoryLoaded);
    objectMgr.chatMgr
        .on(ChatMgr.eventUpdateUnread, _onChatCategoryUnreadChange);

    // 聊天室置顶改变事件
    chatListEvent.on(ChatListEvent.eventChatPinnedUpdate, onChatPinnedUpdate);
    chatListEvent.on(ChatListEvent.eventChatEditSelect, _onChatEditSelect);

    objectMgr.myGroupMgr.on(MyGroupMgr.eventTmpGroup, _onRefreshChatList);

    objectMgr.chatMgr.handleShareData();
  }

  /// 这里是更新首页聊天列表的offset
  void updateOffset(double value) {
    offset.value = value;
    showFakeAppbarInMiniApp.value = offset.value == (screenHeight() - ChatListController.appletAppBarHeight);
  }

  /// 设置小程序页面是否在拖动
  void setIsMiniAppletDraggingIcon(bool value) {
    isMiniAppletDraggingIcon.value = value;
    if (isShowingApplet.value) {
      updateOffset(value ? screenHeight() : screenHeight() - appletAppBarHeight);
    }
  }


  /// 回到首页
  void backToMainPageByAnimation({double stepSize = 20}) {
    isBackingToMainPage = true;

    double barOffset = appletBottomOffset.value; // 当前值
    double targetOffset = 1.sh - 108; // 目标值
    int interval = 10;  // 每步间隔时间 10 毫秒

    // 判断移动方向（正向或负向）
    bool isIncreasing = targetOffset > barOffset;

    double devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    stepSize = stepSize * devicePixelRatio;

    Timer.periodic(Duration(milliseconds: interval), (timer) {
      // 更新 barOffset
      if (isIncreasing) {
        barOffset += stepSize;
        if (barOffset >= targetOffset) {
          barOffset = targetOffset; // 确保最终值
          timer.cancel(); // 停止计时器
          isBackingToMainPage = false; // 动画结束
          backToMainPageState(); // 动画完成后的逻辑处理
        }
      } else {
        barOffset -= stepSize;
        if (barOffset <= targetOffset) {
          barOffset = targetOffset; // 确保最终值
          timer.cancel(); // 停止计时器
          isBackingToMainPage = false; // 动画结束
          backToMainPageState(); // 动画完成后的逻辑处理
        }
      }

      onAppletScroll(barOffset); // 更新UI
    });
  }

  void backToMainPageState() {
    // 先保留这个逻辑
    // mainListViewDuration.value = 300;
    // appletViewDuration.value = 300;
    mainListViewDuration.value = 0;
    appletViewDuration.value = 0;
    appletBackgroudAlpha.value = 0.0;

    /// 小程序上拉 回到主页面
    isShowingApplet.value = false;
    updateOffset(0);
    appletBottomOffset.value = screenHeight();
    // Future.delayed(const Duration(milliseconds: 300))
    //     .then((value) => mainListViewDuration.value = 0);
    // Future.delayed(const Duration(milliseconds: 300))
    //     .then((value) => appletViewDuration.value = 0);
    hideBottomBar.value = false;
    showAppBarInAppBarPosition.value = true;
    showListViewTopBar.value = false;
    appletBackgroudAlpha.value = 0.0;

    appletAppBarOpacity.value = 1;
    isOriginalAppBar.value = true;
    mainListOpacity.value = 1;

    setIsMiniAppletDraggingIcon(false);
    setStatusBarStyleInIOS(false);
  }

  /// 去到小程序
  void backToMiniAppPageByAnimation({double stepSize = 20}) {
    isBackingToMiniAppPage = true;

    double barOffset = offset.value; // 当前值
    double targetOffset = 1.sh - 200; // 目标值
    int interval = 5;  // 每步间隔时间 5 毫秒
    // 判断移动方向（正向或负向）
    bool isIncreasing = targetOffset > barOffset;
    double devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    stepSize = stepSize * devicePixelRatio;

    Timer.periodic(Duration(milliseconds: interval), (timer) {
      // 更新 barOffset
      if (isIncreasing) {
        barOffset += stepSize;
        if (barOffset >= targetOffset) {
          barOffset = targetOffset; // 确保最终值
          timer.cancel(); // 停止计时器
          isBackingToMiniAppPage = false; // 动画结束
          backToMiniAppPageState(); // 动画完成后的逻辑处理
        }
      } else {
        barOffset -= stepSize;
        if (barOffset <= targetOffset) {
          barOffset = targetOffset; // 确保最终值
          timer.cancel(); // 停止计时器
          isBackingToMiniAppPage = false; // 动画结束
          backToMiniAppPageState(); // 动画完成后的逻辑处理
        }
      }

      if (barOffset > 500) {
        hideBottomBar.value = true;
      }
      onScroll(barOffset, fromTimer: true); // 更新UI

    });
  }

  void backToMiniAppPageState() {
    Get.put(PullDownAppletController());

    ///  mainListViewDuration 作用，停止的时候需要有个300的动画，这样在小程序和主页面的切换是有动画的
    ///  这里动画一旦结束，就需要设置为0，因为在拖动的时候，如果还是动画效果，就会出现页面跳动的现象
    mainListViewDuration.value = 300;
    appletViewDuration.value = 300;
    appletBackgroudAlpha.value = 1;
    isShowingApplet.value = true;
    updateOffset(screenHeight() - appletAppBarHeight);
    appletBottomOffset.value = 0;
    Future.delayed(const Duration(milliseconds: 300))
        .then((value) => mainListViewDuration.value = 0);
    Future.delayed(const Duration(milliseconds: 300))
        .then((value) => appletViewDuration.value = 0);
    hideBottomBar.value = true;

    appletAppBarOpacity.value = 1;
    isOriginalAppBar.value = false;
    mainListOpacity.value = 0;
    setStatusBarStyleInIOS(true,milliseconds: 400);
    miniAppIconOpacity.value = 1;
  }

  ///在iOS中设置顶部状态栏
  static void setStatusBarStyleInIOS(bool light, {int milliseconds = 100}) {
    if (Platform.isIOS) {
      Future.delayed(Duration(milliseconds: milliseconds)).then((value) {
        const generalChannel = 'jxim/general';
        const methodChannel = MethodChannel(generalChannel);
        methodChannel.invokeMethod('setStatusBarStyle',light);
      });
    }
  }

  /// 小程序页面底部的bar的高度，在小程序上拉过程，需要慢慢的调整高度，从而实现设计的需求
  double appbarAdjustHeight() {
    // 定义常量，方便修改
    const double minValue = 30;       // 最小边界值
    const double maxValue = 170;      // 最大边界值
    const double minOutput = 0;      // 输出最小值
    const double maxOutput = 12;     // 输出最大值

    double value = appletBottomOffset.value;

    if (value <= minValue) {
      return minOutput; // 小于等于最小值时返回最小输出值
    } else if (value >= maxValue) {
      return maxOutput; // 大于等于最大值时返回最大输出值
    } else {
      // 线性映射，将 [minValue, maxValue] 映射到 [minOutput, maxOutput]
      return (value - minValue) * ((maxOutput - minOutput) / (maxValue - minValue));
    }
  }

  /// 获取屏幕高度当有小程序的时候，这个高度会少点
  double screenHeight() {
    return 1.sh - ((scStatus.value == SpecialContainerStatus.min.index) ? kSheetHeightMin : 0);
  }

  /// 主页面停止滚动
  void mainPageScrollEnd() {
    // miniAppBottomOffset == 0 如果不等于0 代表是滑动小程序页面底部的那个bar回掉的
    if (miniAppBottomOffset > 0) {
      return;
    }
    /// 如果是搜索页面就不需要
    if (isSearching.value) {
      return;
    }
    if (offset.value > stage1Distance) {
      /// 主页面下拉 拉出小程序
      backToMiniAppPageByAnimation();
    }
  }

  /// 小程序页面停止滚动
  void onAppletScrollEnd({double offset = 0, bool fromDragAppbar = false, double barOffset = 0}) {
    if (fromDragAppbar) {
      if (appletBottomOffset.value > stage1Distance) {
        backToMainPageByAnimation();
        Get.delete<PullDownAppletController>();
      } else if (fromDragAppbar) {
        if (barOffset > 0) {
          const int steps = 10; // 总步数
          const int duration = 200; // 总时间（毫秒）
          const double stepSize = 100 / steps; // 每次减少的值
          const int interval = duration ~/ steps; // 每步时间间隔
          int count = 0; // 记录执行次数
          Timer.periodic(const Duration(milliseconds: interval), (timer) {
            barOffset -= stepSize; // 逐步减少 barOffset
            onAppletScroll(barOffset); // 调用方法更新偏移量
            count++;
            if (count >= steps) {
              timer.cancel(); // 达到步数后停止计时器
              barOffset = 0; // 确保最终值为 0
              onAppletScroll(barOffset); // 确保最后一次更新到位
            }
          });
        }
      }
    } else {
      if (offset > stage1Distance * 0.68) {
        backToMainPageByAnimation();
        Get.delete<PullDownAppletController>();
      }
    }
  }

  /// 处理不同阶段UI的变化
  void handleStageAnimation() {
    if (offset.value < stage1Distance) {
      appletBackgroudAlpha.value = 0;
      mainListOpacity.value = 1;
      appletAppBarOpacity.value = 1;
      isOriginalAppBar.value = true;
    } else if (offset.value >= stage1Distance &&
        offset.value <= stage4Distance) {
      // print('1~4');
      final double alpha = 0.5 +
          (offset.value - stage1Distance) / (stage4Distance - stage1Distance);
      appletBackgroudAlpha.value = alpha > 1 ? 1 : (alpha < 0 ? 0 : alpha);
      mainListOpacity.value = 1;
      appletAppBarOpacity.value = 1;
      isOriginalAppBar.value = true;
      if (offset.value >= stage1Distance && offset.value < stage2Distance) {
        // print('1~2');
      } else if (offset.value >= stage2Distance &&
          offset.value <= stage3Distance) {
        // print('2-3');
        final double alpha = 0.5 -
            (0.5 * (offset.value - stage2Distance) / (stage3Distance - stage2Distance));
        appletAppBarOpacity.value = alpha > 1 ? 1 : (alpha < 0 ? 0 : alpha);
        final double listAlpha = 0.8 -
            0.5 *
                (offset.value - stage2Distance) /
                (stage3Distance - stage2Distance);
        mainListOpacity.value =
        listAlpha > 1 ? 1 : (listAlpha < 0 ? 0 : listAlpha);
      } else if (offset.value >= stage3Distance) {
        // print('3~4');
        final double alpha =
            (offset.value - stage3Distance) / (stage4Distance - stage3Distance);
        appletAppBarOpacity.value = alpha > 1 ? 1 : (alpha < 0 ? 0 : alpha);
        isOriginalAppBar.value = false;
        final double listAlpha = 0.3 -
            0.25 *
                (offset.value - stage3Distance) /
                (stage4Distance - stage3Distance);
        mainListOpacity.value =
        listAlpha > 1 ? 1 : (listAlpha < 0 ? 0 : listAlpha);
      }
    } else if (offset.value > stage4Distance) {
      // print("4~");
      appletBackgroudAlpha.value = 1;
      appletAppBarOpacity.value = 1;
      mainListOpacity.value = 0.2;
      isOriginalAppBar.value = false;
    }
  }

  /// 小程序页面开始滚动
  void onAppletScroll(double offset) {
    /// 往上拉的距离，正就是往上拉，负就是往下拉
    final pullUpOffset = offset;
    if (pullUpOffset == 0) {
      setStatusBarStyleInIOS(true);
    }

    // 定义起点和终点
    double startOffset = 200; // 起始位置
    double endOffset = 500;   // 结束位置
    double startOpacity = 1;  // 起始透明度
    double endOpacity = 0.2;  // 结束透明度

    // 根据范围线性插值计算透明度
    if (pullUpOffset <= startOffset) {
      miniAppIconOpacity.value = startOpacity; // 小于起点保持初始值
    } else if (pullUpOffset >= endOffset) {
      miniAppIconOpacity.value = endOpacity;  // 超过终点保持最终值
    } else {
      // 线性插值计算透明度
      double progress = (pullUpOffset - startOffset) / (endOffset - startOffset);
      miniAppIconOpacity.value = startOpacity + (endOpacity - startOpacity) * progress;
    }

    if (pullUpOffset >= 0) {
      /// 上拉
      appletBottomOffset.value = pullUpOffset;
    } else {
      /// 下拉
      appletBottomOffset.value = 0;
    }
    if (isShowingApplet.value && appletBottomOffset.value >= 0) {
      /// 这个才是上滑动，小程序下拉不需要处理，不然页面会出问题的
      double offsetTemp = screenHeight() - appletBottomOffset.value - appletAppBarHeight;
      if (offsetTemp >= 0) {
        updateOffset(offsetTemp);
      } else {
        updateOffset(0);
      }
      handleStageAnimation();
    }
  }

  /// 主页面开始滚动
  void onScroll(double offsetOutside,{bool fromTimer = false}) async {
    if (!isSearching.value && !isShowingApplet.value && isShowMiniApp) {
      /// 不是搜索页面才处理小程序逻辑 && 当前展示的不是小程序才需要处理这个逻辑
      updateOffset(offsetOutside);
      appletBottomOffset.value = screenHeight() - offset.value;

      if (offsetOutside <= 0) {
        /// 上拉
        showListViewTopBar.value = false;
        showAppBarInAppBarPosition.value = true;
      } else {
        /// 下拉
        showListViewTopBar.value = true;
        showAppBarInAppBarPosition.value = false;
      }

      /// 达到临界值，如果此次拖动没有震动过，就需要震动一次
      if (offset.value >= stage1Distance && !hasVibrated && !fromTimer) {
        hasVibrated = true;
        HapticFeedback.heavyImpact();
      }

      if (offset.value < 0) {
        /// 这个offset 不能为负值，不然会报错，可以试试注释这下面这行，然后在首页上拉
        updateOffset(0);
      }
      handleStageAnimation();
    }

    /// close keyboard when start scroll
    if (isSearching.value) {
      if (!isPin.value) {
        isPin.value = true;
      }
    } else {
      isPin.value = false;
    }

    if (isSearching.value) {
      return;
    }

    var offsetY = scrollController.offset;

    if (touchUpDown) {
      if (kSearchHeight.value <= kSearchHeightMax * 0.5) {
        kSearchHeight.value = 0;
      } else {
        kSearchHeight.value = kSearchHeightMax;
      }
      if (kSearchHeight.value == kSearchHeightMax) {
        isShowSearch = true;
        return;
      } else {
        isShowSearch = false;
      }
    }

    if (offsetY <= -kSearchHeightMax - 30 && offsetY >= kSearchHeightMax + 30) {
      return;
    }

    if (offsetY <= 0) {
      if (isShowSearch) {
        if (offsetY <= 0) {
          kSearchHeight.value = kSearchHeightMax;
        }
      } else {
        if (offsetY >= -kSearchHeightMax) {
          kSearchHeight.value = -offsetY;
        } else {
          kSearchHeight.value = kSearchHeightMax;
        }
      }
    } else {
      if (isShowSearch) {
        var height = kSearchHeightMax - offsetY;
        if (height <= 0) {
          kSearchHeight.value = 0.0;
        } else {
          kSearchHeight.value = height;
        }
      } else {
        if (offsetY >= 0) {
          kSearchHeight.value = 0.0;
        }
      }
    }
  }

  void _onRefreshChatList(Object? sender, Object? type, Object? data) {
    if (_cooldownTimer?.isActive ?? false) {
      _pendingExecution = true;
      return;
    }
    _executeRefresh();
  }

  void _executeRefresh() {
    loadChatList();

    _cooldownTimer = Timer(const Duration(seconds: 1), () {
      if (_pendingExecution) {
        _pendingExecution = false;
        _executeRefresh();
      }
    });
  }

  void _onLastMessageLoaded(_, __, ___) async {
    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    if (chats.isNotEmpty) {
      objectMgr.chatMgr.sortChatList(chats);
      chatList.assignAll(chats);
      objectMgr.shareMgr.syncChatList(chats);
      update();
    }
  }

  void _onChatJoined(p0, p1, p2) {
    if (p2 is Chat) {
      if (chatCategoryList.isNotEmpty && currentChatCategoryIdx != 0) return;
      final index = chatList.indexWhere((chat) => chat.id == p2.chat_id);
      if (index == -1) {
        if (p2.delete_time > 0) {
          Group? group = objectMgr.myGroupMgr.getGroupById(p2.id);
          if (group?.roomType == GroupType.TMP.num) {
            objectMgr.chatMgr.doTmpGroupReJoin(p2);

            chatList.add(p2);
            objectMgr.chatMgr.sortChatList(chatList);
          }
        } else if (p2.isVisible) {
          chatList.add(p2);
          objectMgr.chatMgr.sortChatList(chatList);
        }
      }
    }
  }

  Future<void> _onChatDeleted(Object sender, __, Object? deletedChat) async {
    if (deletedChat != null && deletedChat is Chat) {
      if (!deletedChat.isVisible) {
        final removeIdx = chatList
            .indexWhere((element) => element.chat_id == deletedChat.chat_id);
        if (removeIdx != -1) {
          allChats
              .removeWhere((element) => element.chat_id == deletedChat.chat_id);
          chatList.removeAt(removeIdx);

          if (!mapEquals(chatCategoryUnreadCount,
              objectMgr.chatMgr.chatCategoryUnreadCount)) {
            chatCategoryUnreadCount
                .assignAll(objectMgr.chatMgr.chatCategoryUnreadCount);
            update(['chat_category']);
          }
        }
      } else {
        loadChatList();
      }
    } else if (deletedChat is int) {
      final removeIdx =
          chatList.indexWhere((element) => element.chat_id == deletedChat);
      if (removeIdx != -1) {
        allChats.removeWhere((element) => element.chat_id == deletedChat);
        chatList.removeAt(removeIdx);

        if (!mapEquals(chatCategoryUnreadCount,
            objectMgr.chatMgr.chatCategoryUnreadCount)) {
          chatCategoryUnreadCount
              .assignAll(objectMgr.chatMgr.chatCategoryUnreadCount);
          update(['chat_category']);
        }
      }
    }
  }

  void onChatPinnedUpdate(_, __, Object? data) {
    if (data == null || data is! Map) return;

    final chatId = data['chat_id'];
    final sort = data['sort'];

    final chat = chatList.firstWhereOrNull((element) => element.id == chatId);
    if (chat != null) {
      chat.updateValue({'sort': sort});
      objectMgr.chatMgr.sortChatList(chatList);
    }
  }

  void _onAudioChat(_, __, Object? msg) {
    if (msg is! Message) return;
    final chat = objectMgr.chatMgr.getChatById(msg.chat_id);
    if (msg.typ == messageTypeAudioChatOpen) {
      chat?.enableAudioChat.value = true;
    } else {
      chat?.enableAudioChat.value = false;
    }
  }

  void _onChatEditSelect(_, __, Object? data) {
    if (data is! Chat) return;

    isEditing.value = true;
    if (selectedChatIDForEdit.contains(data.id)) {
      selectedChatIDForEdit.remove(data.id);
    } else {
      selectedChatIDForEdit.add(data.id);
    }
  }

  void _onChatCategoryLoaded(_, __, ___) {
    if (objectMgr.chatMgr.chatCategoryList.length !=
        chatCategoryController.length) {
      if (currentChatCategoryIdx == chatCategoryController.length - 1) {
        chatCategoryController.index = 0;
        currentChatCategoryIdx = 0;
      }

      // App initialize changed
      chatCategoryController.dispose();
      chatCategoryController = TabController(
        length: objectMgr.chatMgr.chatCategoryList.length <= 1
            ? 0
            : objectMgr.chatMgr.chatCategoryList.length,
        initialIndex: currentChatCategoryIdx,
        vsync: this,
      );

      // todo: update UI
    }

    resetChatCategoryList();
  }

  void _onChatCategoryUnreadChange(_, __, ___) {
    if (!mapEquals(
        chatCategoryUnreadCount, objectMgr.chatMgr.chatCategoryUnreadCount)) {
      chatCategoryUnreadCount
          .assignAll(objectMgr.chatMgr.chatCategoryUnreadCount);
      update(['chat_category']);
    }
  }

  @override
  void onClose() {
    objectMgr.chatMgr.off(ChatMgr.eventChatJoined, _onChatJoined);

    objectMgr.sharedRemoteDB
        .off("$blockOptDelete:${DBChat.tableName}", _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventChatHide, _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventChatDelete, _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onChatDeleted);

    objectMgr.chatMgr.off(ChatMgr.eventAudioChat, _onAudioChat);

    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventAddMentionChange, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventDelMentionChange, _onRefreshChatList);
    objectMgr.chatMgr
        .off(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr
        .off(ChatMgr.eventChatCategoryLoaded, _onChatCategoryLoaded);
    objectMgr.chatMgr
        .off(ChatMgr.eventChatCategoryChanged, _onChatCategoryLoaded);
    objectMgr.chatMgr
        .off(ChatMgr.eventUpdateUnread, _onChatCategoryUnreadChange);

    chatListEvent.off(ChatListEvent.eventChatPinnedUpdate, onChatPinnedUpdate);
    chatListEvent.off(ChatListEvent.eventChatEditSelect, _onChatEditSelect);
    objectMgr.myGroupMgr.off(MyGroupMgr.eventTmpGroup, _onRefreshChatList);

    searchTabController?.dispose();
    searchFocus.dispose();
    chatListEvent.clear();
    scrollController.dispose();

    super.onClose();
  }

  // ================================ 业务逻辑 ==================================
  loadChatList() async {
    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    objectMgr.miniAppMgr.checkChats(chats);
    if (chats.isEmpty) {
      allChats.clear();
      chatList.clear();
      return;
    }

    List olds = allChats.map((e) => e.msg_idx).toList();
    objectMgr.chatMgr.sortChatList(chats);
    List news = chats.map((e) => e.msg_idx).toList();
    bool isSameList = listEquals(olds, news);
    if (isSameList && chatList.isNotEmpty) {
      return;
    }
    allChats.assignAll(chats);
    final List<Chat> encryptedChats = [];

    for (var chat in allChats) {
      if (chat.sort > maxChatSort) {
        maxChatSort = chat.sort;
      }

      if (notBlank(objectMgr.encryptionMgr.encryptionPrivateKey) &&
          chat.isVisible &&
          chat.hasPreviousEncryption &&
          !notBlank(chat.chat_key)) {
        if (!objectMgr.encryptionMgr.reqSignChatList.keys
            .contains(chat.chat_id)) {
          encryptedChats.add(chat);
        } else {
          int round = objectMgr.encryptionMgr.reqSignChatList[chat.chat_id]!;
          if (round < chat.round) {
            encryptedChats.add(chat);
          }
        }
        encryptedChats.add(chat);
      }

      if (chat.icon.isNotEmpty && chat.iconGaussian.isNotEmpty) {
        await imageMgr.genBlurHashImage(chat.iconGaussian, chat.icon);
      }
    }

    _triggerChatKeyRetrievalFutures(encryptedChats);

    if (objectMgr.chatMgr.chatCategoryList.length != chatCategoryList.length) {
      if (currentChatCategoryIdx == chatCategoryController.length - 1) {
        chatCategoryController.index = 0;
        currentChatCategoryIdx = 0;
      }

      // App initialize changed
      chatCategoryController.dispose();
      chatCategoryController = TabController(
        length: objectMgr.chatMgr.chatCategoryList.length <= 1
            ? 0
            : objectMgr.chatMgr.chatCategoryList.length,
        initialIndex: currentChatCategoryIdx,
        vsync: this,
      );

      resetChatCategoryList();
    }

    if (!mapEquals(
        chatCategoryUnreadCount, objectMgr.chatMgr.chatCategoryUnreadCount)) {
      chatCategoryUnreadCount
          .assignAll(objectMgr.chatMgr.chatCategoryUnreadCount);
      update(['chat_category']);
    }

    if (chatCategoryList.isEmpty ||
        (chatList.isEmpty && currentChatCategoryIdx == 0)) {
      List olds = chatList.map((e) => e.msg_idx).toList();
      objectMgr.chatMgr.sortChatList(chats);
      List news = chats.map((e) => e.msg_idx).toList();
      if (!listEquals(olds, news)) {
        chatList.assignAll(chats);

        objectMgr.shareMgr.syncChatList(allChats);
      }
    }

    if (chatCategoryList.isNotEmpty) {
      if (!isSameList ||
          chatCategoryList[currentChatCategoryIdx].includedChatIds.length !=
              chatList.length) {
        bool hasChanged = false;
        for (int i = 0; i < chats.length; i++) {
          final newChat = chats[i];

          final foundIdx = chatList.indexWhere((c) => c.id == newChat.id);

          if (foundIdx == i && chatList[foundIdx].msg_idx == newChat.msg_idx) {
            continue;
          }

          if (foundIdx != -1) {
            chatList[foundIdx] = newChat;
          } else {
            final foundChat = chatCategoryList[currentChatCategoryIdx]
                .includedChatIds
                .indexWhere((c) => c == newChat.id);
            if (foundChat != -1 || currentChatCategoryIdx == 0) {
              chatList.add(newChat);
            }
          }

          hasChanged = true;
        }

        if (hasChanged) objectMgr.chatMgr.sortChatList(chatList);
      }
    }

    sw.stop();
    if (sw.elapsedMilliseconds > 50) {
      Future.delayed(
        Duration(milliseconds: max(1500 - sw.elapsedMilliseconds, 0)),
        () {
          isInitializing.value = false;
          isShowSkeleton.value = false;
        },
      );
    } else {
      isInitializing.value = false;
      isShowSkeleton.value = false;
    }

    if (objectMgr.pushMgr.initMessage != null) {
      objectMgr.pushMgr.notificationRouting(objectMgr.pushMgr.initMessage!);
    }
  }

  void _triggerChatKeyRetrievalFutures(List<Chat> encryptedChats) async {
    if (!notBlank(objectMgr.encryptionMgr.encryptionPublicKey)) return;
    if (objectMgr.encryptionMgr.isCheckingCipherKeys) return;
    if (encryptedChats.isEmpty) return;

    objectMgr.encryptionMgr.isCheckingCipherKeys = true;
    await objectMgr.encryptionMgr.checkAndUpdateChatCiphers(encryptedChats);
    //objectMgr.encryptionMgr.isCheckingCipherKeys = false;
  }

  void onItemClick(int index) {
    Chat chat = chatList[index];
    Routes.toChat(chat: chat);
  }

  void onChatEditTap() {
    isEditing.value = !isEditing.value;
    chatListEvent.event(
      chatListEvent,
      ChatListEvent.eventMultiSelectStateChange,
      data: isEditing.value,
    );
    if (isEditing.value == false) {
      clearSelectedChatForEdit();
    }
    clearSearching();
  }

  // 隐藏聊天室
  Future<void> hideChat(BuildContext context, Chat? chat) async {
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText:
          localized(hide1Chat, params: ['${selectedChatIDForEdit.length}']),
      onConfirmListener: () {
        isSelectMore.value = false;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );

        for (var chatId in selectedChatIDForEdit) {
          Chat? chat =
              chatList.firstWhereOrNull((element) => element.chat_id == chatId);
          if (chat != null) {
            objectMgr.chatMgr.setChatHide(chat);
          }
        }
        isEditing.value = false;

        imBottomToast(
          context,
          title: localized(
            hide1Chat,
            params: ['${selectedChatIDForEdit.length}'],
          ),
          icon: ImBottomNotifType.INFORMATION,
        );

        clearSelectedChatForEdit();
        isSelectMore.value = true;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );
        Get.back();
      },
    );
  }

  // 删除聊天室
  Future<void> onDeleteChat(BuildContext context, Chat? chat) async {
    BotToast.removeAll(BotToast.textKey);

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText: localized(
        deleteParamChat,
        params: ['${selectedChatIDForEdit.length}'],
      ),
      onConfirmListener: () {
        isSelectMore.value = false;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );

        for (var chatId in selectedChatIDForEdit) {
          Chat? chat =
              chatList.firstWhereOrNull((element) => element.chat_id == chatId);
          if (chat != null) {
            objectMgr.chatMgr.onChatDelete(chat);
          }
        }
        isEditing.value = false;
        imBottomToast(
          context,
          title: localized(
            alrdDeleteParamChat,
            params: ['${selectedChatIDForEdit.length}'],
          ),
          icon: ImBottomNotifType.delete,
        );

        clearSelectedChatForEdit();
        isSelectMore.value = true;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );
        Get.back();
      },
    );
  }

  /// 聊天置顶
  void onPinnedChat(BuildContext context, Chat chat) async {
    final isTop = chat.sort == 0;
    final sort = isTop ? ChatListController.maxChatSort + 1 : 0;

    try {
      await objectMgr.chatMgr.setChatTop(chat, sort);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  Future<void> scanQRCode({
    Function(String)? didGetText,
    bool isWallet = false,
  }) async {
    popUpMenuController.hideMenu();
    FocusManager.instance.primaryFocus?.unfocus();

    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;

    Get.toNamed(RouteName.qrCodeScanner, arguments: {'didGetText': didGetText});
  }

  void resetChatCategoryList() {
    chatCategoryList.assignAll(objectMgr.chatMgr.chatCategoryList);
    chatCategoryList.sort((a, b) => a.isAllChatRoom ? -999 : a.seq - b.seq);
    chatCategoryKey.assignAll(
      List.generate(chatCategoryList.length, (_) => GlobalKey()),
    );

    // 不是第一个tab的时候才需要重置 chatList
    if (currentChatCategoryIdx != 0 &&
        chatCategoryList.isNotEmpty &&
        chatCategoryList[currentChatCategoryIdx].includedChatIds.length !=
            chatList.length) {
      chatList.clear();
      for (final newChat in allChats) {
        final foundChat = chatCategoryList[currentChatCategoryIdx]
            .includedChatIds
            .indexWhere((c) => c == newChat.id);
        if (foundChat != -1) chatList.add(newChat);
      }
    }

    if (currentChatCategoryIdx == 0 &&
        chatCategoryList.isNotEmpty &&
        chatCategoryList.first.isAllChatRoom) {
      chatList.clear();
      chatList.assignAll(allChats);
      objectMgr.chatMgr.sortChatList(chatList);
    }

    chatCategoryUnreadCount.assignAll(
      objectMgr.chatMgr.chatCategoryUnreadCount,
    );
  }

  void onChatCategoryTabChange(int index) {
    currentChatCategoryIdx = index;
    double jumpToValue = 0.0;
    if (searchParam.isNotEmpty) {
      scrollController.jumpTo(jumpToValue);
      return;
    }

    if (index == 0) {
      objectMgr.chatMgr.sortChatList(allChats);
      chatList.assignAll(allChats);
      scrollController.jumpTo(jumpToValue);
      return;
    }

    List<Chat> tempList = allChats
        .where(
          (c) => chatCategoryList[index].includedChatIds.contains(c.chat_id),
        )
        .toList();
    objectMgr.chatMgr.sortChatList(tempList);
    chatList.assignAll(tempList);

    scrollController.jumpTo(jumpToValue);
  }

  void onChatCategoryLongPress(
    BuildContext context,
    int index,
    ChatCategory category,
  ) {
    if (category.isAllChatRoom) return;
    HapticFeedback.mediumImpact();
    currentEditCategory = category;
    final GlobalKey key = getChatCategoryKey(index);

    assert(
      key.currentContext != null,
      'Chat category key on press must not be null',
    );

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;

    final boxPosition = renderBox.localToGlobal(Offset.zero);

    final Alignment targetAlignment;
    final Alignment followerAlignment;

    bool posCenter =
        (boxPosition.dx + 240.0 > ObjectMgr.screenMQ!.size.width) &&
            boxPosition.dx < ObjectMgr.screenMQ!.size.width * 0.60;
    if (posCenter) {
      targetAlignment = Alignment.bottomCenter;
      followerAlignment = Alignment.topCenter;
    } else if (boxPosition.dx > ObjectMgr.screenMQ!.size.width / 2) {
      targetAlignment = Alignment.bottomRight;
      followerAlignment = Alignment.topRight;
    } else {
      targetAlignment = Alignment.bottomLeft;
      followerAlignment = Alignment.topLeft;
    }

    floatWindowOverlay = createOverlayEntry(
      context,
      buildChatCategoryTab(context, category, isOverlay: true),
      buildChatCategoryMenu(context, category),
      layerLink,
      top: boxPosition.dy,
      left: boxPosition.dx,
      targetAnchor: targetAlignment,
      followerAnchor: followerAlignment,
      backgroundColor: colorTextPlaceholder,
      dismissibleCallback: () {
        currentEditCategory = null;
        floatWindowOverlay?.remove();
        floatWindowOverlay = null;
      },
    );
  }

  void toggleChatCategoryStatus(int _, bool value) {
    isChatCategoryEditing.value = value;
    chatCategoryController.index = currentChatCategoryIdx;
  }

  Widget buildChatCategoryTab(
    BuildContext context,
    ChatCategory category, {
    bool isOverlay = false,
  }) {
    Widget child = SizedBox(
      height: 48.0,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: isOverlay ? 0.0 : 8.0,
              bottom: isOverlay ? 0.0 : 8.0,
              left: isOverlay ? 0.0 : 12.0,
              right: isOverlay ? 0.0 : 12.0,
            ),
            child: ChatCategoryTabItem(
              category: category,
              controller: this,
              isOverlay: isOverlay,
            ),
          ),
          if (!category.isAllChatRoom &&
              !isOverlay &&
              isChatCategoryEditing.value)
            Positioned(
              top: 0.0,
              left: 0.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorDivider,
                ),
                padding: const EdgeInsets.all(2.0),
                child: SvgPicture.asset(
                  'assets/svgs/close_thick_outlined_icon.svg',
                  color: colorTextSecondary,
                  width: 10.0,
                  height: 10.0,
                ),
              ),
            ),
        ],
      ),
    );

    if (isOverlay) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: child,
      );
    }

    return child;
  }

  Widget buildChatCategoryMenu(BuildContext context, ChatCategory category) {
    final List<ToolOptionModel> tempList =
        List<ToolOptionModel>.from(chatCategoryMenu);
    final List<Chat> includedChat =
        allChats.where((c) => category.includedChatIds.contains(c.id)).toList();

    bool hasMute = true;
    for (final chat in includedChat) {
      if (!chat.isMute && chat.isValid) {
        hasMute = false;
        break;
      }
    }

    if (hasMute && includedChat.isNotEmpty) {
      final menuIdx = tempList.indexWhere((option) =>
          option.optionType == ChatCategoryMenuType.allMuted.menuType);
      if (menuIdx != -1) {
        tempList[menuIdx] = ToolOptionModel(
          title: ChatCategoryMenuType.allUnMuted.title,
          optionType: ChatCategoryMenuType.allUnMuted.menuType,
          isShow: true,
          tabBelonging: 1,
          imageUrl: 'assets/svgs/chat_category_unmute_outlined.svg',
        );
      }
    }

    return ChatCategorySubItem(
      chatCategoryMenu: tempList,
      onTapCallback: onChatCategorySubCallback,
    );
  }

  void onChatCategorySubCallback(ChatCategoryMenuType type) {
    assert(currentEditCategory != null,
        'To operate a callback, the chat category must not be null.');

    floatWindowOverlay?.remove();
    floatWindowOverlay = null;
    switch (type) {
      case ChatCategoryMenuType.editChatCategory:
        onEditChatCategory(Get.context!, currentEditCategory!);
        break;
      case ChatCategoryMenuType.addChatRoom:
        onEditChatCategoryChatList(Get.context!, currentEditCategory!);
        break;
      case ChatCategoryMenuType.allRead:
        onReadAllChatCategory(currentEditCategory!);
        break;
      case ChatCategoryMenuType.allMuted:
        onMuteAllChatCategory(
          Get.context!,
          currentEditCategory!,
          mute: true,
        );
        break;
      case ChatCategoryMenuType.allUnMuted:
        onMuteAllChatCategory(
          Get.context!,
          currentEditCategory!,
          mute: false,
        );
        break;
      case ChatCategoryMenuType.deleteChatCategory:
        onDeleteChatCategory(Get.context!, currentEditCategory!);
        break;
      case ChatCategoryMenuType.reorderChatCategory:
        break;
      default:
        break;
    }

    currentEditCategory = null;
  }

  GlobalKey getChatCategoryKey(int index) {
    if (chatCategoryKey.length < index) {
      int diff = chatCategoryList.length - index;
      chatCategoryKey.addAll(
        List.generate(diff, (_) => GlobalKey()),
      );
    }

    return chatCategoryKey[index];
  }

  void onEditChatCategory(BuildContext context, ChatCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Container(
        decoration: const BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ChatCategoryCreate(category: category),
      ),
    );
  }

  void onEditChatCategoryChatList(
    BuildContext context,
    ChatCategory category,
  ) async {
    List<Chat> includedChatList = [];
    includedChatList.addAll(allChats.where(
      (c) => category.includedChatIds.contains(c.chat_id),
    ));

    final selectedChatList = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Container(
        decoration: const BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ChatCategorySelection(
          isInclude: true,
          includedChatList: includedChatList,
          allChat: allChats,
        ),
      ),
    );

    if (selectedChatList is! List<Chat>) return;

    final List<int> includedChatIds =
        selectedChatList.map<int>((c) => c.id).toList();

    final List<int> unreadChatListIds = selectedChatList
        .where((c) => c.unread_count > 0)
        .map<int>((c) => c.id)
        .toList();

    // update chat category add chat list
    objectMgr.chatMgr.updateChatCategory(
      category.copyWith(includedChatIds: includedChatIds),
      unreadChatListIds: unreadChatListIds,
      isCategoryFound: true,
      updateRemote: true,
    );
  }

  void onReadAllChatCategory(ChatCategory category) {
    try {
      final List<Chat> includedChat = allChats
          .where((c) => category.includedChatIds.contains(c.id))
          .toList();

      for (final chat in includedChat) {
        objectMgr.chatMgr.updateUnread(chat, chat.msg_idx);
      }
    } catch (_) {
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
    }
  }

  void onMuteAllChatCategory(
    BuildContext context,
    ChatCategory category, {
    bool mute = true,
  }) async {
    try {
      final List<Chat> includedChat = allChats
          .where((c) => category.includedChatIds.contains(c.id))
          .toList();

      bool hasMute = true;
      for (final chat in includedChat) {
        hasMute = await objectMgr.chatMgr.onChatCategoryAllMute(
          chat,
          isMute: mute,
        );
      }

      // 静音API调用失败, 提前返回
      if (!hasMute) return;

      if (mute) {
        imBottomToast(
          context,
          title: localized(
            chatCategoryMuteAllSubTitle,
            params: [category.name],
          ),
          icon: ImBottomNotifType.mute,
        );
      } else {
        imBottomToast(
          context,
          title: localized(
            chatCategoryUnMuteAllSubTitle,
            params: [category.name],
          ),
          icon: ImBottomNotifType.unmute,
        );
      }
    } catch (_) {
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
    }
  }

  void onDeleteChatCategory(BuildContext context, ChatCategory category) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(chatCategoryDeleteHintTitle),
      confirmText: localized(buttonDelete),
      cancelText: localized(buttonCancel),
      cancelTextColor: themeColor,
      onConfirmListener: () => _confirmDeleteChatCategory(category),
      onCancelListener: Get.back,
    );
  }

  void _confirmDeleteChatCategory(ChatCategory category) {
    objectMgr.chatMgr.deleteChatCategory([category]);
  }

  void onChatCategoryReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = chatCategoryList.removeAt(oldIndex - 1);
    if (newIndex <= 1) {
      chatCategoryList.insert(1, item);
    } else {
      chatCategoryList.insert(newIndex - 1, item);
    }
  }

  /// =============================== 搜索模块 ==================================
  void onSearchChanged(String value) {
    searchParam.value = value;
    isTyping.value = true;
    searchDebouncer.call(() {
      isTyping.value = false;
    });
  }

  Future<List<Message>> searchDBMessages({
    required List<int> typeList,
    String? searchText,
    required int pageSize,
    required int pageNumber,
  }) async {
    List<Message> dataList = [];
    String sql = "(expire_time == 0 OR expire_time >= ?) AND ref_typ == 0";

    if (typeList.isNotEmpty) {
      sql += " AND typ IN (${typeList.join(',')})";
    }

    if (searchText != null) {
      sql += " AND content LIKE '%$searchText%'";
    }

    List<Map<String, dynamic>> rows = [];
    try {
      rows.addAll(
        await objectMgr.localDB.loadMessagesByWhereClause(
          sql,
          [DateTime.now().millisecondsSinceEpoch ~/ 1000],
          null,
          pageSize,
          (pageNumber - 1) * pageSize,
          tbname: 'message',
          orderBy: 'create_time',
        ),
      );
      dataList = mapMessageConversion(rows);
    } catch (e) {
      pdebug(e.toString());
    }
    return dataList;
  }

  Future<int> searchDBMessagesCount({
    required List<int> typeList,
  }) async {
    List<Message> dataList = [];
    String sql = "(expire_time == 0 OR expire_time >= ?) AND ref_typ == 0";

    if (typeList.isNotEmpty) {
      sql += " AND typ IN (${typeList.join(',')})";
    }

    List<Map<String, dynamic>> rows = [];
    try {
      rows.addAll(
        await objectMgr.localDB.loadMessagesByWhereClause(
          sql,
          [DateTime.now().millisecondsSinceEpoch ~/ 1000],
          null,
          null,
          null,
          tbname: 'message',
          orderBy: 'create_time',
        ),
      );
      dataList = mapMessageConversion(rows);
    } catch (e) {
      pdebug(e.toString());
    }
    return dataList.length;
  }

  ///转换信息的格式
  List<Message> mapMessageConversion(List<Map<String, dynamic>> messages) {
    return messages.map((e) {
      final msg = Message()..init(e);

      if (msg.message_id == 0) {
        final Chat? found =
            allChats.firstWhereOrNull((c) => c.id == msg.chat_id) ??
                objectMgr.chatMgr.getChatById(msg.chat_id);
        if (found != null) {
          switch (found.typ) {
            case chatTypeSingle:
              final User? user = objectMgr.userMgr.getUserById(msg.send_id);
              if (user == null ||
                  (user.relationship != Relationship.friend &&
                      user.relationship != Relationship.self)) {
                msg.sendState = MESSAGE_SEND_FAIL;
              }
              break;
          }
        }
      }
      return msg;
    }).toList();
  }

  Future<List<Chat>> processSearchChat() async {
    List<Chat> visibleChats = [];
    List<Chat> chats = objectMgr.chatMgr.getAllChats(needProcess: false);

    for (var chat in chats) {
      if (!chat.isVisible) {
        if (chat.isSingle) {
          User? user = await objectMgr.userMgr.loadUserById(chat.friend_id);
          if (user?.relationship != Relationship.friend) {
            continue;
          }
        }
      }
      //过滤被删除的临时群组

      if ((chat.flag_my == ChatStatus.MyChatFlagDisband.value ||
              chat.flag_my == ChatStatus.MyChatFlagKicked.value) &&
          chat.isTmpGroup) {
        continue;
      }

      if (chat.delete_time > 0 && chat.isGroup) {
        Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
        if (group?.roomType == GroupType.TMP.num) {
          continue;
        }
      }

      visibleChats.add(chat);

      if (!notBlank(chat.name)) {
        if (chat.typ == chatTypeSaved) {
          chat.name = localized(homeSavedMessage);
        } else if (chat.typ == chatTypeSystem) {
          chat.name = localized(homeSystemMessage);
        } else if (chat.typ == chatTypeSmallSecretary) {
          chat.name = localized(chatSecretary);
        }
      }
    }
    return visibleChats;
  }

  ///清除搜索flag
  void clearSearching({isUnfocus = false}) async {
    isSearching.value = false;
    searchController.clear();
    searchParam.value = '';
    searchTabController?.index = 0;
    searchTabController?.animateTo(0);
    if (isUnfocus && searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
  }

  ///Desktop Version ====================================================
  bool isCTRLPressed() {
    return HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlRight);
  }

  void tapForEdit(Chat chat) {
    if (chat.isSpecialChat) {
      Toast.showToast(
        localized(hideOrDeleteSavedMessageIsNotAllowed,
            params: [getSpecialChatName(chat.typ)]),
      );
    } else {
      selectedChatIDForEdit.contains(chat.chat_id)
          ? selectedChatIDForEdit.remove(chat.chat_id)
          : selectedChatIDForEdit.add(chat.chat_id);
      update();
    }
  }

  void clearSelectedChatForEdit() {
    selectedChatIDForEdit.clear();
    update();
  }

  // ================================== 工具 ====================================
  /// 创建聊天室
  void showCreateChatPopup() {
    CreateChatController createChatController = Get.put(CreateChatController());

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return CreateChatBottomSheet(
          controller: createChatController,
          createGroupCallback: (type) {
            if (type == GroupType.FRIEND) {
              Get.close(1);
              showAddFriendBottomSheet(isSecondPage: true);
            } else {
              showCreateGroupPopup(context);
            }
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateChatController>();
    });
  }

  /// 创建群组
  void showCreateGroupPopup(BuildContext context) {
    CreateGroupBottomSheetController createGroupBottomSheetController =
        Get.put(CreateGroupBottomSheetController());
    // createGroupBottomSheetController.groupType = type;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return CreateGroupBottomSheet(
          controller: createGroupBottomSheetController,
          cancelCallback: () {
            createGroupBottomSheetController.closePopup();
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateGroupBottomSheetController>();
    });
  }

  Future<void> showAddFriendBottomSheet({bool isSecondPage = false}) async {
    Get.put(SearchContactController());
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        Get.find<SearchContactController>().isSecondPage.value = isSecondPage;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const SearchingView(),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => Get.findAndDelete<SearchContactController>(),
      );
    });
  }

  int _delayTime = 0;

  Future<void> onRefresh() async {
    if (!isSearching.value) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (_delayTime > currentTime) return;
      _delayTime = currentTime + 2000;
      await objectMgr.onAppDataReload();
    }
  }

  void enterSecretaryChat() {
    Chat? chat = objectMgr.chatMgr.getChatByTyp(chatTypeSmallSecretary);
    if (chat != null) {
      if (searchParam.value.trim().isNotEmpty) {
        objectMgr.chatMgr.sendText(chat.id, searchParam.value);
      }

      Routes.toChat(chat: chat);
    }

    searchFocus.unfocus();
    clearSearching();
  }

  showPopUpMenu(BuildContext context) {
    floatWindowRender =
        notificationKey.currentContext!.findRenderObject() as RenderBox;

    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
    } else {
      vibrate();
      bool isMandarin =
          AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();
      double maxWidth = objectMgr.loginMgr.isDesktop
          ? 300
          : isMandarin
              ? 220
              : 220;
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);
      overlayChild = MoreVertView(
        optionList: menuOptions,
        func: () {
          closeMenu();
        },
      );

      for (var option in menuOptions) {
        if (option.optionType == HomePageMenu.scanPaymentQr.optionType) {
          option.isShow = isWalletEnable();
        }
      }

      floatWindowOverlay = createOverlayEntry(
        shouldBlurBackground: false,
        context,
        Container(
          width: floatWindowRender!.size.width,
          height: floatWindowRender!.size.height,
          color: colorBackground,
          padding: const EdgeInsets.only(left: 20, right: 16),
          child: SvgPicture.asset(
            'assets/svgs/add.svg',
            width: 20,
            height: 20,
            color: themeColor,
            fit: BoxFit.fitWidth,
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth, //260
          ),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(
              objectMgr.loginMgr.isDesktop ? 10 : 10.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 0,
                blurRadius: 16,
              ),
            ],
          ),
          child: overlayChild,
        ),
        layerLink,
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 301 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        followerWidgetOffset: const Offset(-10, 20),
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
          Get.delete<MoreVertController>();
        },
      );
    }
  }

  closeMenu() {
    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;
    Get.delete<MoreVertController>();
  }

  Future<void> showSkeletonTask() async {
    String chatListFetchTimeName =
        "${LocalStorageMgr.CHAT_LIST_FETCH_TIME}${objectMgr.userMgr.mainUser.uid}";
    final int? fetchTime =
        objectMgr.localStorageMgr.read<int?>(chatListFetchTimeName);

    if (isInitializing.value &&
        allChats.isEmpty &&
        currentChatCategoryIdx == 0 &&
        (fetchTime == null || fetchTime == 0)) {
      sw.start();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (sw.isRunning) isShowSkeleton.value = true;
      });
    }
  }

  // void onClearRecentChat(BuildContext context) {
  //   showCustomBottomAlertDialog(
  //     context,
  //     subtitle: localized(areYouSureClearSearchHistory),
  //     confirmText: localized(chatClear),
  //     onConfirmListener: () {
  //       recentChatList.clear();
  //       objectMgr.localStorageMgr.write(
  //         LocalStorageMgr.RECENT_CHAT,
  //         jsonEncode(recentChatList),
  //       );
  //     },
  //   );
  // }

  void onForwardMessage(Message messages, Chat chat) {
    if (objectMgr.loginMgr.isDesktop) {
      desktopGeneralDialog(
        Get.context!,
        widgetChild: DesktopForwardContainer(
          chat: chat,
          fromChatInfo: true,
          forwardMsg: [messages],
        ),
      );
    } else {
      showModalBottomSheet(
        context: Get.context!,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: colorOverlay40,
        builder: (BuildContext context) {
          return ForwardContainer(
            chat: chat,
            forwardMsg: [messages],
          );
        },
      );
    }
  }

  Future<void> deleteMessages(
    List<Message> messages,
    int chatId, {
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    List<Message> fakeMessages = [];
    List<Message> floatingPIPCheckMessages = [];

    for (var message in messages) {
      if (message.typ == messageTypeNewAlbum ||
          message.typ == messageTypeReel ||
          message.typ == messageTypeVideo) {
        floatingPIPCheckMessages.add(message);
      }

      if (message.message_id == 0) {
        fakeMessages.add(message);
      } else {
        remoteMessages.add(message);
        remoteMessageIds.add(message.message_id);
      }
    }

    if (floatingPIPCheckMessages.isNotEmpty) {
      objectMgr.tencentVideoMgr
          .checkForFloatingPIPClosure(floatingPIPCheckMessages);
    }

    if (fakeMessages.isNotEmpty) {
      for (int i = 0; i < fakeMessages.length; i++) {
        objectMgr.chatMgr.localDelMessage(fakeMessages[i]);
      }
    }

    if (remoteMessages.isNotEmpty) {
      chat_api.deleteMsg(
        chatId,
        remoteMessageIds,
        isAll: isAll,
      );

      for (var message in remoteMessages) {
        objectMgr.chatMgr.localDelMessage(message);
      }
    }

    if (objectMgr.loginMgr.isMobile) {
      imBottomToast(
        Get.context!,
        title: localized(toastDeleteMessageSuccess),
        icon: ImBottomNotifType.delete,
      );
    } else {
      imBottomToast(
        Get.context!,
        icon: ImBottomNotifType.custom,
        customIcon: const CustomImage(
          'assets/svgs/delete2_icon.svg',
          size: 18,
        ),
        title: localized(deletedSuccess),
      );
    }
  }
}
