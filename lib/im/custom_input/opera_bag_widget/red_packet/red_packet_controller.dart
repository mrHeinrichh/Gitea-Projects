import 'dart:async';
import 'dart:collection';
import 'package:azlistview/azlistview.dart';
import 'package:cashier/im_cashier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_passcode_modal_bottom_sheet.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/wallet/red_packet_model.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart' as im;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/wallet_transfer_error_type.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/model/red_packet.dart';

class RedPacketController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RedPacketController({required this.tag});

  FocusNode otpFocus = FocusNode();
  final String tag;

  final redPacketType = RedPacketType.luckyRedPacket.obs;

  final WalletServices walletServices = WalletServices();

  final Map configMap = {};

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  var currentKeyboardController = TextEditingController().obs;

  RxString amountError = ''.obs;
  RxString redPacketMaxMemError = ''.obs;
  RxInt remarkRemainLength = 30.obs;

  late TabController tabController;

  final TextEditingController filterCryptoController = TextEditingController();

  final ScrollController selectedMembersController = ScrollController();

  double maxTransfer = 0.0;
  String walletBalanceCurrencyType = 'USD';
  final cryptoAmountInFiat = 0.0.obs;
  final totalTransfer = 0.0.obs;
  final totalTransferInFiat = 0.0.obs;
  final quantity = 0.obs;
  final isKeyboardVisible = false.obs;
  final highlightMember = 0.obs;

  final passwordCount = 0.obs;
  RxBool isAttemptWrong = false.obs;
  final themedColor = themeColor.obs;

  List<CurrencyModel> _cryptoCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> get cryptoCurrencyList => _cryptoCurrencyList;

  List<CurrencyModel> _legalCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> get legalCurrencyList => _legalCurrencyList;

  List<CurrencyModel> filterCryptoCurrencyList = <CurrencyModel>[].obs;

  final List<User> groupMemberList = <User>[].obs;
  RxList<User> filterList = <User>[].obs;
  RxList<AZItem> azFilterList = <AZItem>[].obs;
  RxList<User> selectedRecipients = <User>[].obs;

  final selectedCurrency = CurrencyModel().obs;

  RedPacketModel redPacketModel = RedPacketModel();

  Timer? _debounce;

  final toConfirmPage = false.obs;

  final isPasscodeIncorrect = false.obs;
  final isLoading = false.obs;

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;

  bool isBottomSheetOpen = false;

  final CustomInputController customInputController = CustomInputController();

  @override
  onInit() {
    super.onInit();

    tabController = TabController(vsync: this, length: 3);
    tabController.addListener(() {
      switch (tabController.index) {
        case 0:
          redPacketType.value = RedPacketType.luckyRedPacket;
          themedColor.value = redPacketType.value.appBarColor;
          calculateTotalTransfer();
          break;
        case 1:
          redPacketType.value = RedPacketType.normalRedPacket;
          themedColor.value = redPacketType.value.appBarColor;
          calculateTotalTransfer();
          break;
        case 2:
          redPacketType.value = RedPacketType.exclusiveRedPacket;
          themedColor.value = redPacketType.value.appBarColor;
          calculateTotalTransfer();
          break;
      }
    });
    initPage();

    ///ever(isSearching, (_) => clearSearching());
  }

  initPage() async {
    final WalletAssetsModel? data = await walletServices.getUserAssets();
    configMap.addAll(await walletServices.getRedPacketConfig());

    if (data != null) {
      walletBalanceCurrencyType = data.totalAmtCurrencyType!;
      _cryptoCurrencyList = data.cryptoCurrencyInfo!;
      _legalCurrencyList = data.legalCurrencyInfo!;
    }

    filterCryptoCurrencyList.addAll(cryptoCurrencyList);

    selectedCurrency.value = cryptoCurrencyList
        .firstWhereOrNull((element) => element.currencyType == 'USDT')!;

    maxTransfer = selectedCurrency.value.amount!;

    try {
      final Group? grp = await objectMgr.myGroupMgr
          .getGroupByRemote(int.parse(tag), notify: true);
      if (grp != null) {
        List<User> tempUserList = [];
        if (grp.members.isNotEmpty) {
          for (var item in grp.members) {
            User? data;
            if (item['user_name'] != "") {
              data = objectMgr.userMgr.getUserById(item['user_id']);
            } else {
              data = await objectMgr.userMgr.loadUserById2(item['user_id']);
            }
            String alias = objectMgr.userMgr.getUserTitle(data);
            User user = User.fromJson({
              'uid': item['user_id'],
              'nickname': alias == '' ? item['user_name'] : alias,
              'profile_pic': item['icon'],
              'last_online': item['last_online'],
            });
            tempUserList.add(user);
          }
        }

        groupMemberList.assignAll(tempUserList);
        filterList.assignAll(tempUserList);
        filterList.sort(
          (a, b) => multiLanguageSort(
            a.nickname.toLowerCase(),
            b.nickname.toLowerCase(),
          ),
        );
        updateAZFriendList();
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    Get.findAndDelete<RedPacketController>();
    super.onClose();
  }

  setKeyboardState(bool value) {
    isKeyboardVisible(value);
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => onSearch());
  }

  void onSearch() {
    filterList.value = groupMemberList
        .where(
          (User user) => objectMgr.userMgr
              .getUserTitle(user)
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()),
        )
        .toList();
    updateAZFriendList();
  }

  void clearSearching() {
    isSearching.value = false;
    searchParam.value = '';
    searchController.clear();
    onSearch();
  }

  void toSpecificTab() {
    themedColor.value = redPacketType.value.appBarColor;
    tabController.index = redPacketType.value.index;

    calculateTotalTransfer();
  }

  void selectSelectedCurrency(CurrencyModel currency) {
    selectedCurrency.value = currency;

    final data = cryptoCurrencyList.where(
      (element) => element.currencyType == selectedCurrency.value.currencyType,
    )..first;
    if (data.isNotEmpty) {
      maxTransfer = double.parse(data.first.amount.toString());
    }
    amountController.clear();
    calculateGasFee('');
    calculateTotalTransfer();

    update();
  }

  void onSelect(bool? selected, User user) {
    final indexList =
        selectedRecipients.indexWhere((element) => element.id == user.id);
    if (indexList > -1) {
      selectedRecipients
          .removeWhere((User selectedUser) => selectedUser.id == user.id);
      highlightMember.value = 0;
    } else {
      selectedRecipients.add(user);
    }
    calculateTotalTransfer();
  }

  void calculateGasFee(String amount) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (amount.isEmpty) {
        amountController.clear();
        amount = '0';
      }
      calculateTotalTransfer();
      cryptoAmountInFiat.value = await double.parse(amount)
          .to(toCurrencyType: 'USD', currency: selectedCurrency.value);
    });
  }

  bool isEnableNext() {
    if (redPacketType.value == RedPacketType.exclusiveRedPacket) {
      return selectedRecipients.isNotEmpty &&
          amountController.text.isNotEmpty &&
          double.parse(amountController.text) > 0 &&
          totalTransfer.value <= maxTransfer;
    } else {
      return amountController.text.isNotEmpty &&
          double.parse(amountController.text) > 0 &&
          totalTransfer.value <= maxTransfer &&
          quantity.value >= 1 &&
          quantity.value <= groupMemberList.length;
    }
  }

  Future<void> makeMaxAmount() async {
    amountController.text = getMaxTransferAmount();

    calculateGasFee(getMaxTransferAmount());
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void showIMSuccessToast() {
    im.imBottomToast(Get.context!,
        title: localized(youHaveSendRedPacket),
        icon: im.ImBottomNotifType.success,
        isStickBottom: false,
        duration: 3);
  }

  Future<void> confirmSend(String value) async {
    isLoading.value = true;
    if (redPacketType.value == RedPacketType.none) return;

    if (objectMgr.chatMgr.groupSlowMode[int.parse(tag)] != null) {
      if (!objectMgr.chatMgr.groupSlowMode[int.parse(tag)]?['isEnable']) {
        Group group = objectMgr.chatMgr.groupSlowMode[int.parse(tag)]?['group'];
        Message message =
            objectMgr.chatMgr.groupSlowMode[int.parse(tag)]?['message'];
        DateTime createTime =
            DateTime.fromMillisecondsSinceEpoch(message.create_time * 1000);
        Duration duration = Duration(seconds: group.speakInterval) -
            DateTime.now().difference(createTime);
        Toast.showToastMessage(
          localized(inSlowMode, params: [getMinuteSecond(duration)]),
        );
        Get.close(3);
        return;
      }
    }

    redPacketModel.amount = amountController.text;
    redPacketModel.currencyType = selectedCurrency.value.currencyType;
    redPacketModel.chatID = int.parse(tag);
    redPacketModel.rpType = redPacketType.value.value;
    redPacketModel.rpNum = int.tryParse(quantityController.text) ?? 0;
    redPacketModel.recipientIDs =
        selectedRecipients.map<int>((e) => e.id).toList();
    redPacketModel.remark = commentController.text.isEmpty
        ? localized(enterRemark)
        : commentController.text;
    redPacketModel.passcode = pinCodeController.text;
    redPacketModel.tokenMap = null;
    try {
      final res =
          await WalletServices().sendRedPacket(redPacketModel: redPacketModel);
      isPasscodeIncorrect.value = false;
      passwordCount.value = 0;
      if (res.success()) {
        if (res.needTwoFactorAuthPhone || res.needTwoFactorAuthEmail) {
          Map<String, String> tokenMap = await goSecondVerification(
            emailAuth: res.needTwoFactorAuthEmail,
            phoneAuth: res.needTwoFactorAuthPhone,
          );
          if (tokenMap.isEmpty) {
            // Toast.showToast("二次验证失败");
            Get.back();
            return;
          }
          redPacketModel.tokenMap = tokenMap;
          final resAgain = await WalletServices()
              .sendRedPacket(redPacketModel: redPacketModel);
          if (resAgain.success()) {
            Get.close(2);
            showIMSuccessToast();
            await customInputController.playSendMessageSound();
          } else {
            showSuccessToast(resAgain.message.toString());
            Get.back();
          }
        } else {
          if (res.success()) {
            showIMSuccessToast();
          }
          Get.close(2);
          await customInputController.playSendMessageSound();
        }
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        isPasscodeIncorrect.value = true;
        pinCodeController.clear();
        passwordCount.value = 5;
        otpFocus.canRequestFocus = false;
      } else if (e.getPrefix() == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
        isPasscodeIncorrect.value = true;
        showErrorToast(localized(incorrectPassword));
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
      } else {
        final msg = WalletTransferErrorType.getErrorMsg(e);
        showErrorToast(msg);
        Get.back();
        pinCodeController.clear();
      }
    }
    pinCodeController.clear();
    isLoading.value = false;
  }

  void filterCrypto(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      filterCryptoCurrencyList.clear();
      filterCryptoCurrencyList.addAll(
        cryptoCurrencyList
            .where(
              (element) =>
                  element.currencyType!
                      .toLowerCase()
                      .contains(value.toLowerCase()) ||
                  element.currencyName!
                      .toLowerCase()
                      .contains(value.toLowerCase()),
            )
            .toList(),
      );
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void submitCrypto(String value) {
    filterCryptoController.clear();
    filterCryptoCurrencyList.clear();
    filterCryptoCurrencyList.addAll(
      cryptoCurrencyList
          .where(
            (element) => element.currencyType!
                .toLowerCase()
                .contains(value.toLowerCase()),
          )
          .toList(),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void calculateTotalTransfer() {
    switch (redPacketType.value) {
      case RedPacketType.exclusiveRedPacket:
        if (amountController.text.isEmpty || selectedRecipients.isEmpty) {
          totalTransfer.value = 0;
          return;
        }

        totalTransfer.value =
            double.parse(amountController.text) * selectedRecipients.length;
        amountError.value = totalTransfer.value > maxTransfer
            ? localized(redPocketExceedMaxLimit)
            : '';

        break;
      case RedPacketType.normalRedPacket:
        if (amountController.text.isEmpty || quantityController.text.isEmpty) {
          totalTransfer.value = 0;
          return;
        }
        totalTransfer.value = double.parse(amountController.text) *
            double.parse(quantityController.text);

        amountError.value = totalTransfer.value > maxTransfer
            ? localized(redPocketExceedMaxLimit)
            : '';

        break;
      case RedPacketType.luckyRedPacket:
        if (amountController.text.isEmpty || quantityController.text.isEmpty) {
          totalTransfer.value = 0;
          return;
        }
        totalTransfer.value = double.parse(amountController.text);
        break;
      case RedPacketType.none:
        break;
    }
  }

  Future<void> navigateConfirmPage(BuildContext context) async {
    if (!isBottomSheetOpen) {
      isBottomSheetOpen = true;
      calculateTotalTransfer();
      totalTransferInFiat.value = await totalTransfer.value.to(
        toCurrencyType: 'USD',
        currency: selectedCurrency.value,
      );
      pinCodeController = TextEditingController();
      otpFocus = FocusNode();
      if (!otpFocus.hasFocus) {
        otpFocus.requestFocus();
      }
      showModalBottomSheet(
        isScrollControlled: true,
        context: Get.context!,
        backgroundColor: colorBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        builder: (context) => Obx(
          () => CashierViewBottomSheet(
            controller: this,
            amountText: totalTransfer.value
                .toDoubleFloor(selectedCurrency.value.getDecimalPoint),
            currencyText: selectedCurrency.value.currencyType ?? "",
            isLoading: isLoading.value,
            onCompleted: confirmSend,
            onForgetPasscodeTap: () {
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
            title: localized(paymentPassword),
            buttonCancel: localized(buttonCancel),
            transferTypeValue: localized(localized(redPacket)),
            transferTypeTitle: localized(transferType),
            myPaymentMethod: localized(walletTransactionDeduction),
            myPaymentMethodTip: localized(myWallet),
            otpFocus: otpFocus,
            isAttemptWrong: isAttemptWrong,
          ),
        ),
      ).whenComplete(() {
        pinCodeController.clear();
        isBottomSheetOpen = false;
        isLoading.value = false;
        isPasscodeIncorrect.value = false;
      });
    }
  }

  void clearData() {
    quantityController.clear();
    amountController.clear();
    commentController.clear();
    selectedCurrency.value = cryptoCurrencyList
        .firstWhere((element) => element.currencyType == 'USDT');
    quantity.value = 0;
    calculateGasFee('0');
    selectedRecipients.clear();
  }

  void showPasscode(BuildContext context) {
    pinCodeController = TextEditingController();
    showModalBottomSheet(
      backgroundColor: colorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return const RedPacketPasscodeModalBottomSheet();
      },
    );
  }

  void onNumberTap(String number) {
    if (pinCodeController.text.length < 4) {
      final currentValue = pinCodeController.text;
      final newText = currentValue + number;
      pinCodeController.text = newText;
    }
  }

  void onDeleteTap() {
    final currentValue = pinCodeController.text;
    if (currentValue.isNotEmpty) {
      final newText = currentValue.substring(0, currentValue.length - 1);
      pinCodeController.text = newText;
    }
  }

  String getMinTransferAmount() {
    if (configMap.containsKey(selectedCurrency.value.currencyType)) {
      return configMap[selectedCurrency.value.currencyType]['minAmount'];
    }
    return '0';
  }

  String getMaxTransferAmount() {
    if (configMap.containsKey(selectedCurrency.value.currencyType)) {
      if (double.parse(
            configMap[selectedCurrency.value.currencyType]['maxAmount'],
          ) >
          maxTransfer) {
        return maxTransfer
            .toDoubleFloor(selectedCurrency.value.getDecimalPoint);
      }
      return configMap[selectedCurrency.value.currencyType]['maxAmount'];
    }

    return '0';
  }

  int getMaxSplitNumber() {
    if (configMap.containsKey(selectedCurrency.value.currencyType)) {
      if (configMap[selectedCurrency.value.currencyType]['maxSplitNum'] >
          groupMemberList.length) {
        return groupMemberList.length;
      }
      return configMap[selectedCurrency.value.currencyType]['maxSplitNum'];
    }

    return 0;
  }

  ///更新azFriendList列表
  void updateAZFriendList() {
    azFilterList.value = filterList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(azFilterList);
  }

  List<String> filterIndexBar() {
    if (isSearching.value || searchParam.isNotEmpty) {
      return [];
    }
    List<String> indexList = [];

    for (AZItem item in azFilterList) {
      String tag = item.tag;
      bool startChar = tag.startsWith(RegExp(r'[a-zA-Z]'));
      if (startChar) {
        indexList.add(tag);
      }
    }
    List<String> resultList = LinkedHashSet<String>.from(indexList).toList();
    resultList.add('#');
    return resultList;
  }

  //當前選擇的錢包或是轉入轉出類型index
  RxInt selectedIndex = RxInt(0);

  //設置錢包或是轉入轉出類型index
  void selectedIndexHandler(int index) {
    selectedIndex.value = index;
  }

  List getRedPacketTypeItems() {
    return [
      {
        'text': localized(lucky),
        'onClick': () {
          redPacketType.value = RedPacketType.luckyRedPacket;
          calculateTotalTransfer();
        },
      },
      {
        'text': localized(normal),
        'onClick': () {
          redPacketType.value = RedPacketType.normalRedPacket;
          calculateTotalTransfer();
        },
      },
      {
        'text': localized(exclusive),
        'onClick': () {
          redPacketType.value = RedPacketType.exclusiveRedPacket;
          calculateTotalTransfer();
        },
      },
    ];
  }
}
