import 'dart:io';

import 'package:intl/intl.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/toast.dart';

import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';

const String showProfileUsername = 'show_profile_username';
const String showProfilePhoneNumber = 'show_profile_phone_number';
const String showProfilePicture = 'show_profile_picture';
const String showLastSeen = 'show_last_seen';
const String searchByUsername = 'search_by_username';
const String searchByPhoneNumber = 'search_by_phone_number';
const String showEmailAddress = 'show_profile_email';

class SettingServices {
  Future<Secure?> getPasscodeSetting() async {
    try {
      final ResponseData res =
          await CustomRequest.doGet('/app/api/wallet/settings');

      if (res.success()) {
        return Secure.fromIndex(res.data['secure_interval']);
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      if (e.getPrefix() == 101) {
        return null;
      }
      pdebug('AppException: ${e.toString()}');
      return null;
    }
  }

  Future<bool> setPasscode({
    String? passcode,
  }) async {
    final Map<String, dynamic> dataBody = {
      'passcode': '$passcode',
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/wallet/setup-passcode',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        // throw AppException(res.code, res.message);
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> resetPasscode(String? oldPasscode, String? newPasscode) async {
    final Map<String, dynamic> dataBody = {};
    dataBody["old_passcode"] = oldPasscode;
    dataBody["new_passcode"] = newPasscode;

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/wallet/reset-passcode',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> forgetPasscode(String? newPasscode, String? vcode) async {
    final Map<String, dynamic> dataBody = {};
    dataBody["new_passcode"] = newPasscode;
    dataBody["token"] = vcode;

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/wallet/forget-passcode',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> checkPasscode(String? passcode) async {
    final Map<String, dynamic> dataBody = {};
    dataBody["passcode"] = passcode;

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/wallet/check-passcode',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> passcode({
    String? passcode,
  }) async {
    final Map<String, dynamic> dataBody = {
      'passcode': '$passcode',
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        "/app/api/account/wallet/setup-passcode",
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        // throw AppException(res.code, res.message);
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPrivacySetting() async {
    try {
      final ResponseData res =
          await CustomRequest.doGet('/app/api/account/settings/privacy/get');

      if (res.success()) {
        return res.data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPrivacyTypeSetting() async {
    try {
      final ResponseData res =
          await CustomRequest.doGet('/app/api/account/settings/privacy/get');

      if (res.success()) {
        return res.data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> updatePrivacySetting(
    String privacyType,
    int privacyStatus,
  ) async {
    Map<String, dynamic> data = {};

    data[privacyType] = privacyStatus;
    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/account/settings/privacy/update',
        data: data,
      );

      if (res.success()) {
        return true;
      } else {
        // throw AppException(res.code, res.message);
        return false;
      }
    } on AppException catch (e) {
      if (e is NetworkException) {
        Toast.showToast(e.getMessage());
      } else {
        pdebug('AppException: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<bool> updateSingleDevicePrivacy(
    String privacyType,
    int privacyStatus,
  ) async {
    Map<String, dynamic> data = {};

    data[privacyType] = privacyStatus;
    try {
      final ResponseData res = await CustomRequest.doPost(
        '/app/api/auth/privacy/update',
        data: data,
      );

      if (res.success()) {
        return true;
      } else {
        // throw AppException(res.code, res.message);
        return false;
      }
    } on AppException catch (e) {
      if (e is NetworkException) {
        Toast.showToast(e.getMessage());
      } else {
        pdebug('AppException: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<NotificationSetting> getNotificationSetting() async {
    try {
      final ResponseData res = await CustomRequest.doPost(
        '/im/user',
      );

      if (res.success()) {
        return NotificationSetting.fromJson(res.data);
      } else {
        return NotificationSetting();
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> setGlobalNotification(
    NotificationSection notificationSection,
    NotificationMode notificationMode,
  ) async {
    final Map<String, dynamic> dataBody = {
      'mode': notificationMode.value,
      'type': notificationSection.value,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/im/user/mute',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }

  Future<bool> setPreviewNotification(
    NotificationSection notificationSection,
    int previewMode,
  ) async {
    final Map<String, dynamic> dataBody = {
      'preview': previewMode,
      'type': notificationSection.value,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/im/user/preview_notification',
        data: dataBody,
      );

      if (res.success()) {
        return true;
      } else {
        return false;
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<int>> setAllExceptionNotification(
    List<int> chatIDs, {
    int expiry = 0,
  }) async {
    final Map<String, dynamic> dataBody = {
      'chat_ids': chatIDs,
      'expiry': expiry,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(
        '/im/chat/mutes',
        data: dataBody,
      );

      if (res.success()) {
        return res.data['failed_chat_ids'].cast<int>();
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }
}

enum Privacy {
  nobody(1),
  myFriend(2),
  everybody(3);

  const Privacy(this.code);

  final int code;

  static Privacy fromIndex(int index) {
    switch (index) {
      case 1:
        return Privacy.nobody;
      case 2:
        return Privacy.myFriend;
      case 3:
        return Privacy.everybody;
      default:
        return Privacy.nobody;
    }
  }
}

enum Secure {
  noPassword(-1),
  eachTime(0),
  eachSection(1),
  eachDay(2);

  const Secure(this.code);

  final int code;

  static Secure fromIndex(int index) {
    switch (index) {
      case -1:
        return Secure.noPassword;
      case 0:
        return Secure.eachTime;
      case 1:
        return Secure.eachSection;
      case 2:
        return Secure.eachDay;
      default:
        return Secure.noPassword;
    }
  }
}

extension SecureExt on Secure {
  bool get isNoPassword {
    switch (this) {
      case Secure.noPassword:
        return true;
      default:
        return false;
    }
  }

  String get toValue {
    switch (this) {
      case Secure.noPassword:
        return localized(plOff);
      default:
        return localized(plOn);
    }
  }

  String get toTitle {
    switch (this) {
      case Secure.noPassword:
        return localized(notSet);
      default:
        return localized(hasSet);
    }
  }
}

class PermissionSetting {
  bool sendMediaPermission;
  bool sendStickerPermission;

  PermissionSetting({
    this.sendMediaPermission = true,
    this.sendStickerPermission = true,
  });

  static PermissionSetting fromJson(dynamic data) {
    return PermissionSetting(
      sendMediaPermission: data['send_media_permission'] != 1,
    );
  }
}

class NotificationSetting {
  int id;
  bool privateChatMute;
  bool groupChatMute;
  bool walletMute;
  bool friendMute;
  bool privateChatPreviewNotification;
  bool groupChatPreviewNotification;
  bool walletPreviewNotification;
  bool friendPreviewNotification;
  NotificationMode privateChatNotificationType;
  NotificationMode groupChatNotificationType;
  NotificationMode walletNotificationType;
  NotificationMode friendNotificationType;
  List<MuteItem> privateChatMuteList;
  List<MuteItem> groupChatMuteList;
  int incomingSoundId;
  int outgoingSoundId;
  int notificationSoundId;
  int sendMessageSoundId;
  int groupNotificationSoundId;

  NotificationSetting({
    this.id = 0,
    this.privateChatMute = true,
    this.groupChatMute = true,
    this.walletMute = true,
    this.friendMute = true,
    this.privateChatPreviewNotification = false,
    this.groupChatPreviewNotification = false,
    this.walletPreviewNotification = false,
    this.friendPreviewNotification = false,
    this.privateChatNotificationType = NotificationMode.soundVibrate,
    this.groupChatNotificationType = NotificationMode.soundVibrate,
    this.walletNotificationType = NotificationMode.soundVibrate,
    this.friendNotificationType = NotificationMode.soundVibrate,
    this.privateChatMuteList = const [],
    this.groupChatMuteList = const [],
    this.incomingSoundId = 0,
    this.outgoingSoundId = 0,
    this.notificationSoundId = 0,
    this.sendMessageSoundId = 0,
    this.groupNotificationSoundId = 0,
  });

  static NotificationSetting fromJson(dynamic data) {
    return NotificationSetting(
      id: data['id'],
      privateChatMute: data['private_chat_mute'] != 1,
      groupChatMute: data['group_chat_mute'] != 1,
      walletMute: data['wallet_mute'] != 1,
      friendMute: data['friend_mute'] != 1,
      privateChatPreviewNotification:
          data['private_chat_preview_notification'] == 1,
      groupChatPreviewNotification:
          data['group_chat_preview_notification'] == 1,
      walletPreviewNotification: data['wallet_preview_notification'] == 1,
      friendPreviewNotification: data['friend_preview_notification'] == 1,
      privateChatNotificationType: getMode(data['private_chat_mute'] as int),
      groupChatNotificationType: getMode(data['group_chat_mute'] as int),
      walletNotificationType: getMode(data['wallet_mute'] as int),
      friendNotificationType: getMode(data['friend_mute'] as int),
      privateChatMuteList: data['private_chat_mute_list']
          .map<MuteItem>((element) => MuteItem.fromJson(element))
          .toList(),
      groupChatMuteList: data['group_chat_mute_list']
          .map<MuteItem>((element) => MuteItem.fromJson(element))
          .toList(),
      incomingSoundId: data['incoming_sound_id'] ?? 0,
      outgoingSoundId: data['outgoing_sound_id'] ?? 0,
      notificationSoundId: data['notification_sound_id'] ?? 0,
      sendMessageSoundId: data['send_message_sound_id'] ?? 0,
      groupNotificationSoundId: data['group_notification_sound_id'] ?? 0,
    );
  }
}

class MuteItem {
  int chatID;
  int? friendID;
  String? groupName;
  String? icon;
  int expiry;
  int createdTime;
  int chatType;

  MuteItem({
    required this.chatID,
    this.friendID,
    this.groupName,
    this.icon,
    this.expiry = -1,
    this.createdTime = 0,
    this.chatType = 0,
  });

  static MuteItem fromJson(dynamic data) {
    return MuteItem(
      chatID: data['chat_id'],
      friendID: data['friend_id'],
      groupName: data['name'],
      icon: data['icon'],
      expiry: data['expiry'],
      createdTime: data['update_time'],
      chatType: data['typ'],
    );
  }
}

extension MuteItemUtil on int {
  String get getMuteDetail {
    if (this == -1) {
      return localized(alwaysOff);
    } else {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(this * 1000);
      return '${localized(muteUntil)} ${DateFormat('yyyy MMM dd h:mm a').format(dateTime)}';
    }
  }
}

class Version {
  Future<AppVersion> getAllAppVersion() async {
    try {
      final ResponseData res = await CustomRequest.doGet(
        '/app/api/version/app',
        needToken: false,
      );

      if (res.success()) {
        return AppVersion.fromJson(res.data);
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<PlatformDetail?> getAppVersion() async {
    int? os = appVersionUtils.getOsType();
    String? platform = appVersionUtils.getDownloadPlatform();

    /// get en
    String lang = "";
    if (objectMgr.langMgr.getLangKey() == "") {
      final String defaultLocaleStr = Platform.localeName;
      List<String> localeParts = defaultLocaleStr.split("_");
      lang = localeParts[0];
    } else {
      lang = objectMgr.langMgr.getLangKey();
    }

    Map<String, dynamic> dataBody = {};
    dataBody["limit"] = 1;
    dataBody["os"] = os;
    dataBody["platform"] = platform;
    dataBody["lang"] = lang;

    try {
      final ResponseData res = await CustomRequest.doGet(
        '/app/api/version/app_v2',
        data: dataBody,
      );

      if (res.success()) {
        if (res.data is List && res.data.isNotEmpty) {
          return PlatformDetail.fromJson(res.data.first);
        } else {
          return null;
        }
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }

  Future<PlatformDetail> getAppVersionInfo() async {
    int? os;
    String? platform;
    final appVer = await PlatformUtils.getAppVersion();
    if (Platform.isAndroid) {
      os = OsType.android.value;
      platform = Config().androidPlatform;
    } else if (Platform.isIOS) {
      os = OsType.ios.value;
      platform = Config().isTestFlight
          ? DownloadPlatform.testflight.value
          : DownloadPlatform.supersign.value;
    } else if (Platform.isWindows) {
      os = OsType.windows.value;
      platform = DownloadPlatform.windows.value;
    } else if (Platform.isMacOS) {
      os = OsType.mac.value;
      platform = DownloadPlatform.mac.value;
    }

    Map<String, dynamic> dataBody = {};
    dataBody["os"] = os;
    dataBody["platform"] = platform;
    dataBody["version"] = appVer;

    try {
      final ResponseData res = await CustomRequest.doGet(
        '/app/api/version/app_infos',
        data: dataBody,
      );

      if (res.success()) {
        return PlatformDetail.fromJson(res.data);
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }
}

enum PrivacySecuritySettingPage {
  profilePic,
  phoneNum,
  username,
  lastSeen,
  usernameSearch,
  phoneNumSearch,
  emailAddress
}
