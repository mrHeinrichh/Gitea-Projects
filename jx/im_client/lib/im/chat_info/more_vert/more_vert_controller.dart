import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common
    hide ImBottomToast, ImBottomNotifType;
import 'package:intl/intl.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/more_vert/new_mute_until_action_sheet.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/share_link_bottom_sheet.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/auto_delete_message_model.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_dialog.dart';

class MoreVertController extends GetxController
    with MoreVertControllerExtension {
  List<GlobalKey> itemKeys = List.empty(growable: true);
  GlobalKey listKey = GlobalKey(debugLabel: "listKey");

  /// VARIABLES
  late List<ToolOptionModel> optionList;
  RxList<ToolOptionModel> currentList = RxList([]);
  List<ToolOptionModel> antoDeleteSecondaryMenuList = [
    ToolOptionModel(
        title: localized(chatInfoBack),
        optionType: MorePopupOption.back.optionType,
        isShow: true,
        tabBelonging: 5,
        largeDivider: true,
        leftIconUrl: "assets/svgs/chat_info_icon_back.svg",
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle()),
    ToolOptionModel(
        title: localized(timeOneDay),
        optionType: SecondaryMenuOption.oneDay.optionType,
        isShow: true,
        tabBelonging: 5,
        duration: SecondaryMenuOption.oneDay.duration,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle()),
    ToolOptionModel(
        title: localized(chatInfo1Week),
        optionType: SecondaryMenuOption.oneWeek.optionType,
        isShow: true,
        tabBelonging: 5,
        duration: SecondaryMenuOption.oneWeek.duration,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle()),
    ToolOptionModel(
        title: localized(chatInfo1Month),
        optionType: SecondaryMenuOption.oneMonth.optionType,
        isShow: true,
        tabBelonging: 5,
        duration: SecondaryMenuOption.oneMonth.duration,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle()),
    ToolOptionModel(
        title: localized(secondaryMenuOther),
        optionType: SecondaryMenuOption.other.optionType,
        isShow: true,
        tabBelonging: 5,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle()),
    ToolOptionModel(
        title: localized(secondaryMenuDeactivate),
        optionType: SecondaryMenuOption.deactivate.optionType,
        isShow: false,
        tabBelonging: 5,
        titleTextStyle:
            jxTextStyle.chatInfoSecondaryMenuTitleStyle(color: Colors.red)),
    ToolOptionModel(
        title: localized(secondaryMenuTip),
        optionType: SecondaryMenuOption.tip.optionType,
        isShow: true,
        tabBelonging: 5,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTipStyle()),
  ];

  GroupChatInfoController? groupChatInfoController;
  ChatInfoController? chatInfoController;
  bool isUser = true;

  /// 在二级菜单中
  bool isSubList = false;

  /// 二级菜单里的footage
  String? footage;

  FixedExtentScrollController hoursScrollController =
      FixedExtentScrollController();
  FixedExtentScrollController minScrollController =
      FixedExtentScrollController();

  FixedExtentScrollController dayScrollController =
      FixedExtentScrollController();
  FixedExtentScrollController monthScrollController =
      FixedExtentScrollController();
  FixedExtentScrollController yearScrollController =
      FixedExtentScrollController();

  final isShowPickDate = false.obs;

  // auto delete 自定义时间段选择
  // [10秒,20秒，30秒,60秒，5分钟,10分钟，30分钟,1小时,2小时,6小时,12小时,1天,2天，7天,14天,30天,60天,180天]
  List<int> autoDeleteCustomSelectionList = <int>[
    10,
    30,
    60,
    300,
    600,
    1800,
    3600,
    7200,
    21600,
    43200,
    86400,
    604800,
  ];

  List<AutoDeleteMessageModel> autoDeleteOption = [
/*    AutoDeleteMessageModel(
        title: localized(off),
        optionType: AutoDeleteDurationOption.disable.optionType,
        duration: AutoDeleteDurationOption.disable.duration),*/
    AutoDeleteMessageModel(
        title: '10 ${localized(seconds)}',
        optionType: AutoDeleteDurationOption.tenSecond.optionType,
        duration: AutoDeleteDurationOption.tenSecond.duration),
    AutoDeleteMessageModel(
      title: '30 ${localized(seconds)}',
      optionType: AutoDeleteDurationOption.thirtySecond.optionType,
      duration: AutoDeleteDurationOption.thirtySecond.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(minute)}',
      optionType: AutoDeleteDurationOption.oneMinute.optionType,
      duration: AutoDeleteDurationOption.oneMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '5 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.fiveMinute.optionType,
      duration: AutoDeleteDurationOption.fiveMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '10 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.tenMinute.optionType,
      duration: AutoDeleteDurationOption.tenMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '15 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.fifteenMinute.optionType,
      duration: AutoDeleteDurationOption.fifteenMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '30 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.thirtyMinute.optionType,
      duration: AutoDeleteDurationOption.thirtyMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(hour)}',
      optionType: AutoDeleteDurationOption.oneHour.optionType,
      duration: AutoDeleteDurationOption.oneHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '2 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.twoHour.optionType,
      duration: AutoDeleteDurationOption.twoHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '6 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.sixHour.optionType,
      duration: AutoDeleteDurationOption.sixHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '12 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.twelveHour.optionType,
      duration: AutoDeleteDurationOption.twelveHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(day)}',
      optionType: AutoDeleteDurationOption.oneDay.optionType,
      duration: AutoDeleteDurationOption.oneDay.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(week)}',
      optionType: AutoDeleteDurationOption.oneWeek.optionType,
      duration: AutoDeleteDurationOption.oneWeek.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(month)}',
      optionType: AutoDeleteDurationOption.oneMonth.optionType,
      duration: AutoDeleteDurationOption.oneMonth.duration,
    ),
  ];

  Chat? get getChat => groupChatInfoController != null
      ? groupChatInfoController?.chat.value
      : chatInfoController?.chat.value;

  BuildContext get context => groupChatInfoController != null
      ? groupChatInfoController!.context
      : chatInfoController!.context;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<GroupChatInfoController>()) {
      groupChatInfoController = Get.find<GroupChatInfoController>();
      isUser = false;
    } else if (Get.isRegistered<ChatInfoController>()) {
      chatInfoController = Get.find<ChatInfoController>();
    }
  }

  /// METHODS
  Future<void> onTap(int index) async {
    if (!common.CoolDownManager.handler(key: "onMenuTap", duration: 500)) {
      return;
    }
    if (currentList[index].tabBelonging == 3) {
      onNotificationsSecondMenuTap(index);
      return;
    } else if (currentList[index].tabBelonging == 5) {
      _onSecondaryMenuTap(currentList[index]);
      return;
    } else if (currentList[index].tabBelonging == 6) {
      _onHomePageMenuTap(currentList[index]);
      return;
    } else if (currentList[index].tabBelonging == 7) {
      _onContactPageMenuTap(currentList[index]);
      return;
    }

    /// 获取到指定的option
    switch (currentList[index].optionType) {
      case 'groupManagement':
        _goGroupManagement();
        _closeOverlay();
        break;
      case 'clearChatHistory':
        _showClearChatHistorySecondaryMenu();
        break;
      case 'permissions':
        _toPermission();
        break;
      case '改变主题':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'transferOwnership':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'blockUser':
        _closeOverlay();
        if (Get.isRegistered<ChatInfoController>()) {
          Get.find<ChatInfoController>().doBlockUser();
        }
        break;
      case 'Archive Chat':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'createGroup':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'deleteChatHistory':
        _closeOverlay();
        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return DesktopDialog(
                    dialogSize: const Size(300, 150),
                    child: DesktopDialogWithButton(
                      title: localized(deleteChatHistory),
                      subtitle: localized(chatInfoDoYouWantToDelete, params: [
                        (groupChatInfoController != null
                            ? groupChatInfoController!.group.value!.name
                            : objectMgr.userMgr
                                .getUserTitle(chatInfoController!.user.value))
                      ]),
                      buttonLeftText: localized(cancel),
                      buttonLeftOnPress: () {
                        Get.back();
                      },
                      buttonRightText: localized(buttonDelete),
                      buttonRightOnPress: () {
                        _deleteChat();
                      },
                    ));
              });
        } else {
          _showDeleteChatHistorySheet();
        }
        break;
      case 'leaveGroup':
        if (groupChatInfoController == null) break;

        _closeOverlay();
        String subTitle = '';
        if (groupChatInfoController!.isAdmin.value) {
          subTitle = localized(chatInfoYouAreAdminOfGroupWantToLeave,
              params: [(groupChatInfoController!.group.value!.name)]);
        } else if (groupChatInfoController!.isOwner.value) {
          subTitle = localized(chatInfoYouHaveTransferOwnershipBeforeLeave,
              params: [(groupChatInfoController!.group.value!.name)]);
        } else {
          subTitle = localized(chatInfoDoYouWantToLeave,
              params: [(groupChatInfoController!.group.value!.name)]);
        }

        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: groupChatInfoController!.context,
              builder: (BuildContext context) {
                return DesktopDialog(
                    dialogSize: const Size(300, 150),
                    child: DesktopDialogWithButton(
                      title: localized(leaveGroup),
                      subtitle: subTitle,
                      buttonLeftText: localized(cancel),
                      buttonLeftOnPress: () {
                        Get.back();
                      },
                      buttonRightText: localized(buttonLeave),
                      buttonRightOnPress: () {
                        Get.back();
                        _leaveGroup();
                      },
                    ));
              });
        } else {
          _showLeaveGroupSheet();
        }
        break;
      case 'disbandGroup':
        if (groupChatInfoController == null) break;

        _closeOverlay();
        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: groupChatInfoController!.context,
              builder: (BuildContext context) {
                return DesktopDialog(
                    dialogSize: const Size(300, 150),
                    child: DesktopDialogWithButton(
                      title: localized(disbandGroup),
                      subtitle: localized(confirmToDisbandParamGroup, params: [
                        (groupChatInfoController!.group.value!.name)
                      ]),
                      buttonLeftText: localized(cancel),
                      buttonLeftOnPress: () {
                        Get.back();
                      },
                      buttonRightText: localized(disband),
                      buttonRightOnPress: () {
                        _dismissGroup();
                        imBottomToast(
                          Get.context!,
                          title: localized(theGroupAlreadyDisbanded),
                          icon: ImBottomNotifType.INFORMATION,
                        );
                        Get.back();
                      },
                    ));
              });
        } else {
          _showDisbandGroupSheet();
        }
        break;
      case 'search':
        if (chatInfoController != null) {
          chatInfoController!.onChatTap(
            chatInfoController!.context,
            searching: true,
          );
        }
        _closeOverlay();
        break;
      case 'autoDeleteMessage':
        _showAutoMaticDeleteSecondaryMenu();
        break;
      case 'inviteGroup':
        _closeOverlay();
        onShowInviteGroupDialog();
        break;
      case 'screenshotNotification':
        _closeOverlay();
        _showScreenNotificationPopup();
        break;
      case 'aiRealTimeTranslate':
        _closeOverlay();
        if (objectMgr.loginMgr.isDesktop) {
          Get.toNamed(RouteName.translateSettingView,
              arguments: [getChat], id: 1);
        } else {
          Get.toNamed(RouteName.translateSettingView, arguments: [getChat]);
        }
        break;
      case 'encryptionSettings':
        onEncryptionToggle();
        break;
      default:
        break;
    }
  }

  Future<void> onEncryptionToggle() async {
    Chat? c = chatInfoController?.chat.value ??
        groupChatInfoController?.chat.value; //不是单聊就是群聊

    if (c == null) {
      return;
    }

    List<int> users = [];
    if (c.isSingle) {
      users = [objectMgr.userMgr.mainUser.uid, c.friend_id];
    } else if (c.isSaveMsg) {
      users = [objectMgr.userMgr.mainUser.uid];
    } else {
      users.assignAll(groupChatInfoController!.groupMemberListData
          .map((element) => element.uid)
          .toList());
    }

    if (c.isChatKeyValid) {
      users.remove(objectMgr.userMgr.mainUser.uid);
    }

    bool toClose = await objectMgr.encryptionMgr.onEncryptionToggle(c, users);

    if (toClose) {
      _closeOverlay();
    }
  }

  void onNotificationsSecondMenuTap(int index) async {
    DateTime currentDateTime = DateTime.now();
    switch (currentList[index].optionType) {
      case 'oneHour':
        final result = currentDateTime.add(const Duration(hours: 1));
        _muteChat(result.millisecondsSinceEpoch ~/ 1000, MuteDuration.hour);

        break;
      case 'eighthHours':
        final result = currentDateTime.add(const Duration(hours: 8));
        _muteChat(
            result.millisecondsSinceEpoch ~/ 1000, MuteDuration.eighthHours);
        break;
      case 'oneDay':
        final result = currentDateTime.add(const Duration(days: 1));
        _muteChat(result.millisecondsSinceEpoch ~/ 1000, MuteDuration.day);
        break;
      case 'sevenDays':
        final result = currentDateTime.add(const Duration(days: 7));
        _muteChat(
            result.millisecondsSinceEpoch ~/ 1000, MuteDuration.sevenDays);
        break;
      case 'oneWeek':
        final result = currentDateTime.add(const Duration(days: 7));
        _muteChat(result.millisecondsSinceEpoch ~/ 1000, MuteDuration.week);
        break;
      case 'oneMonth':
        final result = currentDateTime.add(const Duration(days: 30));
        _muteChat(result.millisecondsSinceEpoch ~/ 1000, MuteDuration.month);
        break;
      case 'muteUntil':
        _closeOverlay();
        dayScrollController = FixedExtentScrollController();
        monthScrollController = FixedExtentScrollController();
        yearScrollController = FixedExtentScrollController();
        hoursScrollController = FixedExtentScrollController();
        minScrollController = FixedExtentScrollController();
        final result = await showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) {
            return const NewMuteUntilActionSheet();
          },
        );

        if (result != null) {
          _muteChat(result, MuteDuration.custom);
        }
        break;
      case 'muteForever':
        _muteChat(-1, MuteDuration.forever);
        // Get.back();
        break;
      default:
        footage = null;
        update();
        break;
    }
    getChat?.isMuteRX.value =  !checkIsMute(getChat!.mute);
  }

  _goGroupManagement() async {
    if (!objectMgr.loginMgr.isLogin) return;
    if (getChat != null) {
      final User user = objectMgr.userMgr.mainUser;
      final endpoint = Uri.encodeComponent(serversUriMgr.apiUrl);
      final token = objectMgr.loginMgr.account?.token ?? '';
      final String managementUrl =
          "http://h5-group-manage.jxtest.net/group-manage?gid="
          "${getChat!.chat_id}&uid=${user.uid}&endpoint=$endpoint&token=$token&s3=${serversUriMgr.download2Uri?.origin}";

      Get.toNamed(RouteName.groupManagement, arguments: {
        'url': managementUrl,
      });
    }
  }

  _closeOverlay() {
    groupChatInfoController?.floatWindowOverlay?.remove();
    groupChatInfoController?.floatWindowOverlay = null;
    groupChatInfoController?.floatWindowOffset = null;

    chatInfoController?.floatWindowOverlay?.remove();
    chatInfoController?.floatWindowOverlay = null;
    chatInfoController?.floatWindowOffset = null;
  }

  _muteChat(int timeStamp, MuteDuration mType) async {
    if (getChat != null) {
      objectMgr.chatMgr.onChatMute(getChat!,
          expireTime: timeStamp, mType: mType, isNotHomePage: true);
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }
    _closeOverlay();
  }

  _clearHistory(ToolOptionModel model) async {
    if (getChat != null) {
      await objectMgr.chatMgr.clearMessage(getChat!, showToast: false);
      await objectMgr.localDB.clearMessages(getChat!.chat_id);
    }
    if (Get.isRegistered<ChatContentController>(
        tag: getChat?.chat_id.toString())) {
      Get.find<ChatContentController>(tag: getChat?.chat_id.toString())
          .update();
    }
    Get.back();
    imBottomToast(
      context,
      title: localized(deleteMyChatRecord),
      icon: ImBottomNotifType.delete,
    );
  }

  void _toPermission() async {
    if (groupChatInfoController == null) return;

    Group group = groupChatInfoController!.group.value!;
    _closeOverlay();
    Get.toNamed(RouteName.groupChatEditPermission, arguments: {
      'group': group,
      'groupMemberListData': group.members,
      'permission': group.permission,
    });
  }

  _deleteChat() async {
    if (getChat != null) {
      objectMgr.chatMgr.onChatDelete(getChat!);
      if (objectMgr.loginMgr.isDesktop) {
        Get.back();
        Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
      } else {
        Get.until((route) => Get.currentRoute == RouteName.home);
      }
      Toast.showToast(localized(chatInfoDeleteChatSuccessful));
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }

    _closeOverlay();
  }

  _fromInfoPageDeleteChat() async {
    if (getChat != null) {
      objectMgr.chatMgr.onChatDelete(getChat!);
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }

    _closeOverlay();
  }

  _leaveGroup() {
    _closeOverlay();
    if (objectMgr.loginMgr.isDesktop) {
      Get.back(id: 1);
    }
    groupChatInfoController!.onLeaveGroup();
  }

  _dismissGroup() {
    _closeOverlay();
    groupChatInfoController!.onDismissGroup();
  }

  void showAutoDeletePopup() {
    _closeOverlay();
    FixedExtentScrollController autoDeleteScrollController =
        FixedExtentScrollController();
    final currentAutoDeleteDuration = 0.obs;
    RxInt selectIndex = 0.obs;

    if (getChat?.autoDeleteInterval != null) {
      currentAutoDeleteDuration.value = getChat!.autoDeleteInterval;
    }

    selectIndex.value = autoDeleteOption
        .indexWhere((item) => item.duration == currentAutoDeleteDuration.value);
    initDefaultSelect(selectIndex);
    autoDeleteScrollController =
        FixedExtentScrollController(initialItem: selectIndex.value);

    if (objectMgr.loginMgr.isDesktop) {
      showDialog(
          context: context,
          builder: (context) {
            return DesktopDialog(
              child: Container(
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: Icon(
                              Icons.close,
                              color: themeColor,
                              size: 20,
                            ),
                          ),
                          Text(
                            localized(autoDeleteMessage),
                            style: jxTextStyle.textStyleBold16(),
                          ),
                          const SizedBox(
                            width: 15,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: autoDeleteOption.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Obx(
                            () => ElevatedButtonTheme(
                              data: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: colorBackground6,
                                  elevation: 0.0,
                                  textStyle: TextStyle(
                                      fontSize: 13,
                                      color: colorTextPrimary,
                                      fontWeight: MFontWeight.bold4.value),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  currentAutoDeleteDuration.value =
                                      autoDeleteOption[index].duration;
                                  selectIndex.value = index;
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      CheckTickItem(
                                        isCheck: currentAutoDeleteDuration
                                                .value ==
                                            autoDeleteOption[index].duration,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            border: customBorder,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          // height: 20,
                                          child: Text(
                                            autoDeleteOption[index].title,

                                            // 設置文本居中對齊
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.centerRight,
                      child: ElevatedButtonTheme(
                        data: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            disabledBackgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: colorBackground6,
                            elevation: 0.0,
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: colorWhite,
                                fontWeight: MFontWeight.bold4.value),
                          ),
                        ),
                        child: ElevatedButton(
                          child: Text(
                            localized(buttonDone),
                            style: TextStyle(
                                fontSize: 13,
                                color: colorWhite,
                                fontWeight: MFontWeight.bold4.value),
                          ),
                          onPressed: () {
                            // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                            setAutoDeleteInterval(
                                autoDeleteOption[selectIndex.value].duration);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
    } else {
      showModalBottomSheet(
        context: context,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(166),
        ),
        builder: (BuildContext context) {
          return CustomBottomSheetContent(
            bgColor: colorBackground,
            title: localized(autoDeleteTimerTitle),
            showCancelButton: true,
            middleChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 142,
                  margin: const EdgeInsets.only(top: 16, bottom: 28),
                  child: CupertinoPicker.builder(
                    scrollController: autoDeleteScrollController,
                    itemExtent: 44,
                    onSelectedItemChanged: (int index) {
                      selectIndex.value = index;
                    },
                    selectionOverlay: selectionOverlay,
                    itemBuilder: (context, index) {
                      AutoDeleteMessageModel item = autoDeleteOption[index];

                      return Obx(() {
                        TextStyle style;
                        if (selectIndex.value == index) {
                          style = jxTextStyle.titleSmallText(
                            fontWeight: MFontWeight.bold5.value,
                          );
                        } else if (index == selectIndex.value - 1 ||
                            index == selectIndex.value + 1) {
                          style = jxTextStyle.headerSmallText(
                            color: colorTextSecondary,
                          );
                        } else {
                          style = jxTextStyle.supportSmallText(
                            color: colorTextSupporting,
                          );
                        }
                        return Center(
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: style,
                          ),
                        );
                      });
                    },
                    childCount: autoDeleteOption.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButton(
                    text: localized(setAutoDeleteTimer),
                    callBack: () {
                      Get.back();
                      // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                      setAutoDeleteInterval(
                          autoDeleteOption[selectIndex.value].duration);
                    },
                  ),
                ),
                if (groupChatInfoController != null
                    ? groupChatInfoController!.autoDeleteIntervalEnable
                    : chatInfoController!.autoDeleteIntervalEnable)
                  CustomTextButton(
                    localized(closeAutoDeleteTimer),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    onClick: () {
                      Get.back();
                      setAutoDeleteInterval(0);
                    },
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ).whenComplete(() => autoDeleteScrollController.dispose());
    }
  }

  onShowInviteGroupDialog() {
    if (groupChatInfoController == null) return;
    Get.put(GroupInviteLinkController());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const ShareLinkBottomSheet();
      },
    ).then((_) => Get.delete<GroupInviteLinkController>());
  }

  void setAutoDeleteInterval(int duration, {String? timeTitle}) async {
    /// call AutoDeleteMessage API
    int seconds = Duration(seconds: duration).inSeconds;
    final autoDeleteMessageStatus = await ChatHelp.sendAutoDeleteMessage(
      chatId: getChat!.id,
      interval: seconds,
    );

    if (autoDeleteMessageStatus) {
      // Get.back();
      String message = "";
      if (seconds == 0) {
        message = localized(alreadyCancelAutoDeleteMsg);
      } else if (seconds < 60) {
        bool isSingular = seconds == 1;
        message = '${localized(alreadyCancelAutoDeleteMsgParameter, params: [
              "\t${localized(isSingular ? secondParam : secondsParam, params: [
                    "$seconds"
                  ])}"
            ])}\t';
      } else if (seconds < 3600) {
        bool isSingular = seconds ~/ 60 == 1;
        message = localized(alreadyCancelAutoDeleteMsgParameter, params: [
          "\t${localized(isSingular ? minuteParam : minutesParam, params: [
                "${seconds ~/ 60}"
              ])}\t"
        ]);
      } else if (seconds < 86400) {
        bool isSingular = seconds ~/ 3600 == 1;
        message = localized(alreadyCancelAutoDeleteMsgParameter, params: [
          "\t${localized(isSingular ? hourParam : hoursParam, params: [
                "${seconds ~/ 3600}"
              ])}\t"
        ]);
      } else if (seconds < 2592000) {
        bool isSingular = seconds ~/ 86400 == 1;
        int day = seconds ~/ 86400;
        if (day == 7) {
          bool isEnglish =
              AppLocalizations(objectMgr.langMgr.currLocale).isEnglish();
          if (isEnglish) {
            message = localized(alreadyCancelAutoDeleteMsgParameter,
                params: ["\t${timeTitle ?? localized(timeOneWeek)}\t"]);
          } else {
            message = localized(alreadyCancelAutoDeleteMsgParameter,
                params: ["\t${timeTitle ?? localized(timeOneWeek)}\t"]);
          }
        } else {
          message = localized(alreadyCancelAutoDeleteMsgParameter, params: [
            "\t${localized(isSingular ? dayParam : daysParam, params: [
                  "$day"
                ])}\t"
          ]);
        }
      } else {
        bool isSingular = seconds ~/ 2592000 == 1;
        message = localized(alreadyCancelAutoDeleteMsgParameter, params: [
          "\t${localized(isSingular ? monthParam : monthsParam, params: [
                "${seconds ~/ 2592000}"
              ])}\t"
        ]);
      }
      if (seconds == 0) {
        common.showCloseMuteToast(message);
      } else {
        common.showSetMuteToast(message);
      }
      //通知資料刷新
      Get.find<CustomInputController>(tag: getChat!.id.toString())
          .setAutoDeleteMsgInterval(seconds);
    }
  }

  Future<void> _showScreenNotificationPopup() async {
    bool isEnabled = groupChatInfoController != null
        ? groupChatInfoController!.screenshotEnable
        : chatInfoController!.screenshotEnable;

    showCustomBottomAlertDialog(
      groupChatInfoController != null
          ? groupChatInfoController!.context
          : chatInfoController!.context,
      subtitle: localized(
          isEnabled ? turnOffScreenshotDetail : turnOnScreenshotDetail),
      confirmText: localized(isEnabled ? turnOff : turnOn),
      confirmTextColor: isEnabled ? colorRed : themeColor,
      onConfirmListener: () {
        objectMgr.chatMgr.setScreenshotEnable(getChat!.id, isEnabled ? 0 : 1);
      },
    );
  }

  _showAutoMaticDeleteSecondaryMenu() async {
    if (groupChatInfoController != null
        ? groupChatInfoController!.autoDeleteIntervalEnable
        : chatInfoController!.autoDeleteIntervalEnable) {
      for (ToolOptionModel model in antoDeleteSecondaryMenuList) {
        if (model.optionType == "deactivate") {
          model.isShow = true;
          break;
        }
      }
    } else {
      for (ToolOptionModel model in antoDeleteSecondaryMenuList) {
        if (model.optionType == "deactivate") {
          model.isShow = false;
          break;
        }
      }
    }
    initItemKeys(antoDeleteSecondaryMenuList);
    currentList.value = antoDeleteSecondaryMenuList;
  }

  ///  二级菜单
  Future<void> _onSecondaryMenuTap(ToolOptionModel model) async {
    String type = model.optionType;
    switch (type) {
      case "oneDay":
        _closeOverlay();
        setAutoDeleteInterval(model.duration!, timeTitle: model.title);
        break;
      case "oneWeek":
        _closeOverlay();
        setAutoDeleteInterval(model.duration!);
        break;
      case "oneMonth":
        _closeOverlay();
        setAutoDeleteInterval(model.duration!, timeTitle: model.title);
        break;
      case "back":
        initItemKeys(optionList);
        currentList.value = optionList;
        break;
      case "deactivate":
        _closeOverlay();
        setAutoDeleteInterval(model.duration ?? 0, timeTitle: model.title);
        break;
      case "other":
        showAutoDeletePopup();
        break;
      case "secondaryMenuClearRecordOnlyForMe":
        _closeOverlay();
        // Get.back();
        _clearHistory(model);
        break;
      case "tip":
        return;
    }
  }

  void _showClearChatHistorySecondaryMenu() {
    String params = "";
    if (groupChatInfoController != null) {
      params = groupChatInfoController!.group.value?.name ?? '';
    } else {
      if (chatInfoController!.user.value?.uid != 0) {
        params = objectMgr.userMgr.getUserTitle(chatInfoController!.user.value);
      } else {
        params = getSpecialChatName(chatInfoController?.chat.value?.typ);
      }
    }
    String str = localized(secondaryMenuClearMessageTip, params: [params]);
    initItemKeys(optionList);
    currentList.value = [
      ToolOptionModel(
        title: localized(chatInfoBack),
        optionType: MorePopupOption.back.optionType,
        leftIconUrl: "assets/svgs/chat_info_icon_back.svg",
        isShow: true,
        tabBelonging: 5,
        largeDivider: true,
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
      ),
      ToolOptionModel(
        title: str,
        optionType: SecondaryMenuOption.tip.optionType,
        isShow: true,
        tabBelonging: 5,
        largeDivider: false,
        specialTitles: [
          localized(secondaryMenuClearMessageTipStart),
          params,
          localized(secondaryMenuClearMessageTipEnd)
        ],
        titleTextStyle: jxTextStyle.chatInfoSecondaryMenuTipStyle(),
      ),
      ToolOptionModel(
        title: localized(secondaryMenuClearRecordOnlyForMe),
        optionType:
            SecondaryMenuOption.secondaryMenuClearRecordOnlyForMe.optionType,
        isShow: true,
        tabBelonging: 5,
        titleTextStyle:
            jxTextStyle.chatInfoSecondaryMenuTitleStyle(color: Colors.red),
      ),
    ];
  }

  /// 设置默认的选择
  void initDefaultSelect(RxInt selectIndex) {
    selectIndex.value = 0;
    int? autoDeleteInterval = getChat!.autoDeleteInterval;
    if (autoDeleteInterval != null) {
      for (int index = 0; index < autoDeleteOption.length; index++) {
        if (autoDeleteOption[index].duration == autoDeleteInterval) {
          selectIndex.value = index;
          break;
        }
      }
    }
  }

  int? get autoDeleteInterval {
    return getChat!.autoDeleteInterval;
  }

  void initItemKeys(List<ToolOptionModel> list) {
    itemKeys.clear();
    for (var element in list) {
      String key = element.title;
      itemKeys.add(GlobalKey(debugLabel: key));
    }
  }

  List<TextSpan> getTextSpans(
      {required String content,
      required TextStyle style,
      bool? isNeedSplit = true}) {
    List<TextSpan> list = [];
    if (isNeedSplit != null && !isNeedSplit) {
      list.add(TextSpan(
        text: content,
        style: style,
      ));
      return list;
    }
    List<String> characters = content.split('');
    for (int i = 0; i < characters.length; i++) {
      list.add(TextSpan(
        text: characters[i],
        style: style,
      ));
    }
    return list;
  }

  Future<void> _showDeleteChatHistorySheet() async {
    showCustomBottomAlertDialog(context,
        subtitle: groupChatInfoController != null
            ? localized(groupDeleteGroupDetail)
            : localized(chatDeleteSingleDetail),
        canPopConfirm: false, onConfirmListener: () {
      Get.until((route) => Get.currentRoute == RouteName.home);

      /// 如先删除后面加回来，需要掉接口
      _fromInfoPageDeleteChat();
      imBottomToast(
        Get.context!,
        title: groupChatInfoController != null
            ? localized(alrdDeleteGroup)
            : localized(alrdDeleteChat),
        icon: ImBottomNotifType.delete,
      );
    },
        confirmText: groupChatInfoController != null
            ? localized(deleteGroupChat)
            : localized(deleteChatHistory));
  }

  /// 退出群组，改为底部弹出
  Future<void> _showLeaveGroupSheet() async {
    /// 管理员和普通成员
    String confirmText = localized(leaveGroup);
    String content = localized(chatGroupLeaveCheck);

    /// 如果是群组，确认改为 去转让所有权
    if (groupChatInfoController!.isOwner.value) {
      confirmText = localized(gotoTransferTheGroup);
      content = localized(chatGroupOwnerLeaveTransferCheck);
    }

    showCustomBottomAlertDialog(
      context,
      subtitle: content,
      confirmText: confirmText,
      canPopConfirm: false,
      onConfirmListener: () {
        if (groupChatInfoController!.isOwner.value) {
          groupChatInfoController!.ownerLeaveGroup();
        } else {
          Get.until((route) => Get.currentRoute == RouteName.home);
          groupChatInfoController!.notOwnerLeaveGroup();
          imBottomToast(
            Get.context!,
            title: localized(exitTheGroup),
            icon: ImBottomNotifType.INFORMATION,
          );
        }
      },
    );
  }

  /// 解散群租
  Future<void> _showDisbandGroupSheet() async {
    showCustomBottomAlertDialog(
      groupChatInfoController!.context,
      subtitle: localized(disbandGroupCheck),
      canPopConfirm: false,
      confirmText: localized(disbandGroup),
      onConfirmListener: () {
        Get.until((route) => Get.currentRoute == RouteName.home);
        _dismissGroup();
        imBottomToast(
          Get.context!,
          title: localized(theGroupAlreadyDisbanded),
          icon: ImBottomNotifType.INFORMATION,
        );
      },
    );
  }

  /// 是否关闭贪吃
  bool isNeedCallBack(int currentIndex) {
    ToolOptionModel model = currentList[currentIndex];
    String type = model.optionType;
    switch (type) {
      case "clearChatHistory":
      case "autoDeleteMessage":
      case "back":
      case "tip":
        return false;
    }
    return true;
  }

  List<TextSpan> buildTextSpans(int index) {
    var currentItem = currentList[index];
    List<TextSpan> listText = [];
    if (SecondaryMenuOption.tip.optionType == currentItem.optionType) {
      List<String> list = currentItem.specialTitles!;
      if (list.length == 3) {
        listText.addAll(getTextSpans(
          content: list[0],
          style: jxTextStyle.chatInfoSecondaryMenuTipStyle(
              color: colorTextPrimary),
        ));
        listText.add(
          TextSpan(
            text: '\t',
            style: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
          ),
        );
        listText.addAll(getTextSpans(
            content: list[1],
            isNeedSplit: false,
            style: jxTextStyle.chatInfoSecondaryMenuTipStyle(
              color: Colors.black,
              fontWeight: MFontWeight.bold5.value,
            )));
        listText.add(
          TextSpan(
            text: '\t',
            style: jxTextStyle.chatInfoSecondaryMenuTitleStyle(),
          ),
        );
        listText.addAll(getTextSpans(
          content: list[2],
          style: jxTextStyle.chatInfoSecondaryMenuTipStyle(
              color: colorTextPrimary),
        ));
      }
      return listText;
    }
    return [];
  }

  Future<void> _onHomePageMenuTap(ToolOptionModel model) async {
    String type = model.optionType;
    ChatListController controller = Get.find<ChatListController>();
    switch (type) {
      case "createChat":
        controller.showCreateChatPopup();
        break;
      case "addFriend":
        controller.showAddFriendBottomSheet();
        break;
      case "scan":
        controller.scanQRCode();
        break;
      case "scanPaymentQr":
        qrCodeDialogMyMoneyCode(Get.context!, onLeftBtnClick: () {
          Navigator.pop(Get.context!);
          controller.scanQRCode();
        });
        break;
      default:
        break;
    }
  }

  Future<void> _onContactPageMenuTap(ToolOptionModel model) async {
    String type = model.optionType;
    ContactController controller = Get.find<ContactController>();
    switch (type) {
      case "lastOnline":
        controller.contactSortClick(0);
        break;
      case "name":
        controller.contactSortClick(1);
        break;
      default:
        break;
    }
  }
}

