import 'package:get/get.dart';
import 'package:jxim_client/api/sound.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/sound_setting/model/sound_selection_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';

class SoundSelectionController extends GetxController {
  int type = 0;
  String title = "";
  RxList<SoundData> soundList = <SoundData>[].obs;
  RxInt currentIndex = (-1).obs;
  User? mainUser = User();
  int? userId;
  SoundData currentSound = SoundData();
  RxBool isLoading = false.obs;

  SoundSelectionController();

  SoundSelectionController.desktop(SoundSelectionModel data) {
    type = data.type;
    if (type == SoundTrackType.SoundTypeIncomingCall.value) {
      title = localized(ringtone);
    } else if (type == SoundTrackType.SoundTypeNotification.value) {
      title = localized(notifSoundType);
    } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
      title = localized(notifSoundType);
    } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
      title = localized(notifSoundType);
    }

    if (data.userId != null) {
      userId = data.userId;
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();

    mainUser = objectMgr.userMgr.getUserById(objectMgr.userMgr.mainUser.uid);

    if (!objectMgr.loginMgr.isDesktop) {
      final arguments = Get.arguments as Map<String, dynamic>;
      if (arguments.containsKey("data")) {
        SoundSelectionModel data = arguments["data"];
        type = data.type;

        if (type == SoundTrackType.SoundTypeIncomingCall.value) {
          title = localized(ringtone);
        } else if (type == SoundTrackType.SoundTypeNotification.value) {
          title = localized(notifSoundType);
        } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
          title = localized(notifSoundType);
        } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
          title = localized(notifSoundType);
        }

        if (data.userId != null) {
          userId = data.userId;
        }
      }
    }

    await getSoundList();
  }

  Future<void> getSoundList() async {
    isLoading.value = true;
    List<SoundData>? data =
        await objectMgr.soundMgr.getSoundTrackListLocalByType(type);
    if (data.isNotEmpty) {
      soundList.value = data;
      setSoundCurrentIndex(type);
    }
    isLoading.value = false;
  }

  void setSoundCurrentIndex(int type) {
    int? soundId = 0;

    if (type == SoundTrackType.SoundTypeIncomingCall.value) {
      soundId = objectMgr.soundMgr.incomingCallSound?.id;
    } else if (type == SoundTrackType.SoundTypeNotification.value) {
      soundId = objectMgr.soundMgr.notificationSound?.id;
    } else if (type == SoundTrackType.SoundTypeSendMessage.value) {
      soundId = objectMgr.soundMgr.sendMessageSound?.id;
    } else if (type == SoundTrackType.SoundTypeGroupNotification.value) {
      soundId = objectMgr.soundMgr.groupNotificationSound?.id;
    }

    currentIndex.value =
        soundList.indexWhere((element) => element.id == soundId);

    if (currentIndex.value > -1) {
      currentSound = soundList[currentIndex.value];
    }
  }

  void onClickItem(int index) {
    currentIndex.value = index;
    SoundData soundData = soundList[index];
    objectMgr.soundMgr.playSelectedSound(soundData);
  }

  void onBackButtonTrigger() {
    int? id = objectMgr.loginMgr.isDesktop ? 3 : null;

    if (currentIndex.value > -1 &&
        currentSound.id != soundList[currentIndex.value].id) {
      showCustomBottomAlertDialog(
        Get.context!,
        subtitle: localized(areYouSureYouWantToDiscard),
        confirmText: localized(discardButton),
        confirmTextColor: colorRed,
        cancelTextColor: themeColor,
        onConfirmListener: () => Get.back(id: id),
      );
    } else {
      Get.back(id: id);
    }
  }

  Future<void> onDoneButtonClick() async {
    if (currentIndex.value > -1) {
      SoundData soundData = soundList[currentIndex.value];
      bool res = await setUserSound(soundData.id, type);
      if (res) {
        objectMgr.soundMgr.saveSoundData(type, soundData.id ?? 0);
      }
      Get.back(id: objectMgr.loginMgr.isDesktop ? 3 : null);
    } else {
      Toast.showToast("Please select a sound");
    }
  }
}
