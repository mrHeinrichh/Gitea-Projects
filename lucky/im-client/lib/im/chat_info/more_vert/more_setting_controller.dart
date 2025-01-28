import 'dart:io';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
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
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/auto_delete_message_model.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views/component/custom_avatar_hero.dart';

class MoreSettingController extends GetxController {
  User? user = User();
  Group? group = Group();
  Chat? chat = Chat();
  bool isGroup = false;
  int? uid;

  //late int uid;
  int? groupId;
  bool ableChat = false;
  bool isOwner = false;
  bool isAdmin = false;
  RxList<ToolOptionModel> moreVertOptions = RxList();
  CustomPopupMenuController controller = Get.find<CustomPopupMenuController>();

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

  MoreSettingController();

  MoreSettingController.desktop({int? uid, int? groupId, Chat? chat}) {
    if (uid != null) {
      this.uid = uid;
      loadUserInfo(uid);
    }

    if (groupId != null) {
      this.groupId = groupId;
      loadGroupInfo(groupId);
    }

    if (chat != null) {
      this.chat = chat;
    }
  }

  @override
  void onInit() {
    if (Get.arguments != null) {
      if (Get.arguments['groupId'] != null) {
        groupId = Get.arguments['groupId'];
        loadGroupInfo(groupId);
        imMiniAppManager.onCertifySuccessEvent = () {
          loadGroupInfo(groupId);
        };
      } else {
        if (Get.arguments['id'] != null) {
          uid = Get.arguments['id'];
        } else {
          uid = Get.arguments['uid'];
        }
        loadUserInfo(uid!);
      }
      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }
    }

    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventGroupInfoUpdated, _onGroupInfoUpdated);
    super.onInit();
  }

  @override
  void onClose() {
    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventGroupInfoUpdated, _onGroupInfoUpdated);
    super.onClose();
  }

  void loadUserInfo(int uid) async {
    user = await objectMgr.userMgr.loadUserById(uid);

    /// objectMgr.chatMgr.getChatByFriendId 这个方法出了问题，查询不到数据
    if (chat == null) {
      Chat? tempChat = await objectMgr.chatMgr.getChatByFriendId(uid);
      if (tempChat != null) {
        chat = tempChat;
        ableChat = true;
      }
    }
    getSingleChatOptionList();
  }

  void loadGroupInfo(int? id) async {
    group = await objectMgr.myGroupMgr.getLocalGroup(id!);
    if (group != null) {
      int uid = objectMgr.loginMgr.account?.user?.uid ?? 0;
      isOwner = group!.owner == uid;
      List adminList = (group!.admins.length > 0) ? group!.admins : [];
      isAdmin = adminList.isNotEmpty &&
          adminList.contains(objectMgr.userMgr.mainUser.uid);
    }

    Chat? tempChat = await objectMgr.chatMgr.getGroupChatById(id);
    if (tempChat != null) {
      chat = tempChat;
      ableChat = true;
    }
    getGroupChatOptionList();
  }

  void getSingleChatOptionList() {
    /// filter Option List
    moreVertOptions.value = [
      ToolOptionModel(
        title: localized(search),
        optionType: MorePopupOption.search.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
        trailing: true,
      ),
      ToolOptionModel(
        title: localized(autoDeleteMessage),
        optionType: MorePopupOption.autoDeleteMessage.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
        trailing: true,
      ),
      ToolOptionModel(
        title: localized(clearChatHistory),
        optionType: MorePopupOption.clearChatHistory.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(createGroup),
        optionType: MorePopupOption.createGroup.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(blockUser),
        optionType: MorePopupOption.blockUser.optionType,
        color: JXColors.primaryTextBlack,
        tabBelonging: null,
        isShow: true,
      ),
      ToolOptionModel(
        title: localized(deleteChatHistory),
        optionType: MorePopupOption.deleteChatHistory.optionType,
        color: errorColor,
        tabBelonging: null,
        isShow: true,
      ),
    ];
    if (user?.relationship != Relationship.friend) {
      if (ableChat) {
        moreVertOptions.removeWhere((e) =>
            e.optionType == MorePopupOption.autoDeleteMessage.optionType ||
            e.optionType == MorePopupOption.createGroup.optionType);
      } else {
        moreVertOptions.removeWhere((e) =>
            // e.optionType == MorePopupOption.autoDeleteMessage.optionType ||
            e.optionType == MorePopupOption.clearChatHistory.optionType ||
            e.optionType == MorePopupOption.createGroup.optionType ||
            e.optionType == MorePopupOption.deleteChatHistory.optionType);
      }
    }
  }

  void getGroupChatOptionList() async {
    moreVertOptions.value = [
      ///开通认证
      ToolOptionModel(
        title: localized(groupCertified),
        optionType: MorePopupOption.groupCertified.optionType,
        isShow: isOwner,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ///推广中心
      ToolOptionModel(
        title: localized(promoteCenter),
        optionType: MorePopupOption.promoteCenter.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ///群组运营
      ToolOptionModel(
        title: localized(groupOperate),
        optionType: MorePopupOption.groupOperate.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ///投注記錄
      ToolOptionModel(
        title: localized(betRecordHome),
        optionType: MorePopupOption.betRecordHome.optionType,
        isShow: true,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(autoDeleteMessage),
        optionType: MorePopupOption.autoDeleteMessage.optionType,
        isShow: chat!.isValid,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
        trailing: true,
      ),
      ToolOptionModel(
        title: localized(groupManagement),
        optionType: MorePopupOption.groupManagement.optionType,
        isShow: chat!.isValid,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(clearChatHistory),
        optionType: MorePopupOption.clearChatHistory.optionType,
        isShow: !chat!.isDisband,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(permissions),
        optionType: MorePopupOption.permissions.optionType,
        isShow: chat!.isValid,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(deleteChatHistory),
        optionType: MorePopupOption.deleteChatHistory.optionType,
        color: errorColor,
        tabBelonging: null,
        isShow: true,
      ),
      ToolOptionModel(
        title: localized(leaveGroup),
        optionType: MorePopupOption.leaveGroup.optionType,
        isShow: chat!.isValid,
        tabBelonging: null,
        color: JXColors.primaryTextBlack,
      ),
      ToolOptionModel(
        title: localized(disbandGroup),
        optionType: MorePopupOption.disbandGroup.optionType,
        isShow: chat!.isValid,
        tabBelonging: null,
        color: errorColor,
      ),
    ];

    if (chat!.isValid) {
      if (!isOwner) {
        moreVertOptions.removeWhere((e) =>
            e.optionType == MorePopupOption.groupManagement.optionType ||
            e.optionType == MorePopupOption.permissions.optionType ||
            e.optionType == MorePopupOption.autoDeleteMessage.optionType ||
            e.optionType == MorePopupOption.disbandGroup.optionType);

        bool isExist = moreVertOptions
            .any((element) => element.optionType == 'deleteChatHistory');

        if (isExist) {
          final deleteChatHistory = moreVertOptions.firstWhere(
              (element) => element.optionType == 'deleteChatHistory');
          moreVertOptions.remove(deleteChatHistory);
          moreVertOptions.insert(0, deleteChatHistory);
        }
      }
    } else {
      moreVertOptions.removeWhere((e) =>
          e.optionType == MorePopupOption.groupManagement.optionType ||
          e.optionType == MorePopupOption.permissions.optionType ||
          e.optionType == MorePopupOption.autoDeleteMessage.optionType);

      if (!ableChat) {
        moreVertOptions.removeWhere((e) =>
            e.optionType == MorePopupOption.clearChatHistory.optionType ||
            e.optionType == MorePopupOption.deleteChatHistory.optionType);
      }
    }

    if (!Config().enableWallet) {
      moreVertOptions.removeWhere(
          (e) => e.optionType == MorePopupOption.groupManagement.optionType);
    }
    if (sharedDataManager.isGroupCertified || !isOwner) {
      //只有當群組沒開通且自己是群主才可以顯示開通認證
      moreVertOptions.removeWhere((e) =>
      e.optionType == MorePopupOption.groupCertified.optionType);
    }
    if (!sharedDataManager.isGroupCertified) {
      //當群組沒開通移除推廣中心以及投注紀錄
      moreVertOptions.removeWhere((e) =>
      e.optionType == MorePopupOption.promoteCenter.optionType);
      moreVertOptions.removeWhere((e) =>
      e.optionType == MorePopupOption.betRecordHome.optionType);
      if(!imMiniAppManager.isCurrentUserShareholder) {
        //如果不是股東不能看群組運營
        moreVertOptions.removeWhere((e) =>
        e.optionType == MorePopupOption.groupOperate.optionType);
      }
    } else {
      //當群組已開通
      if(!imMiniAppManager.isCurrentUserShareholder) {
        //如果不是股東不能看群組運營
        moreVertOptions.removeWhere((e) =>
        e.optionType == MorePopupOption.groupOperate.optionType);
      }
    }
  }

  Future<void> onTap(BuildContext context, String type) async {
    switch (type) {
      case 'search':
        if (Get.isRegistered<ChatInfoController>()) {
          Get.find<ChatInfoController>().onChatTap(context, searching: true);
        }
        break;
      case 'groupOperate':
        _goGroupOperate(context);
        break;
      case 'groupCertified':
        // Navigator.of(context).push(MaterialPageRoute(
        //     builder: (context) => OfficialCertification.providerPage()));

        break;
      case 'promoteCenter':
        _goPromoteCenter(context);
        break;
      case 'betRecordHome':
        _goBetRecordHome(context);
        break;
      case 'autoDeleteMessage':
        showAutoDeletePopup(context);
        break;
      case 'groupManagement':
        goGroupManagement();
        break;
      case 'clearChatHistory':
        clearHistory();
        break;
      case 'permissions':
        toPermission();
        break;
      case 'leaveGroup':
        showLeaveGroupPopup(context);
        break;
      case 'createGroup':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'blockUser':
        Toast.showToast(localized(homeToBeContinue));
        break;
      default:
        break;
    }
  }

  void goGroupManagement() async {
    if (!objectMgr.loginMgr.isLogin) return;
    if (chat != null) {
      final User user = objectMgr.userMgr.mainUser;
      final endpoint = Uri.encodeComponent(serversUriMgr.apiUrl);
      final token = objectMgr.loginMgr.account?.token ?? '';
      final String managementUrl =
          "http://h5-group-manage.jxtest.net/group-manage?gid="
          "${chat?.chat_id}&uid=${user.uid}&endpoint=$endpoint&token=$token&s3=${serversUriMgr.download2Uri?.origin}";

      Get.toNamed(RouteName.groupManagement, arguments: {
        'url': managementUrl,
      });
    }
  }

  void toPermission() async {
    Get.toNamed(RouteName.groupChatEditPermission,
        arguments: {
          'group': group,
          'groupMemberListData': group?.members,
          'permission': group?.permission,
        },
        id: objectMgr.loginMgr.isDesktop ? 1 : null);
  }

  Future<void> toLeaveGroup() async {
    Get.back();
    if (group == null) return;

    if (isOwner) {
      Get.back();
      List<User> tempUserList = group!.members.map<User>((e) {
        User user = User.fromJson({
          'uid': e['user_id'],
          'nickname': e['user_name'],
          'profile_pic': e['icon'],
          'last_online': e['last_online'],
        });
        user.displayLastOnline = FormatTime.formatTimeFun(e['last_online']);
        return user;
      }).toList();

      GroupChatInfoController controller;
      if (Get.isRegistered<GroupChatInfoController>()) {
        controller = Get.find<GroupChatInfoController>();
      } else {
        controller = Get.put(GroupChatInfoController());
      }

      List<User> userList = controller.sortMemberList(tempUserList);

      userList.removeWhere((element) => objectMgr.userMgr.isMe(element.id));
      Get.toNamed(RouteName.groupAddMember, arguments: {
        'group': group,
        'memberList': userList,
      });
    } else {
      try {
        await objectMgr.myGroupMgr.leaveGroup(group!.uid);
        objectMgr.myGroupMgr.leaveGroupPrefix = 'You have left';
        objectMgr.myGroupMgr.leaveGroupName = group!.name;
        Toast.showToast(localized(groupLeaveGroupSuccessful));
        Get.back();
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        Get.back();
      }
    }
  }

  void dismissGroup() {
    if (group == null) return;
    objectMgr.myGroupMgr.onDismissGroup(group!.uid);
    Get.close(2);
  }

  void clearHistory() async {
    await objectMgr.chatMgr.clearMessage(chat!);
    Get.back();
  }

  void deleteChat() async {
    if (chat != null) {
      objectMgr.chatMgr.onChatDelete(chat!);
      Get.until((route) => Get.currentRoute == RouteName.home);
      Toast.showToast(localized(chatInfoDeleteChatSuccessful));
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }
  }

  Future<void> _goGroupOperate(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    if (chat != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AppGroupManagement.providerPage()));
    }
  }

  _goPromoteCenter(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    if (chat != null) {
      imMiniAppManager.goToPromotionCenterPage(context);
    }
  }

  _goBetRecordHome(BuildContext context) async {
    if (!objectMgr.loginMgr.isLogin) return;
    if (chat != null) {
      imMiniAppManager.goToBetRecordPage(context);
    }
  }

  void showAutoDeletePopup(BuildContext context) {
    int? currentAutoDeleteDuration = 0;
    FixedExtentScrollController autoDeleteScrollController =
    FixedExtentScrollController();
    int selectIndex = 0;
    if (chat?.autoDeleteInterval != null) {
      currentAutoDeleteDuration = chat?.autoDeleteInterval;
    }

    selectIndex = autoDeleteOption.indexWhere((item) => item.duration == currentAutoDeleteDuration);
    autoDeleteScrollController = FixedExtentScrollController(initialItem: selectIndex);

    showModalBottomSheet(
      context: context,
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

    // showModalBottomSheet(
    //   context: context,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(18),
    //   ),
    //   builder: (context) {
    //     return SizedBox(
    //       height: 400.w,
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Container(
    //             alignment: Alignment.center,
    //             padding: EdgeInsets.symmetric(
    //               vertical: 12.w,
    //               horizontal: 20.w,
    //             ),
    //             decoration: const BoxDecoration(
    //               border: Border(
    //                 top: BorderSide(
    //                     color: JXColors.borderPrimaryColor, width: 0.5),
    //                 bottom: BorderSide(
    //                     color: JXColors.borderPrimaryColor, width: 0.5),
    //                 left: BorderSide(
    //                     color: JXColors.borderPrimaryColor, width: 0.5),
    //                 right: BorderSide(
    //                     color: JXColors.borderPrimaryColor, width: 0.5),
    //               ),
    //               borderRadius: BorderRadius.only(
    //                 topRight: Radius.circular(20),
    //                 topLeft: Radius.circular(20),
    //               ),
    //             ),
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 GestureDetector(
    //                   onTap: () {
    //                     Navigator.pop(context);
    //                   },
    //                   child: ImText(
    //                     localized(buttonCancel),
    //                     fontSize: 17.w,
    //                     color: accentColor,
    //                     // localized(autoDeleteMessage),
    //                   ),
    //                 ),
    //                 Text(
    //                   localized(autoDeleteMessage),
    //                   style: jxTextStyle.textStyleBold16(),
    //                 ),
    //                 SizedBox(
    //                   width: 15.w,
    //                 )
    //               ],
    //             ),
    //           ),
    //           Expanded(
    //             child: CupertinoPicker(
    //                 itemExtent: 55,
    //                 scrollController: autoDeleteScrollController,
    //                 onSelectedItemChanged: (int index) {
    //                   selectIndex = index;
    //                 },
    //                 children: autoDeleteOption.map((item) {
    //                   return Container(
    //                     decoration: BoxDecoration(
    //                       border: customBorder,
    //                     ),
    //                     child: ListTile(
    //                       title: Text(
    //                         item.title,
    //                         textAlign: TextAlign.center, // 設置文本居中對齊
    //                       ),
    //                     ),
    //                   );
    //                 }).toList()),
    //           ),
    //           Padding(
    //             padding: EdgeInsets.only(
    //                 bottom: MediaQuery.of(context).padding.bottom +
    //                     (Platform.isAndroid ? 12 : 0),
    //                 left: 10,
    //                 right: 10),
    //             child: PrimaryButton(
    //               bgColor: accentColor,
    //               width: double.infinity,
    //               title: localized(buttonConfirm),
    //               onPressed: () {
    //                 // 在這裡處理按鈕點擊事件，設置Auto Delete選項
    //                 setAutoDeleteInterval(
    //                     autoDeleteOption[selectIndex].duration);
    //               },
    //             ),
    //           )
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  void setAutoDeleteInterval(int duration) async {
    /// call AutoDeleteMessage API
    int seconds = Duration(seconds: duration).inSeconds;
    final autoDeleteMessageStatus = await ChatHelp.sendAutoDeleteMessage(
      chatId: chat?.id,
      interval: seconds,
    );

    if (autoDeleteMessageStatus) {
      Get.back();
      Toast.showToast(localized(chatInfoAutoDeleteMessageSetSuccessful));
      //通知資料刷新
      Get.find<CustomInputController>(tag: chat?.id.toString())
          .setAutoDeleteMsgInterval(seconds);
    }
  }

  void showLeaveGroupPopup(BuildContext context) {
    // String subTitle = '';
    // if (isAdmin) {
    //   subTitle = localized(chatInfoYouAreAdminOfGroupWantToLeave,
    //       params: ["${group?.name}"]);
    // } else if (isOwner) {
    //   subTitle = localized(chatInfoYouHaveTransferOwnershipBeforeLeave,
    //       params: ["${group?.name}"]);
    // } else {
    //   subTitle =
    //       localized(chatInfoDoYouWantToLeave, params: ["${group?.name}"]);
    // }

    /// TODO: need to update to localized text

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: '',
          img: CustomAvatarHero(
            id: group?.uid ?? 0,
            size: 60.0,
            isGroup: true,
            showAutoDeleteIcon: false,
          ),
          // content: Text(
          //   '你确定要离开并删除 ${group?.name}？',
          //   style: const TextStyle(
          //     fontSize: 12,
          //     color: JXColors.primaryTextBlack,
          //     fontWeight: MFontWeight.bold6.value,
          //     decoration: TextDecoration.none,
          //   ),
          // ),
          confirmButtonText: isOwner ? '去转让群组所有权' : localized(buttonLeave),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () => toLeaveGroup(),
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _onGroupInfoUpdated(Object sender, Object event, Object? data) async {
    if (data != null && data is Group && data.id == group?.id) {
      loadGroupInfo(data.id);
    }
  }
}
