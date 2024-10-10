import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

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
    aliasController.text = objectMgr.userMgr.getUserTitle(user.value);
    isDeletedAccount = (user.value?.deletedAt != 0);
    isBlocked.value = (user.value?.relationship == Relationship.blocked);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          withHeader: false,
          confirmButtonText: localized(editContactDeleteFriendTitle),
          cancelButtonText: localized(cancel),
          confirmButtonTextStyle: jxTextStyle.textStyle20(color: colorRed),
          cancelButtonTextStyle: jxTextStyle.textStyle20(color: themeColor),
          confirmCallback: () async {
            Relationship oldRelationship = user.value!.relationship;
            if (oldRelationship != Relationship.blocked &&
                oldRelationship != Relationship.blockByTarget) {
              user.value?.relationship = Relationship.stranger;
              objectMgr.userMgr.onUserChanged([user.value!], notify: true);
            }

            imBottomToast(
              context,
              title: localized(contactUnfriendSuccessfully),
              icon: ImBottomNotifType.unfriendSuccess,
              duration: 3,
              isStickBottom: false,
            );
            Future.delayed(const Duration(seconds: 1), () {
              imBottomToast(
                context,
                title: localized(editContactDeleteFriendTitle),
                icon: ImBottomNotifType.timer,
                duration: 5,
                withCancel: true,
                timerFunction: () async {
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
                },
                undoFunction: () {
                  BotToast.removeAll(BotToast.textKey);
                  if (oldRelationship != user.value!.relationship) {
                    user.value?.relationship = oldRelationship;
                    objectMgr.userMgr
                        .onUserChanged([user.value!], notify: true);
                  }
                },
              );
            });
            if (objectMgr.loginMgr.isDesktop) {
              final id =
                  Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
              Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
            } else {
              Get.until((route) => Get.currentRoute == RouteName.home);
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
      if (aliasController.text == objectMgr.userMgr.getUserTitle(user.value)) {
        //代表沒有改動
        final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
        Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
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
      doUnblockUser();
    } else {
      doBlockUser();
    }
  }

  void doBlockUser() async {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          withHeader: false,
          confirmButtonText: localized(editContactBlockFriendTitle),
          confirmButtonTextStyle: jxTextStyle.textStyle20(color: colorRed),
          cancelButtonText: localized(buttonCancel),
          cancelButtonTextStyle: jxTextStyle.textStyle20(color: themeColor),
          confirmCallback: () {
            objectMgr.userMgr.blockUser(user.value!);
            isBlocked.value = true;
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void doUnblockUser() async {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(
            unblockUserName,
            params: [objectMgr.userMgr.getUserTitle(user.value)],
          ),
          titleTextStyle: jxTextStyle.textStyleBold17(),
          subTitle: localized(unblockUserDesc),
          subtitleTextStyle: jxTextStyle.textStyle13(color: colorTextSecondary),
          confirmButtonText: localized(buttonUnblock),
          confirmButtonTextStyle: jxTextStyle.textStyle17(color: colorRed),
          cancelButtonText: localized(buttonNo),
          cancelButtonTextStyle: jxTextStyle.textStyleBold17(color: themeColor),
          confirmCallback: () {
            isBlocked.value = false;
            objectMgr.userMgr.unblockUser(user.value!);
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
