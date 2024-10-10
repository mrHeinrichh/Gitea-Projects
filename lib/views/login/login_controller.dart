import 'dart:async';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sim_country_code/flutter_sim_country_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/code_define.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/login/components/term_service_bottom_sheet.dart';

//目前以新加坡为默认国家
//若需要更改，只是更改名字
const DEFAULT_COUNTRY = "Singapore";
const PHONE_NUMBER = 1;
const EMAIL_ADDRESS = 2;

class LoginController extends GetxController with GetTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final textFieldKey = GlobalKey<FormFieldState>();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  RxBool wrongPhone = true.obs;
  RxBool wrongEmail = true.obs;
  RxBool isCheckTermService = false.obs;
  RxBool isLoading = false.obs;
  RxString phoneError = "".obs;
  RxString emailError = "".obs;
  Rxn<Country> country = Rxn<Country>();
  Country? defaultCountry;
  RxInt selectMode = 1.obs;
  RxDouble topPadding = (20.h).obs;

  RxBool get validInformation => ((selectMode.value == PHONE_NUMBER &&
              !wrongPhone.value &&
              isCheckTermService.value) ||
          (selectMode.value == EMAIL_ADDRESS &&
              !wrongEmail.value &&
              isCheckTermService.value))
      .obs;

  bool isEnglish = AppLocalizations(objectMgr.langMgr.currLocale).isEnglish();

  //获取所有国家（英文的）
  final List<Country> countryCodeList = countriesEnglish
      .map(
        (s) => Country(
          isMandarin:
              AppLocalizations(objectMgr.langMgr.currLocale).isMandarin(),
          name: s['name'],
          zhName: s['zhName'],
          code: s['code'],
          dialCode: s['dial_code'],
          flagUri: 'flags/${s['code'].toLowerCase()}.png',
        ),
      )
      .toList();

  //搜索后更新的列表
  RxList<Country> updatedCountryList = <Country>[].obs;

  TabController? tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(
      animationDuration: const Duration(milliseconds: 0),
      length: 2,
      vsync: this,
    );
    //默认的国家
    defaultCountry = countryCodeList
        .firstWhereOrNull((element) => element.name == DEFAULT_COUNTRY);

    //如果搜索列表是空的话就把所有国家放入列表
    if (updatedCountryList.isEmpty) updatedCountryList.value = countryCodeList;
    getUpdatedDropdown();

    phoneFocusNode.addListener(() {
      topPadding.value = phoneFocusNode.hasFocus ? 8.h : 20.h;
    });

    emailFocusNode.addListener(() {
      topPadding.value = emailFocusNode.hasFocus ? 8.h : 20.h;
    });
  }

  @override
  void onClose() {
    tabController!.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    super.onClose();
  }

  Future<void> successVerification({int retryTime = 0}) async {
    phoneError.value = "";
    emailError.value = "";
    isLoading.value = true;
    phoneError.value = "";
    emailError.value = "";
    try {
      bool res = false;
      if (selectMode.value == PHONE_NUMBER) {
        res = await getOTP(
          objectMgr.loginMgr.mobile,
          objectMgr.loginMgr.countryCode,
          OtpPageType.login.type,
        );
      } else if (selectMode.value == EMAIL_ADDRESS) {
        res = await getOTPByEmail(
          objectMgr.loginMgr.emailAddress,
          OtpPageType.login.type,
        );
      }
      if (res) {
        //成功获取验证码才去到另一页
        objectMgr.pushMgr.reset();
        Get.toNamed(
          RouteName.otpView,
          arguments: {
            'from_view': OtpPageType.login.page,
            'loginType': selectMode.value
          },
        );
        if (selectMode.value == PHONE_NUMBER) {
          phoneFocusNode.unfocus();
        } else if (selectMode.value == EMAIL_ADDRESS) {
          emailFocusNode.unfocus();
        }
      }
      isLoading.value = false;
    } catch (e) {
      if (e is AppException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
        Toast.showToastMessage(localized(homeOtpManyTimes));
      } else if (e is AppException &&
          e.getPrefix() == CodeDefine.USER_MOBILE_ERROR) {
        phoneError.value = localized(invalidPhoneNumber);
      } else {
        if (retryTime < 5) {
          isLoading.value = true;
          await Future.delayed(const Duration(seconds: 1));
          successVerification(retryTime: retryTime + 1);
          return;
        } else {
          String errorMessage =
              localized(noNetworkCheckYourEmailSettingsAndTryAgain);
          if (selectMode.value == PHONE_NUMBER) {
            phoneError.value = errorMessage;
          } else if (selectMode.value == EMAIL_ADDRESS) {
            emailError.value = errorMessage;
          }
        }
      }
      isLoading.value = false;
    }
  }

  Future<void> checkPhoneNumber(String phoneNumber) async {
    phoneError.value = "";
    final contactNumber = phoneNumber.replaceAll(' ', '');
    if (contactNumber.length > 1) {
      if (objectMgr.loginMgr.isDesktop) {
        final frPhone1 = phone_numbers_parser.PhoneNumber.parse(
          '${country.value?.dialCode} $phoneNumber',
          callerCountry: phone_numbers_parser.IsoCode.fromJson(
            country.value?.code ?? defaultCountry!.code!,
          ),
        );
        final validMobile =
            frPhone1.isValid(type: phone_numbers_parser.PhoneNumberType.mobile);
        wrongPhone.value = !validMobile;
        if (validMobile) {
          objectMgr.loginMgr.mobile = contactNumber;
        }
      } else {
        wrongPhone.value = false;
        if (!wrongPhone.value) {
          objectMgr.loginMgr.mobile = contactNumber;
        }
      }
    } else {
      wrongPhone.value = true;
    }
  }

  void checkEmailFormat(String email) {
    emailError.value = "";
    final RegExp regex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    if (regex.hasMatch(email)) {
      wrongEmail.value = false;
      objectMgr.loginMgr.emailAddress = email;
    } else {
      wrongEmail.value = true;
    }
  }

  //搜索国家
  void searchCountry(String value) {
    updatedCountryList.value = countryCodeList
        .where(
          (element) =>
              element.name!.toLowerCase().contains(value.toLowerCase()) ||
              element.dialCode!.contains(value) ||
              element.zhName.toString().contains(value),
        )
        .toList();
  }

  void selectCountry(int index) {
    Get.back();
    country.value = updatedCountryList[index];
    objectMgr.loginMgr.countryCode = country.value?.dialCode;
    checkPhoneNumber(phoneController.text);
  }

  void getUpdatedDropdown() async {
    int index;
    //根据SIM卡里边的资料获取国家
    String? countryCode;
    try {
      countryCode = await FlutterSimCountryCode.simCountryCode;
    } catch (_) {
      countryCode = null;
    }
    index = countryCodeList.indexWhere(
      (element) =>
          element.code?.toLowerCase() == (countryCode ?? ' ').toLowerCase(),
    );
    if (index != -1) {
      //找到了指定的国家
      country.value = countryCodeList[index];
    } else {
      country.value = defaultCountry;
    }
    objectMgr.loginMgr.countryCode = country.value?.dialCode;
  }

  void showTermService() {
    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isDismissible: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return TermServiceBottomSheet(
          agreeCallback: () {
            isCheckTermService(true);
            Get.back();
          },
          declineCallback: () {
            isCheckTermService(false);
            Get.back();
          },
        );
      },
    );
  }

  void checkTermService() {
    isCheckTermService.value = !isCheckTermService.value;
  }
}
