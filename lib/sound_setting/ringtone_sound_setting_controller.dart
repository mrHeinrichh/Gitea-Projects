import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/sound.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/sound_setting/model/sound_selection_model.dart';
import 'package:jxim_client/sound_setting/select_friend_bottom_sheet.dart';
import 'package:jxim_client/sound_setting/select_friend_bottom_sheet_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

class RingtoneSoundSettingController extends GetxController {
  RxList userList = <String>[].obs;
  RxBool isEditMode = false.obs;
  RxBool isSetOutGoingSound = false.obs;

  @override
  void onInit() {
    super.onInit();
    getRingtoneUserList();
    setOutGoingSound();
  }

  void changeSound() {
    Get.toNamed(
      RouteName.soundSelection,
      arguments: {
        "data": SoundSelectionModel(
          type: SoundTrackType.SoundTypeIncomingCall.value,
        ),
      },
    );
  }

  void selectFriend() {
    SelectFriendBottomSheetController controller =
        Get.put(SelectFriendBottomSheetController());

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return SelectFriendBottomSheet(
          controller: controller,
          callBack: () {},
        );
      },
    ).then((value) {
      Get.findAndDelete<SelectFriendBottomSheetController>();
    });
  }

  void getRingtoneUserList() {
    userList.add("User 1");
    userList.add("User 2");
    userList.add("User 3");
    userList.add("User 4");
  }

  Future<void> setOutGoingSound() async {
    User? mainUser =
        objectMgr.userMgr.getUserById(objectMgr.userMgr.mainUser.uid);
    if (mainUser != null) {
      if (mainUser.outgoingSoundId == 0) {
        isSetOutGoingSound.value = false;
      } else {
        isSetOutGoingSound.value = true;
      }
    }
  }

  Future<void> onChangeOutGoingSound(bool value) async {
    int? soundId = 0;

    if (value) {
      SoundData? soundData = objectMgr.soundMgr.incomingCallSound;
      if (soundData != null) {
        soundId = soundData.id;
      }
    }

    bool res =
        await setUserSound(soundId, SoundTrackType.SoundTypeOutgoingCall.value);
    if (res) {
      isSetOutGoingSound.value = value;
      objectMgr.soundMgr.saveSoundData(
        SoundTrackType.SoundTypeOutgoingCall.value,
        soundId ?? 0,
      );
    }
  }

  void onDeleteCustomization(bool isAll) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title:
              "${localized(isAll ? deleteAllCustomization : deleteSelectedCustomization)}?",
          confirmButtonText: localized(buttonDelete),
          cancelButtonText: localized(buttonCancel),
          confirmButtonColor: colorRed,
          confirmCallback: () => confirmDelete(isAll),
          cancelCallback: () => Get.back(),
          cancelButtonColor: themeColor,
        );
      },
    );
  }

  void confirmDelete(bool isAll) {
    isEditMode.value = false;
  }

  void onEditDoneButtonClick() {
    isEditMode.value = !isEditMode.value;
  }
}
