import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';
import 'package:jxim_client/views/wallet/components/transaction_summary.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:flutter/material.dart';
import '../../../api/wallet_services.dart';
import '../../../object/wallet/address_model.dart';
import '../../../object/wallet/transaction_model.dart';
import '../../../object/wallet/withdraw_modal.dart';
import 'dart:async';
import '../../../utils/color.dart';
import '../../../utils/net/error_code_constant.dart';
import '../../../utils/net/response_data.dart';
import '../../../utils/second_verification_utils.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../utils/toast.dart';
import '../transaction_details_view.dart';

class WithdrawController extends GetxController
    with GetTickerProviderStateMixin {
  late final TabController currencyTypeTabController;
  late TabController tabController;

  final WalletController _walletController = Get.find<WalletController>();
  final WalletServices walletServices = WalletServices();
  final Map configMap = {};
  final minHint = '${localized(walletWithdrawAmountHint)}'.obs;

  final addressWhiteListModeSwitch = false.obs;
  final newAddressWithdrawalSwitch = false.obs;


  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  List<CurrencyModel> get legalCurrencyList {
    return _walletController.legalCurrencyList;
  }
  final FocusNode recipientFocusNode = FocusNode();
  final FocusNode cryptoAmountFocusNode = FocusNode();
  final TextEditingController cryptoAmountController = TextEditingController();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  RxInt commentTextLength = 0.obs;
  Rx<int> recipientAddressTextLength = 0.obs;
  Rx<int> cryptoAmountTextLength = 0.obs;

  TextEditingController pinCodeController = TextEditingController();

  final TextEditingController filterRecipientController =
      TextEditingController();

  WithdrawModel withdrawModel = WithdrawModel();

  late final exchangeCurrencyType;

  final preselectedChain = ''.obs;
  final cryptoAmountInFiat = 0.0.obs;
  final gasFeeInCrypto = 0.00.obs;
  final gasFeeInCryptoText = '0.00'.obs;
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
      commentTextLength.value = commentController.text.length;
    });
    String selectedCurrencyType = Get.arguments['data'] ?? '';

    withdrawModel.selectedCurrency = cryptoCurrencyList.firstWhereOrNull(
        (element) => element.currencyType == selectedCurrencyType);
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
    _walletController.selectedCurrency = CurrencyModel();
    withdrawModel.addrID = '';
    withdrawModel.toAddr = '';
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initWithdrawConfig() async {
    configMap.addAll(await walletServices.getWithdrawConfig());
    getMinHint(withdrawModel.selectedCurrency!.currencyType!);
  }
  Future<void> getSettings() async {
    final resp = await walletServices.getSettings();
    if (resp.code == 0) {
      final isWhiteMode = resp.data['blockchain_addr_white_mode'] ?? false ;
      final isNewAddressLock = resp.data['new_blockchain_addr_lock'];
      addressWhiteListModeSwitch.value = isWhiteMode == 0 ? false : true;
      newAddressWithdrawalSwitch.value = isNewAddressLock == 0 ? false : true;
    }
  }

  void getMinHint(String currencyType) {
    if (configMap.containsKey(currencyType)) {
      minHint.value =
          '${localized(minWalletWithdrawAmountHint)} ${configMap[currencyType]['minAmtPerTrans']['transaction']} ${withdrawModel.selectedCurrency?.currencyType}';
    } else {
      minHint.value = '${localized(walletWithdrawAmountHint)}';
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
    final data = cryptoCurrencyList.where((element) =>
        element.currencyType == withdrawModel.selectedCurrency!.currencyType)
      ..first;
    if (data.isNotEmpty)
      maxTransfer = double.parse(data.first.amount.toString());

    onCryptoAmountChange('');
    cryptoAmountController.clear();
    update();
  }

  void selectChain(String chain) {
    isValidAddress.value = false;
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

  void makeMaxAmount() async {
    cryptoAmountController.clear();
    if (isInternalAddress.value == false) {
      onCryptoAmountChange(maxTransfer.toString());
    }
    cryptoAmountController.text = (maxTransfer - gasFeeInCrypto.value)
        .toDoubleFloor(withdrawModel.selectedCurrency!.getDecimalPoint);
    cryptoAmountInFiat.value = await (double.parse(cryptoAmountController.text))
        .to(toCurrencyType: 'USD', currency: withdrawModel.selectedCurrency!);
    onCryptoAmountChange(cryptoAmountController.text);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void onCryptoAmountChange(String amount) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (amount.isEmpty) {
        cryptoAmountController.clear();
        amount = '0';
      }

      // if (double.parse(amount) > maxTransfer) {
      //   cryptoAmountController.text = maxTransfer.toDoubleFloor(
      //       withdrawModel.selectedCurrency!.currencyType!.getDecimalPoint);
      //   FocusManager.instance.primaryFocus?.unfocus();
      // }
      double.parse(amount) > maxTransfer ? amountIsGreaterThan.value = true :
          amountIsGreaterThan.value = false;


      if (double.parse(amount) <= maxTransfer &&
          recipientController.text.isNotEmpty &&
          isValidAddress.value &&
          isInternalAddress.value == false  && double.parse(amount) >= double.parse(configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction'])) {
        final gasFee = await walletServices.calculateGasFee(
          currencyType: withdrawModel.selectedCurrency!.currencyType!,
          netType: withdrawModel.selectedCurrency!.netType!,
          amount: amount,
          toAddr: recipientController.text.trim(),
        );

        gasFeeInCrypto.value = double.parse(gasFee);
        gasFeeInCryptoText.value = gasFee;
        totalTransfer = double.parse(amount) + gasFeeInCrypto.value;
        // cryptoAmountController.text = (double.parse(amount) - gasFeeInCrypto.value)
        //     .toDoubleFloor(withdrawModel.selectedCurrency!.getDecimalPoint);
      } else {
        gasFeeInCrypto.value = 0.00;
        gasFeeInCryptoText.value = '0.00';
      }
      if (cryptoAmountController.text.isEmpty) {
        cryptoAmountInFiat.value = 0;
      } else {
        cryptoAmountInFiat.value =
            await (double.parse(cryptoAmountController.text)).to(
                toCurrencyType: 'USD',
                currency: withdrawModel.selectedCurrency!);
      }
    if(configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction'] != null){
      if (double.parse(amount)  < double.parse(configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction']) && cryptoAmountInFiat > 0) {
        Toast.showToast(
            '${localized(withdrawMinimunWithdrawAmountIs)}${configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction']} ${withdrawModel.selectedCurrency?.currencyType}');
      }
    }

      gasFeeInFiat = await gasFeeInCrypto.value
          .to(toCurrencyType: 'USD', currency: withdrawModel.selectedCurrency!);

      withdrawModel
        ..amount = double.tryParse(cryptoAmountController.text) ?? 0
        ..gasFee = gasFeeInCrypto.value;
      update();
    });
  }

  bool isEnableNextButton() {
    if (addressWhiteListModeSwitch.value == true && isAddressInWhiteList.value == false) {
      return false;
    }
    return withdrawModel.selectedCurrency!.currencyType != null &&
        withdrawModel.selectedCurrency!.netType != null &&
        cryptoAmountController.text.isNotEmpty &&
        double.parse(cryptoAmountController.text) + gasFeeInCrypto.value <=
            maxTransfer &&
        withdrawModel.toAddr != "" &&
        isValidAddress.value == true &&
        isMyAddress.value == false &&
        recipientController.text.isNotEmpty &&
        double.parse(cryptoAmountController.text) >= double.parse(configMap[withdrawModel.selectedCurrency?.currencyType]['minAmtPerTrans']['transaction']) &&
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
    filterRecipientAddressList.addAll(recipientAddressList.where((element) =>
    element.netType == recipientSelectedCurrency.value?.netType));

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
    filterRecipientAddressList.addAll(recipientAddressList.where((element) =>
        element.netType == recipientSelectedCurrency.value?.netType));
  }

  void selectRecipient(AddressModel address) {
    isValidAddress.value = false;
    withdrawModel.addrID = address.addrID;
    recipientController.text = address.address;
    withdrawModel.toAddr = address.address;
    withdrawModel.selectedCurrency = _walletController.cryptoCurrencyList
        .where((element) => element.currencyType == address.currencyType)
        .first;
    withdrawModel.selectedCurrency?.netType = address.netType;
    update();
    maxTransfer =
        double.parse(withdrawModel.selectedCurrency!.amount.toString());
    withdrawModel.selectedCurrency?.netType = address.netType;
    checkAddress();

    if (cryptoAmountController.text != 0) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }

  Future<void> setRecipientAddress(String address) async {
    recipientController.text = address;
    withdrawModel.toAddr = address;
    withdrawModel.addrID = '';

    checkIfInWhiteList(address);

    if (cryptoAmountController.text != 0) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
    await checkAddress();
  }

  void onChangedRecipient(String value) {
    isValidAddress.value == false;
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    checkIfInWhiteList(value);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        await checkAddress();
        withdrawModel.toAddr = recipientController.text.trim();
        withdrawModel.addrID = '';
      } else {
        withdrawModel.toAddr = recipientController.text.trim();
        withdrawModel.addrID = '';
      }
    });
    if (cryptoAmountController.text != 0) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }
  checkIfInWhiteList(String text){
    bool isInWhiteList = false;
    recipientAddressList.forEach((element) {
      if (element.address == text.trim()) {
        isInWhiteList = true;
      }
    });
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
        Toast.showToast('不能输入自己的地址');
        recipientController.clear();
      }
      update();
    });
  }

  String getAddressOwnerName() {
    final data = recipientAddressList.where((element) =>
        element.address == withdrawModel.toAddr &&
        element.addrID == withdrawModel.addrID);
    if (data.isEmpty) return '';
    return data.first.addrName;
  }

  Future<ResponseData> withdrawToAddress(String passcode,{Map<String,String>? tokenMap}) async {
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
    isValidAddress.value = false;
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
      if (result.success()){
        if (result.needTwoFactorAuthPhone || result.needTwoFactorAuthEmail){
          Map<String, String> tokenMap =
          await goSecondVerification(
              emailAuth: result.needTwoFactorAuthEmail,
              phoneAuth: result.needTwoFactorAuthPhone);
          if (tokenMap.isEmpty){
            Toast.showToast("二次验证失败");
            Get.back();
            return;
          }
          final resultAgain = await withdrawToAddress(value, tokenMap: tokenMap);
          if (resultAgain.txID.isNotEmpty){
            Get.back();
            final data = await getTransactionDetails(resultAgain.txID);
            Get.to(() => TransactionDetailsView(transaction: data,isAfterWithdraw: false));
          }else {
            Toast.showToast(resultAgain.message);
            Get.back();
          }
        }
      }else{
        Toast.showToast(result.message);
        Get.back();
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        pinCodeController.clear();
        passwordCount.value = 5;
        Get.back();
        Get.toNamed(RouteName.blockPasscodeView, arguments: {
          'expiryTime': e.getData()['exp'],
        });
      } else if (e.getPrefix() == ErrorCodeConstant.STATUS_NEW_ADDRESS_IN_24_HOURS_LOCK) {
        Toast.showToast("提现失败，新地址提币锁定中");
        Get.back();
      } else if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_INVALID_WALLET_PASSCODE) {
        pinCodeController.clear();

        passwordCount.value++;
        isLoading.value = false;
      } else {
        Toast.showToast(e.getMessage());
        Get.back();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void filterRecipient(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      filterRecipientAddressList.clear();
      filterRecipientAddressList.addAll(recipientAddressList
          .where((element) =>
              element.addrName.toLowerCase().contains(value.toLowerCase()) &&
              element.netType == withdrawModel.selectedCurrency!.netType)
          .toList());
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void submitRecipient(String value) {
    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(recipientAddressList
        .where((element) =>
            element.addrName.toLowerCase().contains(value.toLowerCase()) &&
            element.netType == withdrawModel.selectedCurrency!.netType)
        .toList());
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> selectNetwork(String value) async {
    recipientSelectedCurrency.value?.netType = value;
    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(recipientAddressList
        .where((element) => element.netType == value)
        .toList());
    if (cryptoAmountController.text != 0) {
      onCryptoAmountChange(cryptoAmountController.text.trim());
    }
  }

  void changePreselectedNetWork(String value){
    preselectedChain.value = value;
  }

  void getCommentWordCount() {
    int count = 0;
    if (commentController.text.isNotEmpty) {
      for (int i = 0; i < commentController.text.length; i++) {
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
        backgroundColor: JXColors.white,
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
                  color: JXColors.secondaryTextBlack,
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
                  Get.back();
                  pinCodeController = TextEditingController();
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    backgroundColor: JXColors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    builder: (context) => Obx(
                      () => TransactionSummary(
                        controller: this,
                        amountText: (withdrawModel.amount+gasFeeInCrypto.value).toString(),
                        currencyText:
                            withdrawModel.selectedCurrency!.currencyType ?? "-",
                        transferType: isInternalAddress.value
                            ? internalTransfer
                            : externalTransfer,
                        isLoading: isLoading.value,
                        onCompleted: completedWithdraw,
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
    final res = await walletServices.postWithdrawExplain();
    if (res.code == 0) {
      withdrawDescription.value = res.data['content'];
    } else {
      withdrawDescription.value = '';
    }
  }
}

extension calculateExchangeRate on double {
  Future<double> to(
      {required String toCurrencyType, required CurrencyModel currency}) async {
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
