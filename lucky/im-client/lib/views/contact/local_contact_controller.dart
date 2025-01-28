import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/contact/app_contact_view.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/device_contact_view.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../api/friends.dart';
import '../../data/db_user.dart';
import '../../main.dart';
import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/net/update_block_bean.dart';
import '../../utils/theme/text_styles.dart';
import '../component/custom_alert_dialog.dart';

class LocalContactController extends GetxController
    with GetSingleTickerProviderStateMixin, StateMixin {
  TabController? tabController;
  late int permissionContacts = 1;
  List<Tab> tabList = [
    Tab(text: localized(localContactLocalContactSync)),
    Tab(text: localized(localContactMyFriends))
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
    final permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      if (permissionContacts == 1) {
        await Permission.contacts.request().isGranted;
        permissionContacts++;
        if (await Permission.contacts.isGranted) {
          await syncContact();
        }
      } else {
        if (!(await Permission.contacts.isGranted)) {
          openAppSettings();
        } else {
          await syncContact();
        }
      }
    } else {
      await syncContact();
    }
    change(null, status: RxStatus.success());
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
  }

  onClose() {
    super.onClose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    Get.find<ContactController>().searchController.clear();
  }

  syncContact() async {
    final List<Map<String, Object>>? localList =
        await objectMgr.userMgr.getContactsList();
    final List list = await createLocalContact(list: localList);
    //获取所有用户的列表
    allReturnedList = list.map((item) => User.fromJson(item)).toList();
    getUpdatedList();
  }

  void getUpdatedList() {
    appContactList.value = allReturnedList
        .where((element) => element.relationship == Relationship.friend)
        .toList();
    deviceContactList.value = allReturnedList
        .where((element) =>
            element.relationship != Relationship.self &&
            element.relationship != Relationship.friend)
        .toList();
  }

  Widget getTrailing(User user) {
    switch (user.relationship) {
      case Relationship.stranger:
        return GestureDetector(
          onTap: () {
            showDialog(
              context: Get.context!,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: localized(addingANewFriend),
                  content: Text(
                    "${localized(adding)} ${user.nickname} ${localized(asANewFriendSendAFriendRequest)}?",
                    style: jxTextStyle.textDialogContent(),
                    textAlign: TextAlign.center,
                  ),
                  confirmText: localized(buttonYes),
                  cancelText: localized(buttonNo),
                  confirmColor: accentColor,
                  confirmCallback: () => addFriend(user),
                );
              },
            );
          },
          child: SvgPicture.asset(
            'assets/svgs/sent_request.svg',
            color: accentColor,
          ),
        );
      case Relationship.sentRequest:
        return Text(
          localized(requestSent),
          style: TextStyle(color: accentColor.withOpacity(0.2)),
        );
      case Relationship.receivedRequest:
        return Text(
          localized(requestReceived),
          style: TextStyle(color: accentColor.withOpacity(0.2)),
        );
      default:
        return const SizedBox();
    }
  }

  ///添加好友
  Future<void> addFriend(User user) async {
    objectMgr.userMgr.addFriend(user);
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
