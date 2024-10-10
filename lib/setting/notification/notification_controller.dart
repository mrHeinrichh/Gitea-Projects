import 'dart:io';

import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/sound_setting/model/sound_selection_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/utility.dart';

import 'package:jxim_client/api/chat.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/user_mgr.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';

class NotificationController extends GetxController {
  final SettingServices _settingServices = SettingServices();

  final privateChatMute = true.obs;
  final groupChatMute = true.obs;
  final walletMute = true.obs;
  final friendMute = true.obs;

  final privateChatPreviewNotification = false.obs;
  final groupChatPreviewNotification = false.obs;
  final walletPreviewNotification = false.obs;
  final friendPreviewNotification = false.obs;

  final privateChatNotificationType = NotificationMode.soundVibrate.obs;
  final groupChatNotificationType = NotificationMode.soundVibrate.obs;
  final walletNotificationType = NotificationMode.soundVibrate.obs;
  final friendNotificationType = NotificationMode.soundVibrate.obs;

  List<MuteItem> privateChatMuteList = <MuteItem>[].obs;
  List<MuteItem> groupChatMuteList = <MuteItem>[].obs;

  final notificationSection = NotificationSection.none.obs;
  final isSelectNotifyTypeIndex = 0.obs;

  final List<SelectionOptionModel> notificationTypeList = [
    if (!Platform.isIOS) ...{
      SelectionOptionModel(
        title: localized(notifSoundType),
        value: NotificationMode.sound.value,
        isSelected: false,
      ),
    },
    SelectionOptionModel(
      title: localized(notifVibrateType),
      value: NotificationMode.vibrate.value,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(notifSoundVibrateType),
      value: NotificationMode.soundVibrate.value,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(notifSilentType),
      value: NotificationMode.silent.value,
      isSelected: false,
    ),
  ];

  /// 发送信息的声音
  final messageSoundNotification = true.obs;

  @override
  void onInit() {
    super.onInit();
    objectMgr.userMgr.on(UserMgr.eventMessageSound, _updateMessageSound);

    initNotificationSetting();
    initMessageSoundNotification();
  }

  @override
  void onClose() {
    objectMgr.userMgr.off(UserMgr.eventMessageSound, _updateMessageSound);
    super.onClose();
  }

  void _updateMessageSound(Object? sender, Object? type, Object? data) async {
    if (data == null) return;
    final CustomData result = data as CustomData;
    if (result.message['key'] == StoreData.messageSoundData.key) {
      setMessageSoundStatus(stringToBool(result.message['value']));
    }
  }

  void initNotificationSetting() async {
    final data = await _settingServices.getNotificationSetting();

    privateChatMute.value = data.privateChatMute;
    objectMgr.pushMgr.updateMute(1, privateChatMute.value);

    groupChatMute.value = data.groupChatMute;
    objectMgr.pushMgr.updateMute(2, groupChatMute.value);

    walletMute.value = data.walletMute;
    objectMgr.pushMgr.updateMute(4, walletMute.value);

    friendMute.value = data.friendMute;
    objectMgr.pushMgr.updateMute(3, friendMute.value);

    privateChatPreviewNotification.value = data.privateChatPreviewNotification;
    objectMgr.pushMgr.updatePreview(1, privateChatPreviewNotification.value);

    groupChatPreviewNotification.value = data.groupChatPreviewNotification;
    objectMgr.pushMgr.updatePreview(2, groupChatPreviewNotification.value);

    walletPreviewNotification.value = data.walletPreviewNotification;
    objectMgr.pushMgr.updatePreview(4, walletPreviewNotification.value);

    friendPreviewNotification.value = data.friendPreviewNotification;
    objectMgr.pushMgr.updatePreview(3, friendPreviewNotification.value);

    setNotificationTypeLocalStorage(
      NotificationSection.privateChat,
      data.privateChatNotificationType,
    );
    setNotificationTypeLocalStorage(
      NotificationSection.groupChat,
      data.groupChatNotificationType,
    );
    setNotificationTypeLocalStorage(
      NotificationSection.wallet,
      data.walletNotificationType,
    );
    setNotificationTypeLocalStorage(
      NotificationSection.friend,
      data.friendNotificationType,
    );

    privateChatMuteList.addAll(data.privateChatMuteList);
    groupChatMuteList.addAll(data.groupChatMuteList);

    privateChatMuteList.sort((a, b) => b.createdTime.compareTo(a.createdTime));
    groupChatMuteList.sort((a, b) => b.createdTime.compareTo(a.createdTime));
  }

