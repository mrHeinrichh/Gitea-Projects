import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/auto_delete_message_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/DesktopDialog.dart';

import '../../../object/chat/chat.dart';
import '../../../object/user.dart';
import '../../../routes.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../views/component/custom_alert_dialog.dart';
import '../../model/group/group.dart';
import 'multi_action_sheet.dart';

class MoreVertController extends GetxController {
  /// VARIABLES
  late List<ToolOptionModel> optionList;
  List<ToolOptionModel> currentList = List.empty(growable: true);

  late final controller;
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
    AutoDeleteMessageModel(
        title: localized(off),
        optionType: AutoDeleteDurationOption.disable.optionType,
        duration: AutoDeleteDurationOption.disable.duration),
    AutoDeleteMessageModel(
        title: '10 ${localized(second)}',
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
      title: '1 ${localized(weeks)}',
      optionType: AutoDeleteDurationOption.oneWeek.optionType,
      duration: AutoDeleteDurationOption.oneWeek.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(month)}',
      optionType: AutoDeleteDurationOption.oneMonth.optionType,
      duration: AutoDeleteDurationOption.oneMonth.duration,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<GroupChatInfoController>()) {
      controller = Get.find<GroupChatInfoController>();
      isUser = false;
    } else {
      controller = Get.find<ChatInfoController>();
    }
  }

  _goBetRecordHome(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    imMiniAppManager.goToBetRecordPage(context);
  }

  /// METHODS
  Future<void> onTap(int index) async {
    if (currentList[index].tabBelonging == 3) {
      onNotificationsSecondMenuTap(index);
      return;
    }

    /// 获取到指定的option
    switch (currentList[index].optionType) {
      case 'groupOperate':
        _closeOverlay();
        goGroupOperate(controller.context);
        break;
      case 'groupCertified':
        _closeOverlay();
        // Navigator.of(controller.context).push(MaterialPageRoute(
        //     builder: (context) => OfficialCertification.providerPage()));

        break;
      case 'promoteCenter':
        _closeOverlay();
        goPromoteCenter(controller.context);
        break;
      case 'betRecordHome':
        _closeOverlay();
        _goBetRecordHome(controller.context);
        break;
      case 'groupManagement':
        _goGroupManagement();
        _closeOverlay();
        break;
      case 'clearChatHistory':
        _closeOverlay();
        showDialog(
          context: controller.context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: localized(clearChatHistory),
              content: Text(
                localized(chatInfoDoYouWantToClear, params: [
                  "${(controller is GroupChatInfoController) ? controller.group.value.name : objectMgr.userMgr.getUserTitle(controller.user.value)}"
                ]),
                style: jxTextStyle.textDialogContent(),
                textAlign: TextAlign.center,
              ),
              confirmText: localized(buttonClear),
              cancelText: localized(buttonCancel),
              confirmCallback: () => _clearHistory(currentList[index]),
            );
          },
        );
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
        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: controller.context,
              builder: (BuildContext context) {
                return DesktopDialog(
                    dialogSize: const Size(300, 150),
                    child: DesktopDialogWithButton(
                      title: localized(deleteChatHistory),
                      subtitle: localized(chatInfoDoYouWantToDelete, params: [
                        "${(controller is GroupChatInfoController) ? controller.group.value.name : objectMgr.userMgr.getUserTitle(controller.user.value)}"
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
          showDialog(
            context: controller.context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(deleteChatHistory),
                content: Text(
                  localized(chatInfoDoYouWantToDelete, params: [
                    "${(controller is GroupChatInfoController) ? controller.group.value.name : objectMgr.userMgr.getUserTitle(controller.user.value)}"
                  ]),
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmText: localized(buttonDelete),
                cancelText: localized(buttonCancel),
                confirmCallback: () => _deleteChat(),
              );
            },
          );
        }

        _closeOverlay();
        break;
      case 'leaveGroup':
        String subTitle = '';
        if (controller.isAdmin.value) {
          subTitle = localized(chatInfoYouAreAdminOfGroupWantToLeave,
              params: ["${controller.group.value.name}"]);
        } else if (controller.isOwner.value) {
          subTitle = localized(chatInfoYouHaveTransferOwnershipBeforeLeave,
              params: ["${controller.group.value.name}"]);
        } else {
          subTitle = localized(chatInfoDoYouWantToLeave,
              params: ["${controller.group.value.name}"]);
        }

        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: controller.context,
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
                        _leaveGroup();
                      },
                    ));
              });
        } else {
          showDialog(
            context: controller.context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(leaveGroup),
                content: Text(
                  subTitle,
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmText: localized(buttonLeave),
                cancelText: localized(buttonCancel),
                confirmCallback: () => _leaveGroup(),
              );
            },
          );
        }
        _closeOverlay();
        break;
      case 'disbandGroup':
        if (objectMgr.loginMgr.isDesktop) {
          showDialog(
              context: controller.context,
              builder: (BuildContext context) {
                return DesktopDialog(
                    dialogSize: const Size(300, 150),
                    child: DesktopDialogWithButton(
                      title: localized(disbandGroup),
                      subtitle: localized(confirmToDisbandParamGroup,
                          params: ["${controller.group.value.name}"]),
                      buttonLeftText: localized(cancel),
                      buttonLeftOnPress: () {
                        Get.back();
                      },
                      buttonRightText: localized(disband),
                      buttonRightOnPress: () {
                        _dismissGroup();
                      },
                    ));
              });
        } else {
          showDialog(
            context: controller.context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(disbandGroup),
                content: Text(
                  localized(confirmToDisbandParamGroup,
                      params: ['${controller.group.value.name}']),
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmText: localized(disband),
                cancelText: localized(buttonCancel),
                confirmCallback: () => _dismissGroup(),
              );
            },
          );
        }
        _closeOverlay();
        break;
      case 'search':
        if (Get.isRegistered<ChatInfoController>()) {
          Get.find<ChatInfoController>()
              .onChatTap(controller.context, searching: true);
        }
        _closeOverlay();
        break;
      case 'autoDeleteMessage':
        showAutoDeletePopup();
        break;
      case 'inviteGroup':
        _closeOverlay();
        onShowInviteGroupDialog();
        break;
      case 'screenshotNotification':
        _closeOverlay();
        _showScreenNotificationPopup();
        break;
      default:
        break;
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
        final result = await Get.bottomSheet(
          const MuteUntilActionSheet(),
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
  }

  _goGroupManagement() async {
    if (!objectMgr.loginMgr.isLogin) return;
    Chat? chat = await _getChat();
    if (chat != null) {
      final User user = objectMgr.userMgr.mainUser;
      final endpoint = Uri.encodeComponent(serversUriMgr.apiUrl);
      final token = objectMgr.loginMgr.account?.token ?? '';
      final String managementUrl =
          "http://h5-group-manage.jxtest.net/group-manage?gid="
          "${chat.chat_id}&uid=${user.uid}&endpoint=$endpoint&token=$token&s3=${serversUriMgr.download2Uri?.origin}";

      Get.toNamed(RouteName.groupManagement, arguments: {
        'url': managementUrl,
      });
    }
  }

  _closeOverlay() {
    controller.floatWindowOverlay?.remove();
    controller.floatWindowOverlay = null;
    controller.floatWindowOffset = null;
  }

  _muteChat(int timeStamp, MuteDuration mType) async {
    Chat? chat = await _getChat();

    if (chat != null) {
      objectMgr.chatMgr.onChatMute(chat,
          expireTime: timeStamp, mType: mType, isNotHomePage: true);
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }
    _closeOverlay();
  }

  Future<Chat?> _getChat() async {
    Chat? chat;
    if (isUser) {
      User user = controller.user.value;
      chat = await objectMgr.chatMgr.getChatByFriendId(user.uid);
    } else {
      Group group = controller.group.value;
      chat = objectMgr.chatMgr.getChatById(group.id);
    }
    return chat;
  }

  _clearHistory(ToolOptionModel model) async {
    Chat? chat = await _getChat();

    if (chat != null) {
      await objectMgr.chatMgr.clearMessage(chat);
    }
    if (Get.isRegistered<ChatContentController>(
        tag: chat?.chat_id.toString())) {
      Get.find<ChatContentController>(tag: chat?.chat_id.toString()).update();
    }
  }

  void _toPermission() async {
    Group group = controller.group!.value;
    _closeOverlay();
    Get.toNamed(RouteName.groupChatEditPermission, arguments: {
      'group': group,
      'groupMemberListData': group.members,
      'permission': group.permission,
    });
  }

  _deleteChat() async {
    Chat? chat = await _getChat();

    if (chat != null) {
      objectMgr.chatMgr.onChatDelete(chat);
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

  _leaveGroup() {
    _closeOverlay();
    if (objectMgr.loginMgr.isDesktop) {
      Get.back(id: 1);
    }
    controller.onLeaveGroup();
  }

  _dismissGroup() {
    _closeOverlay();
    controller.onDismissGroup();
  }

  void showAutoDeletePopup() {
    _closeOverlay();
    FixedExtentScrollController autoDeleteScrollController =
        FixedExtentScrollController();
    final currentAutoDeleteDuration = 0.obs;
    int selectIndex = 0;
    if (controller.chat.value?.autoDeleteInterval != null) {
      currentAutoDeleteDuration.value =
          controller.chat.value?.autoDeleteInterval;
    }

    selectIndex = autoDeleteOption
        .indexWhere((item) => item.duration == currentAutoDeleteDuration.value);
    autoDeleteScrollController =
        FixedExtentScrollController(initialItem: selectIndex);

    if (objectMgr.loginMgr.isDesktop) {
      showDialog(
          context: controller.context,
          builder: (context) {
            return DesktopDialog(
              child: Container(
                decoration: BoxDecoration(
                  color: JXColors.white,
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
                              color: accentColor,
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
                                  surfaceTintColor: JXColors.outlineColor,
                                  elevation: 0.0,
                                  textStyle: TextStyle(
                                      fontSize: 13,
                                      color: JXColors.primaryTextBlack,
                                      fontWeight: MFontWeight.bold4.value),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  currentAutoDeleteDuration.value =
                                      autoDeleteOption[index].duration;
                                  selectIndex = index;
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
                            backgroundColor: accentColor,
                            disabledBackgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: JXColors.outlineColor,
                            elevation: 0.0,
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: JXColors.white,
                                fontWeight: MFontWeight.bold4.value),
                          ),
                        ),
                        child: ElevatedButton(
                          child: Text(
                            localized(buttonDone),
                            style: TextStyle(
                                fontSize: 13,
                                color: JXColors.white,
                                fontWeight: MFontWeight.bold4.value),
                          ),
                          onPressed: () {
                            // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                            setAutoDeleteInterval(
                                autoDeleteOption[selectIndex].duration);
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
        context: controller.context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        builder: (context) {
          return SizedBox(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: JXColors.borderPrimaryColor, width: 0.5),
                      bottom: BorderSide(
                          color: JXColors.borderPrimaryColor, width: 0.5),
                      left: BorderSide(
                          color: JXColors.borderPrimaryColor, width: 0.5),
                      right: BorderSide(
                          color: JXColors.borderPrimaryColor, width: 0.5),
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  child: SizedBox(
                    height: 26,
                    child: NavigationToolbar(
                      leading: SizedBox(
                        width: 74,
                        child: OpacityEffect(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              localized(buttonCancel),
                              style:
                                  jxTextStyle.textStyle17(color: accentColor),
                            ),
                          ),
                        ),
                      ),
                      middle: Text(
                        localized(autoDeleteMessage),
                        style: jxTextStyle.textStyleBold16(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                      itemExtent: 55,
                      scrollController: autoDeleteScrollController,
                      onSelectedItemChanged: (int index) {
                        selectIndex = index;
                      },
                      children: autoDeleteOption.map((item) {
                        return ListTile(
                          title: Text(
                            item.title,
                            textAlign: TextAlign.center, // 設置文本居中對齊
                          ),
                        );
                      }).toList()),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom +
                          (Platform.isAndroid ? 12 : 0),
                      left: 10,
                      right: 10),
                  child: PrimaryButton(
                    bgColor: accentColor,
                    width: double.infinity,
                    title: localized(buttonConfirm),
                    onPressed: () {
                      // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                      setAutoDeleteInterval(
                          autoDeleteOption[selectIndex].duration);
                    },
                  ),
                )
              ],
            ),
          );
        },
      ).whenComplete(() => autoDeleteScrollController.dispose());
    }
  }

  onShowInviteGroupDialog() {
    if (controller is GroupChatInfoController) {
      // if (objectMgr.loginMgr.isDesktop) {
      //     //   if (desktopSettingCurrentRoute != RouteName.shareView) {
      //     //     selectedIndex.value = 9;
      //     //     Get.offAllNamed(RouteName.desktopChatEmptyView,
      //     //         predicate: (route) =>
      //     //         route.settings.name == RouteName.desktopChatEmptyView,
      //     //         id: 3);
      //     //     Get.toNamed(RouteName.shareView, id: 3);
      //     //   }
      //     // } else {
      Get.bottomSheet(
        GetBuilder(
          init: ShareController(
              groupChatId:
                  (controller as GroupChatInfoController).chat.value?.id),
          builder: (controller) => const ShareView(),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
      // }
    }
  }

  void setAutoDeleteInterval(int duration) async {
    /// call AutoDeleteMessage API
    int seconds = Duration(seconds: duration).inSeconds;
    final autoDeleteMessageStatus = await ChatHelp.sendAutoDeleteMessage(
      chatId: controller.chat.value.id,
      interval: seconds,
    );

    if (autoDeleteMessageStatus) {
      Get.back();
      String message = "";
      if (seconds == 0) {
        message = '${localized(you)} ${localized(turnOffAutoDeleteMessage)}';
      } else if (seconds < 60) {
        bool isSingular = seconds == 1;
        message =
            '${localized(you)} ${localized(turnOnAutoDeleteMessage, params: [
              "${localized(isSingular ? secondParam : secondsParam, params: [
                    "${seconds}"
                  ])}"
            ])}';
      } else if (seconds < 3600) {
        bool isSingular = seconds ~/ 60 == 1;
        message =
            '${localized(you)} ${localized(turnOnAutoDeleteMessage, params: [
              "${localized(isSingular ? minuteParam : minutesParam, params: [
                    "${seconds ~/ 60}"
                  ])}"
            ])}';
      } else if (seconds < 86400) {
        bool isSingular = seconds ~/ 3600 == 1;
        message =
            '${localized(you)} ${localized(turnOnAutoDeleteMessage, params: [
              "${localized(isSingular ? hourParam : hoursParam, params: [
                    "${seconds ~/ 3600}"
                  ])}"
            ])}';
      } else if (seconds < 2592000) {
        bool isSingular = seconds ~/ 86400 == 1;
        message =
            '${localized(you)} ${localized(turnOnAutoDeleteMessage, params: [
              "${localized(isSingular ? dayParam : daysParam, params: [
                    "${seconds ~/ 86400}"
                  ])}"
            ])}';
      } else {
        bool isSingular = seconds ~/ 2592000 == 1;
        message =
            '${localized(you)} ${localized(turnOnAutoDeleteMessage, params: [
              "${localized(isSingular ? monthParam : monthsParam, params: [
                    "${seconds ~/ 2592000}"
                  ])}"
            ])}';
      }
      Toast.showToast(message);
      //通知資料刷新
      Get.find<CustomInputController>(tag: controller.chat.value.id.toString())
          .setAutoDeleteMsgInterval(seconds);
    }
  }

  void _showScreenNotificationPopup() {
    bool isEnabled = controller.screenshotEnable;
    showDialog(
      context: controller.context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(screenshotNotification),
          content: Text(
            localized(
                isEnabled ? screenshotDescriptionOff : screenshotDescriptionOn),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(isEnabled ? turnOff : turnOn),
          cancelText: localized(buttonCancel),
          confirmColor: isEnabled ? errorColor : accentColor,
          confirmCallback: () {
            // objectMgr.chatMgr.setScreenshotEnable(controller.chat.value?.id, 1);
            objectMgr.chatMgr.setScreenshotEnable(
                controller.chat.value?.id, isEnabled ? 0 : 1);
          },
        );
      },
    );
  }
}

Future<void> goGroupOperate(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AppGroupManagement.providerPage()));
}

Future<void> goPromoteCenter(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    imMiniAppManager.goToPromotionCenterPage(context);
}
