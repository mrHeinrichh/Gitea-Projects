import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

class EditContactController extends GetxController {
  final Color buttonColor = const Color(0xFF7561E5);
  final TextEditingController aliasController = TextEditingController();

  RxBool isChecked = false.obs;
  RxBool canSubmit = false.obs;
  RxString nickname = "".obs;
  RxBool invalidName = false.obs;
  RxBool showClearBtn = false.obs;
  final user = Rxn<User>();
  bool isDeletedAccount = false;

  int uid = 0;

  EditContactController();
  EditContactController.desktop({int? uid}){
    if(uid != null){
      this.uid = uid;
    }
  }

  onInit() async {
    super.onInit();
    if(Get.arguments?["uid"] != null){
      uid = Get.arguments["uid"];
    }
    user.value = await objectMgr.userMgr.loadUserById(uid);
    nickname.value = user.value?.nickname ?? '';
    aliasController.text = objectMgr.userMgr.getUserTitle(user.value);
    isDeletedAccount = (user.value?.deletedAt != 0);
    validateChanges();

    ///监听数据库的更新
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
  }

  void setShowClearBtn(bool showBtn) {
    if (!showBtn) {
      invalidName.value = false;
    }

    showClearBtn(showBtn);
  }

  void clearName(){
    aliasController.clear();
    setShowClearBtn(false);
    checkName('');
  }

  onClose() {
    super.onClose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
  }

  void confirmUnfriend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(contactUnfriend),
          subTitle: localized(contactThisContactWillNoLongerBeYourFriend),
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonCancel),
          confirmButtonColor: errorColor,
          cancelButtonColor: accentColor,
          confirmCallback: () async {
            if (await deleteFriend(uuid: user.value?.accountId ?? '')) {
              ImBottomToast(Routes.navigatorKey.currentContext!,
                  title: localized(contactUnfriendSuccessfully),
                  icon: ImBottomNotifType.unfriend);
              if( objectMgr.loginMgr.isDesktop){
                final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
                Get.back(id:objectMgr.loginMgr.isDesktop ?id : null);
              }
            } else {
              pdebug(
                  "*Error* rejectFriend(edit_contact_controller) - API return false");
            }
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
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
    if (invalidName.value || isDeletedAccount || (aliasController.text == objectMgr.userMgr.getUserTitle(user.value))) {
      canSubmit.value = false;
    } else {
      canSubmit.value = true;
    }
  }

  void changeFriendDetails() async {
    if (canSubmit.value) {
      if (user.value == null) return;
      if (aliasController.text == objectMgr.userMgr.getUserTitle(user.value)) {
        //代表沒有改動
        final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
        Get.back(id:objectMgr.loginMgr.isDesktop ? id : null);
        return;
      }
      user.value?.alias = aliasController.text;
      if (aliasController.text.toLowerCase() == nickname.value.toLowerCase()) {
        user.value?.alias = '';
      }
      try {
        final res = await editFriendNickname(
          uuid: user.value!.accountId,
          alias: user.value!.alias,
        );
        if (res) {
          objectMgr.userMgr.onUserChanged([user.value!], notify: true);
          final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
          Get.back(id:objectMgr.loginMgr.isDesktop ? id : null);
          ImBottomToast(Routes.navigatorKey.currentContext!,
              title: localized(toastChangeFriendAliasSuccessfully),
              icon: ImBottomNotifType.success);
          // Toast.showToast(localized(toastChangeFriendAliasSuccessfully));
        } else {
          ImBottomToast(Routes.navigatorKey.currentContext!,
              title: localized(toastChangeFriendAliasUnsuccessfully),
              icon: ImBottomNotifType.warning);
          // Toast.showToast(localized(toastChangeFriendAliasUnsuccessfully));
        }
      } catch (e) {
        // Toast.showToast(localized(toastUnknownError));
        ImBottomToast(Routes.navigatorKey.currentContext!,
            title: localized(toastUnknownError),
            icon: ImBottomNotifType.warning);
      }
    }
  }

  ///更新数据库通知
  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User && user.value?.uid == data.uid) {
      if (data.relationship != Relationship.friend) {
        Toast.showToast(
            "${localized(youHaveBeenRemovedFrom)} ${user.value?.nickname}${localized(sFriendList)}");
        Get.back();
      }
    }
  }
}