mixin MoreVertControllerExtension {
  final selectedDateFormat = ''.obs;
  final selectionOverlay = CupertinoPickerDefaultSelectionOverlay(
    background: Colors.black.withOpacity(0.03),
    capStartEdge: false,
    capEndEdge: false,
  );

  List<int> generateNumRange(
      {required int startNum, required int maxNum, required int minNum}) {
    if (startNum < minNum || startNum > maxNum) {
      return [];
    }
    List<int> list =
        List<int>.generate(maxNum - startNum + 1, (index) => startNum + index);
    if (startNum != 0) {
      for (int i = minNum; i < startNum; i++) {
        list.add(i);
      }
    }
    return list;
  }

  ///获取当前月最大天数
  int getMaxDaysInMonth(DateTime date) {
    DateTime nextMonthDate = DateTime(date.year, date.month + 1, 1);
    DateTime lastDayOfCurrentMonth =
        nextMonthDate.subtract(const Duration(days: 1));
    return lastDayOfCurrentMonth.day;
  }

  void goBack(BuildContext context) {
    if (isCurrentTime()) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, formatDateTime(selectedDateFormat.value));
  }

  String getBtnTitle() {
    if (isCurrentTime()) {
      return localized(buttonClose);
    }
    String title = selectedDateFormat.value == ''
        ? localized(turnOff)
        : '${localized(muteUtil)} ${selectedDateFormat.value}';
    return title;
  }

  int formatDateTime(String dateString) {
    final DateFormat formatter = DateFormat('MM/dd/yy, HH:mm');
    DateTime dateTime = formatter.parse(dateString);
    int millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
    int secondsSinceEpoch = millisecondsSinceEpoch ~/ 1000;
    return secondsSinceEpoch;
  }

  bool isCurrentTime() {
    DateTime now = DateTime.now();

    // 获取当前时间的总分钟数
    int currentTotalMinutesSinceEpoch =
        now.millisecondsSinceEpoch ~/ (1000 * 60);

    // 获取指定日期时间的总分钟数
    int selectedTotalMinutesSinceEpoch =
        formatDateTime(selectedDateFormat.value) ~/ 60;

    // 计算时间差（当前时间总分钟数 - 指定时间总分钟数）
    int minuteDifference =
        currentTotalMinutesSinceEpoch - selectedTotalMinutesSinceEpoch;

    return minuteDifference >= 0;
  }
}
