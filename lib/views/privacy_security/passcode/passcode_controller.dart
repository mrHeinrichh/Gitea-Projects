import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';

import 'package:jxim_client/utils/lang_util.dart';

class PasscodeController extends GetxController {
  String? fromView;
  Chat? chat;

  List<ToolOptionModel> selectionOptions = [
    ToolOptionModel(
      title: localized(changePaymentPassword),
      optionType: WalletPasscodeOption.changePasscode.type,
      isShow: true,
      tabBelonging: null,
      color: colorTextPrimary,
    ),
    ToolOptionModel(
      title: localized(resetPaymentPassword),
      optionType: WalletPasscodeOption.resetPasscode.type,
      isShow: true,
      tabBelonging: null,
      color: colorTextPrimary,
    ),
  ];

  @override
  void onInit() {
    if (Get.arguments != null) {
      if (Get.arguments['from_view'] != null) {
        fromView = Get.arguments['from_view'];
      }
      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }
    }
    super.onInit();
  }

  Future<void> walletPasscodeOptionClick(
    String type, {
    bool isFromChatRoom = false,
  }) async {
    switch (type) {
      case 'changePasscode':
        if (objectMgr.loginMgr.isDesktop) {
          Get.toNamed(RouteName.currentPasscodeView, id: 3);
        } else {
          Get.toNamed(RouteName.currentPasscodeView);
        }
        break;
      case 'resetPasscode':
        String countryCode = objectMgr.userMgr.mainUser.countryCode;
        String contactNumber = objectMgr.userMgr.mainUser.contact;

        try {
          //发送otp到手机号码
          final res = await getOTP(
            contactNumber,
            countryCode,
            OtpPageType.resetPasscode.type,
          );
          if (res) {
            if (objectMgr.loginMgr.isDesktop) {
              Get.toNamed(
                RouteName.otpView,
                arguments: {'from_view': OtpPageType.resetPasscode.page},
                id: 3,
              );
            } else {
              Get.toNamed(
                RouteName.otpView,
                arguments: {
                  'from_view': OtpPageType.resetPasscode.page,
                  'is_from_chat_room': isFromChatRoom,
                },
              );
            }
          }
        } on AppException catch (e) {
          Toast.showToast(e.getMessage());
        }
        break;
      default:
        break;
    }
  }

  void navigateToSetupPasscodeView() {
    final Map<String, dynamic> arguments = {};
    arguments["passcode_type"] = WalletPasscodeOption.setPasscode.type;

    if (fromView != null) {
      arguments["from_view"] = fromView;
    }
    if (chat != null) {
      arguments["chat"] = chat;
    }
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(
        RouteName.setupPasscodeView,
        arguments: arguments,
        id: 3,
      );
    } else {
      arguments["is_from_chat_room"] = true;
      Get.toNamed(
        RouteName.setupPasscodeView,
        arguments: arguments,
      );
    }
  }
}
