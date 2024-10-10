import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';

import 'package:jxim_client/utils/get_utils.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

class AddressSecuritySettingController extends GetxController {
  final addressWhiteListModeSwitch = false.obs;
  final newAddressWithdrawalSwitch = false.obs;

  bool get isWhiteMode => addressWhiteListModeSwitch.value;

  bool get isNewAddressLock => newAddressWithdrawalSwitch.value;

  @override
  void onInit() {
    super.onInit();
    getSettings();
  }

  Future<void> getSettings() async {
    final resp = await walletServices.getSettings();
    if (resp.code == 0) {
      final isWhiteMode = resp.data['blockchain_addr_white_mode'] ?? false;
      final isNewAddressLock = resp.data['new_blockchain_addr_lock'];
      addressWhiteListModeSwitch.value = isWhiteMode == 0 ? false : true;
      newAddressWithdrawalSwitch.value = isNewAddressLock == 0 ? false : true;
    }
  }

  void _handleSuccess() {
    showSuccessToast(localized(toastSetSuccess));
  }

  void updateSettingsWithWhiteMode() async {
    final res = await walletServices.updateBlockchainSettingsWithWhiteMode(
      isWhiteMode: isWhiteMode,
    );

    if (res.success()) {
      if (res.needTwoFactorAuthPhone || res.needTwoFactorAuthEmail) {
        Map<String, String>? tokenMap = await goSecondVerification(
          emailAuth: res.needTwoFactorAuthEmail,
          phoneAuth: res.needTwoFactorAuthPhone,
        );

        // check if pin is provided
        if (tokenMap.isNotEmpty) {
          Map<String, String> token = {
            if (tokenMap.containsKey('phoneToken'))
              'phone_token': tokenMap['phoneToken']!,
            if (tokenMap.containsKey('emailToken'))
              'email_token': tokenMap['emailToken']!,
          };
          final resAgain =
              await walletServices.updateBlockchainSettingsWithWhiteMode(
            isWhiteMode: isWhiteMode,
            tokenMap: token,
          );
          if (resAgain.success()) {
            _handleSuccess();
            getFindOrNull<WithdrawController>()?.getSettings();
          } else {
            showErrorToast(resAgain.message.toString());
            addressWhiteListModeSwitch.value = !isWhiteMode;
          }
        } else {
          // exit without pin
          addressWhiteListModeSwitch.value = !isWhiteMode;
        }
      } else {
        _handleSuccess();
        getFindOrNull<WithdrawController>()?.getSettings();
      }
    } else {
      showErrorToast(localized(errorSettingFailed));
      addressWhiteListModeSwitch.value = !isWhiteMode;
    }
  }

  void updateSettingsWithNewAddressLock() async {
    final res = await walletServices.updateBlockchainSettingsWithNewAddressLock(
      isNewAddressLock: isNewAddressLock,
    );

    if (res.success()) {
      if (res.needTwoFactorAuthPhone || res.needTwoFactorAuthEmail) {
        Map<String, String>? tokenMap = await goSecondVerification(
          emailAuth: res.needTwoFactorAuthEmail,
          phoneAuth: res.needTwoFactorAuthPhone,
        );

        // check if pin is provided
        if (tokenMap.isNotEmpty) {
          Map<String, String> token = {
            if (tokenMap.containsKey('phoneToken'))
              'phone_token': tokenMap['phoneToken']!,
            if (tokenMap.containsKey('emailToken'))
              'email_token': tokenMap['emailToken']!,
          };
          final resAgain =
              await walletServices.updateBlockchainSettingsWithNewAddressLock(
            isNewAddressLock: isNewAddressLock,
            tokenMap: token,
          );
          if (resAgain.success()) {
            _handleSuccess();
          } else {
            showErrorToast(resAgain.message.toString());
            newAddressWithdrawalSwitch.value = !isNewAddressLock;
          }
        } else {
          // exit without pin
          newAddressWithdrawalSwitch.value = !isNewAddressLock;
        }
      } else {
        _handleSuccess();
      }
    } else {
      showErrorToast(localized(errorSettingFailed));
      newAddressWithdrawalSwitch.value = !isNewAddressLock;
    }
  }

  Future<void> setAddressWhiteListModeSwitch(bool value) async {
    addressWhiteListModeSwitch.value = value;
    updateSettingsWithWhiteMode();
  }

  Future<void> setNewAddressWithdrawalSwitch(bool value) async {
    newAddressWithdrawalSwitch.value = value;
    updateSettingsWithNewAddressLock();
  }
}
