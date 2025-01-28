import 'dart:convert';
import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart' as account_api;
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/account.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/views/login/login_controller.dart';

///获取OTP的种类

class LoginMgr extends EventDispatcher {
  static const String LOGIN_ACCOUNT = "LOGIN_ACCOUNT";
  static const String eventLinkDevice = "eventLinkDevice";

  Account? _account;

  Account? get account => _account;

  // 大陆登陆
  mainlandSetAccount(Account? a) {
    _account = a;
  }

  String? inviterSecret;

  // 是否大陆用户
  get isMainlandUser => Config().orgChannel == 4;

  // 是否登陆开关
  get isLogin => _account != null && notBlank(_account?.token);

  //辨认是否使用电脑端
  bool get isDesktop =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  //辨认是否使用手机端
  bool get isMobile => Platform.isIOS || Platform.isAndroid;

  void saveAccount(Account acc) {
    SharedDataManager.shared
        .putUserInfo(acc.token, acc.user?.uid, Config().orgChannel);
    if (notBlank(acc.token)) {
      _account = acc;
      if (_account?.user != null &&
          notBlank(_account!.user!.profilePicture) &&
          notBlank(_account!.user!.profilePictureGaussian)) {
        imageMgr.genBlurHashImage(_account!.user!.profilePictureGaussian,
            _account!.user!.profilePicture);
      }

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

  // 登出的token
  String? _loginOutToken;

  Future<Account?> loadAccount() async {
    final String? jsonStr =
        objectMgr.localStorageMgr.readSecurely(LOGIN_ACCOUNT);
    pdebug("loadAccount======> $jsonStr");
    if (notBlank(jsonStr)) {
      Map<String, dynamic> data = json.decode(jsonStr!);
      Account account = Account.fromJson(data);
      if (account != null &&
          account.deviceToken.isNotEmpty &&
          PlatformUtils.deviceToken != null &&
          PlatformUtils.deviceToken.isNotEmpty &&
          account.deviceToken != PlatformUtils.deviceToken) {
        _loginOutToken = account.token;
      } else {
        _account = account;
      }
      return account;
    }
    return null;
  }

  checkNeedLoginOut() {
    if (_loginOutToken?.isNotEmpty ?? false) {
      objectMgr.logout(token: _loginOutToken);
    }
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
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(RouteName.desktopLoadingView);
    }

    try {
      objectMgr.loginMgr.vcodeToken = await account_api.checkVCode(
        vCode: otpCode,
        type: type,
      );

      Account account = await account_api.accountLogin();
      _account = account;

      pdebug("LoginToken=====> ${CustomRequest.token}");

      CustomRequest.token = account.token;

      if (!notBlank(_account?.user?.username)) {
        throw CodeException(
          ErrorCodeConstant.STATUS_USER_NOT_EXIST,
          localized(thisUserIsNotExits),
          _account,
        );
      }

      saveAccount(account);

      return account;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> registerAccount({
    required String username,
    required String nickname,
    required String profilePic,
    required String gausPath,
  }) async {
    final User user = await account_api.register(
      username: username,
      nickname: nickname,
      profilePic: profilePic,
      gausPath: gausPath,
      secret: inviterSecret,
    );

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

  String vcodeToken = "";

  String mainlandInviteCode = ""; // 大陆用户的邀请码

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
    CustomRequest.token = "";
    objectMgr.localStorageMgr.remove(LOGIN_ACCOUNT);
    objectMgr.localStorageMgr.remove(LocalStorageMgr.PUSH_INFO);
    objectMgr.localStorageMgr.remove(LocalStorageMgr.SET_PASSWORD);
    clearData();
    clear();
  }

  // 登陆账号和前一个用户不同时删除上一个账号的所有
  easeAll() async {
    objectMgr.localStorageMgr.cleanAll();
    objectMgr.localStorageMgr.clear();
  }

  //辨认是否网页
  int get platform => isMobile ? 1 : 2;

  ///Desktop Version ====================================================
  RxString desktopSecret = ''.obs;
}
