import 'dart:async';

import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sim_country_code/flutter_sim_country_code.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/network_diagnose/network_diagnose_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/code_define.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/login/components/term_service_bottom_sheet.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/login/desktop_term_service_dialog.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;

//目前以新加坡为默认国家
//若需要更改，只是更改名字
const DEFAULT_COUNTRY = "Singapore";
const PHONE_NUMBER = 1;
const EMAIL_ADDRESS = 2;

class LoginController extends GetxController {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final textFieldKey = GlobalKey<FormFieldState>();

  final ScrollController scrollController = ScrollController();

  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  RxBool wrongPhone = true.obs;
  RxBool wrongEmail = true.obs;
  RxBool isCheckTermService = false.obs;
  RxBool isLoading = false.obs;
  RxBool isNotCountryAvailable = false.obs;
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
  late final List<Country> countryCodeList;

  //搜索后更新的列表
  RxList<Country> updatedCountryList = <Country>[].obs;
  PhoneCountryData? initialCountryData;

  //网络诊断
  final currentCountry = localized(unknown).obs;
  final currentIP = localized(unknown).obs;
  Map<String, String> testResult = {};
  final diagnoseStatus = 0.obs;
  final networkWarningTitle = localized(diagnosing).obs;
  List taskStatuses = <NetworkDiagnoseTask>[
    NetworkDiagnoseTask(type: ConnectionTask.connectNetwork),
    NetworkDiagnoseTask(type: ConnectionTask.shieldConnectNetwork),
  ].obs;
  ConnectionTask? abnormalTask;
  final isDiagnosing = false.obs;

