import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import '../../../api/wallet_services.dart';
import '../../../object/wallet/wallet_settings_bean.dart';
import '../../../object/wallet/wallet_today_total_bean.dart';
import '../../../utils/net/response_data.dart';
import '../../../utils/second_verification_utils.dart';

class LimitSecondaryAuthController extends GetxController {
  final TextEditingController legalCurrencyController = TextEditingController();
  final TextEditingController cryptoCurrencyController =
      TextEditingController();

  var currentKeyboardController = TextEditingController().obs;
  final isKeyboardVisible = false.obs;

  final dailyLimitLegal = "--".obs;
  final dailyLimitCrypto = "--".obs;
  final dailyCapLegal = "--".obs;
  final dailyCapCrypto = "--".obs;

  final isValidLimit = false.obs;

  void onLegalChange(String amount) {}

  void onCryptoChange(String amount) {}

  Future<void> onSaveLimit() async {
    Map<String, dynamic> map = {
      "cnyAmt": "${dailyLimitLegal.value}",
      "usdtAmt": "${dailyLimitCrypto.value}"
    };
    ResponseData res = await walletServices.postDailyTransferUpdate(map);
    if (res.code == 0) {
      bool isPhoneAuth = res.data["phoneVcodeSend"]??false;
      bool emailAuth = res.data["emailVcodeSend"]??false;
      Map<String,String> tokenMap= await goSecondVerification(phoneAuth: isPhoneAuth,emailAuth: emailAuth);
      if(tokenMap.isEmpty){
        getSettings();
        return;
      }
      handleResult(tokenMap);
    } else {
      showWarningToast(res.message);
    }
  }

  setKeyboardState(bool value) {
    isKeyboardVisible(value);
  }

  @override
  void onInit() {
    super.onInit();
    getSettings();
    getWalletTodayTotalSettings();
  }

  Future<void> getSettings() async {
    ///每日转出额度
    final res = await walletServices.getSettings();
    if (res.code == 0) {
      WalletSettingsBean bean = WalletSettingsBean.fromJson(res.data);
      DailyTransferOutQuota? item = bean.dailyTransferOutQuota;
      if (item != null) {
        dailyLimitLegal.value = item.cNY ?? "--";
        dailyLimitCrypto.value = item.uSDT ?? "--";
      }
    } else {
      showWarningToast(res.message);
    }
  }

  Future<void> getWalletTodayTotalSettings() async {
    Map<String, dynamic> map = {
      "currencyTypes": ["USDT", "CNY"],
      "txType": "ITN_TRANSFER"
    };

    /// 已使用额度
    final res = await walletServices.postWalletTodayTotalSettings(map);

    if (res.code == 0) {
      dynamic list = res.data;
      if (list != null) {
        try {
          for (Map<String, dynamic> item in list) {
            final bean = WalletTodayTotalSettingBean.fromJson(item);
            String currencyType = bean.currencyType ?? "--";
            if (currencyType == "USDT") {
              dailyCapCrypto.value = bean.amount ?? "--";
            } else if (currencyType == "CNY") {
              dailyCapLegal.value = bean.amount ?? "--";
            }
          }
        } catch (e) {}
      }
    } else {
      showWarningToast(res.message);
    }
  }

  Future<void> handleResult(Map<String,String> tokenMap) async {
    if(tokenMap.isNotEmpty){
      Map<String,dynamic> map ={
        "cnyAmt":dailyLimitLegal.value,
        "usdtAmt":dailyLimitCrypto.value,
      };
      map.addAll(tokenMap);
      final data = await  walletServices.postDailyTransferUpdate(map);
      if(data.code==0){
        getSettings();
        Get.back();
      }else{
        showWarningToast(data.message);
      }
    }
  }
}
