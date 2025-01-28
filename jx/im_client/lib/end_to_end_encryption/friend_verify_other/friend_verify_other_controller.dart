import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/friend_list_bottom_sheet/friend_list_bottom_sheet_controller.dart';
import 'package:jxim_client/end_to_end_encryption/friend_list_bottom_sheet/friend_list_bottom_sheet_view.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';

class FriendVerifyOtherController extends GetxController {
  User? user;
  RxString friendName = ''.obs;
  TextEditingController textEditingController = TextEditingController();
  FocusNode pwFocusNode = FocusNode();
  RxBool isValidSubmit = false.obs;

  void showFriendListPopup(BuildContext context) {
    FriendListBottomSheetController friendListBottomSheetController =
        Get.put(FriendListBottomSheetController());

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return FriendListBottomSheetView(
          controller: friendListBottomSheetController,
          callback: (value) {
            user = value;
            validateToProceed(user, textEditingController.text);
            friendName.value = objectMgr.userMgr.getUserTitle(value);
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<FriendListBottomSheetController>();
    });
  }

  void onChanged(String value) {
    validateToProceed(user, value);
  }

  void validateToProceed(User? user, String code) {
    if (code != '' && user != null) {
      isValidSubmit.value = true;
    } else {
      isValidSubmit.value = false;
    }
  }

  void onClickNext() {
    if (!isValidSubmit.value) {
      return;
    }

    if (user != null && textEditingController.text != '') {
      Get.toNamed(
        RouteName.encryptionFriendVerifyOtherConfirmPage,
        arguments: {
          'user': user,
          'code': textEditingController.text,
        },
      );
    }
  }
}
