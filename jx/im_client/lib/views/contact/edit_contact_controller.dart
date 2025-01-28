import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';

class EditContactController extends GetxController {
  final Color buttonColor = const Color(0xFF7561E5);
  final TextEditingController aliasController = TextEditingController();

  RxBool isChecked = false.obs;
  RxBool canSubmit = false.obs;
  RxString nickname = "".obs;
  RxBool invalidName = false.obs;
  RxBool showClearBtn = false.obs;
  RxBool isBlocked = false.obs;
  final user = Rxn<User>();
  bool isDeletedAccount = false;

  int uid = 0;

  EditContactController();

  EditContactController.desktop({int? uid}) {
    if (uid != null) {
      this.uid = uid;
    }
  }

  @override
  onInit() async {
    super.onInit();
    if (Get.arguments?["uid"] != null) {
      uid = Get.arguments["uid"];
    }
    user.value = await objectMgr.userMgr.loadUserById(uid);
    nickname.value = user.value?.nickname ?? '';
    isDeletedAccount = (user.value?.deletedAt != 0);
    isBlocked.value = (user.value?.relationship == Relationship.blocked);
    if (isDeletedAccount) {
      aliasController.text = localized(deletedAccountTitle);
    } else {
      aliasController.text = objectMgr.userMgr.getUserTitle(user.value);
    }
    validateChanges();
  }

  void setShowClearBtn(bool showBtn) {
    if (!showBtn) {
      invalidName.value = false;
    }

    showClearBtn(showBtn);
  }

  void clearName() {
    aliasController.clear();
    setShowClearBtn(false);
    checkName('');
  }

  void confirmUnfriend(BuildContext context) {
    showCustomBottomAlertDialog(
      Get.context!,
      withHeader: false,
      confirmText: localized(editContactDeleteFriendTitle),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () async {
        Relationship oldRelationship = user.value!.relationship;
        if (oldRelationship != Relationship.blocked &&
            oldRelationship != Relationship.blockByTarget) {
          user.value?.relationship = Relationship.stranger;
          user.value?.friendTags?.clear();
          objectMgr.userMgr.onUserChanged([user.value!], notify: true);
        }

        imBottomToast(
          context,
          title: localized(contactUnfriendSuccessfully),
          icon: ImBottomNotifType.unfriendSuccess,
          duration: 3,
        );
        Future.delayed(const Duration(seconds: 1), () async {
          // unblock then unfriend
          if (oldRelationship == Relationship.blocked) {
            await objectMgr.userMgr.unblockUser(user.value!);
          }

          if (await deleteFriend(uuid: user.value?.accountId ?? '')) {
          } else {
            pdebug(
              "*Error* rejectFriend(edit_contact_controller) - API return false",
            );
          }
        });
        if (objectMgr.loginMgr.isDesktop) {
          final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
          Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
        } else {
          Get.until((route) => Get.currentRoute == RouteName.home);
        }
      },
    );
  }

  void undoName() {
    aliasController.text = nickname.value;
    checkName(nickname.value);
  }

  void checkName(String name) {
    bool hasForeSpace = Regular.foreWithSpace(name);
    final textLength = getMessageLength(name);

    if (textLength < 0 || textLength > 30 || hasForeSpace) {
      invalidName.value = true;
    } else {
      invalidName.value = false;
    }
    validateChanges();
  }

  void validateChanges() {
    if (invalidName.value ||
        isDeletedAccount ||
        (aliasController.text == objectMgr.userMgr.getUserTitle(user.value))) {
      canSubmit.value = false;
    } else {
      canSubmit.value = true;
    }
  }

  void changeFriendDetails() async {
    if (canSubmit.value) {
      if (user.value == null) return;
      String newAlias = aliasController.text.trim();
      if (newAlias == objectMgr.userMgr.getUserTitle(user.value)) {
        //代表沒有改動
        final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
        Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
        return;
      }
      user.value?.alias = newAlias;
      if (newAlias.toLowerCase() == nickname.value.toLowerCase()) {
        user.value?.alias = '';
      }
      try {
        final res = await editFriendNickname(
          uuid: user.value!.accountId,
          alias: user.value!.alias,
          friendTags: user.value!.friendTags ?? <int>[],
        );
        if (res) {
          objectMgr.userMgr.onUserChanged([user.value!], notify: true);
          final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
          Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(toastChangeFriendAliasSuccessfully),
            icon: ImBottomNotifType.success,
          );
          // Toast.showToast(localized(toastChangeFriendAliasSuccessfully));
        } else {
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(toastChangeFriendAliasUnsuccessfully),
            icon: ImBottomNotifType.warning,
          );
          // Toast.showToast(localized(toastChangeFriendAliasUnsuccessfully));
        }
      } catch (e) {
        // Toast.showToast(localized(toastUnknownError));
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(toastUnknownError),
          icon: ImBottomNotifType.warning,
        );
      }
    }
  }

  void onTapBlock(bool value) {
    if (isBlocked.value) {
      isBlocked.value = false;
      objectMgr.userMgr.unblockUser(user.value!);
    } else {
      doBlockUser();
    }
  }

  void doBlockUser() async {
    showCustomBottomAlertDialog(
      Get.context!,
      withHeader: false,
      confirmText: localized(editContactBlockFriendTitle),
      cancelText: localized(buttonCancel),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () {
        objectMgr.userMgr.blockUser(user.value!);
        isBlocked.value = true;
      },
    );
  }
}
