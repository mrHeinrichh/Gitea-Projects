import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart' as account_api;
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/views/login/login_controller.dart';

import '../object/account.dart';
import '../object/user.dart';
import '../utils/config.dart';
import '../utils/net/request.dart';
import 'local_storage_mgr.dart';

///获取OTP的种类

class LoginMgr extends EventDispatcher {
  static const String LOGIN_ACCOUNT = "LOGIN_ACCOUNT";
  static const String eventLinkDevice = "eventLinkDevice";

  Account? _account;

  Account? get account => _account;

  String? inviterSecret;

  get isLogin => _account != null && notBlank(_account?.token);

  //辨认是否使用电脑端
  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  //辨认是否使用手机端
  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  void saveAccount(Account acc) {
    SharedDataManager.shared.putUserInfo(acc.token,acc.user?.uid, Config().orgChannel);
    if (notBlank(acc.token)) {
      _account = acc;
      String jsonStr = json.encode(acc.toJson());
      pdebug("SaveAccount======> $jsonStr");
      objectMgr.localStorageMgr.writeSecurely(LOGIN_ACCOUNT, jsonStr);
    }
  }

  setUserOfAccount(User user) {
    if (isLogin) {
      _account!.user?.updateValue(user.toJson());
      saveAccount(_account!);
    }
  }

  Future<Account?> loadAccount() async {
    final String? jsonStr =
        await objectMgr.localStorageMgr.readSecurely(LOGIN_ACCOUNT);
    pdebug("loadAccount======> $jsonStr");
    if (notBlank(jsonStr)) {
      Map<String, dynamic> data = json.decode(jsonStr!);
      _account = Account.fromJson(data);
      return account;
    }
    return null;
  }

  // # 登陆
  // #mobile 手机号
  // #passworld 密码
  // #otpCode 验证码
  Future<Account> login({
    String? otpCode,
    int? type,
    required int loginType,
  }) async {
    if (loginType == EMAIL_ADDRESS) {
      objectMgr.loginMgr.countryCode = '';
      objectMgr.loginMgr.mobile = '';
    } else if (loginType == PHONE_NUMBER) {
      objectMgr.loginMgr.emailAddress = '';
    }
    if(objectMgr.loginMgr.isDesktop){
      Get.toNamed(RouteName.desktopLoadingView);
    }
    objectMgr.loginMgr.vcodeToken = await account_api.checkVCode(
      vCode: otpCode,
      type: type,
    );
    Account account = await account_api.accountLogin();
    _account = account;

    pdebug("LoginToken=====> ${Request.token}");

    Request.token = account.token;

    if(!notBlank(_account?.user?.username)){
      throw CodeException(ErrorCodeConstant.STATUS_USER_NOT_EXIST, localized(thisUserIsNotExits), _account);
    }
    
    saveAccount(account);

    return account;
  }

  Future<User> registerAccount({
    required String username,
    required String nickname,
    required String profilePic,
  }) async {
    final User user = await account_api.register(
        username: username, nickname: nickname, profilePic: profilePic, secret: inviterSecret);

    return user;
  }

  Future<bool> checkNeedLogin() async {
    await loadAccount();
    return _account?.user == null;
  }

  // Old Server and Old logic
  static const String eventUpdateName = 'update_name';
  static const String eventUpdateCity = 'update_city';
  static const String eventUpdateBirthday = 'update_birthday';
  static const String eventUpdateLoading = 'update_Loading';
  static const String eventCheckAgree = 'update_check_agree';
  static const String checkPasswordInput = 'check_password_input';
  static const String checkClickBtn = 'check_click_btn';
  static const String checkakeyLogin = 'check_akey_login';
  static const String checkFocus = 'check_focus';
  static const String eventcountryCode = 'country_code';
  static const String eventState = 'eventState';

  String mobile = "";

  String emailAddress = "";

  String _deviceName = "";

  String vcodeToken = "";

  String get deviceName => _deviceName;

  set deviceName(String value) {
    _deviceName = value;
  }

  String _deviceId = "";

  String get deviceId => _deviceId;

  set deviceId(String value) {
    _deviceId = value;
  }

  var checkGetCodePhone = {}; //判断验证码获取时间

  //同意条款判断
  bool _isReadAgreement = false;

  bool get isReadAgreement => _isReadAgreement;

  set isReadAgreement(bool value) {
    _isReadAgreement = value;
    event(this, eventCheckAgree);
  }

  bool _isShowLogin = false;

  bool get isShowLogin => _isShowLogin;

  set isShowLogin(bool value) {
    _isShowLogin = value;
    event(this, checkakeyLogin);
  }

  //国家码
  String? countryCode = '+65';

  clearData() {
    checkGetCodePhone.clear();
    _isReadAgreement = false;
    _isShowLogin = true;
    _account = null;
  }

  Future<void> logout() async {
    Request.token = "";
    objectMgr.localStorageMgr.remove(LOGIN_ACCOUNT);
    objectMgr.localStorageMgr.remove(LocalStorageMgr.SET_PASSWORD);
    clearData();
  }

  // 登陆账号和前一个用户不同时删除上一个账号的所有
  easeAll() async {
    objectMgr.localStorageMgr.cleanAll();
    objectMgr.localStorageMgr.clear();
  }

  //获取OS种类
  Future<int> getOSType() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      //安卓手机
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      _deviceId = '${androidInfo.id}';
      return 1;
    } else if (Platform.isIOS) {
      //苹果手机
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceName = '${iosInfo.systemName} ${iosInfo.utsname.nodename}';
      _deviceId = '${iosInfo.identifierForVendor}';
      return 2;
    } else if (Platform.isWindows) {
      //Windows电脑
      WindowsDeviceInfo windowInfo = await deviceInfo.windowsInfo;
      _deviceName = '${windowInfo.computerName}';
      _deviceId = '${windowInfo.deviceId}';
      return 3;
    } else if (Platform.isMacOS) {
      //MacOS电脑
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      _deviceName = '${macInfo.model}';
      _deviceId = '${macInfo.systemGUID}';
      return 4;
    } else if (Platform.isLinux) {
      //Linux电脑
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      _deviceName = '${linuxInfo.name}';
      _deviceId = '${linuxInfo.machineId}';
      return 5;
    } else {
      return 6;
    }
  }

  //辨认是否网页
  int getPlatform() {
    if (isMobile) {
      return 1;
    } else {
      return 2;
    }
  }

  ///Desktop Version ====================================================
  RxString desktopSecret = ''.obs;
}
