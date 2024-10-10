// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/account_contact.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/check_otp_model.dart';
import 'package:jxim_client/object/device_list_model.dart';
import 'package:jxim_client/object/language_translate_model.dart';
import 'package:jxim_client/object/my_app_config.dart';
import 'package:jxim_client/object/translate_array_model.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/object/account.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';

Future<bool> getOTP(String? mobile, String? countryCode, int type) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["country_code"] = countryCode;
  dataBody["contact"] = mobile;
  dataBody["type"] = type;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/vcode/get",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}

Future<bool> getOTPByEmail(String? email, int type) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["email"] = email;
  dataBody["type"] = type;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/vcode/get-email",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}

Future<String> checkVCode({
  String? vCode,
  int? type,
}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["email"] = objectMgr.loginMgr.emailAddress;
  dataBody["country_code"] = objectMgr.loginMgr.countryCode;
  dataBody["contact"] = objectMgr.loginMgr.mobile;
  dataBody["code"] = vCode;
  dataBody["type"] = type;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/vcode/check",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return res.data["token"];
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug(e);
    rethrow;
  }
}

Future<Account> accountLogin() async {
  CustomRequest.flag = CustomRequest.flag + 1;
  final Map<String, dynamic> dataBody = {};
  dataBody["email"] = objectMgr.loginMgr.emailAddress;
  dataBody["country_code"] = objectMgr.loginMgr.countryCode;
  dataBody["contact"] = objectMgr.loginMgr.mobile;
  dataBody["vcode_token"] = objectMgr.loginMgr.vcodeToken;
  dataBody["platform"] = objectMgr.loginMgr.getPlatform();
  dataBody["os_type"] = await objectMgr.loginMgr.getOSType();
  dataBody["device_id"] = objectMgr.loginMgr.deviceId;
  dataBody["device_name"] = objectMgr.loginMgr.deviceName;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/login-user",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return Account.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug(e);
    rethrow;
  }
}

