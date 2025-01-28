import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/views/contact/app_contact_view.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/device_contact_view.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalContactController extends GetxController
    with GetSingleTickerProviderStateMixin, StateMixin {
  TabController? tabController;
  final showPermission = true.obs;

  List<Tab> tabList = [
    Tab(text: localized(localContactLocalContactSync)),
    Tab(text: localized(localContactMyFriends)),
  ];
  List<Widget> tabViewList = [
    const DeviceContactView(),
    const AppContactView(),
  ];
  RxList<User> deviceContactList = <User>[].obs;
  RxList<User> appContactList = <User>[].obs;
  List<User> allReturnedList = [];

  @override
  Future<void> onInit() async {
    super.onInit();
    change(null, status: RxStatus.loading());
    tabController = TabController(length: tabList.length, vsync: this);

    bool isGranted = await Permissions.request([Permission.contacts]);
    bool shouldUpdate = true;
    if (isGranted) {
      showPermission.value = false;
      shouldUpdate = await syncContact();
    }

    if (shouldUpdate) {
      change(null, status: RxStatus.success());
    }
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.on(ObjectMgr.eventAppLifeState, _didChangeAppLifecycleState);
  }

  @override
  onClose() {
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.off(ObjectMgr.eventAppLifeState, _didChangeAppLifecycleState);
    Get.find<ContactController>().searchController.clear();
    super.onClose();
  }

  Future<bool> syncContact() async {
    try {
      final List<Map<String, Object>>? localList =
          await objectMgr.userMgr.getContactsList();
      final List list = await createLocalContact(list: localList);
      //获取所有用户的列表
      allReturnedList = list.map((item) {
        // Find matching contact in localList based on the same phone number
        final matchingLocalContact = localList?.firstWhere(
          (localContact) {
            final phoneNumberList =
                localContact['phone_number'] as List<dynamic>;
            return phoneNumberList.any((phoneEntry) {
              final phoneNumber = (phoneEntry as Map<String, String>)['number'];
              return phoneNumber != null &&
                  phoneNumber.contains(item['contact']);
            });
          },
          orElse: () => <String, Object>{},
        );

        // Merge local contact data with the returned list item
        return User.fromJson({
          ...item,
          'local_name': matchingLocalContact?['name'] ?? '',
          'local_phone_numbers': ((matchingLocalContact?['phone_number']
                  as List)[0] as Map<String, String>)['number'] ??
              '',
        });
      }).toList();

      getUpdatedList();
      return true;
    } catch (e) {
      imBottomToast(Get.context!,
          title: localized(connectionFailedPleaseCheckTheNetwork),
          icon: ImBottomNotifType.INFORMATION);
      return false;
    }
  }

  Future<void> _didChangeAppLifecycleState(sender, type, state) async {
    if (showPermission.value && state == AppLifecycleState.resumed) {
      if (await Permission.contacts.request().isGranted) {
        showPermission.value = false;
        syncContact();
      }
    }
  }

  void getUpdatedList() {
    appContactList.value = allReturnedList
        .where((element) => element.relationship == Relationship.friend)
        .toList();
    deviceContactList.value = allReturnedList
        .where(
          (element) =>
              element.relationship != Relationship.self &&
              element.relationship != Relationship.friend,
        )
        .toList();
  }

  ///更新数据库通知
  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      final int index =
          allReturnedList.indexWhere((element) => element.uid == data.uid);
      allReturnedList[index].relationship = data.relationship;
      getUpdatedList();
    }
  }
}
