import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart' as friend_api;
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/db_user.dart';
import '../../managers/call_mgr.dart';
import '../../object/user.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/net/update_block_bean.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../component/custom_alert_dialog.dart';
import '../component/custom_confirmation_popup.dart';
import '../register/components/themedAlertDialog.dart';

class SearchContactController extends GetxController {
  final usernameList = <User>[].obs;
  final contactList = <User>[].obs;

  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxBool isSearchTyping = false.obs;
  final searchParam = ''.obs;

  ScrollController scrollController = ScrollController();

  int offset = 0;
  bool hasMoreResult = false;

  @override
  void onInit() {
    super.onInit();
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    debounce(searchParam, (_) async => contactSearching());
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        //reach bottom of scroll bar
        scrollForMore();
      }
    });

    /// 搜索从信息气泡长按电话号码'Search User' 功能
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('phoneNumber')) {
      String phoneNumber = arguments['phoneNumber'];
      searchController.text = phoneNumber;
      searchParam.value = phoneNumber;
      isSearching.value = true;
      isSearchTyping.value = true;
      debounce(searchParam, (_) async => contactSearching());
    }
  }

  onClose() {
    super.onClose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
  }

  scrollForMore() {
    if (hasMoreResult) {
      offset += 20;
      contactSearching(isScroll: true);
    }
  }

  contactSearching({bool isScroll = false}) async {
    if (!isScroll) {
      usernameList.value = [];
      contactList.value = [];
      offset = 0; //limit 20
      hasMoreResult = false;
    }

    Map<String, dynamic> resultList = {};
    try {
      resultList =
          await friend_api.searchUser(param: searchParam.value, offset: offset);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
    if (resultList['username']!.isNotEmpty) {
      usernameList.addAll((resultList['username'] as List<dynamic>)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList());
      if (resultList['username']!.length == 20) {
        hasMoreResult = true;
      } else {
        hasMoreResult = false;
      }
    } else {
      hasMoreResult = false;
    }

    if (resultList['contact']!.isNotEmpty) {
      contactList.addAll((resultList['contact'] as List<dynamic>)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList());
    }

    isSearchTyping.value = false;
  }

  scanQR() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    final PermissionStatus status = await Permission.camera.status;
    if (status.isGranted) {
      Get.toNamed(RouteName.qrCodeScanner);
    } else {
      final bool rationale = await Permission.camera.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied)
        openSettingPopup(Permissions().getPermissionName(Permission.camera));
      else {
        final PermissionStatus status = await Permission.camera.request();
        if (status.isGranted) Get.toNamed(RouteName.qrCodeScanner);
        if (status.isPermanentlyDenied) openSettingPopup(Permissions().getPermissionName(Permission.camera));
      }
    }
  }

  ///添加好友
  void addFriend(User user) async {
    objectMgr.userMgr.addFriend(user);
  }

  ///接受好友请求
  Future<void> acceptFriend(User user) async {
    objectMgr.userMgr.acceptFriend(user);
  }

  ///拒绝好友请求
  Future<void> rejectFriend(User user) async {
    objectMgr.userMgr.rejectFriend(user);
  }

  Widget checkStatus(Relationship status) {
    switch (status) {
      case Relationship.stranger:
      case Relationship.receivedRequest:
        return SvgPicture.asset(
          'assets/svgs/add_new_friend_icon.svg',
          color: accentColor,
        );
      case Relationship.sentRequest:
        return Text(localized(requestSent),
            style: TextStyle(color: accentColor.withOpacity(0.2)));
      default:
        return const Text("");
    }
  }

  void accessContact() {
    Get.dialog(
      ThemedAlertDialog(
        title: localized(jiangXiaWouldLikeToAccessYourContacts),
        content: localized(thisWillBeUsedToManageYourContact),
        cancelButtonText: localized(dontAllow),
        cancelButtonCallback: () {
          Get.back();
          debugPrint(localized(contactAccessDenied));
        },
        confirmButtonText: localized(buttonOk),
        confirmButtonCallback: () {
          Get.back();
          debugPrint(localized(contactAccessAllowed));
        },
      ),
    );
  }

  /// 本地数据库更新通知
  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      updateList(usernameList, data);
      updateList(contactList, data);
    }
  }

  void updateList(RxList<User> userList, User updatedUser) {
    final int index =
        userList.indexWhere((user) => user.uid == updatedUser.uid);
    if (index != -1) {
      // The user exists in the list, update the data
      userList[index] = updatedUser;
    }
  }

  Future<void> findContact(BuildContext context) async {
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(RouteName.shareView);
    } else {
      final permission = await Permission.contacts.status;
      if (permission != PermissionStatus.granted) {
        if (await Permission.contacts.isPermanentlyDenied) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(contactAccessContacts),
                content: Text(
                  localized(contactAccessDesc),
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmText: localized(homeSetting),
                cancelText: localized(buttonCancel),
                confirmColor: accentColor,
                confirmCallback: () => openAppSettings(),
              );
            },
          );
        } else {
          await Permission.contacts.request().isGranted;
          if (await Permission.contacts.isGranted) {
            Get.toNamed(RouteName.localContactView);
          }
        }
      } else {
        Get.toNamed(RouteName.localContactView);
      }
    }
  }

  void onAddFriendClick(BuildContext context, User user) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(contactFriendRequest),
          subTitle:
          "${localized(accept)} ${user.nickname}${localized(sFriendRequest)}?",
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () {
            acceptFriend(user);
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
