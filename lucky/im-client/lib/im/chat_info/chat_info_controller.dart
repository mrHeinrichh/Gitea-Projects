import 'dart:async';
import 'dart:math';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_view.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

import '../../data/db_user.dart';
import '../../main.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/net/update_block_bean.dart';
import '../../views/component/custom_alert_dialog.dart';
import '../../views_desktop/component/desktop_forward_container.dart';
import '../../views_desktop/component/desktop_general_dialog.dart';
import '../private_chat/single_chat_controller.dart';
import 'group/group_chat_info_controller.dart';

class ChatInfoController extends GetxController
    with GetTickerProviderStateMixin {
  /// ============================= VARIABLES ==================================
  final isLoading = false.obs;

  final user = Rxn<User>();
  final chat = Rxn<Chat>();

  bool get chatIsNotEmpty => chat.value?.id != 0;

  final isMute = false.obs;
  final ableEdit = false.obs;
  final ableChat = false.obs;
  final ableCall = true.obs;
  final ableMute = true.obs;
  final isDeletedAccount = false.obs;

  /// friend request
  final ableAddFriend = false.obs;
  final ableFriendRequestSent = false.obs;
  final ableAcceptFriend = false.obs;
  final ableRejectFriend = false.obs;

  RxDouble flexAppbarHeight = 550.0.obs;
  final GlobalKey childKey = GlobalKey();
  int uid = 0;

  final onCallPressed = false.obs;
  final callingAudio = false.obs;

  final isMuteOpen = false.obs;
  final isMoreOpen = false.obs;

  CustomPopupMenuController controller = Get.find<CustomPopupMenuController>();

  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  GlobalKey tabBarKey = GlobalKey();
  late BuildContext context;

  RxList<ChatInfoModel> singleChatTabOptions = <ChatInfoModel>[].obs;

  // List<ChatInfoModel> singleChatTabOptions = [
  //   ChatInfoModel(
  //       tabType: ChatInfoTabOption.media.tabType, stringKey: "mediaTab"),
  //   ChatInfoModel(
  //       tabType: ChatInfoTabOption.file.tabType, stringKey: "fileTab"),
  //   ChatInfoModel(
  //       tabType: ChatInfoTabOption.audio.tabType, stringKey: "voiceTab"),
  //   ChatInfoModel(
  //       tabType: ChatInfoTabOption.link.tabType, stringKey: "linkTab"),
  //   ChatInfoModel(
  //       tabType: ChatInfoTabOption.group.tabType, stringKey: "groupTab"),
  // ];

  List<ToolOptionModel> deleteOptions = [
    ToolOptionModel(
      title: localized(deleteForEveryone),
      optionType: DeletePopupOption.deleteForEveryone.optionType,
      largeDivider: false,
      isShow: true,
      tabBelonging: 1,
      color: Colors.red,
    ),
    ToolOptionModel(
      title: localized(deleteForMe),
      optionType: DeletePopupOption.deleteForMe.optionType,
      largeDivider: false,
      isShow: true,
      tabBelonging: 1,
      color: Colors.red,
    ),
  ];

  bool autoDeleteIntervalEnable = false;

  bool screenshotEnable = false;

  RxInt currentTabIndex = 0.obs;

  RxBool onMoreSelect = false.obs;
  final selectedMessageList = <Message>[].obs;
  void Function(Message message)? onMoreSelectCallback;
  RxBool onAudioPlaying = false.obs;

  RxInt scrollTabColors = 0.obs; //紀錄當前的tab顏色 0:tab本身顏色 1:profile背景色

  /// 多功能工具栏 控制器
  late TabController tabController;
  late final ScrollController scrollController;
  TabController? forwardViewController;

  ValueNotifier<bool> appBarIsCollapsed = ValueNotifier<bool>(false);

  /// 多功能工具Key
  GlobalKey moreVertKey = GlobalKey();
  GlobalKey notificationKey = GlobalKey();

  //簡介的文字行數
  int profileTextNumLines = 0;

  final List<ToolOptionModel> muteOptionModelList = [
    ToolOptionModel(
      title: localized(chatInfo1Hour),
      optionType: MutePopupOption.oneHour.optionType,
      isShow: true,
      tabBelonging: 3,
    ),
    ToolOptionModel(
      title: localized(chatInfo8Hours),
      optionType: MutePopupOption.eighthHours.optionType,
      isShow: true,
      tabBelonging: 3,
    ),
    ToolOptionModel(
      title: localized(chatInfo1Day),
      optionType: MutePopupOption.oneDay.optionType,
      isShow: true,
      tabBelonging: 3,
    ),
    ToolOptionModel(
        title: localized(chatInfo7Days),
        optionType: MutePopupOption.sevenDays.optionType,
        isShow: true,
        tabBelonging: 3,
        largeDivider: true),
    ToolOptionModel(
      title: '${localized(muteUntil)}',
      optionType: MutePopupOption.muteUntil.optionType,
      isShow: true,
      tabBelonging: 3,
    ),
    ToolOptionModel(
      title: localized(muteForever),
      optionType: MutePopupOption.muteForever.optionType,
      isShow: true,
      tabBelonging: 3,
      color: errorColor,
    ),
  ];

  /// 悬浮小窗参数
  OverlayEntry? floatWindowOverlay;
  Widget? overlayChild;
  final LayerLink layerLink = LayerLink();
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;

  //tab置頂的高度要多少
  double pinnedHeight = 0;

  ChatInfoController();

  ChatInfoController.desktop(int uid) {
    this.uid = uid;
  }

  /// METHODS
  @override
  void onInit() async {
    super.onInit();

    if (Get.arguments != null) {
      uid = Get.arguments["uid"];
    }

    tabController = TabController(
      length: singleChatTabOptions.length,
      vsync: this,
    );

    tabController.addListener(() {
      currentTabIndex.value = tabController.index;
      if (!tabController.indexIsChanging) {
        //切換tab就強制將tab置頂
        scrollToTabPinned();
      }
    });

    forwardViewController = TabController(
      length: 2,
      vsync: this,
    );
    VolumePlayerService.sharedInstance.playerStateStream
        .listen(onAudioPlayingListener);

    scrollController = ScrollController();
    //偵測滑動距離超越tab高度變更tab背景顏色
    scrollController.addListener(() {
      if (!objectMgr.loginMgr.isDesktop) {
        //手機端才需要支援tab置頂
        if (pinnedHeight == 0) {
          pinnedHeight = calPinnedHeight(0);
        }
        if (scrollController.position.pixels >= pinnedHeight &&
            scrollTabColors == 0) {
          scrollTabColors.value = 1;
        } else if (scrollController.position.pixels < pinnedHeight &&
            scrollTabColors == 1) {
          scrollTabColors.value = 0;
        }
      }
    });
    await loadUserInfo();

    if (chat.value != null) {
      await checkShowMediaFileTab();
    }

    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBChat.tableName}", _onChatReplace);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    objectMgr.chatMgr
        .on(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
  }

  //檢查是否需要顯示媒體檔案等的tab
  checkShowMediaFileTab() async {
    List results = await Future.wait([
      checkMediaExist(),
      checkFileExist(),
      checkVoiceExist(),
      checkLinkExist(),
      checkGroupExist(),
    ]);
    singleChatTabOptions.clear();
    if (results[0].length > 0) {
      //檢查媒體
      singleChatTabOptions.add(ChatInfoModel(
          tabType: ChatInfoTabOption.media.tabType, stringKey: "mediaTab"));
    }
    if (results[1].length > 0) {
      //檢查檔案
      singleChatTabOptions.add(ChatInfoModel(
          tabType: ChatInfoTabOption.file.tabType, stringKey: "fileTab"));
    }
    if (results[2].length > 0) {
      //檢查音訊
      singleChatTabOptions.add(ChatInfoModel(
          tabType: ChatInfoTabOption.audio.tabType, stringKey: "voiceTab"));
    }
    if (results[3].length > 0) {
      //檢查連結
      singleChatTabOptions.add(ChatInfoModel(
          tabType: ChatInfoTabOption.link.tabType, stringKey: "linkTab"));
    }
    if (results[4].length > 0) {
      //檢查紅包
      singleChatTabOptions.add(ChatInfoModel(
          tabType: ChatInfoTabOption.group.tabType, stringKey: "groupTab"));
    }
    tabController = TabController(
      length: singleChatTabOptions.length,
      vsync: this,
    );

    tabController.addListener(() {
      currentTabIndex.value = tabController.index;
      if (!tabController.indexIsChanging) {
        //切換tab就強制將tab置頂
        scrollToTabPinned();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  //檢查該好友是否有媒體
  Future<List> checkMediaExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND (typ = ? OR typ = ? OR typ = ? OR typ = ?) AND deleted != 1 AND expire_time == 0',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        chat.value!.msg_idx + 1,
        messageTypeImage,
        messageTypeVideo,
        messageTypeReel,
        messageTypeNewAlbum,
      ],
      'DESC',
      1,
    );

    return tempList;
  }

  //檢查該好友是否有檔案
  Future<List> checkFileExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ?',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        messageTypeFile,
      ],
      'DESC',
      1,
    );

    return tempList;
  }

  //檢查該好友是否有音訊
  Future<List> checkVoiceExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND (typ = ?)',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        messageTypeVoice,
      ],
      'DESC',
      1,
    );

    return tempList;
  }

  //檢查該好友是否有連結
  Future<List> checkLinkExist() async {
    List<Map<String, dynamic>> tempList = await objectMgr.localDB
        .loadMessagesByWhereClause(
            'chat_id = ? AND chat_idx > ? AND typ = ?',
            [chat.value!.id, chat.value!.hide_chat_msg_idx, messageTypeLink],
            'DESC',
            1);

    return tempList;
  }

  //檢查該好友是否有群組
  Future<List> checkGroupExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.myGroupMgr.getCommonGroupByRemote(user.value!.uid);

    return tempList;
  }

  double scrollTabPinned = 460.0;
  double scrollTabPinnedNoProfile = 400.0;

  //滑動將tab置頂
  scrollToTabPinned() {
    double pinnedHeight = calPinnedHeight(scrollController.position.pixels);
    if (scrollTabColors.value == 0) {
      scrollController.animateTo(
        pinnedHeight,
        curve: Curves.linear,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  //計算tab置頂高度
  double calPinnedHeight(double currentPos) {
    //利用當前的tab位置計算要置頂的高度同時必須扣掉多餘的padding及tool bar高度
    return currentPos +
        getTabYPos(tabBarKey) -
        (objectMgr.loginMgr.isDesktop
            ? 72
            : (kToolbarHeight + MediaQuery.of(context).padding.top - 6));
  }

  //取得當前tab的絕對位置
  double getTabYPos(_key) {
    RenderBox renderBox = _key.currentContext.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    return offset.dy;
  }

  loadUserInfo() async {
    // 先显示本地的User对象
    isLoading.value = true;
    user.value = await objectMgr.userMgr.loadUserById(uid);
    Chat? tempChat = await objectMgr.chatMgr.getChatByFriendId(uid);
    if (tempChat != null) {
      chat.value = tempChat;
      autoDeleteIntervalEnable = chat.value!.autoDeleteEnabled;
      ableChat.value = true;
      screenshotEnable = chat.value!.screenshotEnabled;
    }
    checkRelationship();
    isLoading.value = false;
    isMute.value = checkIsMute(chat.value?.mute ?? 0);

    // 异步加载API最新的User信息
    try {
      final User? latestUser =
          await objectMgr.userMgr.loadUserById(uid, remote: true, notify: true);
      if (latestUser != null && latestUser != user.value) {
        user.value = latestUser;
      }
    } catch (e) {
      pdebug(e);
    } finally {
      isDeletedAccount.value = (user.value?.deletedAt != 0);
      checkRelationship();
    }

    updateFlexBarHeight();
  }

  @override
  void onClose() {
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);

    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBChat.tableName}", _onChatReplace);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);

    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;

    VolumePlayerService.sharedInstance.stopPlayer();
    VolumePlayerService.sharedInstance.resetPlayer();

    Get.findAndDelete<ChatInfoController>();
    super.onClose();
  }

  onAudioPlayingListener(bool isPlaying) {
    onAudioPlaying.value = isPlaying;
  }

  /// 通知按钮点击回调
  Future<void> onNotificationTap(BuildContext context) async {
    if (!ableMute.value) return;
    if (checkIsMute(chat.value!.mute)) {
      if (chat.value != null) {
        objectMgr.chatMgr
            .onChatMute(chat.value!, expireTime: 0, isNotHomePage: true);
      } else {
        Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      }
    } else {
      showMuteOptionPopup(context);
    }
  }

  /// 问题是删除过后的chat delete_time > 0, 在获取列表的时候后端chat是delete_time > 0是会被隐藏的
  Future<void> onChatTap(BuildContext context, {bool searching = false}) async {
    Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.value!.uid,
        remote: serversUriMgr.isKiWiConnected);

    if (chat == null) return;
    if (Get.isRegistered<SingleChatController>(tag: chat.id.toString())) {
      Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
      Get.find<CustomInputController>(tag: chat.id.toString())
          .inputFocusNode
          .requestFocus();
      Get.find<SingleChatController>(tag: chat.id.toString())
          .isSearching(searching);
    } else {
      if (objectMgr.loginMgr.isDesktop) {
        if (Get.find<HomeController>().pageIndex.value == 0) {
          Routes.toChatDesktop(chat: chat);
        } else {
          final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
          Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
          Get.find<HomeController>().tabController?.index = 0;
          Get.find<HomeController>().pageIndex.value = 0;
          Future.delayed(const Duration(milliseconds: 300), () {
            Routes.toChatDesktop(chat: chat);
          });
        }
      } else {
        Routes.toChat(
          chat: chat,
          searching: searching,
        );
      }
    }
  }

  /// more_vert 点击回调
  void onMore(BuildContext context) {
    if (ableChat.value && !objectMgr.userMgr.isMe(user.value?.uid ?? 0)) {
      showMoreOptionPopup(context);
    }
  }

  void onTabChange(int index) {
    if (currentTabIndex.value == index) {
      //點擊原先的tab也要將tab置頂
      scrollToTabPinned();
    }
    currentTabIndex.value = index;
  }

  /// ================================ 业务逻辑 =================================
  void onMoreCancel() {
    onMoreSelect.value = false;
    selectedMessageList.clear();
  }

  void onForwardMessage(BuildContext context) {
    if (objectMgr.loginMgr.isDesktop) {
      DesktopGeneralDialog(
        context,
        widgetChild: DesktopForwardContainer(
          chat: chat.value!,
          fromChatInfo: true,
          forwardMsg: selectedMessageList,
        ),
      );
    } else {
      showModalBottomSheet(
        context: Get.context!,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return ForwardContainer(
            chat: chat.value!,
            forwardMsg: selectedMessageList,
          );
        },
      );
    }
  }

  void onDeleteMessage(BuildContext context, GlobalKey key) {
    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      if (floatWindowOverlay != null) {
        deleteOptions[0].isShow = true;
        floatWindowOverlay?.remove();
        floatWindowOverlay = null;
      }
    } else {
      floatWindowRender = key.currentContext!.findRenderObject() as RenderBox;
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);

      selectedMessageList.forEach((message) {
        if (!deleteOptions[0].isShow) return;
        deleteOptions[0].isShow = objectMgr.userMgr.isMe(message.send_id) &&
            DateTime.now().millisecondsSinceEpoch -
                    (message.create_time * 1000) <
                const Duration(days: 1).inMilliseconds;
      });

      floatWindowOverlay = createOverlayEntry(
        context,
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 8,
          ),
          margin: const EdgeInsets.symmetric(
            vertical: 3,
            horizontal: 4,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 24,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(
            maxWidth: 220.0,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deleteOptions.length,
            itemBuilder: (BuildContext context, int index) {
              if (deleteOptions[index].isShow == false) return const SizedBox();

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () =>
                    onDeleteOptionTap(context, deleteOptions[index].optionType),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    deleteOptions[index].title,
                    style: TextStyle(
                      color: deleteOptions[index].color ?? accentColor,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        layerLink,
        left: floatWindowOffset!.dx,
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        dismissibleCallback: () {
          floatWindowOffset = null;
          deleteOptions[0].isShow = true;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
        },
      );
    }
  }

  void onDeleteOptionTap(BuildContext context, String optionTitle) {
    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;

    switch (optionTitle) {
      case 'deleteForEveryone':
        onDeletePrompt(context, isAll: true);
        break;
      case 'deleteForMe':
        onDeletePrompt(context, isAll: false);
        break;
      default:
        break;
    }
  }

  onDeletePrompt(
    BuildContext context, {
    bool isAll = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(popupDelete),
          content: Text(
            isAll
                ? localized(chatInfoThisMessageWillBeDeletedForAllReceipts)
                : localized(
                    chatInfoThisMessageWillBeDeletedFromYourMessageHistory),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonYes),
          cancelText: localized(buttonNo),
          confirmCallback: () async {
            await deleteMessages(
              selectedMessageList,
              chatId: chat.value!.id,
              isAll: isAll,
            );
            Toast.showToast(localized(toastDeleteSuccess));
          },
        );
      },
    ).whenComplete(() {
      onMoreSelect.value = false;
      selectedMessageList.clear();
    });
  }

  Future<void> deleteMessages(
    List<dynamic> messages, {
    int? chatId,
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    // filter fake message
    messages.forEach((message) {
      if (message is Message) {
        if (message.message_id == 0 && !message.isSendOk) {
          objectMgr.chatMgr.mySendMgr.remove(message);
        } else {
          remoteMessages.add(message);
          remoteMessageIds.add(message.message_id);
        }
      } else if (message is AlbumDetailBean) {
        Message? msg = message.currentMessage;
        if (msg != null) {
          if (msg.message_id == 0 && !msg.isSendOk) {
            objectMgr.chatMgr.mySendMgr.remove(msg);
          } else {
            remoteMessages.add(msg);
            remoteMessageIds.add(msg.message_id);
          }
        } else {
          throw "检查代码逻辑";
        }
      }
    });

    if (remoteMessages.length > 0) {
      chat_api.deleteMsg(
        chatId ?? remoteMessages.first.chat_id,
        remoteMessageIds,
        isAll: isAll,
      );

      remoteMessages.forEach((message) {
        objectMgr.chatMgr.localDelMessage(message);
      });
    }
  }

  /// ============================== Actions 调用函数 ===========================

  ///发送好友请求
  void addFriend() async {
    if (ableAddFriend.value) {
      objectMgr.userMgr.addFriend(user.value!);
    }
  }

  ///接受好友请求
  void acceptFriend() async {
    if (ableAcceptFriend.value) {
      objectMgr.userMgr.acceptFriend(user.value!);
    }
  }

  ///拒绝好友请求
  void rejectFriend() async {
    if (ableRejectFriend.value) {
      await objectMgr.userMgr.rejectFriend(user.value!);
    }
  }

  ///获取对方关系，显示操作
  Widget getAction() {
    switch (user.value?.relationship) {
      case Relationship.friend:
        return SvgPicture.asset(
          'assets/svgs/Edit.svg',
          width: 16,
          height: 16,
          color: JXColors.primaryTextBlack,
        );
      case Relationship.stranger:
        if (objectMgr.userMgr.isMe(user.value?.uid ?? 0)) {
          return const SizedBox();
        } else {
          return const Icon(
            Icons.person_add_alt_1_outlined,
            color: JXColors.indigo,
          );
        }
      case Relationship.sentRequest:
        return Text(
          localized(chatInfoRequestSent),
          style: TextStyle(
            color: accentColor.withOpacity(0.2),
            fontSize: 14.w,
          ),
        );
      case Relationship.receivedRequest:
        return Text(
          localized(chatInfoAcceptFriend),
          style: TextStyle(
            color: accentColor,
            fontSize: 14.w,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  ///拨打电话
  Future<void> startCall({bool isAudio = true}) async {
    if (user.value == null || !ableCall.value) return;
    callingAudio.value = isAudio;
    onCallPressed.value = true;
    Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.value!.uid);
    if (chat != null) {
      try {
        objectMgr.callMgr.startCall(chat, isAudio);
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
      } finally {
        onCallPressed.value = false;
        callingAudio.value = false;
      }
    }
  }

  ///更新数据库通知
  Future<void> _onUserUpdate(Object sender, Object type, Object? data) async {
    /// 新建用户
    if (type == "u:user" && data is RowObject) {
      User user = User.fromJson(data.toJson());
      data = user;
    }
    if ((data is User) && data.id == user.value?.uid) {
      User newUser = data;
      user.update((val) {
        val?.updateValue(newUser.toJson());
      });

      isDeletedAccount.value = (user.value?.deletedAt != 0);
      checkRelationship();

      ///更改显示框高度
      updateFlexBarHeight();
    }
  }

  void _onChatUpdate(Object sender, Object type, Object? data) {
    if (data is Chat && chat.value?.chat_id == data.chat_id) {
      ableChat.value = true;
      screenshotEnable = data.screenshotEnabled;
      autoDeleteIntervalEnable = data.autoDeleteEnabled;
    }
  }

  void _onChatReplace(Object sender, Object type, Object? data) {
    if (data is Chat && chat.value?.chat_id == data.chat_id) {
      chat.value = data;
      ableChat.value = true;
      screenshotEnable = data.screenshotEnabled;
      autoDeleteIntervalEnable = data.autoDeleteEnabled;
    }
  }

  void _onAutoDeleteIntervalChange(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (data.chat_id != chat.value?.id) return;
      MessageInterval msgInterval =
          data.decodeContent(cl: MessageInterval.creator);
      if (msgInterval.interval == 0) {
        autoDeleteIntervalEnable = false;
      } else {
        autoDeleteIntervalEnable = true;
      }
    }
  }

  void _onMuteChanged(Object sender, Object type, Object? data) {
    if (data is Chat && chat.value?.chat_id == data.id) {
      if (checkIsMute(data.mute)) {
        isMute.value = true;
      } else {
        isMute.value = false;
      }
    }
  }

  checkRelationship() {
    ableEdit.value = false;
    ableCall.value = false;
    ableMute.value = false;

    ableAddFriend.value = false;
    ableFriendRequestSent.value = false;
    ableAcceptFriend.value = false;
    ableRejectFriend.value = false;

    if (!isDeletedAccount.value) {
      switch (user.value?.relationship) {
        case Relationship.friend:
          ableEdit.value = true;
          ableCall.value = true;
          ableMute.value = true;
          ableChat.value = true;
          break;
        case Relationship.stranger:
          ableAddFriend.value = true;
          ableChat.value = false;
          break;
        case Relationship.sentRequest:
          ableFriendRequestSent.value = true;
          ableChat.value = false;
          break;
        case Relationship.receivedRequest:
          ableAcceptFriend.value = true;
          ableRejectFriend.value = true;
          ableChat.value = false;
          break;
        default:
          break;
      }
    }
  }

  void updateFlexBarHeight() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (childKey.currentContext != null) {
        final height =
            (childKey.currentContext?.findRenderObject() as RenderBox)
                .size
                .height;
        flexAppbarHeight.value = height + (isDesktop ? 60.w : 40.w);
      }
    });
  }

  void exitInfoView() {
    if (isDesktop) {
      final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
      Get.find<ContactController>().selectedUserUID.value = 101010;
      if (chat.value == null) {
        Get.back(id: id);
        return;
      }
      if (Get.isRegistered<SingleChatController>(
              tag: chat.value?.id.toString()) ||
          Get.isRegistered<GroupChatController>(
              tag: Get.find<ChatListController>()
                  .desktopSelectedChatID
                  .toString()) ||
          id == 1) {
        Get.back(id: id);
        if (Get.isRegistered<CustomInputController>(
            tag: chat.value?.id.toString())) {
          Get.find<CustomInputController>(tag: chat.value?.id.toString())
              .inputFocusNode
              .requestFocus();
        }
      } else {
        Get.toNamed(RouteName.desktopChatEmptyView, id: 2);
      }
    } else {
      Get.back();
    }
  }

  void showMuteOptionPopup(BuildContext context) {
    floatWindowRender =
        notificationKey.currentContext!.findRenderObject() as RenderBox;
    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
      isMuteOpen.value = false;
    } else {
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);
      bool isMandarin =
          AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();

      overlayChild = MoreVertView(
        optionList: muteOptionModelList,
        func: () => isMuteOpen.value = false,
      );
      isMuteOpen.value = true;
      floatWindowOverlay = createOverlayEntry(
        shouldBlurBackground: false,
        context,
        GestureDetector(
          onTap: () => onNotificationTap(context),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            width: floatWindowRender!.size.width,
            height: floatWindowRender!.size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isMute.value
                      ? 'assets/svgs/chat_info_unmute.svg'
                      : 'assets/svgs/chat_info_mute.svg',
                  width: 22,
                  height: 22,
                  color: ableMute.value
                      ? accentColor
                      : accentColor.withOpacity(0.3),
                ),
                SizedBox(height: 2),
                Text(
                  isMute.value ? localized(unmute) : localized(mute),
                  style: jxTextStyle.textStyle12(
                    color: ableMute.value
                        ? accentColor
                        : accentColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: objectMgr.loginMgr.isDesktop
                ? 300
                : isMandarin
                    ? 128
                    : 160,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                objectMgr.loginMgr.isDesktop ? 10 : 10.0.w),
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
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 321 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: objectMgr.loginMgr.isDesktop
            ? Alignment.bottomCenter
            : Alignment.bottomRight,
        followerAnchor: objectMgr.loginMgr.isDesktop
            ? Alignment.topCenter
            : Alignment.topRight,
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
          isMuteOpen.value = false;
        },
      );
    }
  }

  void showMoreOptionPopup(BuildContext context) {
    List<ToolOptionModel> optionModelList = [
      ToolOptionModel(
        title: localized(search),
        optionType: MorePopupOption.search.optionType,
        isShow: true,
        tabBelonging: 4,
      ),
      ToolOptionModel(
        title: localized(autoDeleteMessage),
        optionType: MorePopupOption.autoDeleteMessage.optionType,
        isShow: true,
        tabBelonging: 4,
        trailingText: localized(autoDeleteIntervalEnable ? turnOn : turnOff),
      ),
      ToolOptionModel(
        title: localized(screenshotNotification),
        optionType: MorePopupOption.screenshotNotification.optionType,
        isShow: true,
        tabBelonging: 4,
        trailingText: localized(screenshotEnable ? turnOn : turnOff),
      ),
      ToolOptionModel(
        title: localized(createGroup),
        optionType: MorePopupOption.createGroup.optionType,
        isShow: true,
        tabBelonging: 4,
        largeDivider: true,
      ),
      ToolOptionModel(
        title: localized(clearChatHistory),
        optionType: MorePopupOption.clearChatHistory.optionType,
        isShow: true,
        tabBelonging: 4,
      ),
      ToolOptionModel(
          title: localized(deleteChatHistory),
          optionType: MorePopupOption.deleteChatHistory.optionType,
          isShow: true,
          tabBelonging: 4,
          color: errorColor),
    ];

    if (user.value?.relationship != Relationship.friend) {
      if (ableChat.value) {
        optionModelList.removeWhere((e) =>
            e.optionType == MorePopupOption.autoDeleteMessage.optionType ||
            e.optionType == MorePopupOption.createGroup.optionType);
      } else {
        optionModelList.removeWhere((e) =>
            // e.optionType == MorePopupOption.autoDeleteMessage.optionType ||
            e.optionType == MorePopupOption.clearChatHistory.optionType ||
            e.optionType == MorePopupOption.createGroup.optionType ||
            e.optionType == MorePopupOption.deleteChatHistory.optionType);
      }
    }

    floatWindowRender =
        moreVertKey.currentContext!.findRenderObject() as RenderBox;
    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
      isMoreOpen.value = false;
    } else {
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);
      bool isMandarin =
          AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();
      overlayChild = MoreVertView(
        optionList: optionModelList,
        func: () => isMoreOpen.value = false,
      );

      isMoreOpen.value = true;
      floatWindowOverlay = createOverlayEntry(
        shouldBlurBackground: false,
        context,
        Container(
          padding: const EdgeInsets.all(8.0),
          width: floatWindowRender!.size.width,
          height: floatWindowRender!.size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svgs/chat_info_more.svg',
                width: 22,
                height: 22,
                color: accentColor,
              ),
              const SizedBox(height: 2),
              Text(
                localized(searchMore),
                style: jxTextStyle.textStyle12(
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: objectMgr.loginMgr.isDesktop
                ? 300
                : isMandarin
                    ? 168
                    : 240,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                objectMgr.loginMgr.isDesktop ? 10 : 10.0.w),
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
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 321 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
          isMoreOpen.value = false;
        },
      );
    }
  }

  void doBlockUser() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(blockUserName,
              params: [objectMgr.userMgr.getUserTitle(user.value)]),
          content: Text(
            localized(blockUserDesc),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonBlock),
          cancelText: localized(buttonNo),
          confirmCallback: () => objectMgr.userMgr.blockUser(user.value!),
        );
      },
    );
  }

  void doUnblockUser() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(unblockUserName,
              params: [objectMgr.userMgr.getUserTitle(user.value)]),
          content: Text(
            localized(unblockUserDesc),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonUnblock),
          cancelText: localized(buttonNo),
          confirmCallback: () => objectMgr.userMgr.unblockUser(user.value!),
        );
      },
    );
  }
}
