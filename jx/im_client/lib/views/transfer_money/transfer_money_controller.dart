import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/wallet/wallet_assets_bean.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/utils/wallet_transfer_error_type.dart';

class TransferMoneyController extends GetxController
    with GetTickerProviderStateMixin {
  late final int chatId;

  final amountController = TextEditingController();
  final remarkController = TextEditingController();
  final passwordCount = 0.obs;
  final isPasscodeIncorrect = false.obs;
  RxBool isAttemptWrong = false.obs;
  TextEditingController pinCodeController = TextEditingController();
  final isLoading = false.obs;
  final amountFocusNode = FocusNode();
  final noteFocusNode = FocusNode();
  FocusNode otpFocus = FocusNode();
  final remarkTextLength = 0.obs;

  VoidCallback? onFocusChangedCallback;

  final Rx<WalletAssetsData> _assetsData = WalletAssetsData(
    totalAmt: '-',
    totalAmtCurrencyType: '',
    cryptoCurrencyInfos: [],
    legalCurrencyInfos: [],
    updateTime: null,
  ).obs;

  WalletAssetsData get assetsData => _assetsData.value;

  final _amount = 0.0.obs;

  String get amount => _amount.toString();

  final _error = ''.obs;

  String get error => _error.value;

  bool get isOverWalletAmount =>
      _amount > double.parse(currencyAmount ?? '0.0');

  bool get isNextEnabled =>
      _amount > 0 && isOverWalletAmount == false && isLoading.value == false;

  String get walletAmount => assetsData.totalAmt ?? "-";

  String? get currencyAmount => _getCurrencyInfo(_currency)?.amount;

  CurrencyALLType _currency = CurrencyALLType.currencyUSDT;

  CurrencyALLType get currency => _currency;

  final _remark = ''.obs;

  String get remark => _remark.value;

  final _isKeyboardVisible = false.obs;

  bool get isKeyboardVisible => _isKeyboardVisible.value;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments['chatId'] != null) {
      chatId = Get.arguments['chatId'];
    }

    init();
  }

  @override
  void onClose() {
    amountController.dispose();
    remarkController.dispose();
    super.onClose();
  }

  WalletAssets? _getCurrencyInfo(CurrencyALLType type) {
    WalletAssets? info;
    final legalList = assetsData.legalCurrencyInfos;
    if (legalList.isNotEmpty) {
      info = legalList.firstWhereOrNull(
        (element) => element.currencyType == type.type,
      );
    }

    if (info != null) return info;

    final cryptoList = assetsData.cryptoCurrencyInfos;

    if (cryptoList.isEmpty) return null;

    if (cryptoList.isNotEmpty) {
      info = cryptoList.firstWhereOrNull(
        (element) => element.currencyType == type.type,
      );
    }

    return info;
  }

  void init() {
    requestWalletAssets();
  }

  void requestWalletAssets() async {
    ResponseData resData = await walletServices
        .getWalletAssets({"totalAmtCurrencyType": currency.type});
    if (resData.code == 0) {
      _assetsData.value = WalletAssetsData.fromJson(resData.data);
    } else {
      // showToast(resData.message);
    }

    update();
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void updateCurrency(CurrencyALLType type) {
    _currency = type;
    requestWalletAssets();
  }

  void setError(String value) {
    _error.value = value;
  }

  void clearError() {
    _error.value = '';
  }

  void setAmount(double value) {
    _amount.value = value;
  }

  void showKeyboard() {
    _isKeyboardVisible.value = true;
  }

  void setKeyboardValue(value) => _isKeyboardVisible.value = value;

  void hideKeyboard() {
    _isKeyboardVisible.value = false;
    amountFocusNode.unfocus();
    noteFocusNode.unfocus();
  }

  Future<ResponseData> requestTransfer(
    String password, {
    Map<String, dynamic>? tokenMap,
  }) async {
    try {
      isLoading.value = true;
      final ret = await sendTransferRequest(
        password: password,
        remark: remarkController.text,
        tokenMap: tokenMap,
      );
      if (ret.success()) {
        return ret;
      } else {
        isPasscodeIncorrect.value = true;
        if (ret.code == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
          pinCodeController.clear();
          passwordCount.value = 5;
        } else if (ret.code == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
          showErrorToast(localized(incorrectPassword));

          if (ret.data != null && ret.data['retry_chance'] != null) {
            passwordCount.value = 5 - ret.data['retry_chance'] as int;
            if (isPasscodeIncorrect.value && passwordCount.value != 5) {
              pinCodeController.clear();
            }
          } else {
            pinCodeController.clear();
          }
          if (!otpFocus.hasFocus) {
            otpFocus.requestFocus();
          }
        } else {
          showErrorToast(ret.message);
          pinCodeController.clear();
        }
        isLoading.value = false;
        pinCodeController.clear();
        return ResponseData(code: ret.code, message: ret.message);
      }
    } on AppException catch (e) {
      return handleErrorResult(e);
    }
  }

  ResponseData<dynamic> handleErrorResult(AppException e) {
    isPasscodeIncorrect.value = true;
    if (e.getPrefix() == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
      pinCodeController.clear();
      passwordCount.value = 5;
      otpFocus.canRequestFocus = false;
    } else if (e.getPrefix() == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
      showErrorToast(localized(incorrectPassword));
      passwordCount.value = 5 - e.getData()['retry_chance'] as int;
      if (isPasscodeIncorrect.value && passwordCount.value != 5) {
        pinCodeController.clear();
      }
      isAttemptWrong.value = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!otpFocus.hasFocus) {
          otpFocus.requestFocus();
        }
      });
    } else {
      final msg = WalletTransferErrorType.getErrorMsg(e);
      showErrorToast(msg);
    }
    isLoading.value = false;
    return ResponseData(
      code: -1,
      message: WalletTransferErrorType.getErrorMsg(e),
    );
  }

  void onConfirmed(
    password, {
    Function(String errorMsg)? showError,
    Function(bool isShow)? showDialog,
  }) async {
    const normalTextingBarHeight = 52.0;
    const bottomMargin = normalTextingBarHeight + 12;

    try {
      ResponseData res = await requestTransfer(password);
      bool needAuthPhone = res.needTwoFactorAuthPhone;
      bool needAuthEmail = res.needTwoFactorAuthEmail;
      if (res.success()) {
        if (needAuthPhone || needAuthEmail) {
          Map<String, String> tokenMap = await goSecondVerification(
            emailAuth: needAuthEmail,
            phoneAuth: needAuthPhone,
          );
          if (tokenMap.isEmpty) {
            showErrorToast(
              localized(walletToastSecondVerifyFailed),
              bottomMargin: bottomMargin,
            );
            return;
          }
          ResponseData resAgain = await requestTransfer(
            password,
            tokenMap: tokenMap,
          );
          Get.close(2);
          if (resAgain.success()) {
            showSuccessToast(
              localized(walletToastSentToFriendSuccess),
              bottomMargin: bottomMargin,
            );
          } else {
            showErrorToast(
              localized(walletToastSentToFriendFailed),
              bottomMargin: bottomMargin,
            );
          }
        } else {
          Get.close(2);
          showSuccessToast(
            localized(walletToastSentToFriendSuccess),
            bottomMargin: bottomMargin,
          );
        }
      }
    } on AppException catch (e) {
      final msg = WalletTransferErrorType.getErrorMsg(e);

      showErrorToast(
        msg,
        bottomMargin: bottomMargin,
      );
    }
  }

  Future<ResponseData> sendTransferRequest({
    required String password,
    String? remark,
    Map<String, dynamic>? tokenMap,
  }) async {
    setLoading(true);

    try {
      ResponseData resData = await walletServices.postTransferChat({
        "chatID": chatId,
        "amount": amount,
        "currencyType": currency.type,
        "passcode": password,
        if (remark != null) "remark": remark,
        ...?tokenMap,
      });

      return resData;
    } catch (e) {
      return ResponseData(code: -1, message: e.toString());
    } finally {
      setLoading(false);
    }
  }
}
