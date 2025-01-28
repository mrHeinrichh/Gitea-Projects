import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import '../../../object/enums/enum.dart';
import '../../../routes.dart';

class PasscodeController extends GetxController {
  String? fromView;
  Chat? chat;

  List<ToolOptionModel> selectionOptions = [
    ToolOptionModel(
      title: '更改支付密码',
      optionType: WalletPasscodeOption.changePasscode.type,
      isShow: true,
      tabBelonging: null,
      color: JXColors.primaryTextBlack,
    ),
    ToolOptionModel(
      title: '重置支付密码',
      optionType: WalletPasscodeOption.resetPasscode.type,
      isShow: true,
      tabBelonging: null,
      color: JXColors.primaryTextBlack,
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

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> walletPasscodeOptionClick(String type) async {
    switch (type) {
      case 'changePasscode':
        if(objectMgr.loginMgr.isDesktop){
          Get.toNamed(RouteName.currentPasscodeView,id: 3);
        }else{
          Get.toNamed(RouteName.currentPasscodeView);
        }
        break;
      case 'resetPasscode':
        String countryCode = objectMgr.userMgr.mainUser.countryCode;
        String contactNumber = objectMgr.userMgr.mainUser.contact;

        try {
          //发送otp到手机号码
          final res = await getOTP(
              contactNumber, countryCode, OtpPageType.resetPasscode.type);
          if (res) {
            if(objectMgr.loginMgr.isDesktop){
              Get.toNamed(
                RouteName.otpView,
                arguments: {'from_view': OtpPageType.resetPasscode.page},
                id: 3,
              );
            }else{
              Get.toNamed(
                RouteName.otpView,
                arguments: {'from_view': OtpPageType.resetPasscode.page},
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
    if(objectMgr.loginMgr.isDesktop){
      Get.toNamed(
        RouteName.setupPasscodeView,
        arguments: arguments,
        id: 3
      );
    }else{
      Get.toNamed(
        RouteName.setupPasscodeView,
        arguments: arguments,
      );
    }

  }
}