  @override
  void onInit() {
    super.onInit();
    initPhoneCountry();

    phoneFocusNode.addListener(() {
      topPadding.value = phoneFocusNode.hasFocus ? 8.h : 20.h;

      if (scrollController.hasClients &&
          scrollController.offset < scrollController.position.maxScrollExtent) {
        WidgetsBinding.instance.addPersistentFrameCallback((_) {
          if (!scrollController.hasClients) return;
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
    });

    emailFocusNode.addListener(() {
      topPadding.value = emailFocusNode.hasFocus ? 8.h : 20.h;
      if (scrollController.hasClients &&
          scrollController.offset < scrollController.position.maxScrollExtent) {
        WidgetsBinding.instance.addPersistentFrameCallback((_) {
          if (!scrollController.hasClients) return;
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
    });
    phoneFocusNode.requestFocus();
    getUpdatedDropdown();
  }

  @override
  void onClose() {
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void initPhoneCountry() async {
    countryCodeList = countriesEnglish
        .map(
          (s) => Country(
              isMandarin:
                  AppLocalizations(objectMgr.langMgr.currLocale).isMandarin(),
              name: s['name'],
              zhName: s['zhName'],
              code: s['code'],
              dialCode: s['dial_code'],
              flagUri: 'flags/${s['code'].toLowerCase()}.png',
              mobileNumber: s['mobile_number']),
        )
        .toList();
    //默认的国家
    defaultCountry = countryCodeList
        .firstWhereOrNull((element) => element.name == DEFAULT_COUNTRY);

    initialCountryData =
        PhoneCodes.getPhoneCountryDataByCountryCode(defaultCountry!.code!);

    //如果搜索列表是空的话就把所有国家放入列表
    if (updatedCountryList.isEmpty) updatedCountryList.value = countryCodeList;
  }

  Future<void> successVerification({int retryTime = 0}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    diagnoseStatus.value = 0;
    for (var task in taskStatuses) {
      task.description = '';
      task.status.value = ConnectionTaskStatus.processing;
    }
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
        showConfirmationDialog();
      }
      isLoading.value = false;
    } catch (e) {
      if (e is AppException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
        Toast.showToast(localized(homeOtpManyTimes));
      } else if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_BE_REACH_LIMIT) {
        Toast.showToast(localized(homeOtpBeMaxLimit));
      } else if (e is AppException &&
              e.getPrefix() == CodeDefine.USER_MOBILE_ERROR ||
          objectMgr.loginMgr.mobile.length == 1) {
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
          _startDiagnose();
          if (selectMode.value == PHONE_NUMBER) {
            phoneError.value = errorMessage;
          } else if (selectMode.value == EMAIL_ADDRESS) {
            emailError.value = errorMessage;
            if (e is AppException &&
                e.getPrefix() == ErrorCodeConstant.STATUS_SEND_VCODE_ERROR) {
              emailError.value = localized(pleaseEnterAValidEmailAddress);
            }
          }
        }
      }
      isLoading.value = false;
    }
  }

  void checkCountryCode(String code) {
    for (var element in countryCodeList) {
      if (element.dialCode == code) {
        country.value = element;
        initialCountryData =
            PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
        update(['phone']);
        objectMgr.loginMgr.countryCode = country.value?.dialCode;
        isNotCountryAvailable.value = false;
        phoneController.clear();
        return;
      } else {
        isNotCountryAvailable.value = true;
        phoneController.clear();
      }
    }
    phoneError.value = "";
  }

  Future<void> checkPhoneNumber(String phoneNumber,
      {bool detectCountry = true}) async {
    phoneError.value = "";
    final contactNumber = phoneNumber.replaceAll(' ', '');
    if (contactNumber.isNotEmpty) {
      // detect country based on dial code
      // if (detectCountry) {
      //   Country? matchedCountry = countryCodeList.firstWhereOrNull((country) =>
      //       contactNumber.startsWith(country.dialCode!.replaceAll('+', '')));
      //   if (matchedCountry != null) {
      //     country.value = matchedCountry;
      //     objectMgr.loginMgr.countryCode = country.value?.dialCode;
      //   }
      // }

      if (objectMgr.loginMgr.isDesktop) {
        final frPhone = phone_numbers_parser.PhoneNumber.parse(
          '${country.value?.dialCode} $contactNumber',
          callerCountry: phone_numbers_parser.IsoCode.fromJson(
            country.value?.code ?? defaultCountry!.code!,
          ),
        );
        final validMobile =
            frPhone.isValid(type: phone_numbers_parser.PhoneNumberType.mobile);
        wrongPhone.value = !validMobile;
        if (validMobile) {
          objectMgr.loginMgr.mobile = contactNumber;
        }
      } else {
        wrongPhone.value = false;

        if (!((country.value?.mobileNumber ?? '0').removeAllWhitespace.length <=
            contactNumber.length)) {
          wrongPhone.value = true;
        }

        objectMgr.loginMgr.mobile = contactNumber;
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
    phoneError.value = "";
    country.value = updatedCountryList[index];
    codeController.text = country.value!.dialCode!;
    isNotCountryAvailable.value = false;
    initialCountryData =
        PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
    update(['phone']);
    objectMgr.loginMgr.countryCode = country.value?.dialCode;
    phoneController.clear();
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
    codeController.text = country.value?.dialCode ?? defaultCountry!.dialCode!;
  }

  void showTermService() {
    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isDismissible: true,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: colorBackground,
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

  Future<Object?> showDesktopTermService() {
    return desktopGeneralDialog(
      navigatorKey.currentContext!,
      color: colorTextPlaceholder,
      widgetChild: DesktopTermServiceDialog(
        agreeCallBack: () {
          isCheckTermService(true);
          Get.back();
        },
      ),
    );
  }

  void checkTermService() {
    isCheckTermService.value = !isCheckTermService.value;
  }

  Future<void> showConfirmationDialog() {
    return showDialog(
      context: Get.context!,
      builder: (_) {
        String dialCode = country.value?.dialCode ?? defaultCountry!.dialCode!;
        String phoneNumber = phoneController.text;

        String title = '$dialCode $phoneNumber';
        String subtitle = localized(isThisTheCorrectPhoneNumber);

        if (selectMode.value == EMAIL_ADDRESS) {
          title = emailController.text;
          subtitle = localized(isThisTheCorrectEmailAddress);
        }

        return Dialog(
          backgroundColor: colorWhite,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: objectMgr.loginMgr.isDesktop ? 320 : double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: selectMode.value == PHONE_NUMBER
                        ? MFontSize.size28.value
                        : MFontSize.size20.value,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: jxTextStyle.textStyle13(),
                ),
                CustomTextButton(
                  localized(buttonEdit),
                  padding: const EdgeInsets.all(23),
                  onClick: Get.back,
                ),
                CustomButton(
                  text: localized(continueProcessing),
                  callBack: () {
                    Get.back();

                    if (selectMode.value == PHONE_NUMBER) {
                      phoneFocusNode.unfocus();
                    } else if (selectMode.value == EMAIL_ADDRESS) {
                      emailFocusNode.unfocus();
                    }

                    Get.toNamed(
                      RouteName.otpView,
                      arguments: {
                        'from_view': OtpPageType.login.page,
                        'loginType': selectMode.value
                      },
                    );
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startDiagnose() async {
    FocusManager.instance.primaryFocus?.unfocus();
    isDiagnosing.value = true;
    networkWarningTitle.value = localized(diagnosing);
    _fetchUserLocation();
    testResult.clear();
    diagnoseStatus.value = 1;
    abnormalTask = null;
    for (int i = 0; i < taskStatuses.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final taskResult = taskStatuses[i].type == ConnectionTask.connectNetwork
          ? await _testConnectivity(taskStatuses[i])
          : await _testShieldConnectNetwork(taskStatuses[i]);
      if (taskResult) {
        taskStatuses[i].status.value = ConnectionTaskStatus.success;
      } else {
        taskStatuses[i].status.value = ConnectionTaskStatus.failure;
        diagnoseStatus.value = 3;
        isDiagnosing.value = false;
        _reportLog();
        return;
      }
    }
    diagnoseStatus.value = 2;
    isDiagnosing.value = false;
    networkWarningTitle.value = localized(diagnoseComplete);
    _reportLog();
  }

  Future<void> _fetchUserLocation() async {
    final result = await getUserIP();
    currentCountry.value = result['country'] ?? localized(unknown);
    currentIP.value = result['ip'] ?? localized(unknown);
    if (result.containsKey("error")) {
      testResult["IP info 报错"] = result["error"]!;
    }
  }

  Future<bool> _testConnectivity(NetworkDiagnoseTask task) async {
    try {
      int duration = await testGetHeadTime(Config().officialUrl);
      task.description =
          localized(diagnoseSuccess1, params: [duration.toString()]);
      testResult['连接互联网'] = '成功，用时：$duration ms';
      return true;
    } catch (e) {
      task.description = localized(networkTaskError1);
      networkWarningTitle.value = localized(networkWarningTitle1);
      testResult['连接互联网'] = 'Catch Error: ${e.toString()}';
      return false;
    }
  }

  Future<bool> _testShieldConnectNetwork(NetworkDiagnoseTask task) async {
    if (serversUriMgr.speed1Uri == null) {
      task.description = localized(networkTaskError2);
      networkWarningTitle.value = localized(networkWarningTitle2);
      testResult['连接互联网(加速)'] = 'speed1Uri为空';
      return false;
    }

    String uri = serversUriMgr.speed1Uri!.toString();
    try {
      int duration = await testGetHeadTime(uri);
      task.description =
          localized(diagnoseSuccess2, params: [duration.toString()]);
      testResult['连接互联网(加速)'] = '成功，用时：$duration ms';
      return true;
    } catch (e) {
      task.description = localized(networkTaskError2);
      networkWarningTitle.value = localized(networkWarningTitle2);
      testResult['连接互联网(加速)'] = "Catch Error: ${e.toString()}";
      return false;
    }
  }

  void _reportLog() {
    testResult['是从登录检测'] = "true";
    testResult['网络连接模式'] = connectivityMgr.preConnectType.toString();
    testResult['用户所在地'] = currentCountry.value;
    testResult['IP地址'] = currentIP.value;
    String formattedLog =
        testResult.entries.map((e) => "${e.key}: ${e.value}").join('\n');
    objectMgr.logMgr.logNetworkMgr.addMetrics(
      LogNetworkDiagnoseMsg(msg: formattedLog),
    );
  }
}

class StringPatternInputFormatter extends TextInputFormatter {
  final String pattern; // Example: "000 000 000"
  final int maxLength; // Maximum allowed length for the formatted string

  StringPatternInputFormatter(this.pattern, {this.maxLength = 20});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final numericInput =
        newValue.text.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    final buffer = StringBuffer();
    int digitIndex = 0;

    // Repeat the pattern dynamically until reaching maxLength or input length
    while (digitIndex < numericInput.length && buffer.length < maxLength) {
      for (int i = 0; i < pattern.length; i++) {
        if (digitIndex >= numericInput.length || buffer.length >= maxLength) {
          break;
        }

        if (pattern[i] == '0') {
          buffer.write(numericInput[digitIndex]);
          digitIndex++;
        } else {
          buffer.write(pattern[i]);
        }
      }
    }

    final formattedText =
        buffer.toString().substring(0, buffer.length.clamp(0, maxLength));
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