Future<User> register({
  String? username,
  String? nickname,
  String? profilePic,
  String? secret,
}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["username"] = username;
  dataBody["nickname"] = nickname;
  dataBody["profile_pic"] = profilePic;
  dataBody["language"] = objectMgr.langMgr.currLocale.languageCode;
  dataBody["app_version"] = await PlatformUtils.getAppVersion();
  dataBody["vcode_token"] = objectMgr.loginMgr.vcodeToken;
  dataBody["secret"] = secret;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/update-new-user",
      data: dataBody,
    );

    if (res.success()) {
      User user = User.fromJson(res.data);
      return user;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

// 检验taken是否有效，并下发玩家信息
Future<bool> tokenRefresh() async {
  Map<String, dynamic> dataBody = {};
  objectMgr.loginMgr.account?.getToken(dataBody);
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/token/refresh",
      data: dataBody,
      needToken: false,
      refreshToken: true,
    );

    if (res.success()) {
      objectMgr.loginMgr.account
          ?.saveToken(res.data["access_token"], res.data["refresh_token"]);
      if (objectMgr.loginMgr.account != null) {
        objectMgr.loginMgr.saveAccount(objectMgr.loginMgr.account!);
        objectMgr.socketMgr
            .doRefreshToken(token: objectMgr.loginMgr.account?.token);
      }
      return true;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<bool> checkUser(String username) async {
  Map<String, dynamic> dataBody = {};
  dataBody["username"] = username.toLowerCase();
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/check-username-availability",
      data: dataBody,
      needToken: false,
    );
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<bool> checkPhone(String countryCode, String contactNumber) async {
  Map<String, dynamic> dataBody = {};
  dataBody["country_code"] = countryCode;
  dataBody["contact"] = contactNumber.replaceAll(' ', '');

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/check-phone-availability",
      data: dataBody,
      needToken: false,
    );
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<bool> checkEmail(String email) async {
  Map<String, dynamic> dataBody = {};
  dataBody["email"] = email;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/check-email-availability",
      data: dataBody,
      needToken: false,
    );
    return res.success();
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<User> updateUsername(String username) async {
  Map<String, dynamic> dataBody = {};
  dataBody["username"] = username;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/update-username",
      data: dataBody,
    );
    if (res.success()) {
      return User.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<User> updatePhone(
  String countryCode,
  String contactNumber,
  String vCode,
) async {
  Map<String, dynamic> dataBody = {};
  dataBody["country_code"] = countryCode;
  dataBody["contact"] = contactNumber;
  dataBody["vcode"] = vCode;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/update-contact",
      data: dataBody,
    );
    if (res.success()) {
      return User.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<User> doUpdateEmail(String vCode, String email) async {
  Map<String, dynamic> dataBody = {};
  dataBody["email"] = email;
  dataBody["vcode"] = vCode;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/update-contact",
      data: dataBody,
    );
    if (res.success()) {
      return User.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug('AppException: ${e.getMessage().toString()}');
    rethrow;
  }
}

Future<User> getUser({String? userId}) async {
  Map<String, dynamic> dataBody = {};
  String url = "/app/api/account/profile";
  if (userId != null) {
    dataBody["user_id"] = userId;
  }
  try {
    final ResponseData res = await CustomRequest.doGet(url, data: dataBody);

    if (res.success()) {
      User user = User.fromJson(res.data);
      return user;
    } else {
      throw AppException(res.code, res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<User> updateUserDetail(Map<String, dynamic> data) async {
  try {
    final ResponseData res =
        await CustomRequest.doPost("/app/api/account/update", data: data);

    if (res.success()) {
      return User.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException {
    rethrow;
  }
}

Future<bool> isIOSBackgroundLaunchMode() async {
  bool fromBackgroundMode = false;
  if (Platform.isIOS) {
    final mode = await objectMgr.pushMgr.getIOSLaunchMode();
    fromBackgroundMode = mode == "background";
  }
  return fromBackgroundMode;
}

//心跳接口 判断用户是否在线
Future heartbeat(int cur_time, {isOnline = true}) async {
  if (!objectMgr.loginMgr.isLogin) {
    return;
  }

  bool fromIOSBackground = await isIOSBackgroundLaunchMode();
  if (fromIOSBackground) {
    return;
  }

  final systemPlatform = appVersionUtils.getSystemPlatform();
  final platform = appVersionUtils.getDownloadPlatform();
  final appVer = await PlatformUtils.getAppVersion();

  String lang = "";
  if (objectMgr.langMgr.getLangKey() == "") {
    final String defaultLocaleStr = Platform.localeName;
    List<String> localeParts = defaultLocaleStr.split("_");
    lang = localeParts[0];
  } else {
    lang = objectMgr.langMgr.getLangKey();
  }

  dynamic data = {
    "cur_time": cur_time,
    "user_id": objectMgr.userMgr.mainUser.uid,
    "os": systemPlatform,
    "platform": platform,
    "app_ver": appVer,
    "lang": lang,
    "is_online": isOnline ? 1 : 0,
  };

  final res =
      await CustomRequest.doGet("/app/api/account/heartbeat", data: data);
  if (res.success()) {
    objectMgr
        .checkAppVersion(HeartBeatAppVersion.fromJson(res.data['app_version']));

    objectMgr.callMgr.fps = res.data['fps'] ?? 30;
    objectMgr.callMgr.resolution = res.data['resolution'] ?? 18;
  }
}

Future<bool> userLogout() async {
  try {
    final res = await CustomRequest.doGet("/app/api/auth/logout");
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    if (errorCodeToKick.contains(e.getPrefix())) {
      return true;
    }
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<CheckOtpModel?> checkOtpCode(
  String contact,
  String countryCode,
  String email,
  int type,
  String code,
) async {
  Map<String, dynamic> dataBody = {};
  dataBody["contact"] = contact;
  dataBody["country_code"] = countryCode;
  dataBody["email"] = email;
  dataBody["type"] = type;
  dataBody["code"] = code;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/vcode/check",
      data: dataBody,
    );

    if (res.success()) {
      return CheckOtpModel.fromJson(res.data);
    } else {
      return null;
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> deleteUser(String? vcode) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["vcode_token"] = vcode;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/delete-user",
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

///Desktop Version ====================================================
Future<String> desktopGenerateQR() async {
  final Map<String, dynamic> dataBody = {
    'os_type': await objectMgr.loginMgr.getOSType(),
    'platform': objectMgr.loginMgr.getPlatform(),
    'device_name': objectMgr.loginMgr.deviceName,
    'device_id': objectMgr.loginMgr.deviceId,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/desktop/api/auth/request-login",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return res.data["secret"];
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (_) {
    rethrow;
  }
}

Future<bool> authoriseDesktopLogin(String secret) async {
  final Map<String, dynamic> dataBody = {
    'secret': secret,
  };

  try {
    final res = await CustomRequest.doPost(
      "/app/api/auth/authorise-device",
      data: dataBody,
    );
    return res.success();
  } on AppException catch (_) {
    rethrow;
  }
}

Future<Map<String, dynamic>> desktopLoginCheck() async {
  final Map<String, dynamic> dataBody = {
    'secret': objectMgr.loginMgr.desktopSecret.value,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/desktop/api/auth/check-login",
      data: dataBody,
      needToken: false,
    );
    return res.data;
  } on AppException catch (_) {
    rethrow;
  }
}

Future<bool> desktopConfirmLogin() async {
  final Map<String, dynamic> dataBody = {
    'secret': objectMgr.loginMgr.desktopSecret.value,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/desktop/api/auth/confirm-login",
      data: dataBody,
      needToken: false,
    );
    return res.success();
  } on AppException catch (_) {
    rethrow;
  }
}

Future<dynamic> deviceList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/auth/device-list",
      needToken: true,
    );
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

Future<DeviceHistoryListModel> deviceHistory() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/auth/device-history",
      needToken: true,
    );
    if (res.success()) {
      return DeviceHistoryListModel.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<ResponseData> removeDevices(List<int>? deviceIdList) async {
  final Map<String, dynamic> dataBody = {
    'udid': deviceIdList,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/remove-devices",
      data: dataBody,
      needToken: true,
    );

    return res;
  } on AppException catch (_) {
    rethrow;
  }
}

Future<ResponseData> updateVoipSession(
  int udid,
  int status, [
  bool isDesktop = false,
]) async {
  final Map<String, dynamic> dataBody = {
    'udid': udid,
    'status': status,
    'is_pc': isDesktop,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/update-voip-notification-status",
      data: dataBody,
    );
    return res;
  } on AppException catch (_) {
    rethrow;
  }
}

Future<List<LanguageTranslateModel>> getLanguageTranslation(
  String targetLang,
) async {
  final Map<String, dynamic> dataBody = {};
  dataBody['target_lang'] = targetLang;

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/version/translation_v2',
      data: dataBody,
    );

    if (res.success()) {
      return res.data
          .map<LanguageTranslateModel>(
            (e) => LanguageTranslateModel.fromJson(e),
          )
          .toList()
          .where((LanguageTranslateModel e) => e.path.isNotEmpty)
          .toList();
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    rethrow;
  }
}

Future<ResponseData> updateLanguage(String language) async {
  final Map<String, dynamic> dataBody = {
    'language': language,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/account/update-language',
      data: dataBody,
    );
    return res;
  } on AppException {
    rethrow;
  }
}

Future<TranslateModel> getTranslateText(String languageTo, String text) async {
  final Map<String, dynamic> dataBody = {'lang_to': languageTo, 'text': text};

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/im/translate',
      data: dataBody,
    );
    return TranslateModel.fromJson(res.data);
  } on AppException {
    rethrow;
  }
}

Future<TranslateArrayModel> getTranslateArray(
  String languageTo,
  List<String> textArray, {
  int? chatId,
  int? chatIdx,
}) async {
  Map<String, dynamic> dataBody = {'lang_to': languageTo, 'text': textArray};

  if (chatId != null && chatIdx != null) {
    dataBody["chat_id"] = chatId;
    dataBody["chat_idx"] = chatIdx;
  }

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/im/translate/v2',
      data: dataBody,
    );
    return TranslateArrayModel.fromJson(res.data);
  } on AppException {
    rethrow;
  }
}

Future<TranscribeModel> getTranscribeText(
  String languageTo,
  String mediaPath,
) async {
  final Map<String, dynamic> dataBody = {
    'lang_to': languageTo,
    'media_path': mediaPath,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/im/transcribe',
      data: dataBody,
    );
    return TranscribeModel.fromJson(res.data);
  } on AppException {
    rethrow;
  }
}

Future<bool> feedback(
  String category,
  String description,
  List<String> attachments,
) async {
  Map<String, dynamic> dataBody = {};
  dataBody["category"] = category;
  dataBody["description"] = description;
  dataBody["attachments"] = attachments;
  try {
    final ResponseData res = await CustomRequest.doPost(
        "/app/api/account/report-issue",
        data: dataBody);

    if (res.success()) {
      return true;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (_) {
    rethrow;
  }
}

Future<AccountContactList> accountSearch(String phone, {int limit = 20}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["query"] = phone;
  dataBody["limit"] = limit;
  dataBody["offset"] = 0;
  dataBody["phone_only"] = true;

  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/account/search",
      data: dataBody,
    );

    if (res.success()) {
      return AccountContactList.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug(e);
    rethrow;
  }
}

Future<ResponseData> sendEmailCode(String email, String vCode, int type) async {
  Map<String, dynamic> dataBody = {};
  dataBody["email"] = email;
  dataBody["code"] = vCode;
  dataBody["type"] = type;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/auth/vcode/check",
      data: dataBody,
    );
    return res;
  } on AppException catch (e) {
    return ResponseData(code: -1, message: e.getMessage().toString());
  }
}

