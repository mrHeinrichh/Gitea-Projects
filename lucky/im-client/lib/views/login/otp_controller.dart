import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/object/account.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/views/login/welcome_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../main.dart';
import '../../routes.dart';
import '../../api/account.dart';
import '../../utils/net/error_code_constant.dart';
import '../../utils/toast.dart';
import 'login_controller.dart';

class OtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocus = FocusNode();
  RxString intPhoneFormat = ''.obs;

  ///OTP状态的变量
  RxBool wrongOTP = false.obs;
  RxBool redBorder = false.obs;
  RxBool greenBorder = false.obs;
  RxBool isLoginComplete = false.obs;
  RxBool loginProgress = false.obs;

  ///重新发送OTP的变量
  RxBool otpResent = false.obs;
  RxInt counterValue = 0.obs;
  RxInt otpAttempts = 5.obs;
  RxBool resendDisabled = false.obs;

  RxString fromView = ''.obs;

  ///更改手机号的变量
  String countryCode = '';
  String phoneNumber = '';
  String emailAddress = '';
  bool changePhone = false;

  late LoginController loginController;

  ///加邮箱
  bool addEmail = false;

  OtpController();

  OtpController.desktop(
      {String? fromView,
      String? countryCode,
      String? phoneNumber,
      bool? changePhone}) {
    if (fromView != null) {
      this.fromView.value = fromView;
      if (this.fromView.value == OtpPageType.changePhoneNumber.page) {
        this.countryCode = countryCode ?? '';
        this.phoneNumber = phoneNumber ?? '';
        this.changePhone = changePhone ?? false;
      } else if (this.fromView.value == OtpPageType.login.page) {
        countryCode = objectMgr.loginMgr.countryCode ?? '+65';
        phoneNumber = objectMgr.loginMgr.mobile;
        emailAddress = objectMgr.loginMgr.emailAddress;
      } else if (this.fromView.value == OtpPageType.changeEmail.page) {
        emailAddress = Get.arguments['email'] ?? '';
        addEmail = Get.arguments['add_email'] ?? false;
      } else {
        this.countryCode = objectMgr.userMgr.mainUser.countryCode;
        this.phoneNumber = objectMgr.userMgr.mainUser.contact;
        emailAddress = objectMgr.userMgr.mainUser.email;
      }
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Get.isRegistered<LoginController>()) {
      loginController = Get.find<LoginController>();
    } else {
      loginController = Get.put(LoginController());
    }

    //如果更改手机号的话，必须要传进来
    if (Get.arguments != null) {
      if (Get.arguments['from_view'] != null) {
        fromView.value = Get.arguments['from_view'];
        if (fromView == OtpPageType.changePhoneNumber.page) {
          countryCode = Get.arguments['changed_countryCode'] ?? '';
          phoneNumber = Get.arguments['changed_number'] ?? '';
          changePhone = Get.arguments['change_phone'] ?? false;
        } else if (fromView == OtpPageType.login.page) {
          countryCode = objectMgr.loginMgr.countryCode ?? '+65';
          phoneNumber = objectMgr.loginMgr.mobile;
          emailAddress = objectMgr.loginMgr.emailAddress;
          if (loginController.selectMode == PHONE_NUMBER)
            await setDisplayPhoneNumber(fromView.value);
        } else if (fromView.value == OtpPageType.changeEmail.page) {
          emailAddress = Get.arguments['email'] ?? '';
          addEmail = Get.arguments['add_email'] ?? false;
        } else if (fromView.value == OtpPageType.secondVerification.page) {
        bool  phoneAuth = Get.arguments['phoneAuth'] ?? false;
        if(phoneAuth){
          countryCode = objectMgr.userMgr.mainUser.countryCode;
          phoneNumber = objectMgr.userMgr.mainUser.contact;
          intPhoneFormat.value = '$countryCode $phoneNumber';
        }else{
          emailAddress = objectMgr.userMgr.mainUser.email;
        }
        }else if(fromView.value == OtpPageType.resetPasscode.page){
          countryCode = objectMgr.userMgr.mainUser.countryCode;
          phoneNumber = objectMgr.userMgr.mainUser.contact;
          intPhoneFormat.value = '$countryCode $phoneNumber';
          emailAddress = objectMgr.userMgr.mainUser.email;
        } else {
          countryCode = objectMgr.userMgr.mainUser.countryCode;
          phoneNumber = objectMgr.userMgr.mainUser.contact;
          intPhoneFormat.value = '$countryCode $phoneNumber';
          emailAddress = objectMgr.userMgr.mainUser.email;
        }
      }
    }
    //一进来这个页面就开始倒计时
    startTimer();

    await Future.delayed(
      const Duration(milliseconds: 300),
          () {
        if (!otpFocus.hasFocus){
          otpFocus.requestFocus();
        }
      },
    );
  }

  void accountChecking() async {
    wrongOTP.value = false;
    loginProgress.value = true;
    LoginController controller;
    if (Get.isRegistered<LoginController>())
      controller = Get.find<LoginController>();
    else
      controller = Get.put(LoginController());

    if (fromView == OtpPageType.login.page) {
      //账号登入
      try {
        await objectMgr.loginMgr.login(
          otpCode: otpController.text,
          type: OtpPageType.login.type,
          loginType: controller.selectMode.value,
        );

        /// 由于登出时会clearTables, 因此登录后退出在登录时会重新跑objectMgr.init初始化tables
        if (SharedRemoteDB.isTableEmpty) {
          await objectMgr.init();
        }

        if (objectMgr.loginMgr.isLogin) {
          await objectMgr.prepareDBData(objectMgr.loginMgr.account!.user!);
        }

        greenBorder.value = false;
        isLoginComplete.value = true;
        SystemChannels.textInput.invokeMethod('TextInput.hide');

        objectMgr.socketMgr.updateSocketTime =
            DateTime.now().millisecondsSinceEpoch;
        objectMgr.appInitState.value = AppInitState.idle;
        if (objectMgr.loginMgr.isDesktop) {
          Get.offAllNamed(RouteName.desktopHome);
        } else {
          Get.offAllNamed(RouteName.home);
        }
      } on CodeException catch (e) {
        //用户不存在，引导到创建新用户
        if (objectMgr.loginMgr.isDesktop) {
          Get.back();
        }
        if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_NOT_EXIST) {
          greenBorder.value = false;
          if (objectMgr.loginMgr.isDesktop) {
            Get.back();
            Toast.showToast(
              "${localized(thisUserIsNotExits)}",
              duration: const Duration(milliseconds: 3000),
            );
          } else {
            await Future.delayed(
              const Duration(milliseconds: 1000),
              () {
                if(e.getData() is Account){
                  Get.offAll(const WelcomeView());
                }
                greenBorder.value = false;
              },
            );
          }
        }else if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_ALREADY_EXIST){
          Get.back();
          Toast.showToast("${localized(userMobileTaken)}", duration: const Duration(milliseconds: 3000));
        }
        if (e.getPrefix() == ErrorCodeConstant.STATUS_LOGIN_FAILED ||
            e.getPrefix() == ErrorCodeConstant.STATUS_VCODE_ERROR) {
          //密码错误或者登入失败
          otpAttempts -= 1;
          wrongOTP.value = true;
          redBorder.value = true;
          await Future.delayed(
            const Duration(seconds: 1),
            () {
              redBorder.value = false;
              otpController.clear();
              otpFocus.requestFocus();
            },
          );
        }

        if (e.getPrefix() == ErrorCodeConstant.STATUS_BLOCK_NUMBER) {
          Toast.showToast(localized(thisNumberHasBeenBlocked));
        } else if (e.getPrefix() == ErrorCodeConstant.STATUS_BLOCK_EMAIL) {
          Toast.showToast(localized(thisEmailHasBeenBlocked));
        }
      } on AppException catch (e) {
        Toast.showToast('${e.getMessage()}');
      }
    } else if (fromView == OtpPageType.changePhoneNumber.page) {
      //更改手机号
      final UserBioController controller = Get.find<UserBioController>();
      try {
        await controller.changeContact(
            countryCode, phoneNumber, otpController.text);
        greenBorder.value = true;
        await Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            if (objectMgr.loginMgr.isDesktop) {
              Get.close(2, 3);
            } else {
              Get.close(2);
            }
            Toast.showSnackBar(
                context: Get.context!,
                message: localized(userChangeNumSuccess));
            greenBorder.value = false;
          },
        );
      } on CodeException {
        otpAttempts -= 1;
        wrongOTP.value = true;
        redBorder.value = true;
        await Future.delayed(
          const Duration(seconds: 1),
          () {
            redBorder.value = false;
            otpController.clear();
            otpFocus.requestFocus();
          },
        );
      } on AppException catch (e) {
        Toast.showToast('${e.getMessage()}');
      }
    } else if (fromView == OtpPageType.resetPasscode.page) {
      verifyOtpCode(
          OtpPageType.resetPasscode.page, OtpPageType.resetPasscode.type);
    } else if (fromView == OtpPageType.deleteAccount.page) {
      verifyOtpCode(
          OtpPageType.deleteAccount.page, OtpPageType.deleteAccount.type);
    } else if (fromView.value == OtpPageType.changeEmail.page) {
      final UserBioController controller = Get.find<UserBioController>();
      try {
        await controller.addEmail(emailAddress, otpController.text);
        greenBorder.value = true;
        await Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            Get.close(2);
            Toast.showSnackBar(
                context: Get.context!, message: localized(changeEmailSuccess));
            greenBorder.value = false;
          },
        );
      } on CodeException catch (_) {
        otpAttempts -= 1;
        wrongOTP.value = true;
        redBorder.value = true;
        await Future.delayed(
          const Duration(seconds: 1),
          () {
            redBorder.value = false;
            otpController.clear();
            otpFocus.requestFocus();
          },
        );
      } on AppException catch (e) {
        Toast.showToast('${e.getMessage()}');
      }
    }else if(fromView == OtpPageType.secondVerification.page){
      bool  phoneAuth = Get.arguments['phoneAuth'] ?? false;
      if(phoneAuth){
        verifyOtpCode(
            OtpPageType.secondVerification.page, OtpPageType.secondVerification.type);
      }else{
        verifyEmailCode(emailAddress,otpController.text,OtpPageType.secondVerification.type);
      }
    }

    if (otpAttempts == 0) {
      Toast.showToast(localized(homeOtpNoLonger));
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    loginProgress.value = false;
  }

  Future<void> resendOTP() async {
    if (resendDisabled.value) return;
    otpAttempts.value = 5;
    startTimer();
    bool result = false;
    int? otpType;

    if (fromView == OtpPageType.login.page) {
      otpType = OtpPageType.login.type;
    } else if (fromView == OtpPageType.changePhoneNumber.page) {
      otpType = OtpPageType.changePhoneNumber.type;
    } else if (fromView == OtpPageType.resetPasscode.page) {
      otpType = OtpPageType.resetPasscode.type;
    } else if (fromView == OtpPageType.deleteAccount.page) {
      otpType = OtpPageType.deleteAccount.type;
    }

    try {
      if (Get.isRegistered<LoginController>()) {
        final controller = Get.find<LoginController>();
        if (controller.selectMode.value == PHONE_NUMBER)
          result = await getOTP(phoneNumber, countryCode, otpType!);
        else if (controller.selectMode.value == EMAIL_ADDRESS)
          result = await getOTPByEmail(emailAddress, otpType!);
      } else {
        result = await getOTP(phoneNumber, countryCode, otpType!);
      }

      if (result) {
        Toast.showToastMessage(localized(homeOtpResend));
      }
    } catch (e) {
      if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
        Toast.showToastMessage(localized(homeOtpMaxLimit));
        resendDisabled.value = true;
      } else {
        Toast.showToastMessage(localized(homeOtpFailed));
      }
    }
    //startTimer();
  }

  void startTimer() async {
    otpResent.value = true;
    counterValue.value = 60;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counterValue.value == 1) {
        timer.cancel();
        otpResent.value = false;
      } else {
        counterValue.value--;
      }
    });
  }

  void backToLogin() {
    final loginController = Get.find<LoginController>();
    loginController.isLoading.value = false;
    loginController.phoneFocusNode.requestFocus();

    if (objectMgr.loginMgr.isDesktop) {
      Get.back(id: 3);
    } else {
      Get.back();
    }
  }

  Future<void> setDisplayPhoneNumber(String fromView) async {
    if (objectMgr.loginMgr.isDesktop) {
      intPhoneFormat.value = '$countryCode $phoneNumber';
    } else {
      String? dialCode = loginController.countryCodeList
          .firstWhere((element) => element.dialCode == countryCode)
          .code;
      intPhoneFormat.value = (await PhoneNumber.parse('$countryCode $phoneNumber',
          callerCountry: dialCode != null ? IsoCode.fromJson(dialCode) : null))
          .international;
    }
  }

  /// check OTP Code
  Future<void> verifyOtpCode(String fromView, int otpType) async {
    try {
      if (objectMgr.userMgr.mainUser.countryCode != "" &&
          objectMgr.userMgr.mainUser.contact != "") {
        emailAddress = '';
      } else {
        if (objectMgr.userMgr.mainUser.email != "") {
          countryCode = '';
          phoneNumber = '';
        }
      }
      final data = await checkOtpCode(
          phoneNumber, countryCode, emailAddress, otpType, otpController.text);

      /// navigate to setup passcode view if otp is valid
      if (data != null && data.token != "") {
        if (fromView == OtpPageType.resetPasscode.page) {
          if (objectMgr.loginMgr.isDesktop) {
            Get.toNamed(RouteName.setupPasscodeView,
                arguments: {
                  'passcode_type': WalletPasscodeOption.resetPasscode.type,
                  'token': data.token,
                },
                id: 3);
          } else {
            Get.toNamed(
              RouteName.setupPasscodeView,
              arguments: {
                'passcode_type': WalletPasscodeOption.resetPasscode.type,
                'token': data.token,
              },
            );
          }
        } else if (fromView == OtpPageType.deleteAccount.page) {
          deleteAccount(data.token);
        }else if(fromView == OtpPageType.secondVerification.page){
          Get.back(result: { 'token': data.token,});
        }
      }else{
        if(fromView == OtpPageType.secondVerification.page){
          Get.back(result: { });
        }
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_LOGIN_FAILED) {
        otpAttempts -= 1;
        wrongOTP.value = true;
        redBorder.value = true;
        await Future.delayed(
          const Duration(seconds: 1),
          () {
            redBorder.value = false;
            otpController.clear();
            otpFocus.requestFocus();
          },
        );
      } else {
        Toast.showToast(e.getMessage());
      }
    }
  }


  Future<void> verifyEmailCode(String vCode, String email,int type) async {
    try{
      final res = await sendEmailCode(emailAddress, otpController.text,type);
         if(fromView == OtpPageType.secondVerification.page){
           if(res.code==0 && res.data!=null){
             Get.back(result: { 'token': res.data['token'],});
           }else{
             Toast.showToast(res.message);
           }
        }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_LOGIN_FAILED) {
        otpAttempts -= 1;
        wrongOTP.value = true;
        redBorder.value = true;
        await Future.delayed(
          const Duration(seconds: 1),
              () {
            redBorder.value = false;
            otpController.clear();
            otpFocus.requestFocus();
          },
        );
      } else {
        Toast.showToast(e.getMessage());
      }
    }
  }

  Future<void> deleteAccount(String? token) async {
    final data = await deleteUser(token);
    if (data) {
      Get.toNamed(RouteName.deleteAccountCompleteView);
    }
  }

  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.contains(countryCode)) {
      return '${phoneNumber.substring(0, countryCode.length)} ${phoneNumber.substring(countryCode.length)}';
    } else {
      return phoneNumber;
    }
  }
}
