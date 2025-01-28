import 'package:cashier/im_cashier.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:intl/intl.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';
import 'package:jxim_client/views/wallet/controller/keyboard_controller.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/transaction_model.dart';
import 'package:jxim_client/object/wallet/withdraw_modal.dart';
import 'dart:async';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/wallet/transaction_details_view.dart';

class WithdrawController extends GetxController
    with GetTickerProviderStateMixin {
  late final TabController currencyTypeTabController;
  late TabController tabController;
  FocusNode otpFocus = FocusNode();
  final WalletController _walletController = Get.find<WalletController>();
  final WalletServices walletServices = WalletServices();
  final Map configMap = {};
  final minHint = localized(walletWithdrawAmountHint).obs;

  final addressWhiteListModeSwitch = false.obs;
  final newAddressWithdrawalSwitch = false.obs;
  final isPasscodeIncorrect = false.obs;
  RxBool isAttemptWrong = false.obs;

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  // List<CurrencyModel> get legalCurrencyList {
  //   return _walletController.legalCurrencyList;
  // }
  final FocusNode recipientFocusNode = FocusNode();
  final FocusNode cryptoAmountFocusNode = FocusNode();
  final TextEditingController cryptoAmountController = TextEditingController();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  final KeyboardController keyboardController = KeyboardController();
  var moreSpace = 0.0.obs;

  final markFocusNode = FocusNode();
  VoidCallback? onFocusChangedCallback;

  RxInt commentTextLength = 0.obs;
  Rx<int> recipientAddressTextLength = 0.obs;
  Rx<int> cryptoAmountTextLength = 0.obs;

  TextEditingController pinCodeController = TextEditingController();

  final TextEditingController filterRecipientController =
      TextEditingController();

  WithdrawModel withdrawModel = WithdrawModel();

  late final String exchangeCurrencyType;

  final preselectedChain = ''.obs;
  final cryptoAmountInFiat = 0.0.obs;
  final gasFeeInCrypto = 1.00.obs;
  final gasFeeInCryptoText = '1.00'.obs;
  double gasFeeInFiat = 0.0;
  double maxTransfer = 0.0;
  double totalTransfer = 0.0;

  final passwordCount = 0.obs;
  final amountIsGreaterThan = false.obs;
  final isAddressInWhiteList = false.obs;

  List<AddressModel> recipientAddressList = <AddressModel>[];
  List<AddressModel> filterRecipientAddressList = <AddressModel>[].obs;
  List<AddressModel> ownAddressList = <AddressModel>[];

  Timer? _debounce;
  Timer? _addressDebounce;

  final recipientHeight = 10.obs;

  final isValidAddress = true.obs;
  final isInternalAddress = false.obs;
  final isMyAddress = false.obs;
  final withdrawDescription = ''.obs;

  final isLoading = false.obs;
  final commentWordCount = 30.obs;

  Rxn<CurrencyModel> recipientSelectedCurrency = Rxn<CurrencyModel>();

  @override
  Future<void> onInit() async {
    super.onInit();
    getWithdrawDescription();
    currencyTypeTabController = TabController(vsync: this, length: 2);
    tabController =
        TabController(vsync: this, length: cryptoCurrencyList.length);
    tabController.addListener(tabBarListener);

    exchangeCurrencyType = _walletController.walletBalanceCurrencyType;
    commentController.addListener(() {
      commentTextLength.value = commentController.text.characters.length;
    });
    String selectedCurrencyType = Get.arguments['data'] ?? '';

    withdrawModel.selectedCurrency = cryptoCurrencyList.firstWhereOrNull(
      (element) => element.currencyType == selectedCurrencyType,
    );
    withdrawModel.selectedCurrency?.netType =
        withdrawModel.selectedCurrency?.supportNetType?.first;
    maxTransfer =
        double.parse(withdrawModel.selectedCurrency!.amount!.toString());

    recipientController.addListener(() {
      recipientAddressTextLength.value = recipientController.text.length;
    });

    cryptoAmountController.addListener(() {
      cryptoAmountTextLength.value = cryptoAmountController.text.length;
    });

    cryptoAmountFocusNode.addListener(() {
      if (!cryptoAmountFocusNode.hasFocus) {
        toCheckIfLessThanMinMoney();
      }
    });

    getSettings();
    getUSDTAddressList();
  }

  @override
  void onReady() {
    super.onReady();
    initWithdrawConfig();
  }

  @override
  void onClose() {
    cryptoAmountController.dispose();
    commentController.dispose();
    recipientController.dispose();
    _debounce?.cancel();
    _addressDebounce?.cancel();
    _walletController.selectedCurrency = CurrencyModel();
    withdrawModel.addrID = '';
    withdrawModel.toAddr = '';
    super.onClose();
  }

  updateBottomSpace(double space) {
    moreSpace.value = space;
    update();
  }

  Future<void> initWithdrawConfig() async {
    configMap.addAll(await walletServices.getWithdrawConfig());
    getMinHint(withdrawModel.selectedCurrency!.currencyType!);
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

  void getMinHint(String currencyType) {
    if (configMap.containsKey(currencyType)) {
      minHint.value =
          '${localized(minWalletWithdrawAmountHint)} ${configMap[currencyType]['minAmtPerTrans']['transaction']}';
    } else {
      minHint.value = localized(walletWithdrawAmountHint);
    }
  }

  Future<void> tabBarListener() async {
    recipientSelectedCurrency.value = cryptoCurrencyList[tabController.index];
    recipientSelectedCurrency.value?.netType =
        recipientSelectedCurrency.value?.supportNetType?.first;

    await getRecipientAddressList(currency: recipientSelectedCurrency.value);
  }

  void selectSelectedCurrency(CurrencyModel currency) {
    withdrawModel.selectedCurrency = currency;
    withdrawModel.selectedCurrency?.netType = currency.supportNetType!.first;
    getMinHint(withdrawModel.selectedCurrency!.currencyType!);
    final data = cryptoCurrencyList.where(
      (element) =>
          element.currencyType == withdrawModel.selectedCurrency!.currencyType,
    )..first;
    if (data.isNotEmpty) {
      maxTransfer = double.parse(data.first.amount.toString());
    }

    onCryptoAmountChange('');
    cryptoAmountController.clear();
    update();
  }

  void selectChain(String chain) {
    //isValidAddress.value = false;
    withdrawModel.selectedCurrency!.netType = chain;
    onCryptoAmountChange(cryptoAmountController.text);
    checkAddress();
    getRecipientController().selectChain(chain);
    update();
  }

  RecipientAddressBookController getRecipientController() {
    bool isRegistered =
        GetInstance().isRegistered<RecipientAddressBookController>();

    if (isRegistered) return Get.find<RecipientAddressBookController>();

    final controller = RecipientAddressBookController();

    Get.put<RecipientAddressBookController>(controller);
    return controller;
  }

  getGas(String amount) async {
    String address = recipientController.text.trim();
    if (address.isEmpty) {
      if (withdrawModel.selectedCurrency!.netType! == "TRC20") {
        address = "TD48W7HzdV5XkrzGSpiM2UKgCYNjhTfnit";
      } else {
        address = "0xF0bAfD58E23726785A1681e1DEa0da15cB038C61";
      }
    }
    try {
      final gasFee = await walletServices.calculateGasFee(
        currencyType: withdrawModel.selectedCurrency!.currencyType!,
        netType: withdrawModel.selectedCurrency!.netType!,
        amount: amount,
        toAddr: address,
      );
      return gasFee;
    } on AppException {
      return "1";
    }
  }

  void makeMaxAmount() async {
    cryptoAmountController.clear();
    // if (isInternalAddress.value == false) {
    //   onCryptoAmountChange(maxTransfer.toString());
    // }
    if (maxTransfer == 0) {
      // set amount to zero
      cryptoAmountController.text = '0.00';
      cryptoAmountInFiat.value = 0.00;
      //set gas fee to zero
      gasFeeInCrypto.value = 0;
      gasFeeInCryptoText.value = '0.00';
    } else {
      // calculate gas fee
      final gasFee = await getGas((maxTransfer - 1).toString());
      gasFeeInCrypto.value = double.parse(gasFee);
      gasFeeInCryptoText.value = gasFee;

      cryptoAmountController.text = (maxTransfer - gasFeeInCrypto.value)
          .toDoubleFloor(withdrawModel.selectedCurrency!.getDecimalPoint);
      cryptoAmountInFiat.value =
          await (double.parse(cryptoAmountController.text)).to(
        toCurrencyType: 'USD',
        currency: withdrawModel.selectedCurrency!,
      );
    }

    onCryptoAmountChange(cryptoAmountController.text);
    // FocusManager.instance.primaryFocus?.unfocus();
    // toCheckIfLessThanMinMoney();
  }

  void toCheckIfLessThanMinMoney() {
    if (configMap[withdrawModel.selectedCurrency?.currencyType]
            ?['minAmtPerTrans']?['transaction'] !=
        null) {
      double inputMoney = double.parse(
        cryptoAmountController.text.isNotEmpty
            ? cryptoAmountController.text
            : "0",
      );
      double minAmtPerTrans = double.parse(
        configMap[withdrawModel.selectedCurrency?.currencyType]
            ['minAmtPerTrans']['transaction'],
      );
      if (inputMoney < minAmtPerTrans && cryptoAmountInFiat > 0) {
        common.showWarningToast(
          '${localized(withdrawMinimunWithdrawAmountIs)}${configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction']} ${withdrawModel.selectedCurrency?.currencyType}',
        );
      }
    }
  }

  void onCryptoAmountChange(String amount) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      if (amount.isEmpty) {
        cryptoAmountController.clear();
        amount = '0';
      }

      // if (double.parse(amount) > maxTransfer) {
      //   cryptoAmountController.text = maxTransfer.toDoubleFloor(
      //       withdrawModel.selectedCurrency!.currencyType!.getDecimalPoint);
      //   FocusManager.instance.primaryFocus?.unfocus();
      // }

      // Check if account balance is zero
      if (maxTransfer == 0) {
        gasFeeInCrypto.value = 0;
        gasFeeInCryptoText.value = formatNumber('0', withDot: true);
        totalTransfer = 0;

        // Show error if user inputs more than zero
        double.parse(amount) > 0
            ? amountIsGreaterThan.value = true
            : amountIsGreaterThan.value = false;
      } else {
        // Calculate gas fee and total transfer amount
        if (double.parse(amount) <= maxTransfer &&
            recipientController.text.isNotEmpty &&
            isValidAddress.value &&
            isInternalAddress.value == false &&
            double.parse(amount) >=
                double.parse(
                  configMap[withdrawModel.selectedCurrency?.currencyType]
                  ['minAmtPerTrans']['transaction'],
                )) {
          final gasFee = await getGas(amount);

        gasFeeInCrypto.value = double.parse(gasFee);
        gasFeeInCryptoText.value = formatNumber(gasFee, withDot: true);
        totalTransfer = double.parse(amount) + gasFeeInCrypto.value;
        // cryptoAmountController.text = (double.parse(amount) - gasFeeInCrypto.value)
        //     .toDoubleFloor(withdrawModel.selectedCurrency!.getDecimalPoint);
      } else {
        final gasFee = await getGas(
          configMap[withdrawModel.selectedCurrency?.currencyType]
              ['minAmtPerTrans']['transaction'],
        );
        gasFeeInCrypto.value = double.parse(gasFee);
        gasFeeInCryptoText.value = formatNumber(gasFee, withDot: true);
      }
      if (cryptoAmountController.text.isEmpty) {
        cryptoAmountInFiat.value = 0;
      } else {
        cryptoAmountInFiat.value =
            await (double.parse(cryptoAmountController.text)).to(
          toCurrencyType: 'USD',
          currency: withdrawModel.selectedCurrency!,
        );
      }

      // 检测金额是否足够
      double needMoney = double.parse(amount) + gasFeeInCrypto.value;
      if (maxTransfer > gasFeeInCrypto.value) {
        amountIsGreaterThan.value = needMoney > maxTransfer;
      } else {
        amountIsGreaterThan.value = false;
      }

      gasFeeInFiat = await gasFeeInCrypto.value
          .to(toCurrencyType: 'USD', currency: withdrawModel.selectedCurrency!);

        withdrawModel
          ..amount = double.tryParse(cryptoAmountController.text) ?? 0
          ..gasFee = gasFeeInCrypto.value;
        update();
      }
    });
  }

  bool isEnableNextButton() {
    if (addressWhiteListModeSwitch.value == true &&
        isAddressInWhiteList.value == false) {
      return false;
    }
    return withdrawModel.selectedCurrency?.currencyType != null &&
        withdrawModel.selectedCurrency!.netType != null &&
        cryptoAmountController.text.isNotEmpty &&
        double.parse(cryptoAmountController.text) + gasFeeInCrypto.value <=
            maxTransfer &&
        withdrawModel.toAddr != "" &&
        isValidAddress.value == true &&
        isMyAddress.value == false &&
        recipientController.text.isNotEmpty &&
        double.parse(cryptoAmountController.text) >=
            double.parse(
              configMap[withdrawModel.selectedCurrency?.currencyType]
                  ['minAmtPerTrans']['transaction'],
            ) &&
        double.parse(cryptoAmountController.text) > 0;
  }

  void addComment() {
    if (commentController.text.isNotEmpty) {
      withdrawModel.remark = commentController.text;
    }
  }

  Future<List<AddressModel>> getUSDTAddressList() async {
    final data = await walletServices.getRecipientsAddress(
      currencyType: 'USDT',
    );
    recipientAddressList.clear();
    filterRecipientAddressList.clear();
    recipientAddressList.addAll(data);
    filterRecipientAddressList.addAll(
      recipientAddressList.where(
        (element) =>
            element.netType == recipientSelectedCurrency.value?.netType,
      ),
    );

    //重新检查当前输入的usdt地址
    if (recipientController.text.isNotEmpty) {
      checkIfInWhiteList(recipientController.text);
    }
    return filterRecipientAddressList;
  }

  Future<void> getRecipientAddressList({CurrencyModel? currency}) async {
    final data = await walletServices.getRecipientsAddress(
      currencyType: recipientSelectedCurrency.value?.currencyType,
    );
    recipientAddressList.clear();
    filterRecipientAddressList.clear();
    recipientAddressList.addAll(data);
    filterRecipientAddressList.addAll(
      recipientAddressList.where(
        (element) =>
            element.netType == recipientSelectedCurrency.value?.netType,
      ),
    );
  }

  void selectRecipient(AddressModel address) {
    isValidAddress.value = false;
    withdrawModel.addrID = address.addrID;
    recipientController.text = address.address;
    withdrawModel.toAddr = address.address;
    withdrawModel.selectedCurrency = cryptoCurrencyList
        .where((element) => element.currencyType == address.currencyType)
        .first;
    withdrawModel.selectedCurrency?.netType = address.netType;
    update();
    maxTransfer =
        double.parse(withdrawModel.selectedCurrency!.amount.toString());
    withdrawModel.selectedCurrency?.netType = address.netType;
    checkAddress();

    if (cryptoAmountController.text.isNotEmpty) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }

  Future<void> setRecipientAddress(String address) async {
    recipientController.text = address;
    withdrawModel.toAddr = address;
    withdrawModel.addrID = '';

    checkIfInWhiteList(address);

    if (cryptoAmountController.text.isNotEmpty) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
    await checkAddress();
  }

  void onChangedRecipient(String value) {
    //isValidAddress.value == false;
    if (_addressDebounce?.isActive ?? false) _addressDebounce?.cancel();

    checkIfInWhiteList(value);

    _addressDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        await checkAddress();
        withdrawModel.toAddr = recipientController.text.trim();
        withdrawModel.addrID = '';
      } else {
        withdrawModel.toAddr = recipientController.text.trim();
        withdrawModel.addrID = '';
      }
    });
    if (cryptoAmountController.text.isNotEmpty) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }

  checkIfInWhiteList(String text) {
    bool isInWhiteList = false;
    for (var element in recipientAddressList) {
      if (element.address == text.trim()) {
        isInWhiteList = true;
      }
    }
    isAddressInWhiteList.value = isInWhiteList;
  }

  void updateLength(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result =
          ownAddressList.where((element) => element.address == value.trim());
      if (result.isEmpty) {
        withdrawModel.toAddr = value;
      } else {
        Toast.showToast(localized(walletCantEnterYourOwnAddress));
        recipientController.clear();
      }
      update();
    });
  }

  String getAddressOwnerName() {
    final data = recipientAddressList.where(
      (element) =>
          element.address == withdrawModel.toAddr &&
          element.addrID == withdrawModel.addrID,
    );
    if (data.isEmpty) return '';
    return data.first.addrName;
  }

  Future<ResponseData> withdrawToAddress(
    String passcode, {
    Map<String, String>? tokenMap,
  }) async {
    withdrawModel.passcode = passcode;
    withdrawModel.tokenMap = tokenMap;
    final res = await walletServices.withdrawToAddress(withdrawModel);
    return res;
  }

  Future<TransactionModel> getTransactionDetails(String transactionID) async {
    final data =
        await walletServices.getTransactionDetail(transactionID: transactionID);
    return data;
  }

  Future<void> checkAddress() async {
    //isValidAddress.value = false;
    if (recipientController.text.isNotEmpty) {
      final result = await walletServices.validateAddress(
        address: recipientController.text.trim(),
        netType: withdrawModel.selectedCurrency!.netType!,
      );

      isValidAddress.value = result['isValid'];
      isInternalAddress.value = result['isInternal'];
      isMyAddress.value = result['isOwnAdr'];
    } else {
      isMyAddress.value = false;
      isValidAddress.value = true;
    }
  }

  Future<void> completedWithdraw(String value) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await withdrawToAddress(value);
      if (result.success()) {
        if (result.needTwoFactorAuthPhone || result.needTwoFactorAuthEmail) {
          Map<String, String> tokenMap = await goSecondVerification(
            emailAuth: result.needTwoFactorAuthEmail,
            phoneAuth: result.needTwoFactorAuthPhone,
          );
          if (tokenMap.isEmpty) {
            Toast.showToast(localized(walletToastSecondVerifyFailed));
            Get.back();
            return;
          }
          final resultAgain =
              await withdrawToAddress(value, tokenMap: tokenMap);

          if (resultAgain.txID.isNotEmpty) {
            Get.back();
            final data = await getTransactionDetails(resultAgain.txID);
            Get.to(
              () => TransactionDetailsView(
                transaction: data,
                isAfterWithdraw: false,
              ),
            );
          } else {
            Toast.showToast(resultAgain.message);
            Get.back();
          }
        } else {
          if (result.txID.isNotEmpty) {
            Get.back();
            final data = await getTransactionDetails(result.txID);
            Get.to(
              () => TransactionDetailsView(
                transaction: data,
                isAfterWithdraw: false,
              ),
            );
          } else {
            Toast.showToast(result.message);
            Get.back();
          }
        }
      } else {
        Toast.showToast(result.message);
        Get.back();
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        pinCodeController.clear();
        passwordCount.value = 5;
        Get.back();
        Get.toNamed(
          RouteName.blockPasscodeView,
          arguments: {
            'expiryTime': e.getData()['exp'],
          },
        );
      } else if (e.getPrefix() == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
        isPasscodeIncorrect.value = true;
        common.showErrorToast(localized(incorrectPassword));
        if (e.getData() != null && e.getData()['retry_chance'] != null) {
          passwordCount.value = 5 - e.getData()['retry_chance'] as int;
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
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_NEW_ADDRESS_IN_24_HOURS_LOCK) {
        Toast.showToast(localized(walletToastWithdrawFailedAddressLocked));
        Get.back();
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_INVALID_WALLET_PASSCODE) {
        pinCodeController.clear();

        passwordCount.value++;
        isLoading.value = false;
      } else {
        Toast.showToast(e.getMessage());
        pinCodeController.clear();
        isAttemptWrong.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!otpFocus.hasFocus) {
            otpFocus.requestFocus();
          }
          isAttemptWrong.value = false;
        });
      }
    } finally {
      isLoading.value = false;
      pinCodeController.clear();
    }
  }

  void filterRecipient(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      filterRecipientAddressList.clear();
      filterRecipientAddressList.addAll(
        recipientAddressList
            .where(
              (element) =>
                  element.addrName
                      .toLowerCase()
                      .contains(value.toLowerCase()) &&
                  element.netType == withdrawModel.selectedCurrency!.netType,
            )
            .toList(),
      );
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void submitRecipient(String value) {
    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(
      recipientAddressList
          .where(
            (element) =>
                element.addrName.toLowerCase().contains(value.toLowerCase()) &&
                element.netType == withdrawModel.selectedCurrency!.netType,
          )
          .toList(),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> selectNetwork(String value) async {
    recipientSelectedCurrency.value?.netType = value;
    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(
      recipientAddressList
          .where((element) => element.netType == value)
          .toList(),
    );
    if (cryptoAmountController.text.isNotEmpty) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }

  void changePreselectedNetWork(String value) {
    preselectedChain.value = value;
  }

  void getCommentWordCount() {
    int count = 0;
    if (commentController.text.isNotEmpty) {
      for (int i = 0; i < commentController.text.characters.length; i++) {
        if (commentController.text[i].isChineseCharacter) {
          count += 2;
        } else {
          count += 1;
        }
      }
    }
    commentWordCount.value = 30 - count;
  }

  void nextProgress(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: colorWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        builder: (builder) => Column(
          children: [
            const SizedBox(height: 30.0),
            Image.asset(
              'assets/images/common/validate_info.png',
              width: 148.0,
              height: 148.0,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 30.0,
                right: 30.0,
                top: 20.0,
              ),
              child: Text(
                localized(validateInfoTitle),
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: MFontWeight.bold5.value,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 30.0,
                right: 30.0,
                top: 8.0,
              ),
              child: Text(
                localized(validateInfoContent),
                style: const TextStyle(
                  fontSize: 14.0,
                  color: colorTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: FullScreenWidthButton(
                title: localized(buttonOk),
                onTap: () {
                  // 点击了第一个弹框的ok
                  Get.back();
                  pinCodeController = TextEditingController();
                  otpFocus = FocusNode();
                  if (!otpFocus.hasFocus) {
                    otpFocus.requestFocus();
                  }
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    backgroundColor: colorWhite,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    builder: (context) => Obx(
                      () => CashierViewBottomSheet(
                        controller: this,
                        amountText:
                            (withdrawModel.amount + gasFeeInCrypto.value)
                                .toString(),
                        currencyText:
                            withdrawModel.selectedCurrency!.currencyType ?? "-",
                        isLoading: isLoading.value,
                        onCompleted: completedWithdraw,
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
                        title: localized(walletConfirmPayment),
                        buttonCancel: localized(buttonCancel),
                        transferTypeValue: isInternalAddress.value
                            ? localized(localized(internalTransfer))
                            : localized(localized(externalTransfer)),
                        transferTypeTitle: localized(localized(walletPayType)),
                        myPaymentMethod: localized(myPaymentMethod),
                        myPaymentMethodTip: localized(myWallet),
                        otpFocus: otpFocus,
                        isAttemptWrong: isAttemptWrong,
                      ),
                    ),
                  ).whenComplete(pinCodeController.clear);
                },
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom,
            ),
          ],
        ),
      );

  void clearRecipientAddress() {
    recipientController.clear();
    withdrawModel.addrID = '';
    gasFeeInCrypto.value = 0.00;
    checkAddress();
    update();
  }

  Future<void> getWithdrawDescription() async {
    final result = await walletServices.getReceiveAndPayExpalinData();
    String amountLimit = '0.00/1000000.00';
    String fee = '1 USDT';
    if (result.success()) {
      String min = result.data['usedWithdrawAmt'] ?? "0.00";
      String max = result.data['maxDailyWithdrawAmt'] ?? "1000000.00";
      amountLimit = "$min/$max";
      String feeValue = result.data['withdrawalFee'] ?? "1";
      fee = "${feeValue}USDT";
    }
    withdrawDescription.value =
        "${localized(withdrawStaticDescriptionPart1)} $amountLimit${localized(withdrawStaticDescriptionPart2)}\n${localized(withdrawStaticDescriptionPart3)}\n${localized(withdrawStaticDescriptionPart4)}$fee\n${localized(withdrawStaticDescriptionPart5)}";
    update();
  }

  void onKeyboardNumberListener(String? value) {
    RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');
    String amountText = cryptoAmountController.text;
    if (!pattern.hasMatch(cryptoAmountController.text) &&
        cryptoAmountController.text.isNotEmpty) {
      cryptoAmountController.text = amountText.isNotEmpty
          ? amountText.substring(0, cryptoAmountController.text.length - 1)
          : amountText;

      amountText = amountText.substring(0, amountText.length - 1);
    }
    if (cryptoAmountController.text.indexOf("0") == 0 &&
        cryptoAmountController.text.indexOf(".") != 1 &&
        cryptoAmountController.text.length > 1) {
      cryptoAmountController.text = amountText.substring(1);
      amountText = amountText.substring(1);
    }
  }

  String currencyType() {
    return withdrawModel.selectedCurrency?.currencyType ?? "USDT";
  }

  String netType() {
    return withdrawModel.selectedCurrency?.netType ?? "TRC20";
  }

  static String formatNumber(dynamic number, {bool withDot = true}) {
    double? parsedNumber;

    if (number is double) {
      parsedNumber = number;
    } else if (number is String) {
      try {
        parsedNumber = double.parse(number);
      } catch (e) {
        return 'Invalid number';
      }
    } else {
      return 'Invalid input';
    }

    final formatter = NumberFormat(withDot ? '#,##0.00' : '#,##0', 'en_US');
    return formatter.format(parsedNumber);
  }
}

extension CalculateExchangeRate on double {
  Future<double> to({
    required String toCurrencyType,
    required CurrencyModel currency,
  }) async {
    final WalletServices walletServices = WalletServices();
    final data = await walletServices.calculateExchangeCurrency(
      amount: this,
      fromCurrencyType: currency.currencyType!,
      // fromNetType: 'TRC20',
      toCurrencyType: toCurrencyType,
    );
    return double.parse(data);
  }
}