Future<GetStoreData> getStore(String key) async {
  Map<String, dynamic> dataBody = {};
  dataBody["key"] = key;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/store/get-store",
      data: dataBody,
    );

    if (res.success()) {
      return GetStoreData.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException {
    //Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<bool> updateStore(
  String key,
  String value, {
  bool isBroadcast = false,
}) async {
  Map<String, dynamic> dataBody = {};
  dataBody["key"] = key;
  dataBody["value"] = value;
  dataBody["is_broadcast"] = isBroadcast;

  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/store/update-store",
      data: dataBody,
    );

    if (res.success()) {
      return true;
    } else {
      return false;
    }
  } on AppException {
    //Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<MyAppConfig> getMyConfig() async {
  final Map<String, dynamic> dataBody = {};
  dataBody["channel_id"] = Config().orgChannel;

  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/account/get_app_config",
      data: dataBody,
      needToken: false,
    );

    if (res.success()) {
      return MyAppConfig.fromJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    pdebug(e);
    rethrow;
  }
}

Future<ResponseData> validateInvitation(String code) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/account/validate_code",
      data: {'code_id': code},
      needToken: true,
    );

    return res;
  } catch (e) {
    // 请求过程中的异常处理
    pdebug('Exception: ${e.toString()}');
    rethrow;
  }
}
