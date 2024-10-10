import 'package:azlistview/azlistview.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_log_mgr.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/views/call_log/component/call_log_tile.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/call_log/all_call_log.dart';
import 'package:jxim_client/views/call_log/missed_call.dart';

class CallLogController extends GetxController
    with GetTickerProviderStateMixin {
  final BuildContext context = navigatorKey.currentContext!;
  late final TabController tabController;

  ScrollController recentScrollController = ScrollController();
  ScrollController missedScrollController = ScrollController();

  final GlobalKey<AnimatedListState> recentListKey =
      GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> missListKey =
      GlobalKey<AnimatedListState>();

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final searchParam = ''.obs;
  final isSearching = false.obs;
  final callLogFilters = [localized(all), localized(missed)];

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

  final sliderControllerMap = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    tabController = TabController(length: tabList.length, vsync: this);
    objectMgr.callLogMgr
        .on(objectMgr.callLogMgr.eventAddCallLog, _onCallLogAdded);
    objectMgr.callLogMgr
        .on(objectMgr.callLogMgr.eventDelCallLog, _onCallLogDeleted);
    objectMgr.callLogMgr
        .on(objectMgr.callLogMgr.eventCallLogUnreadUpdate, onUnreadCall);
    objectMgr.callLogMgr
        .on(objectMgr.callLogMgr.eventCallLogInited, _onCallLogInited);
    tabController.addListener(() {
      isEditing.value = false;
      updateEditStatus();
      onUnreadCall("", "", null);
      selectedChannelIDForEdit.clear();
    });

    loadLogData();
  }

  loadLogData() async {
    List<Call> recentCalls =
        await objectMgr.callLogMgr.loadCallLog(CallLogType.all);
    recentCalls.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    recentCallList.assignAll(recentCalls);

    List<Call> missedCalls =
        await objectMgr.callLogMgr.loadCallLog(CallLogType.missedCall);
    missedCalls.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    missedCallList.assignAll(missedCalls);

    onUnreadCall("", "", null);
    updateEditStatus();
  }

  void onUnreadCall(_, __, Object? data) async {
    int callUnread = await objectMgr.callLogMgr.getUnreadCallCount();
    Get.find<HomeController>().missedCallCount.value = callUnread;
  }

  void _onCallLogInited(_, __, Object? data) async {
    loadLogData();
  }

  void _onCallLogAdded(Object sender, Object type, Object? data) async {
    if (data != null && data is List<Call>) {
      List<Call> calls = data;
      if (calls.isEmpty) return;

      recentCallList.insertAll(0, data);
      recentListKey.currentState?.insertAllItems(0, calls.length);

      for (final callLog in calls) {
        if (objectMgr.callLogMgr.isMissCallLog(callLog)) {
          missedCallList.insertAll(0, data);
          missListKey.currentState?.insertAllItems(0, calls.length);
        }
      }

      updateEditStatus();
    }
  }

  void _onCallLogDeleted(Object sender, Object type, Object? data) async {
    if (data != null && data is List<Call>) {
      List<Call> calls = data;
      if (calls.isEmpty) return;

      if (calls.length < 2) {
        Call removedCall = calls.first;
        int missedIndex = missedCallList
            .indexWhere((e) => e.channelId == removedCall.channelId);
        if (missedIndex >= 0) {
          missedCallList.removeAt(missedIndex);
          missListKey.currentState?.removeItem(
            missedIndex,
            (context, animation) =>
                buildItem(1, missedIndex, removedCall, animation),
          );
        }

        int recentIndex = recentCallList
            .indexWhere((e) => e.channelId == removedCall.channelId);
        if (recentIndex >= 0) {
          recentCallList.removeAt(recentIndex);
          recentListKey.currentState?.removeItem(
            recentIndex,
            (context, animation) =>
                buildItem(0, recentIndex, removedCall, animation),
          );
        }
      } else {
        final isMissed =
            callLogFilters[tabController.index] == localized(missed);
        if (isMissed) {
          List<Call> removeCalls = List.from(missedCallList);
          for (final call in removeCalls) {
            int recentIndex =
                recentCallList.indexWhere((e) => e.channelId == call.channelId);
            if (recentIndex >= 0) {
              recentCallList.removeAt(recentIndex);
              recentListKey.currentState?.removeItem(
                recentIndex,
                (context, animation) =>
                    buildItem(0, recentIndex, call, animation),
              );
            }
          }
        } else {
          recentCallList.clear();
          recentListKey.currentState
              ?.removeAllItems((context, animation) => const SizedBox.shrink());
        }

        missedCallList.clear();
        missListKey.currentState
            ?.removeAllItems((context, animation) => const SizedBox.shrink());
      }

      updateEditStatus();
    }
  }

  void tapForEdit(Call callItem) {
    selectedChannelIDForEdit.contains(callItem)
        ? selectedChannelIDForEdit.remove(callItem)
        : selectedChannelIDForEdit.add(callItem);
    update();
  }

  Future<void> removeLogs(List<Call> callItems) async {
    objectMgr.callLogMgr.removeCallLog(callItems);
  }

  Future<void> onDeleteCallLog(Call callItem) async {
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText: localized(reelDeleteConfirm),
      onConfirmListener: () {
        isDeleting = true;

        imBottomToast(
          context,
          title: localized(deleteParamCall, params: ['1']),
          icon: ImBottomNotifType.timer,
          duration: 5,
          timerFunction: () {
            removeLogs([callItem]);
            clearSelectedChannelForEdit();
            isDeleting = false;
          },
          undoFunction: () {
            isDeleting = false;
            BotToast.removeAll(BotToast.textKey);
            clearSelectedChannelForEdit();
          },
          withCancel: true,
        );

        isEditing.value = false;
      },
    );
  }

  Future<void> onDeleteMultiCallLog() async {
    final isMissed = callLogFilters[tabController.index] == localized(missed);

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText: localized(reelDeleteConfirm),
      onConfirmListener: () {
        isDeleting = true;

        imBottomToast(
          context,
          title: localized(
            deleteParamCall,
            params: [
              '${isMissed ? missedCallList.length : recentCallList.length}',
            ],
          ),
          icon: ImBottomNotifType.timer,
          duration: 5,
          timerFunction: () {
            removeLogs(isMissed ? missedCallList : recentCallList);
            clearSelectedChannelForEdit();
            isDeleting = false;
          },
          undoFunction: () {
            isDeleting = false;
            BotToast.removeAll(BotToast.textKey);
            clearSelectedChannelForEdit();
          },
          withCancel: true,
        );

        isEditing.value = false;
      },
    );
  }

  void clearSelectedChannelForEdit() {
    selectedChannelIDForEdit.clear();
    // closeAllSlideCells();
    update();
  }

  void closeAllSlideCells() async {
    sliderControllerMap.forEach((key, value) {
      SlidableController sliderController = value;
      sliderController.close();
    });
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
          .where(
            (element) => objectMgr.userMgr
                .getUserTitle(element)
                .toLowerCase()
                .contains(searchParam.toLowerCase()),
          )
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
    objectMgr.callLogMgr
        .off(objectMgr.callLogMgr.eventAddCallLog, _onCallLogAdded);
    objectMgr.callLogMgr
        .off(objectMgr.callLogMgr.eventDelCallLog, _onCallLogDeleted);
    objectMgr.callLogMgr
        .off(objectMgr.callLogMgr.eventCallLogUnreadUpdate, onUnreadCall);
    objectMgr.callLogMgr
        .off(objectMgr.callLogMgr.eventCallLogInited, _onCallLogInited);
    sliderControllerMap.clear();
    super.onClose();
  }

  Future<void> showCallOptionPopup(BuildContext context, User? user) async {
    if (user == null) return;

    String userTitle =
        objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(user.uid));

    showCustomBottomAlertDialog(
      context,
      title: localized(callNow, params: [userTitle]),
      items: [
        CustomBottomAlertItem(
          text: localized(chatVoice),
          onClick: () => startCall(user.uid, true),
        ),
        CustomBottomAlertItem(
          text: localized(chatVideo),
          onClick: () => startCall(user.uid, false),
        ),
      ],
    );
  }

  Future<void> showCallSingleOption(
    BuildContext context,
    User? user,
    bool isVoiceCall,
  ) async {
    if (user == null) return;

    // showCustomBottomAlertDialog(
    //   context,
    //   title: localized(callPopUpTitle),
    //   subtitle: localized(callPopUpDesc),
    //   confirmTextColor: themeColor,
    //   confirmText: localized(callPopUpConfirm),
    //   onConfirmListener: () => startCall(user.uid, isVoiceCall),
    // );

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(attachmentCallVoice),
          onClick: () async {
            startCall(user.uid, true);
          },
        ),
        CustomBottomAlertItem(
          text: localized(attachmentCallVideo),
          onClick: () async {
            startCall(user.uid, false);
          },
        ),
      ],
    );
  }

  Widget buildItem(
    int tabIndex,
    int index,
    Call callItem,
    Animation<double> animation,
  ) {
    bool isMissed = callLogFilters[tabController.index] == localized(missed);

    String channelKey = "${callItem.channelId}_$tabIndex";
    if (sliderControllerMap[channelKey] == null) {
      GlobalKey<CallLogTileState> globalKey = GlobalKey<CallLogTileState>();
      sliderControllerMap[channelKey] = globalKey;
    }

    return SizeTransition(
      sizeFactor: animation,
      child: CallLogTile(
        key: sliderControllerMap[channelKey],
        tabIndex: tabIndex,
        callItem: callItem,
        isLastIndex: isMissed
            ? (index == missedCallList.length - 1)
            : index == recentCallList.length - 1,
      ),
    );
  }

  onDeleteBtnClicked(int tabIndex, Call callItem) async {
    String channelKey = "${callItem.channelId}_$tabIndex";
    if (sliderControllerMap.containsKey(channelKey)) {
      GlobalKey<CallLogTileState> globalKey = sliderControllerMap[channelKey];
      if (globalKey.currentState != null) {
        globalKey.currentState?.openEndAction();
      }
    }
  }
}