  bool getShowNotificationVariable() {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        return privateChatMute.value;
      case NotificationSection.groupChat:
        return groupChatMute.value;
      case NotificationSection.wallet:
        return walletMute.value;
      case NotificationSection.friend:
        return friendMute.value;
      default:
        return false;
    }
  }

  bool getShowPreviewVariable() {
    if (getShowNotificationVariable()) {
      switch (notificationSection.value) {
        case NotificationSection.privateChat:
          return privateChatPreviewNotification.value;
        case NotificationSection.groupChat:
          return groupChatPreviewNotification.value;
        case NotificationSection.wallet:
          return walletPreviewNotification.value;
        case NotificationSection.friend:
          return friendPreviewNotification.value;
        default:
          return false;
      }
    } else {
      return false;
    }
  }

  Future<void> setNotification(bool value) async {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        privateChatMute.value = value;
        objectMgr.pushMgr.updateMute(1, value);

        break;
      case NotificationSection.groupChat:
        groupChatMute.value = value;
        objectMgr.pushMgr.updateMute(2, value);

        break;
      case NotificationSection.wallet:
        walletMute.value = value;
        objectMgr.pushMgr.updateMute(4, value);

        break;
      case NotificationSection.friend:
        friendMute.value = value;
        objectMgr.pushMgr.updateMute(3, value);

        break;
      case NotificationSection.none:
        break;
    }

    if (notificationSection.value != NotificationSection.none) {
      final result = await _settingServices.setGlobalNotification(
        notificationSection.value,
        getNotificationTypeLocalStorage(notificationSection.value, value),
      );
      if (result) {
        switch (notificationSection.value) {
          case NotificationSection.privateChat:
            privateChatNotificationType.value = getNotificationTypeLocalStorage(
              NotificationSection.privateChat,
              value,
            );
            break;
          case NotificationSection.groupChat:
            groupChatNotificationType.value = getNotificationTypeLocalStorage(
              NotificationSection.groupChat,
              value,
            );
            break;
          case NotificationSection.wallet:
            walletNotificationType.value = getNotificationTypeLocalStorage(
              NotificationSection.wallet,
              value,
            );
            break;
          case NotificationSection.friend:
            friendNotificationType.value = getNotificationTypeLocalStorage(
              NotificationSection.friend,
              value,
            );
            break;
          case NotificationSection.none:
            break;
        }
      }
    }
  }

  void setPreview(bool value) {
    if (getShowNotificationVariable()) {
      switch (notificationSection.value) {
        case NotificationSection.privateChat:
          privateChatPreviewNotification.value = value;
          objectMgr.pushMgr.updatePreview(1, value);
          break;
        case NotificationSection.groupChat:
          groupChatPreviewNotification.value = value;
          objectMgr.pushMgr.updatePreview(2, value);

          break;
        case NotificationSection.wallet:
          walletPreviewNotification.value = value;
          objectMgr.pushMgr.updatePreview(3, value);

          break;
        case NotificationSection.friend:
          friendPreviewNotification.value = value;
          objectMgr.pushMgr.updatePreview(4, value);

          break;
        case NotificationSection.none:
          break;
      }
    } else {
      Toast.showToast(
        localized(notifManageMP),
      );
    }

    if (notificationSection.value != NotificationSection.none) {
      _settingServices.setPreviewNotification(
        notificationSection.value,
        value ? 1 : 0,
      );
    }
  }

  NotificationMode getNotificationMode() {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        return privateChatNotificationType.value;
      case NotificationSection.groupChat:
        return groupChatNotificationType.value;
      case NotificationSection.wallet:
        return walletNotificationType.value;
      case NotificationSection.friend:
        return friendNotificationType.value;
      case NotificationSection.none:
        return NotificationMode.silent;
    }
  }

  List<MuteItem> getExceptionList() {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        return privateChatMuteList;
      case NotificationSection.groupChat:
        return groupChatMuteList;
      default:
        return [];
    }
  }

  int getGroupInfoValue(index) {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        return privateChatMuteList[index].friendID!;
      case NotificationSection.groupChat:
        return groupChatMuteList[index].chatID;
      default:
        return 0;
    }
  }

  String getMuteDetail(index) {
    switch (notificationSection.value) {
      case NotificationSection.privateChat:
        return privateChatMuteList[index].expiry.getMuteDetail;
      case NotificationSection.groupChat:
        return groupChatMuteList[index].expiry.getMuteDetail;
      default:
        return 'Error';
    }
  }

  bool showExceptionList() {
    if (notificationSection.value == NotificationSection.privateChat ||
        notificationSection.value == NotificationSection.groupChat) {
      return true;
    }
    return false;
  }

  void deleteAllException() async {
    final List<MuteItem> muteList =
        (notificationSection.value == NotificationSection.privateChat)
            ? privateChatMuteList
            : groupChatMuteList;
    if (muteList.isNotEmpty) {
      final data = await _settingServices.setAllExceptionNotification(
        muteList.map<int>((e) => e.chatID).toList(),
      );

      for (MuteItem muteItem in muteList) {
        Chat? chat = objectMgr.chatMgr.getChatById(muteItem.chatID);
        if (chat != null) {
          objectMgr.chatMgr.updateNotificationStatus(chat, 0);
        }
      }

      muteList.removeWhere((element) => !data.contains(element.chatID));
      if (muteList.isEmpty) {
        Toast.showToast(localized(msgUnMuteAllChatSuccess));
      } else {
        Toast.showToast(localized(errorUnMuteFailed));
      }
    }
  }

  void unMuteSpecificChat(index) async {
    final data = (notificationSection.value == NotificationSection.privateChat)
        ? privateChatMuteList[index]
        : groupChatMuteList[index];
    var res = await muteSpecificChat(data.chatID, 0);
    if (res.success()) {
      Chat? chat = objectMgr.chatMgr.getChatById(data.chatID);
      if (chat != null) {
        objectMgr.chatMgr.updateNotificationStatus(chat, 0);
        Toast.showToast(localized(chatInfoUnMuteChatSuccessful));
      }
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }

    if (notificationSection.value == NotificationSection.privateChat) {
      privateChatMuteList.removeAt(index);
    } else {
      groupChatMuteList.removeAt(index);
    }
  }

  Future<void> changeNotificationMode(NotificationMode notificationMode) async {
    final result = await _settingServices.setGlobalNotification(
      notificationSection.value,
      notificationMode,
    );

    if (result) {
      switch (notificationSection.value) {
        case NotificationSection.privateChat:
          privateChatNotificationType.value = notificationMode;
          break;
        case NotificationSection.groupChat:
          groupChatNotificationType.value = notificationMode;
          break;
        case NotificationSection.wallet:
          walletNotificationType.value = notificationMode;
          break;
        case NotificationSection.friend:
          friendNotificationType.value = notificationMode;
          break;
        case NotificationSection.none:
          break;
      }
      objectMgr.pushMgr
          .updateMode(notificationSection.value.value, notificationMode);
      setNotificationTypeLocalStorage(
        notificationSection.value,
        notificationMode,
      );
    }
  }

  Future<void> setNotificationTypeLocalStorage(
    NotificationSection notificationSection,
    NotificationMode notificationMode,
  ) async {
    String notificationSectionKey = "";
    switch (notificationSection) {
      case NotificationSection.privateChat:
        notificationSectionKey = LocalStorageMgr.PRIVATE_CHAT_NOTIFICATION;
        privateChatNotificationType.value = notificationMode;
        break;
      case NotificationSection.groupChat:
        notificationSectionKey = LocalStorageMgr.GROUP_CHAT_NOTIFICATION;
        groupChatNotificationType.value = notificationMode;
        break;
      case NotificationSection.wallet:
        notificationSectionKey = LocalStorageMgr.WALLET_NOTIFICATION;
        walletNotificationType.value = notificationMode;
        break;
      case NotificationSection.friend:
        notificationSectionKey = LocalStorageMgr.FRIEND_NOTIFICATION;
        friendNotificationType.value = notificationMode;
        break;
      case NotificationSection.none:
        break;
    }

    objectMgr.pushMgr.updateMode(notificationSection.value, notificationMode);

    if (notificationMode != NotificationMode.mute) {
      objectMgr.localStorageMgr
          .write(notificationSectionKey, notificationMode.value);
    }
  }

  NotificationMode getNotificationTypeLocalStorage(
    NotificationSection notificationSection,
    bool notificationStatus,
  ) {
    String notificationSectionKey = "";
    switch (notificationSection) {
      case NotificationSection.privateChat:
        notificationSectionKey = LocalStorageMgr.PRIVATE_CHAT_NOTIFICATION;
        break;
      case NotificationSection.groupChat:
        notificationSectionKey = LocalStorageMgr.GROUP_CHAT_NOTIFICATION;
        break;
      case NotificationSection.wallet:
        notificationSectionKey = LocalStorageMgr.WALLET_NOTIFICATION;
        break;
      case NotificationSection.friend:
        notificationSectionKey = LocalStorageMgr.FRIEND_NOTIFICATION;
        break;
      case NotificationSection.none:
        break;
    }

    if (notificationStatus) {
      int? notificationMode =
          objectMgr.localStorageMgr.read(notificationSectionKey);
      if (notificationMode != null) {
        return getMode(notificationMode);
      } else {
        return NotificationMode.soundVibrate;
      }
    } else {
      return NotificationMode.mute;
    }
  }

  Future<void> initMessageSoundNotification() async {
    bool? status = objectMgr.localStorageMgr
        .read(LocalStorageMgr.MESSAGE_SOUND_NOTIFICATION);
    if (status != null) {
      messageSoundNotification.value = status;
    } else {
      final GetStoreData res = await getStore(StoreData.messageSoundData.key);
      if (notBlank(res.value)) {
        setMessageSoundStatus(stringToBool(res.value));
      } else {
        setMessageSoundStatusRemote(true);
      }
    }
  }

  Future<void> setMessageSoundStatusRemote(bool status) async {
    final bool res = await updateStore(
      StoreData.messageSoundData.key,
      status.toString(),
      isBroadcast: true,
    );
    if (res) {
      setMessageSoundStatus(status);
    }
  }

  void setMessageSoundStatus(bool status) {
    messageSoundNotification.value = status;
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.MESSAGE_SOUND_NOTIFICATION, status);
  }

  void changeSound(int type) {
    Get.toNamed(
      RouteName.soundSelection,
      arguments: {"data": SoundSelectionModel(type: type)},
    );
  }

  void changeCallSound() {
    Get.toNamed(RouteName.ringtoneSoundSetting);
  }

  void onClickChangeSound() {
    if (notificationSection.value == NotificationSection.privateChat) {
      changeSound(SoundTrackType.SoundTypeNotification.value);
    } else {
      changeSound(SoundTrackType.SoundTypeGroupNotification.value);
    }
  }
}

