import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/chat_info/components/member_view_menu.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_view.dart';
import 'package:jxim_client/im/chat_info/more_vert/new_mute_until_action_sheet.dart';
import 'package:jxim_client/im/chat_info/more_vert/select_new_group_owner_view.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_view.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_container.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:lottie/lottie.dart';

class GroupChatInfoController extends GetxController
    with GetTickerProviderStateMixin {
  /// ============================= VARIABLES ==================================
  final isLoading = false.obs;
  final group = Rxn<Group>();
  final chat = Rxn<Chat>();
  final isOwner = false.obs;
  final isAdmin = false.obs;
  final adminList = [].obs;
  final newOwnerID = 0.obs;
  final flexAppbarHeight = 320.0.obs;
  final GlobalKey childKey = GlobalKey();
  final moreVertKey = GlobalKey();
  final notificationKey = GlobalKey();
  final groupMemberListData = <User>[].obs;
  final isGroupChatDescExpanded = false.obs;
  final myGroupAlias = ''.obs;
  GlobalKey tabBarKey = GlobalKey();
  late BuildContext context;

  int touchIndex = -1;

  updateGroupChatDescExpanded(bool isExpanded) {
    isGroupChatDescExpanded(isExpanded);
  }

  CustomPopupMenuController controller = Get.find<CustomPopupMenuController>();

  final groupRequestInfoListData = <User>[].obs;

  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  int groupId = 0;

  /// 多功能工具栏 控制器
  late TabController tabController;
  RxInt currentForwardPage = RxInt(0);

  late final ScrollController scrollController;
  TabController? forwardViewController;
  TextEditingController ownershipController = TextEditingController();

  //簡介的文字行數
  int profileTextNumLines = 0;
  final downOffset = 0.0.obs;

  RxList<ChatInfoModel> groupTabOptions = <ChatInfoModel>[].obs;

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

  RxInt currentTabIndex = 0.obs;

  RxBool onMoreSelect = false.obs;
  final selectedMessageList = <dynamic>[].obs;
  void Function(Message message)? onMoreSelectCallback;
  RxBool onAudioPlaying = false.obs;

  RxInt scrollTabColors = 0.obs; //紀錄當前的tab顏色 0:tab本身顏色 1:profile背景色

  final appBarIsCollapsed = false.obs;

  final isMute = false.obs;
  final forwardEnable = true.obs;

  final isMuteOpen = false.obs;
  final isMoreOpen = false.obs;
  final isFirstTime = true.obs;

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
      largeDivider: true,
    ),
    ToolOptionModel(
      title: localized(muteUtilTitle),
      optionType: MutePopupOption.muteUntil.optionType,
      isShow: true,
      tabBelonging: 3,
    ),
    ToolOptionModel(
      title: localized(muteForever),
      optionType: MutePopupOption.muteForever.optionType,
      isShow: true,
      tabBelonging: 3,
      imageUrl: "assets/svgs/chat_info_item_mute_forever.svg",
      color: colorRed,
    ),
  ];

  bool autoDeleteIntervalEnable = false;

  /// 群成员 长按选项
  List<ToolOptionModel> groupAdminMemberOptions = [
    ToolOptionModel(
      title: localized(transferOwnership),
      optionType: GroupAdminMemberPopupOption.transferOwnership.optionType,
      isShow: true,
      largeDivider: false,
      color: colorTextPrimary,
      tabBelonging: 5,
    ),
    ToolOptionModel(
      title: localized(promoteAdmin),
      optionType: GroupAdminMemberPopupOption.promoteAdmin.optionType,
      isShow: true,
      largeDivider: false,
      color: colorTextPrimary,
      tabBelonging: 5,
    ),
    ToolOptionModel(
      title: localized(demoteAdmin),
      optionType: GroupAdminMemberPopupOption.demoteAdmin.optionType,
      isShow: true,
      largeDivider: false,
      color: colorTextPrimary,
      tabBelonging: 5,
    ),
    ToolOptionModel(
      title: localized(deleteMember),
      optionType: GroupAdminMemberPopupOption.deleteMember.optionType,
      isShow: true,
      largeDivider: false,
      color: colorRed,
      tabBelonging: 5,
    ),
  ];

  /// 悬浮小窗参数
  OverlayEntry? floatWindowOverlay;
  Widget? overlayChild;
  final LayerLink layerLink = LayerLink();
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;

  final editEnable = true.obs;
  final addMemberEnable = true.obs;
  bool screenshotEnable = false;

  /// 临时群组
  RxBool isGroupExpireSoon = false.obs;
  // 是否为加密
  final RxBool isEncrypted = false.obs;
  final remainingTime = '...'.obs;
  Timer? expireCountDownTimer;

  GroupChatInfoController();

  GroupChatInfoController.desktop(this.groupId);

  /// ============================== METHODS ===================================
  @override
  void onInit() {
    super.onInit();

    VolumePlayerService.sharedInstance.playerStateStream
        .listen(onAudioPlayingListener);

    _doInit();
  }

  //tab置頂的高度要多少
  double pinnedHeight = 0;

  _doInit() async {
    downOffset.value = objectMgr.callMgr.topFloatingOffsetY;
    final Map<String, dynamic> arguments =
        (Get.arguments ?? Get.parameters) as Map<String, dynamic>;
    if (arguments['groupId'] != null) {
      groupId = arguments['groupId'];
    }

    await getGroupInfo(groupId);

    if (chat.value != null) {
      checkShowMemberMediaTab();
    }

    isMute.value = checkIsMute(chat.value?.mute ?? 0);
    isEncrypted.value = chat.value?.isEncrypted ?? false;

    if (!Config().enableRedPacket) {
      groupTabOptions.removeWhere(
        (element) => element.tabType == ChatInfoTabOption.redPacket.tabType,
      );
    }

    scrollController =
        ScrollController(initialScrollOffset: 0); //initialScrllOffset);
    //偵測滑動距離超越tab高度變更tab背景顏色
    scrollController.addListener(() {
      if (!objectMgr.loginMgr.isDesktop) {
        //手機端才需要支援tab置頂
        if (pinnedHeight == 0) {
          pinnedHeight = calPinnedHeight(0);
        }
        if (scrollController.position.pixels >= pinnedHeight &&
            scrollTabColors.value == 0) {
          scrollTabColors.value = 1;
        } else if (scrollController.position.pixels < pinnedHeight &&
            scrollTabColors.value == 1) {
          scrollTabColors.value = 0;
        }
      }
    });

    forwardViewController = TabController(
      length: 2,
      vsync: this,
    );

    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventGroupInfoUpdated, eventGroupInfoUpdated);

    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBChat.tableName}", _onChatReplace);

    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);

    objectMgr.chatMgr
        .on(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.onlineMgr.on(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.chatMgr.on(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    objectMgr.callMgr.on(CallMgr.eventTopFloating, _onTopFloatingUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);

    if (group.value?.isTmpGroup == true) {
      objectMgr.myGroupMgr
          .on(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    }
  }

  void _onChangeEncryptionUpdate(sender, type, data) {
    if (data is Chat && chat.value?.id == data.id) {
      isEncrypted.value = chat.value?.isEncrypted ?? false;
    }
  }

  //檢查是否需要顯示會員媒體檔案等的tab
  checkShowMemberMediaTab() async {
    List results = await Future.wait([
      checkMediaExist(),
      checkFileExist(),
      checkLinkExist(),
      checkVoiceExist(),
      checkTaskExist(),
      checkRedPacketExist(),
    ]);

    //檢查會員
    if (groupMemberListData.isNotEmpty) {
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.member.tabType,
          stringKey: "memberTab",
        ),
      );
    }

    if (results[0].length > 0) {
      //檢查媒體
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.media.tabType,
          stringKey: "mediaTab",
        ),
      );
    }
    if (results[1].length > 0) {
      //檢查檔案
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.file.tabType,
          stringKey: "fileTab",
        ),
      );
    }
    if (results[2].length > 0) {
      //檢查連結
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.link.tabType,
          stringKey: "linkTab",
        ),
      );
    }
    if (results[3].length > 0) {
      //檢查音訊
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.audio.tabType,
          stringKey: "voiceTab",
        ),
      );
    }
    if (results[4].length > 0) {
      //檢查任務
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.tasks.tabType,
          stringKey: "tasks",
        ),
      );
    }
    if (results[5].length > 0 &&
        (!objectMgr.loginMgr.isDesktop) &&
        (Config().enableRedPacket)) {
      //檢查紅包
      groupTabOptions.add(
        ChatInfoModel(
          tabType: ChatInfoTabOption.redPacket.tabType,
          stringKey: "redPacketTab",
        ),
      );
    }
    tabController = TabController(
      length: groupTabOptions.length,
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

  //檢查該群組是否有媒體
  Future<List> checkMediaExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND (typ = ? OR typ = ? OR typ = ? OR typ = ?) AND deleted != 1 AND expire_time == 0 AND ref_typ == 0',
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

  //檢查該群組是否有檔案
  Future<List> checkFileExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ? AND ref_typ == 0',
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

  //檢查該群組是否有音訊
  Future<List> checkVoiceExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND (typ = ?) AND ref_typ == 0',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        messageTypeVoice,
      ],
      'DESC',
      1,
    );
    List<Message> mList = tempList.map((e) => Message()..init(e)).toList();

    mList = mList
        .where((element) => !element.isDeleted && !element.isExpired)
        .toList();
    return mList;
  }

  //檢查該群組是否有連結
  Future<List> checkLinkExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ? AND ref_typ == 0',
      [chat.value!.id, chat.value!.hide_chat_msg_idx, messageTypeLink],
      'DESC',
      1,
    );

    return tempList;
  }

  //檢查該群組是否有紅包
  Future<List> checkRedPacketExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ? AND ref_typ == 0',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        messageTypeSendRed,
      ],
      null,
      null,
    );

    return tempList;
  }

  //檢查該群組是否有任務
  Future<List> checkTaskExist() async {
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND typ = ? AND deleted != 1 AND expire_time == 0 AND ref_typ == 0',
      [
        chat.value!.id,
        chat.value!.hide_chat_msg_idx,
        chat.value!.msg_idx + 1,
        messageTypeTaskCreated,
      ],
      'DESC',
      1,
    );

    return tempList;
  }

  double scrollTabPinned = 320.0;
  double scrollTabPinnedNoProfile = 260.0;

  //滑動將tab置頂
  scrollToTabPinned() {
    double pinnedHeight = calPinnedHeight(scrollController.position.pixels);
    if (scrollTabColors.value == 0) {
      scrollController.animateTo(
        pinnedHeight,
        curve: Curves.linear,
        duration:
            Duration(milliseconds: objectMgr.loginMgr.isDesktop ? 50 : 200),
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
  double getTabYPos(key) {
    RenderBox renderBox = key.currentContext.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    return offset.dy;
  }

  getGroupInfo(int groupId) async {
    // sharedDataManager.setGid(groupId);
    isLoading.value = true;
    group.value = await objectMgr.myGroupMgr.getLocalGroup(groupId);
    chat.value = await objectMgr.chatMgr.getGroupChatById(groupId);
    autoDeleteIntervalEnable = chat.value?.autoDeleteEnabled ?? false;
    isLoading.value = false;

    if (group.value != null) {
      updateValues();
    }

    if (!chat.value!.isValid) {
      editEnable.value = false;
    }

    loadGroupInfo(groupId);
  }

  @override
  void onClose() {
    objectMgr.myGroupMgr
        .off(MyGroupMgr.eventGroupInfoUpdated, eventGroupInfoUpdated);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBChat.tableName}", _onChatReplace);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.onlineMgr.off(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.chatMgr.off(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    if (group.value?.isTmpGroup == true) {
      objectMgr.myGroupMgr
          .off(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    }
    objectMgr.chatMgr.off(CallMgr.eventTopFloating, _onTopFloatingUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);
    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;

    VolumePlayerService.sharedInstance.stopPlayer();
    VolumePlayerService.sharedInstance.resetPlayer();

    scrollController.dispose();
    super.onClose();
  }

  void _onTopFloatingUpdate(Object sender, Object type, Object? data) {
    if (data is double) {
      downOffset.value = data;
      update();
    }
  }

  onAudioPlayingListener(bool isPlaying) {
    onAudioPlaying.value = isPlaying;
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (data is List<User>) {
      for (var dataUser in data) {
        final existingIndex =
            groupMemberListData.indexWhere((user) => user.uid == dataUser.uid);

        if (existingIndex != -1) {
          groupMemberListData[existingIndex].lastOnline = dataUser.lastOnline;
        }
      }
    }
  }

  void _onChatUpdate(Object sender, Object type, Object? data) {
    if (data is Chat && chat.value?.chat_id == data.chat_id) {
      if (!data.isValid) {
        editEnable.value = false;
        isOwner.value = false;
        isAdmin.value = false;
        groupMemberListData.clear();
        addMemberEnable.value = false;
        screenshotEnable = false;
        updateFlexBarHeight();
      }

      if (data.autoDeleteEnabled) {
        autoDeleteIntervalEnable = true;
      } else {
        autoDeleteIntervalEnable = false;
      }
    }
  }

  void _onChatReplace(Object sender, Object type, Object? data) {
    if (data is Chat && chat.value?.chat_id == data.chat_id) {
      if (data.autoDeleteEnabled) {
        autoDeleteIntervalEnable = true;
      } else {
        autoDeleteIntervalEnable = false;
      }
      chat.value = data;
    }
  }

  void _onGroupIsExpired(_, __, Object? data) {
    if (data != null &&
        data is Map<String, dynamic> &&
        data['id'] == group.value?.id) {
      if (data['isExpiring']) {
        _startExpireCountDownTimer(data['timestamp']);
      } else {
        remainingTime.value = '';
        expireCountDownTimer?.cancel();
        expireCountDownTimer = null;
        isGroupExpireSoon.value = false;
      }
    }
  }

  _startExpireCountDownTimer(int timestamp) {
    if (expireCountDownTimer != null) return;

    expireCountDownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      DateTime targetTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
      Duration leftTime = targetTime.difference(DateTime.now());
      if (leftTime.isNegative) {
        remainingTime.value = '00:00:00';
        expireCountDownTimer!.cancel();
        expireCountDownTimer = null;
      } else {
        remainingTime.value = countDownDuration(leftTime);
      }
      isGroupExpireSoon.value = true;
    });
  }

  void eventGroupInfoUpdated(Object sender, Object event, Object? data) async {
    if (data != null && data is Group && data.id == group.value?.id) {
      Group newGroup = data;
      group.update((val) {
        val?.updateValue(newGroup.toJson());
      });
      updateValues();
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

  /// ================================ 逻辑函数 =================================

  /// 远程获取 group 资料
  void loadGroupInfo(int grpId) async {
    try {
      final Group? grp =
          await objectMgr.myGroupMgr.getGroupByRemote(grpId, notify: true);
      if (grp != null) {
        grp.members.sort((a, b) => a['user_id'].compareTo(b['user_id']));
        group.value = grp;
        updateValues();
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
    getEditAndAddPermission();
  }

  getEditAndAddPermission() {
    if (group.value != null && chat.value!.isValid) {
      if (!isOwner.value && !isAdmin.value) {
        editEnable.value = false;
        addMemberEnable.value = GroupPermissionMap.groupPermissionAddMembers
            .isAllow(group.value!.permission);
        forwardEnable.value = GroupPermissionMap.groupPermissionForwardMessages
            .isAllow(group.value!.permission);
      } else {
        forwardEnable.value = true;
        editEnable.value = true;
      }
      screenshotEnable = GroupPermissionMap.groupPermissionScreenshot
          .isAllow(group.value!.permission);
    }

    if (!chat.value!.isValid) {
      addMemberEnable.value = false;
    }
  }

  void updateValues() async {
    if (group.value == null) return;
    adminList.value = group.value!.admins.map<int>((e) => e as int).toList();
    isOwner.value = objectMgr.userMgr.isMe(group.value!.owner);
    isAdmin.value = adminList.isNotEmpty &&
        adminList.contains(objectMgr.userMgr.mainUser.uid);
    if (chat.value!.isValid) {
      loadMembers();
      if (group.value!.isTmpGroup) {
        if (isLessThan24hrsUTC(group.value!.expireTime)) {
          isGroupExpireSoon.value = true;
          _startExpireCountDownTimer(group.value!.expireTime);
        }
      }
    }
    getEditAndAddPermission();
    updateFlexBarHeight();
  }

  /// 加载 群成员基础信息
  void loadMembers() {
    List<User> tempUserList = group.value!.members.map<User>((e) {
      User user = User.fromJson({
        'uid': e['user_id'],
        'nickname': notBlank(e['group_alias'])
            ? e['group_alias']
            : objectMgr.userMgr
                .getUserTitle(objectMgr.userMgr.getUserById(e['user_id'])),
        'profile_pic': e['icon'],
        'last_online': e['last_online'],
        'deleted_at': e['delete_time'],
      });
      return user;
    }).toList();
    processGroupCallInfo();
    groupMemberListData.value = sortMemberList(tempUserList);
  }

  processGroupCallInfo() {
    if (group.value != null) {
      if (group.value!.members.isNotEmpty) {
        for (var member in group.value!.members) {
          User? user = objectMgr.userMgr.getUserById(member["user_id"]);
          if (user != null) {
            member["user_name"] = objectMgr.userMgr.getUserTitle(user);
          }
        }
      }
    }
    sharedDataManager.saveGroupInfo(group.toJson());
  }

  List<User> sortMemberList(List<User> memberList) {
    if (memberList.isEmpty) return [];

    List<User> tempList = [];
    User? me = memberList
        .firstWhereOrNull((element) => objectMgr.userMgr.isMe(element.uid));
    if (me != null) {
      myGroupAlias.value = me.nickname;
      tempList.insert(
        0,
        memberList.firstWhere((element) => objectMgr.userMgr.isMe(element.uid)),
      );
    }

    /// 检测 群主是否为当前账号
    if (!isOwner.value && memberList.isNotEmpty) {
      User? owner =
          memberList.firstWhereOrNull((user) => user.uid == group.value?.owner);
      if (owner != null) {
        tempList.add(owner);
      }
    }

    /// 排序 管理员并添加
    List<User> adminTempList = memberList
        .where(
          (User e) =>
              adminList.contains(e.uid) && !objectMgr.userMgr.isMe(e.uid),
        )
        .toList();

    adminTempList.sort((User a, User b) {
      return a.lastOnline < b.lastOnline ? 1 : -1;
    });
    tempList.addAll(adminTempList);

    /// 排序普通成员 并添加
    List<User> lastOnlineUserList = memberList
        .where(
          (User e) =>
              !adminList.contains(e.uid) &&
              e.uid != group.value?.owner &&
              !objectMgr.userMgr.isMe(e.uid),
        )
        .toList();

    lastOnlineUserList.sort((User a, User b) {
      return a.lastOnline < b.lastOnline ? 1 : -1;
    });
    tempList.addAll(lastOnlineUserList);

    return tempList;
  }

  /// 问题是删除过后的chat delete_time > 0, 在获取列表的时候后端chat是delete_time > 0是会被隐藏的
  Future<void> onChatTap(BuildContext context, {bool searching = false}) async {
    Chat? chat =
        await objectMgr.chatMgr.getGroupChatById(groupId, remote: true);
    if (chat != null) {
      if (Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
        Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
        Get.find<CustomInputController>(tag: chat.id.toString())
            .inputFocusNode
            .requestFocus();
        Get.find<GroupChatController>(tag: chat.id.toString())
            .isSearching(searching);
      } else {
        if (objectMgr.loginMgr.isDesktop) {
          Routes.toChat(chat: chat);
        } else {
          Routes.toChat(
            chat: chat,
            searching: searching,
            popCurrent: true,
          );
        }
      }
    }
  }

  // 設置靜音
  setMute(stringValue) {
    getMuteDuration(stringValue);
  }

  /// 通知按钮点击回调
  void onNotificationTap(BuildContext context) async {
    isFirstTime.value = false;
    await vibrate();
    bool isJoined = await objectMgr.myGroupMgr
        .isGroupMember(group.value!.id, objectMgr.userMgr.mainUser.id);
    if (!isJoined) {
      Toast.showToast(localized(youAreNoLongerInThisGroup));
      return;
    }

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
      desktopGeneralDialog(
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

  void onForwardMessageMenu(BuildContext context, dynamic msg) {
    if (objectMgr.loginMgr.isDesktop) {
      desktopGeneralDialog(
        context,
        widgetChild: DesktopForwardContainer(
          chat: chat.value!,
          fromChatInfo: true,
          forwardMsg: [msg],
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
            forwardMsg: [msg],
          );
        },
      );
    }
  }

  void getDeleteOptionsList(dynamic message) {
    for (ToolOptionModel model in deleteOptions) {
      model.isShow = true;
    }
    if (isOwner.value) {
      if (message is Message) {
        if (!deleteOptions[0].isShow) return;
        if (objectMgr.userMgr.isMe(message.send_id)) {
          deleteOptions[0].isShow = objectMgr.userMgr.isMe(message.send_id) &&
              DateTime.now().millisecondsSinceEpoch -
                      (message.create_time * 1000) <
                  const Duration(days: 1).inMilliseconds;
        }
      } else if (message is AlbumDetailBean) {
        Message msg = message.currentMessage;
        if (!deleteOptions[0].isShow) return;
        if (objectMgr.userMgr.isMe(msg.send_id)) {
          deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
              DateTime.now().millisecondsSinceEpoch - (msg.create_time * 1000) <
                  const Duration(days: 1).inMilliseconds;
        }
      } else {
        throw "检查代码逻辑";
      }
    } else if (isAdmin.value) {
      if (message is Message) {
        if (!deleteOptions[0].isShow) return;
        if (objectMgr.userMgr.isMe(message.send_id)) {
          deleteOptions[0].isShow = objectMgr.userMgr.isMe(message.send_id) &&
              DateTime.now().millisecondsSinceEpoch -
                      (message.create_time * 1000) <
                  const Duration(days: 1).inMilliseconds;
        } else if (group.value != null &&
            group.value!.owner == message.send_id) {
          deleteOptions[0].isShow = false;
        }
      } else if (message is AlbumDetailBean) {
        Message msg = message.currentMessage;
        if (!deleteOptions[0].isShow) return;
        if (objectMgr.userMgr.isMe(msg.send_id)) {
          deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
              DateTime.now().millisecondsSinceEpoch - (msg.create_time * 1000) <
                  const Duration(days: 1).inMilliseconds;
        } else if (group.value != null && group.value!.owner == msg.send_id) {
          deleteOptions[0].isShow = false;
        }
      }
    } else {
      if (message is Message) {
        if (!deleteOptions[0].isShow) return;
        deleteOptions[0].isShow = objectMgr.userMgr.isMe(message.send_id) &&
            DateTime.now().millisecondsSinceEpoch -
                    (message.create_time * 1000) <
                const Duration(days: 1).inMilliseconds;
      } else if (message is AlbumDetailBean) {
        Message msg = message.currentMessage;
        if (!deleteOptions[0].isShow) return;
        deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
            DateTime.now().millisecondsSinceEpoch - (msg.create_time * 1000) <
                const Duration(days: 1).inMilliseconds;
      }
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

      if (isOwner.value) {
        for (var message in selectedMessageList) {
          if (message is Message) {
            if (!deleteOptions[0].isShow) continue;
            if (objectMgr.userMgr.isMe(message.send_id)) {
              deleteOptions[0].isShow =
                  objectMgr.userMgr.isMe(message.send_id) &&
                      DateTime.now().millisecondsSinceEpoch -
                              (message.create_time * 1000) <
                          const Duration(days: 1).inMilliseconds;
            }
          } else if (message is AlbumDetailBean) {
            Message msg = message.currentMessage;
            if (!deleteOptions[0].isShow) continue;
            if (objectMgr.userMgr.isMe(msg.send_id)) {
              deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
                  DateTime.now().millisecondsSinceEpoch -
                          (msg.create_time * 1000) <
                      const Duration(days: 1).inMilliseconds;
            }
          } else {
            throw "检查代码逻辑";
          }
        }
      } else if (isAdmin.value) {
        for (var message in selectedMessageList) {
          if (message is Message) {
            if (!deleteOptions[0].isShow) continue;
            if (objectMgr.userMgr.isMe(message.send_id)) {
              deleteOptions[0].isShow =
                  objectMgr.userMgr.isMe(message.send_id) &&
                      DateTime.now().millisecondsSinceEpoch -
                              (message.create_time * 1000) <
                          const Duration(days: 1).inMilliseconds;
            } else if (group.value != null &&
                group.value!.owner == message.send_id) {
              deleteOptions[0].isShow = false;
            }
          } else if (message is AlbumDetailBean) {
            Message msg = message.currentMessage;
            if (!deleteOptions[0].isShow) continue;
            if (objectMgr.userMgr.isMe(msg.send_id)) {
              deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
                  DateTime.now().millisecondsSinceEpoch -
                          (msg.create_time * 1000) <
                      const Duration(days: 1).inMilliseconds;
            } else if (group.value != null &&
                group.value!.owner == msg.send_id) {
              deleteOptions[0].isShow = false;
            }
          }
        }
      } else {
        for (var message in selectedMessageList) {
          if (message is Message) {
            if (!deleteOptions[0].isShow) continue;
            deleteOptions[0].isShow = objectMgr.userMgr.isMe(message.send_id) &&
                DateTime.now().millisecondsSinceEpoch -
                        (message.create_time * 1000) <
                    const Duration(days: 1).inMilliseconds;
          } else if (message is AlbumDetailBean) {
            Message msg = message.currentMessage;
            if (!deleteOptions[0].isShow) continue;
            deleteOptions[0].isShow = objectMgr.userMgr.isMe(msg.send_id) &&
                DateTime.now().millisecondsSinceEpoch -
                        (msg.create_time * 1000) <
                    const Duration(days: 1).inMilliseconds;
          }
        }
      }

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
                      color: deleteOptions[index].color ?? themeColor,
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

  void exitInfoView() {
    if (isDesktop) {
      Get.back(id: 1);
      Get.find<CustomInputController>(tag: chat.value?.chat_id.toString())
          .inputFocusNode
          .requestFocus();
    } else {
      Get.back();
    }
  }

  void onDeleteOptionTap(
    BuildContext context,
    String optionTitle, {
    dynamic msg,
  }) {
    floatWindowOffset = null;
    floatWindowOverlay?.remove();
    floatWindowOverlay = null;

    switch (optionTitle) {
      case 'deleteForEveryone':
        onDeletePrompt(context, isAll: true, msg: msg);
        break;
      case 'deleteForMe':
        onDeletePrompt(context, isAll: false, msg: msg);
        break;
      default:
        break;
    }
  }

  onDeletePrompt(
    BuildContext context, {
    bool isAll = false,
    dynamic msg,
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
                    chatInfoThisMessageWillBeDeletedFromYourMessageHistory,
                  ),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonYes),
          cancelText: localized(buttonNo),
          confirmCallback: () async {
            await deleteMessages(
              msg == null ? selectedMessageList : [msg],
              chatId: chat.value!.id,
              isAll: isAll,
            );
            ImBottomToast(
              Get.context!,
              title: localized(toastDeleteSuccess),
              icon: ImBottomNotifType.success,
            );
          },
        );
      },
    ).whenComplete(() {
      onMoreCancel();
    });
  }

  Future<void> deleteMessages(
    List<dynamic> messages, {
    int? chatId,
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    List<Message> floatingPIPCheckMessages = [];

    // filter fake message
    for (var msg in messages) {
      if (msg.typ == messageTypeNewAlbum ||
          msg.typ == messageTypeReel ||
          msg.typ == messageTypeVideo) {
        floatingPIPCheckMessages.add(msg);
      }

      if (msg is Message) {
        if (msg.message_id == 0 && !msg.isSendOk) {
          objectMgr.chatMgr.mySendMgr.remove(msg);
        } else {
          remoteMessages.add(msg);
          remoteMessageIds.add(msg.message_id);
        }
      } else if (msg is AlbumDetailBean) {
        Message? bean = msg.currentMessage;
        if (bean != null) {
          if (bean.message_id == 0 && !bean.isSendOk) {
            objectMgr.chatMgr.mySendMgr.remove(bean);
          } else {
            remoteMessages.add(bean);
            remoteMessageIds.add(bean.message_id);
          }
        } else {
          pdebug("前面逻辑出了问题");
          throw "检查代码";
        }
      }
    }

    if (floatingPIPCheckMessages.isNotEmpty) {
      objectMgr.tencentVideoMgr
          .checkForFloatingPIPClosure(floatingPIPCheckMessages);
    }

    if (remoteMessages.isNotEmpty) {
      chat_api.deleteMsg(
        chatId ?? remoteMessages.first.chat_id,
        remoteMessageIds,
        isAll: isAll,
      );

      for (var message in remoteMessages) {
        objectMgr.chatMgr.localDelMessage(message);
      }
    }
  }

  /// ============================ 群聊操作逻辑 ==================================
  void onLeaveGroup() async {
    if (group.value == null) return;

    if (isOwner.value) {
      Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
      List<User> userList = groupMemberListData.toList();
      userList.removeWhere((element) => objectMgr.userMgr.isMe(element.id));
      Get.toNamed(
        RouteName.groupAddMember,
        arguments: {'group': group.value, 'memberList': userList},
      );
    } else {
      try {
        await objectMgr.myGroupMgr.leaveGroup(group.value!.uid);
        objectMgr.myGroupMgr.leaveGroupPrefix = 'You have left';
        objectMgr.myGroupMgr.leaveGroupName = group.value!.name;
        Toast.showToast(localized(groupLeaveGroupSuccessful));
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
      }

      if (objectMgr.loginMgr.isDesktop) {
        Get.back(id: 1);
      } else if (group.value?.roomType == GroupType.TMP.num) {
        Get.offAllNamed(RouteName.home);
      } else {
        Get.back(id: null);
      }
    }
  }

  ownerSearch(String param) {
    List<User> userList = groupMemberListData.toList();
    userList = userList
        .where(
          (element) =>
              element.nickname.toLowerCase().contains(param.toLowerCase()),
        )
        .toList();
    return userList;
  }

  void onDismissGroup() {
    if (group.value == null) return;
    objectMgr.myGroupMgr.onDismissGroup(group.value!.uid);
    Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
  }

  void onAddMemberTap() async {
    if (group.value == null) return;

    bool isJoined = await objectMgr.myGroupMgr
        .isGroupMember(group.value!.id, objectMgr.userMgr.mainUser.id);
    if (!isJoined) {
      Toast.showToast(localized(youAreNoLongerInThisGroup));
      return;
    }

    if (group.value!.members.length >= 200) {
      Toast.showToast('群成员限制在200个');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      routeSettings: RouteSettings(arguments: {'group': group.value, 'chat': chat.value}),
      builder: (context) {
        Get.lazyPut(() => GroupAddMemberController());
        return const GroupAddMemberView();
      },
    ).whenComplete(() => Get.findAndDelete<GroupAddMemberController>());

    // Get.toNamed(
    //   RouteName.groupAddMember,
    //   arguments: {'group': group.value},
    //   id: objectMgr.loginMgr.isDesktop ? 1 : null,
    // );
  }

  void onMemberClicked(int userId) async {
    bool isJoined = await objectMgr.myGroupMgr
        .isGroupMember(group.value!.id, objectMgr.userMgr.mainUser.id);
    if (!isJoined) {
      Toast.showToast(localized(youAreNoLongerInThisGroup));
      return;
    }
    if (!objectMgr.userMgr.isMe(userId)) {
      /// avoid re-initialize tabController when user click too fast
      await Future.delayed(const Duration(milliseconds: 200), () {
        Chat? chat = objectMgr.chatMgr.getChatByUserId(userId);
        if (chat != null) {
          Get.back();
          Get.toNamed(
            RouteName.chatInfo,
            arguments: {
              "uid": userId,
            },
            id: objectMgr.loginMgr.isDesktop ? 1 : null,
          );
        } else {
          Get.toNamed(
            RouteName.chatInfo,
            arguments: {
              "uid": userId,
            },
            id: objectMgr.loginMgr.isDesktop ? 1 : null,
          );
        }
      });
    }
  }

  /// ========================= Tab部分操作逻辑 ==================================
  onMemberItemLongPress(
    BuildContext context,
    RenderBox renderBox,
    int index, {
    required Widget target,
  }) {
    final user = groupMemberListData[index];
    List<ToolOptionModel> tempList = [];
    if (isOwner.value) {
      if (adminList.contains(user.uid)) {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'promoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      } else {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'demoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      }
    } else if (isAdmin.value) {
      tempList.add(groupAdminMemberOptions.last);
    }

    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
    } else {
      /// 判断位子坐标是否可以存放选项
      floatWindowRender = renderBox;
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);
      var left = floatWindowOffset!.dx;
      var top = floatWindowOffset!.dy;
      var targetAnchor = Alignment.bottomLeft;
      var followerAnchor = Alignment.topLeft;

      if (floatWindowOffset!.dy + (40.0 * tempList.length) >=
          MediaQuery.of(context).size.height) {
        targetAnchor = Alignment.topLeft;
        followerAnchor = Alignment.bottomLeft;
      } else {
        targetAnchor = Alignment.bottomLeft;
        followerAnchor = Alignment.topLeft;
      }

      floatWindowOverlay = createOverlayEntry(
        context,
        target,
        Container(
          width: 220,
          margin: EdgeInsets.only(
            left: 10.0,
            bottom: followerAnchor == Alignment.bottomLeft ? 20 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: tempList.length,
            itemBuilder: (context, optionId) {
              if (!tempList[optionId].isShow) return const SizedBox();
              return GestureDetector(
                onTap: () => onAdminMemberOptionTap(
                  tempList[optionId].optionType,
                  groupMemberListData[index],
                ),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorBorder,
                        width: optionId == tempList.length - 1 ? 0.0 : 1.0,
                      ),
                    ),
                  ),
                  child: Text(
                    tempList[optionId].title,
                    style: TextStyle(
                      color: tempList[optionId].color ?? themeColor,
                      fontSize: 14.0.w,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        layerLink,
        left: left,
        right: null,
        top: top,
        bottom: null,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
        },
      );
    }
  }

  bool onMemberItemLongPressMenuFilter(int index) {
    /// 如果是普通成员 什么都不能做
    if (!isOwner.value && !isAdmin.value) return true;
    final user = groupMemberListData[index];

    /// 如果 管理员长按群主 || 管理员 长按 管理员
    if (isAdmin.value &&
        (user.uid == group.value!.owner || adminList.contains(user.uid))) {
      return true;
    }

    return false;
  }

  Widget onMemberItemLongPressMenu(int index) {
    final user = groupMemberListData[index];
    List<ToolOptionModel> tempList = [];
    if (isOwner.value) {
      if (adminList.contains(user.uid)) {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'promoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      } else {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'demoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      }
    } else if (isAdmin.value) {
      tempList.add(groupAdminMemberOptions.last);
    }

    List<ToolOptionModel> tempListShow = [];
    for (ToolOptionModel model in tempList) {
      if (model.isShow) {
        tempListShow.add(model);
      }
    }

    Widget menu = MemberViewMenu(
      tempList: tempListShow,
      itemIndex: index,
    );
    return menu;
  }

  double onMemberItemLongPressMenuHeight(int index) {
    final user = groupMemberListData[index];
    List<ToolOptionModel> tempList = [];
    if (isOwner.value) {
      if (adminList.contains(user.uid)) {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'promoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      } else {
        tempList = groupAdminMemberOptions.map((e) {
          if (e.optionType == 'demoteAdmin') {
            e.isShow = false;
          } else {
            e.isShow = true;
          }
          return e;
        }).toList();
      }
    } else if (isAdmin.value) {
      tempList.add(groupAdminMemberOptions.last);
    }

    double totalHeight = 44.0 * tempList.length;

    return totalHeight;
  }

  onAdminMemberOptionTap(String title, User user) async {
    EasyDebounce.debounce(
        'chat_pop_menu_member_click', const Duration(milliseconds: 200),
        () async {
      if (group.value == null) return;
      switch (title) {
        case 'transferOwnership':
          await objectMgr.myGroupMgr
              .transferOwnership(group.value!.id, user.id);
          break;
        case 'promoteAdmin':
          final success =
              await objectMgr.myGroupMgr.addAdmin(group.value!.id, [user.id]);
          if (success) {
            adminList.add(user.id);
          }
          break;
        case 'demoteAdmin':
          final success = await objectMgr.myGroupMgr
              .removeAdmin(group.value!.id, [user.id]);
          if (success) {
            adminList.remove(user.id);
          }
          break;
        case 'deleteMember':
          objectMgr.myGroupMgr.kickMembers(group.value!.id, [user.id]);
          break;
        default:
          break;
      }

      final inputController =
          Get.find<CustomInputController>(tag: chat.value?.id.toString());
      inputController.chatController.resetPopupWindow();

      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
    });
  }

  updateFlexBarHeight() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (childKey.currentContext != null) {
        RenderObject? renderObject =
            childKey.currentContext!.findRenderObject();
        if (renderObject is RenderBox) {
          final height = renderObject.size.height;
          flexAppbarHeight.value =
              height + (objectMgr.loginMgr.isDesktop ? 60.w : 40.w);
        }
      }
    });
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
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isMute.value
                      ? 'assets/svgs/chat_info_unmute.svg'
                      : 'assets/svgs/chat_info_mute.svg',
                  width: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
                  height: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
                  color: chat.value!.isValid
                      ? themeColor
                      : themeColor.withOpacity(0.3),
                ),
                SizedBox(height: objectMgr.loginMgr.isDesktop ? 2 : 2.w),
                Text(
                  isMute.value ? localized(unmute) : localized(mute),
                  style: jxTextStyle.textStyle12(
                    color: chat.value!.isValid
                        ? themeColor
                        : themeColor.withOpacity(0.3),
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
                    ? 220
                    : 220,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              objectMgr.loginMgr.isDesktop ? 10 : 10.0.w,
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
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 321 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
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
    vibrate();
    isFirstTime.value = true;
    bool isScreenshotEnabled = GroupPermissionMap.groupPermissionScreenshot
        .isAllow(group.value!.permission);
    List<ToolOptionModel> optionModelList = [
      ToolOptionModel(
        title: localized(inviteGroup),
        optionType: MorePopupOption.inviteGroup.optionType,
        isShow: !chat.value!.isDisband,
        tabBelonging: null,
        largeDivider: true,
        imageUrl: 'assets/svgs/chat_info_item_forward.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      ToolOptionModel(
        title: localized(autoTranslate),
        optionType: MorePopupOption.aiRealTimeTranslate.optionType,
        isShow: true,
        tabBelonging: 4,
        imageUrl: 'assets/svgs/chat_info_item_translate.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      ToolOptionModel(
        title:
            "${localized(screenshotNotification)}/${localized(isScreenshotEnabled ? turnOn : turnOff)}",
        optionType: MorePopupOption.screenshotNotification.optionType,
        isShow: !chat.value!.isDisband,
        tabBelonging: 4,
        imageUrl: 'assets/svgs/chat_info_item_screenshot.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      ToolOptionModel(
        title: localized(
          autoDeleteIntervalEnable ? setAntoDeleteTime : openDeleteTime,
        ),
        optionType: MorePopupOption.autoDeleteMessage.optionType,
        isShow: chat.value!.isValid,
        tabBelonging: null,
        trailingText: getAutoDeleteTrailingText(
          autoDeleteIntervalEnable,
          chat.value?.autoDeleteInterval,
        ),
        imageUrl: autoDeleteIntervalEnable
            ? null
            : 'assets/svgs/chat_info_item_auto_delete.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      // ToolOptionModel(
      //   title: localized(groupManagement),
      //   optionType: MorePopupOption.groupManagement.optionType,
      //   isShow: chat.value!.isValid,
      //   tabBelonging: null,
      // ),
      ToolOptionModel(
        title: localized(clearChatHistory),
        optionType: MorePopupOption.clearChatHistory.optionType,
        isShow: !chat.value!.isDisband,
        largeDivider: !isOwner.value,
        tabBelonging: null,
        imageUrl: 'assets/svgs/chat_info_item_clear_record.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      ToolOptionModel(
        title: localized(settingEncryptedConversation),
        optionType: MorePopupOption.encryptionSettings.optionType,
        isShow: isOwner.value,
        tabBelonging: null,
        largeDivider: true,
        imageUrl: (chat.value?.isEncrypted ?? false) ? null : 'assets/svgs/chat_info_item_encryption.svg',
        trailingText: (chat.value?.isEncrypted ?? false) ? localized(settingEnabled) : null,
        trailingTextStyle: (chat.value?.isEncrypted ?? false) ? jxTextStyle.textStyle17(color: Colors.black) : null,
      ),
      // ToolOptionModel(
      //   title: localized(permissions),
      //   optionType: MorePopupOption.permissions.optionType,
      //   isShow: chat.value!.isValid,
      //   tabBelonging: null,
      // ),
      ToolOptionModel(
        title: localized(deleteGroupChat),
        optionType: MorePopupOption.deleteChatHistory.optionType,
        isShow: true,
        tabBelonging: null,
        color: colorRed,
        imageUrl: 'assets/svgs/chat_info_item_delete.svg',
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(
          color: colorRed,
        ),
      ),
      ToolOptionModel(
        title: localized(leaveGroup),
        optionType: MorePopupOption.leaveGroup.optionType,
        isShow: chat.value!.isValid,
        tabBelonging: null,
        color: colorRed,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(
          color: colorRed,
        ),
        imageUrl: 'assets/svgs/chat_info_item_leave.svg',
      ),
      ToolOptionModel(
        title: localized(disbandGroup),
        optionType: MorePopupOption.disbandGroup.optionType,
        isShow: chat.value!.isValid,
        tabBelonging: null,
        color: colorRed,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(
          color: colorRed,
        ),
        imageUrl: 'assets/svgs/chat_info_item_disband.svg',
      ),
    ];

    if (chat.value!.isValid) {
      if (!isOwner.value) {
        if (!isAdmin.value) {
          optionModelList.removeWhere(
            (e) => e.optionType == MorePopupOption.autoDeleteMessage.optionType,
          );
        }
        optionModelList.removeWhere(
          (e) =>
              e.optionType == MorePopupOption.groupManagement.optionType ||
              e.optionType == MorePopupOption.permissions.optionType ||
              e.optionType == MorePopupOption.disbandGroup.optionType ||
              e.optionType == MorePopupOption.screenshotNotification.optionType,
        );
      }
    } else {
      optionModelList.removeWhere(
        (e) =>
            e.optionType == MorePopupOption.groupManagement.optionType ||
            e.optionType == MorePopupOption.permissions.optionType ||
            e.optionType == MorePopupOption.autoDeleteMessage.optionType,
      );

      if (chat.value == null) {
        optionModelList.removeWhere(
          (e) =>
              e.optionType == MorePopupOption.clearChatHistory.optionType ||
              e.optionType == MorePopupOption.deleteChatHistory.optionType,
        );
      }
    }

    if (!isWalletEnable()) {
      optionModelList.removeWhere(
        (e) => e.optionType == MorePopupOption.groupManagement.optionType,
      );
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
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  themeColor,
                  BlendMode.srcIn,
                ),
                child: Lottie.asset(
                  'assets/lottie/animate_more_icon.json',
                  width: objectMgr.loginMgr.isDesktop ? 22 : 20.w,
                  height: objectMgr.loginMgr.isDesktop ? 22 : 20.w,
                  repeat: false,
                ),
              ),
              SizedBox(height: objectMgr.loginMgr.isDesktop ? 2 : 0.w),
              Text(
                localized(searchMore),
                style: jxTextStyle.textStyle12(
                  color: themeColor,
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
                    ? 220
                    : 220,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              objectMgr.loginMgr.isDesktop ? 10 : 10.0.w,
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

  Future<void> getMuteDuration(String? value) async {
    DateTime currentDateTime = DateTime.now();
    DateTime expTime = currentDateTime;
    switch (value) {
      case 'muteForever':
        muteChat(-1, mType: MuteDuration.forever);
        // Get.back();
        break;
      case 'oneHour':
        expTime = currentDateTime.add(const Duration(hours: 1));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.hour,
        );
        // Get.back();
        break;
      case 'eighthHours':
        expTime = currentDateTime.add(const Duration(hours: 8));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.eighthHours,
        );
        // Get.back();
        break;
      case 'oneDay':
        expTime = currentDateTime.add(const Duration(days: 1));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.day,
        );
        // Get.back();
        break;
      case 'sevenDays':
        expTime = currentDateTime.add(const Duration(days: 7));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.sevenDays,
        );
        break;
      case 'oneWeek':
        expTime = currentDateTime.add(const Duration(days: 7));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.week,
        );
        // Get.back();
        break;
      case 'oneMonth':
        expTime = currentDateTime.add(const Duration(days: 30));
        muteChat(
          expTime.millisecondsSinceEpoch ~/ 1000,
          mType: MuteDuration.month,
        );
        // Get.back();
        break;
      case 'muteUntil':

        /// Close mute popup selection
        // Get.back();

        MoreVertController controller;
        if (Get.isRegistered<MoreVertController>()) {
          controller = Get.find<MoreVertController>();
        } else {
          controller = Get.put(MoreVertController());
        }
        controller.dayScrollController = FixedExtentScrollController();
        controller.monthScrollController = FixedExtentScrollController();
        controller.yearScrollController = FixedExtentScrollController();
        controller.hoursScrollController = FixedExtentScrollController();
        controller.minScrollController = FixedExtentScrollController();
        final result = await Get.bottomSheet(
          const NewMuteUntilActionSheet(),
        );
        if (result != null) {
          muteChat(result, mType: MuteDuration.custom);
        }
        break;
    }
  }

  void muteChat(int timeStamp, {MuteDuration? mType}) async {
    if (chat.value != null) {
      objectMgr.chatMgr
          .onChatMute(chat.value!, expireTime: timeStamp, mType: mType);
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }
  }

  bool setScrollable() {
    Locale locale = objectMgr.langMgr.currLocale;
    if (objectMgr.loginMgr.isDesktop || groupTabOptions.length > 1) {
      if (locale.languageCode == "en" && groupTabOptions.length > 5) {
        return true;
      }
      return false;
    } else {
      return true;
    }
  }

  String getMuteIcon() {
    String str = isMute.value
        ? isFirstTime.value
            ? 'assets/svgs/chat_info_unmute.svg'
            : 'assets/lottie/animate_bell_off.json'
        : isFirstTime.value
            ? "assets/svgs/chat_info_mute.svg"
            : 'assets/lottie/animate_bell_on.json';
    return str;
  }

  /// 群主
  void ownerLeaveGroup() async {
    if (group.value == null) return;
    Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
    List<User> userList = groupMemberListData.toList();
    userList.removeWhere((element) => objectMgr.userMgr.isMe(element.id));

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectNewGroupOwnerView(
          group: group.value,
          membersList: userList,
        );
      },
    );
  }

  /// 非群主
  void notOwnerLeaveGroup() async {
    if (group.value == null) return;
    try {
      await objectMgr.myGroupMgr.leaveGroup(group.value!.uid);
      objectMgr.myGroupMgr.leaveGroupPrefix = 'You have left';
      objectMgr.myGroupMgr.leaveGroupName = group.value!.name;
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  void setUpItemKey(
    List mList,
    List<TargetWidgetKeyModel> keyList, {
    bool isFromMedia = false,
  }) {
    int mNum = mList.length;
    int kNum = keyList.length;
    if (mNum > kNum) {
      int diff = mNum - kNum;
      for (int i = 0; i < diff; i++) {
        final targetWidgetKey = GlobalKey();
        TargetWidgetKeyModel model = TargetWidgetKeyModel(0, targetWidgetKey);
        keyList.add(model);
      }
    }
  }

  /// 更改自己群里的昵称
  void modifyGroupAlias(String name) async {
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      ImBottomToast(
        Get.context!,
        title: localized(chatInfoPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
      );
      return;
    }
    bool success = await objectMgr.myGroupMgr.setMyGroupAlias(groupId, name);
    if (success) {
      // If is empty then set user default nickname
      if (name == '') {
        name = objectMgr.userMgr.mainUser.nickname;
      }
      myGroupAlias.value = name;

      ImBottomToast(
        Get.context!,
        title: localized(groupAliasUpdateSuccess),
        icon: ImBottomNotifType.success,
      );
    } else {
      ImBottomToast(
        Get.context!,
        title: localized(chatInfoPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
      );
    }
  }
}

class TargetWidgetKeyModel {
  TargetWidgetKeyModel(this.messageId, this.targetWidgetKey);

  final int messageId;
  final GlobalKey targetWidgetKey;
}

class InfoMessage extends Message {}

bool checkIsMute(int timeStamp) {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000 < timeStamp ||
      timeStamp == -1;
}
