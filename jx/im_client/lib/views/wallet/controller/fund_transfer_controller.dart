import 'package:cashier/im_cashier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/api/payment_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/payment/fund_transfer_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/wallet/components/number_pad.dart';
import 'package:jxim_client/views/wallet/controller/keyboard_controller.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';

class FundTransferController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final isLoading = false.obs;
  FocusNode otpFocus = FocusNode();
  TextEditingController pinCodeController = TextEditingController();
  final isPasscodeIncorrect = false.obs;
  final passwordCount = 0.obs;
  final FocusNode moneyTextFieldFocus = FocusNode();
  final textController = TextEditingController();
  final textControllerFocusNode = FocusNode();
  RxString exceedAmountTxt = ''.obs;
  RxBool isAttemptWrong = false.obs;

  List<CurrencyModel> _legalCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> _cryptoCurrencyList = <CurrencyModel>[];

  //所有錢包
  RxList<CurrencyModel> totalWalletList = RxList<CurrencyModel>();

  //所有錢包幣種
  RxList<CurrencyModel> totalWalletTypeList = RxList<CurrencyModel>();

  //當前選擇的錢包
  Rxn<CurrencyModel> currentWallet = Rxn<CurrencyModel>();

  //所有可用的錢包轉入轉出類型
  List<WalletTransferType> walletTransferTypeList =
      List.from(WalletConfig.getWalletTransferList());

  //從哪個錢包類型轉出
  Rxn<WalletTransferType> fromWalletTransferType =
      Rxn<WalletTransferType>(WalletTransferType.transferRemain);

  //轉入哪個錢包類型
  Rxn<WalletTransferType> toWalletTransferType =
      Rxn<WalletTransferType>(WalletTransferType.transferSafe);

  //當前選擇的錢包或是轉入轉出類型index
  RxInt selectedIndex = RxInt(0);

  //是否可以送出劃轉(打api)
  RxBool isCanSend = RxBool(false);

  //前一頁傳入的貨幣種類
  String initCurrencyType = "USD";

  final KeyboardController keyboardController = KeyboardController();
  var moreSpace = 0.0.obs;

  FundTransferController(this.initCurrencyType);

  @override
  void onInit() {
    super.onInit();
    walletTransferTypeList =
        List.from(WalletConfig.getWalletTransferList(type: initCurrencyType));
    initData();
    textController.addListener(() {
      checkAmountLimit(textController.text);
      onKeyboardNumberListener();
      setIsCanSend();
    });
  }

  void showCustomKeyboard() {
    Get.bottomSheet(buildKeyboard());
  }

  Widget buildKeyboard() {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            color: colorBackground,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localized(buttonCancel),
                    style: jxTextStyle.textStyleBold14(color: themeColor),
                  ),
                  Text(
                    localized(buttonDone),
                    style: jxTextStyle.textStyleBold14(color: themeColor),
                  ),
                ],
              ),
            ),
          ),
          NumberPad(
            showDot: true,
            bottomColor: colorBackground,
            onNumTap: (num1) {
              pdebug(num1);
            },
            onDeleteTap: () {
              pdebug('End');
            },
          ),
        ],
      ),
    );
  }

  //取得初始化資料
  initData() async {
    final WalletAssetsModel? data =
        await walletServices.getUserAssets(isShowBox: true);
    if (data != null) {
      _legalCurrencyList = data.legalCurrencyInfo!;
      _cryptoCurrencyList = data.cryptoCurrencyInfo!;
      totalWalletList
          .assignAll(_legalCurrencyList..addAll(_cryptoCurrencyList));
      switchCurrencyType(initCurrencyType);
    }
  }

  //切換貨幣類型
  switchCurrencyType(String currencyType) {
    initCurrencyType = currencyType;
    for (var element in totalWalletList) {
      if (initCurrencyType == element.currencyType) {
        currentWallet.value = element;
        break;
      }
    }
    List<CurrencyModel> totalWalletTypeList = [];
    if (_legalCurrencyList.isNotEmpty) {
      totalWalletTypeList.add(_legalCurrencyList[0]);
    }
    if (_cryptoCurrencyList.isNotEmpty) {
      totalWalletTypeList.add(_cryptoCurrencyList[0]);
    }
    this.totalWalletTypeList.assignAll(totalWalletTypeList);
  }

  //設置當前選擇的錢包
  setCurrentWallet(CurrencyModel wallet) {
    //重新定義錢包轉入轉出類型
    walletTransferTypeList = List.from(
      WalletConfig.getWalletTransferList(type: wallet.currencyType!),
    );
    if (wallet.currencyType == "USDT" &&
        (fromWalletTransferType.value?.code == WalletConfig.bobiTransferCode ||
            toWalletTransferType.value?.code ==
                WalletConfig.bobiTransferCode)) {
      //如果原本有選擇波幣的轉入或轉出則一律還原
      fromWalletTransferType.value = WalletTransferType.transferRemain;
      toWalletTransferType.value = WalletTransferType.transferSafe;
    }
    for (var element in totalWalletList) {
      if (wallet.currencyType == element.currencyType &&
          ((fromWalletTransferType.value?.code ==
                      WalletConfig.remainTransferCode &&
                  element.assetType == WalletTypeAPI.USER_AVAIL.name) ||
              (fromWalletTransferType.value?.code ==
                      WalletConfig.safeTransferCode &&
                  element.assetType == WalletTypeAPI.USER_BOX.name))) {
        currentWallet.value = element;
        break;
      }
    }
    setIsCanSend();
  }

  //取得當前選擇的錢包index
  int getCurrentWalletIndex() {
    return totalWalletTypeList.indexWhere(
      (element) => currentWallet.value?.currencyType == element.currencyType,
    );
  }

  //取得當前選擇的轉出類型index
  int getCurrentFromTransferIndex() {
    return walletTransferTypeList.indexWhere(
      (element) => fromWalletTransferType.value?.code == element.code,
    );
  }

  //取得當前選擇的轉入類型index
  int getCurrentToTransferIndex() {
    return walletTransferTypeList.indexWhere(
      (element) => toWalletTransferType.value?.code == element.code,
    );
  }

  //設定錢包轉入轉出類型
  setWalletTransferType(WalletTransferType from, WalletTransferType to) {
    fromWalletTransferType.value = from;
    toWalletTransferType.value = to;
    setCurrentWallet(currentWallet.value!);
  }

  //互換錢包類型轉入轉出類型
  exchangeWalletTransferType() {
    WalletTransferType? temp = fromWalletTransferType.value;
    fromWalletTransferType.value = toWalletTransferType.value;
    toWalletTransferType.value = temp;
    setCurrentWallet(currentWallet.value!);
  }

  //設置錢包或是轉入轉出類型index
  void selectedIndexHandler(int index) {
    selectedIndex.value = index;
  }

  //設置是否可以送出劃轉
  void setIsCanSend({Function? callback}) {
    double amount = double.tryParse(textController.text) ?? 0;
    if (amount > 0 && amount <= (currentWallet.value!.amount ?? 0)) {
      isCanSend.value = true;
    } else {
      isCanSend.value = false;
      callback?.call(amount);
    }
  }

  //發送劃轉api
  Future<FundTransferModel?> sendTransfer(
    BuildContext context,
    String orderType,
    String password,
  ) async {
    String amount = textController.text;
    FundTransferModel? data;
    ResponseData res = await paymentServices.fundTransfer(
      amount: amount,
      currencyType: currentWallet.value!.currencyType!,
      orderType: orderType,
      password: password,
    );
    if (res.success()) {
      data = FundTransferModel.fromJson(res.data);
    } else {
      isPasscodeIncorrect.value = true;
      if (res.code == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        pinCodeController.clear();
        passwordCount.value = 5;
        otpFocus.canRequestFocus = false;
      } else if (res.code == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
        common.showWarningToast(localized(incorrectPassword));
        if (res.data != null && res.data['retry_chance'] != null) {
          passwordCount.value = 5 - res.data['retry_chance'] as int;
          if (isPasscodeIncorrect.value && passwordCount.value != 5) {
            pinCodeController.clear();
          }
        } else {
          pinCodeController.clear();
        }
        isAttemptWrong.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!otpFocus.hasFocus) {
            otpFocus.requestFocus();
          }
          isAttemptWrong.value = false;
        });
      } else {
        common.showWarningToast(res.message);
        pinCodeController.clear();
      }
      data = null;
    }
    return data;
  }

  //劃轉成功後取得交易詳情
  Future<common.WalletRecordTradeItem?> getRecordData(
    BuildContext context,
    String txID,
  ) async {
    common.WalletRecordTradeItem? data;
    ResponseData res = await paymentServices.getRecordData(
      txID: txID,
    );
    if (res.success()) {
      data = common.WalletRecordTradeItem.fromJson(res.data);
    } else {
      imBottomToast(
        context,
        title: res.message,
        icon: ImBottomNotifType.warning,
      );
      data = null;
    }
    return data;
  }

  //根據用戶選取的轉入轉出類型取得api所需的order type
  String getOrderType() {
    String fromCode = fromWalletTransferType.value!.code;
    String toCode = toWalletTransferType.value!.code;
    String orderType = WalletTransferTypeAPI.BOB_WITHDRAW.name; //預設用戶餘額轉到波幣
    if (fromCode == WalletConfig.safeTransferCode &&
        toCode == WalletConfig.bobiTransferCode) {
      //保險櫃轉到波幣
      orderType = WalletTransferTypeAPI.BOB_WITHDRAW_FROM_USER_BOX.name;
    } else if (fromCode == WalletConfig.remainTransferCode &&
        toCode == WalletConfig.safeTransferCode) {
      //用戶餘額轉到保險櫃
      orderType = WalletTransferTypeAPI.USER_AVAIL_TO_BOX.name;
    } else if (fromCode == WalletConfig.safeTransferCode &&
        toCode == WalletConfig.remainTransferCode) {
      //保險櫃轉到用戶餘額
      orderType = WalletTransferTypeAPI.USER_BOX_TO_AVAIL.name;
    } else if (fromCode == WalletConfig.bobiTransferCode &&
        toCode == WalletConfig.remainTransferCode) {
      //波幣轉到用戶餘額
      orderType = WalletTransferTypeAPI.BOB_RECHARGE.name;
    } else if (fromCode == WalletConfig.bobiTransferCode &&
        toCode == WalletConfig.safeTransferCode) {
      //波幣轉到保險櫃
      orderType = WalletTransferTypeAPI.BOB_RECHARGE_TO_USER_BOX.name;
    }
    return orderType;
  }

  void onPressed(BuildContext context) {
    //先關閉鍵盤
    FocusScope.of(context).unfocus();
    //取得劃轉類型
    String orderType = getOrderType();
    if (orderType == WalletTransferTypeAPI.BOB_RECHARGE.name ||
        orderType == WalletTransferTypeAPI.BOB_RECHARGE_TO_USER_BOX.name) {
      //從波幣轉出去要打波幣api
    } else {
      //如果不是由波幣轉出去直接開啟密碼確認並打劃轉api
/*      imShowBottomSheet(context, (context) =>
          TransactionPwdDialog(
            amount: textController.text,
            currencyUnit: currentWallet.value?.currencyType,
            onConfirmFunc: (password,
                {Function(String errorMsg)? showError,
                  Function(bool isShow)? showDialog}) async {
              FundTransferModel? data = await sendTransfer(
                  context, orderType, password);
              Navigator.pop(context); //關閉密碼彈窗
              if (data != null) {
                showWarningToast(localized(fundTransferSuccess))
                WalletRecordTradeItem? recordData = await getRecordData(
                    context, data.txID!);
                Get.back();
                sharedDataManager.gotoWalletRecordDetailPage(
                    context, recordData);
                // Get.until((route) => route.settings.name == RouteName.walletView);
              }
            },
          ));*/
      otpFocus = FocusNode();
      if (!otpFocus.hasFocus) {
        otpFocus.requestFocus();
      }
      pinCodeController = TextEditingController();
      showModalBottomSheet(
        isScrollControlled: true,
        context: Get.context!,
        barrierColor: colorOverlay40,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        builder: (context) => Obx(
          () => CashierViewBottomSheet(
            step: 1,
            onCompleted: (
              password, {
              Function(String errorMsg)? showError,
              Function(bool isShow)? showDialog,
            }) async {
              await handeData(context, password, orderType);
              pinCodeController.clear();
            },
            isLoading: isLoading.value,
            onForgetPasscodeTap: () async {
              PasscodeController passCodeController;
              if (Get.isRegistered<PasscodeController>()) {
                passCodeController = Get.find<PasscodeController>();
              } else {
                passCodeController = Get.put(PasscodeController());
              }
              passCodeController.walletPasscodeOptionClick(
                'resetPasscode',
                isFromChatRoom: true,
              );
            },
            isPasscodeIncorrect: isPasscodeIncorrect,
            controller: this,
            amountText: textController.text,
            currencyText: currentWallet.value?.currencyType ?? "usdt",
            title: localized(paymentPassword),
            buttonCancel: localized(buttonCancel),
            transferTypeValue: localized(transferMoney),
            transferTypeTitle: localized(walletTransactionType),
            myPaymentMethod: localized(myPaymentMethod),
            myPaymentMethodTip: fromWalletTransferType.value?.name ??
                localized(walletAvailableBalance),
            otpFocus: otpFocus,
            isAttemptWrong: isAttemptWrong,
          ),
        ),
      ).then((value) {
        isLoading.value = false;
      });
    }
  }

  Future<void> handeData(
    BuildContext context,
    String password,
    String orderType,
  ) async {
    isLoading.value = true;
    FundTransferModel? data = await sendTransfer(context, orderType, password);
    isLoading.value = false;
    if (data != null) {
      common.showSuccessToast(localized(fundTransferSuccess));
      common.WalletRecordTradeItem? recordData =
          await getRecordData(context, data.txID!);
      Get.back();
      common.sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
      // Get.until((route) => route.settings.name == RouteName.walletView);
    }
  }

  void onKeyboardNumberListener() {
    RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');
    String amountText = textController.text;
    if (!pattern.hasMatch(textController.text) &&
        textController.text.isNotEmpty) {
      textController.text = amountText.isNotEmpty
          ? amountText.substring(0, textController.text.length - 1)
          : amountText;

      amountText = amountText.substring(0, amountText.length - 1);
    }
    if (textController.text.indexOf("0") == 0 &&
        textController.text.indexOf(".") != 1 &&
        textController.text.length > 1) {
      textController.text = amountText.substring(1);
      amountText = amountText.substring(1);
    }
    setIsCanSend(callback: (double amount) {});
  }

  void checkAmountLimit(dynamic number) {
    double amount = 10000000;
    if (number is String) {
      if (number.isNotEmpty) {
        amount = double.parse(number);
      } else {
        exceedAmountTxt.value = '';
        update();
        return;
      }
    }
    if (amount > (currentWallet.value!.amount ?? 0)) {
      exceedAmountTxt.value = localized(walletTransferExceedAvailBalance);
    } else {
      exceedAmountTxt.value = '';
    }
    update();
  }
}