extension BooleanUtils on bool {
  String get getStatus {
    if (this) {
      return localized(plOn);
    } else {
      return localized(plOff);
    }
  }

  NotificationMode get getNotificationMode {
    if (this) {
      return NotificationMode.soundVibrate;
    } else {
      return NotificationMode.mute;
    }
  }
}

enum NotificationSection {
  none(value: 0),
  privateChat(value: 1),
  groupChat(value: 2),
  wallet(value: 3),
  friend(value: 4);

  final int value;

  const NotificationSection({required this.value});
}

extension NotificationSectionUtils on NotificationSection {
  String? get toTitle {
    switch (this) {
      case NotificationSection.privateChat:
        return localized(notifPrivatesChat);
      case NotificationSection.groupChat:
        return localized(notifGroupChats);
      case NotificationSection.wallet:
        return localized(walletWallet);
      case NotificationSection.friend:
        return localized(contactFriendRequest);
      default:
        return "";
    }
  }
}

enum NotificationMode {
  soundVibrate(value: 0),
  mute(value: 1),
  vibrate(value: 2),
  silent(value: 3),
  sound(value: 4);

  final int value;

  const NotificationMode({required this.value});
}

NotificationMode getMode(int notificationType){
  switch (notificationType) {
    case 0:
      return NotificationMode.soundVibrate;
    case 1:
      return NotificationMode.mute;
    case 2:
      return NotificationMode.vibrate;
    case 3:
      return NotificationMode.silent;
    case 4:
      return NotificationMode.sound;
    default:
      return NotificationMode.soundVibrate;
  }
}

extension NotificationModeUtils on NotificationMode {
  String get toStatus {
    switch (this) {
      case NotificationMode.soundVibrate:
        return localized(notifSoundVibrateType);
      case NotificationMode.sound:
        return localized(notifSoundType);
      case NotificationMode.vibrate:
        return localized(notifVibrateType);
      case NotificationMode.mute:

        /// hide Mute Text
        return "";
      //return localized(notifMuteType);
      case NotificationMode.silent:
        return localized(notifSilentType);
    }
  }
}
