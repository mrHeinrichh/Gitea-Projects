import 'package:azlistview/azlistview.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import '../../data/db_call_log.dart';
import '../../main.dart';
import '../../managers/call_mgr.dart';
import '../../object/azItem.dart';
import '../../object/call.dart';
import '../../object/chat/chat.dart';
import '../../object/selection_option_model.dart';
import '../../object/user.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/im_toast/im_bottom_toast.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/net/app_exception.dart';
import '../../utils/net/update_block_bean.dart';
import '../../utils/toast.dart';
import '../../utils/utility.dart';
import '../component/custom_confirmation_popup.dart';
import '../component/custom_avatar.dart';
import 'all_call_log.dart';
import 'missed_call.dart';

class CallLogController extends GetxController
    with GetTickerProviderStateMixin {
  final BuildContext context = Routes.navigatorKey.currentContext!;
  late final TabController tabController;

  ScrollController recentScrollController = ScrollController();
  ScrollController missedScrollController = ScrollController();

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final searchParam = ''.obs;
  final isSearching = false.obs;

  List<User> friendList = [];
  RxList<AZItem> azFriendList = <AZItem>[].obs;
  final isEditing = false.obs;

  RxList<Call> recentCallList = RxList<Call>();
  RxList<Call> missedCallList = RxList<Call>();
  final selectedChannelIDForEdit = <Call>[].obs;
  bool isDeleting = false;

  final canEdit = false.obs;

  final List<Widget> tabList = [
    const AllCallLog(),
    const MissedCall(),
  ];

  final List<SelectionOptionModel> optionList = [
    SelectionOptionModel(
      title: localized(chatVoice),
    ),
    SelectionOptionModel(
      title: localized(chatVideo),
    ),
  ];

  @override
  Future<void> onInit() async {
    super.onInit();
    tabController = TabController(length: tabList.length, vsync: this);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBCallLog.tableName}", _onCallLogUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBCallLog.tableName}", _onCallLogUpdate);
    objectMgr.callMgr
        .on(objectMgr.callMgr.eventCallLogUpdate, _onCallLogUpdate);

    tabController.addListener(() {
      isEditing.value = false;
      updateEditStatus();
      selectedChannelIDForEdit.clear();
    });
    await getLocalCallLog();
    Future.delayed(const Duration(seconds: 2), () => getRemoteCallLog());
  }

  getLocalCallLog({bool needRead = false}) async {
    final tempCallLogs = await objectMgr.localDB.loadCallLogs();
    final callLogs =
        tempCallLogs.map((e) => Call.fromJson(e, fromLocalDB: true)).toList();
    objectMgr.callMgr.callLog = callLogs;
    objectMgr.callMgr.callLogSort();
    updateEditStatus();
    if (needRead) {
      updateCallRead();
    }
  }

  updateCallRead() {
    objectMgr.localDB.updateCallRead();
    Get.find<HomeController>().missedCallCount.value = 0;
  }

  void getUnreadCall() async {
    int callUnread = await objectMgr.localDB.getUnreadCall();
    Get.find<HomeController>().missedCallCount.value = callUnread;
  }

  void _onCallLogUpdate(Object sender, Object type, Object? data) {
    recentCallList.value = objectMgr.callMgr.callLog
        .where((element) => element.deletedAt == 0)
        .toList();
    missedCallList.value = recentCallList
        .where((element) => objectMgr.callMgr.getMissedStatus(element))
        .toList();
    updateEditStatus();
  }

  void tapForEdit(Call callItem) {
    selectedChannelIDForEdit.contains(callItem)
        ? selectedChannelIDForEdit.remove(callItem)
        : selectedChannelIDForEdit.add(callItem);
    update();
  }

  Future<void> removeLog(Call callItem) async {
    callItem.deletedAt = DateTime.now().millisecondsSinceEpoch;
    objectMgr.callMgr.onCallLogChanged(
      [callItem],
    );
    try {
      await deleteLog(callItem.channelId);
    } catch (e) {
      if (e is NetworkException) {
        // Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      } else
        Toast.showToast(e.toString());
    }
  }

  void onDeleteCallLog(Call callItem) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          img: CustomAvatar(
            uid: objectMgr.userMgr.isMe(callItem.callerId)
                ? callItem.receiverId
                : callItem.callerId,
            size: 56,
          ),
          subTitle: "${localized(logInfoDoYouWantToDelete)}",
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          confirmButtonText: localized(buttonDelete),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () => removeLog(callItem),
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void onDeleteMultiCallLog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(deleteCallLog),
          withHeader: false,
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          confirmButtonText: localized(deleteParamCall,
              params: ['${selectedChannelIDForEdit.length}']),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () {
            isDeleting = true;
            ImBottomToast(context,
                title: localized(deleteParamCall,
                    params: ['${selectedChannelIDForEdit.length}']),
                icon: ImBottomNotifType.timer,
                duration: 5, timerFunction: () {
              selectedChannelIDForEdit.forEach((callItem) {
                removeLog(callItem);
              });
              Get.back();
              clearSelectedChannelForEdit();
              isDeleting = false;
            }, undoFunction: () {
              isDeleting = false;
              BotToast.removeAll(BotToast.textKey);
              clearSelectedChannelForEdit();
            }, withCancel: true);
            isEditing.value = false;
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void clearSelectedChannelForEdit() {
    selectedChannelIDForEdit.clear();
    update();
  }

  void updateAZFriendList() {
    azFriendList.value = friendList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(azFriendList);
    azFriendList.refresh();
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => search());
  }

  void search() {
    if (searchParam.value.isNotEmpty) {
      friendList = objectMgr.userMgr.friendWithoutBlacklist
          .where((element) => objectMgr.userMgr
              .getUserTitle(element)
              .toLowerCase()
              .contains(searchParam.toLowerCase()))
          .toList();
    } else {
      friendList = objectMgr.userMgr.friendWithoutBlacklist;
    }

    updateAZFriendList();
  }

  void clearSearching() {
    isSearching.value = false;
    if (!isSearching.value) {
      searchController.clear();
      searchParam.value = '';
    }
    search();
  }

  Future<void> startCall(int uid, bool isVoiceCall) async {
    Chat? chat = await objectMgr.chatMgr.getChatByFriendId(uid);
    if (chat != null) objectMgr.callMgr.startCall(chat, isVoiceCall);
  }

  void getFriendList() {
    friendList = objectMgr.userMgr.friendWithoutBlacklist;
    updateAZFriendList();
  }

  void getRemoteCallLog({bool needRead = false}) async {
    int lastUpdateTime;
    if (objectMgr.callMgr.callLog.isNotEmpty) {
      lastUpdateTime = objectMgr.callMgr.lastUpdatedCallLog.updatedAt;
    } else {
      await getLocalCallLog(); // retry to get local db
      objectMgr.callMgr.callLog.isNotEmpty
          ? lastUpdateTime = objectMgr.callMgr.lastUpdatedCallLog.updatedAt
          : lastUpdateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    getUnreadCall();
    final callLogs = await getCallLog(lastUpdateTime);
    if (callLogs != null) {
      var result = await filterRemoteCallLog(callLogs);
      if (result != null) {
        await objectMgr.callMgr.onCallLogChanged(result);
        int unreadNum = result.length;
        Get.find<HomeController>().missedCallCount.value += unreadNum;
      }
    }
    if (needRead) {
      updateCallRead();
    }
  }

  filterRemoteCallLog(List<Call> callLogs) async {
    List<Call> filteredLogs = [];
    for (Call call in callLogs) {
      if (!await objectMgr.localDB.isExist(call.channelId)) {
        switch (call.status) {
          case 1:
            call.status = CallEvent.CallEnd.event;
            break;
          case 2:
            call.status = CallEvent.CallOptEnd.event;
            break;
          case 3:
            call.status = CallEvent.CallReject.event;
            break;
          case 4:
            call.status = CallEvent.CallOptReject.event;
            break;
          case 6:
            call.status = CallEvent.CallOptCancel.event;
            break;
          case 8:
            call.status = CallEvent.CallOptBusy.event;
            break;
          case 9:
          case 10:
          case 12:
            call.status = CallEvent.CallTimeOut.event;
            break;
          default:
            continue;
        }
        filteredLogs.add(call);
      }
    }
    return filteredLogs;
  }

  void updateEditStatus() {
    canEdit.value = tabController.index == 0 && recentCallList.isNotEmpty ||
        tabController.index == 1 && missedCallList.isNotEmpty;
    if (!canEdit.value) isEditing.value = false;
  }

  @override
  void onClose() {
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBCallLog.tableName}", _onCallLogUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBCallLog.tableName}", _onCallLogUpdate);
    objectMgr.callMgr
        .off(objectMgr.callMgr.eventCallLogUpdate, _onCallLogUpdate);
    super.onClose();
  }

  void showCallOptionPopup(BuildContext context, User? user) {
    if (user == null) return;

    String userTitle =
        objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(user.uid));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          title: localized(callNow, params: ['$userTitle']),
          selectionOptionModelList: optionList,
          callback: (index) {
            if (index == 0) {
              startCall(user.uid, true);
            } else if (index == 1) {
              startCall(user.uid, false);
            }
          },
        );
      },
    );
  }

  void showCallSingleOption(BuildContext context, User? user, bool isVoiceCall) {
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
            title: localized(callPopUpTitle),
            subTitle: localized(callPopUpDesc),
            confirmButtonText: localized(callPopUpConfirm),
            cancelButtonText: localized(buttonCancel),
            confirmCallback: () {
              startCall(user.uid, isVoiceCall);
            },
            cancelCallback: () => Get.back(),
        );
      },
    );
  }
}
