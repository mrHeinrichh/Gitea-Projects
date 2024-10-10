import 'package:azlistview/azlistview.dart';
import 'package:cashier/im_cashier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/payment_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/account_contact.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/object/wallet/wallet_transfer_model.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/wallet/controller/keyboard_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:im_common/im_common.dart' as common;

class TransferController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final remainInputCount = 30.obs;
  final isLoading = false.obs;
  final isPasscodeIncorrect = false.obs;
  TextEditingController pinCodeController = TextEditingController();
  FocusNode otpFocus = FocusNode();
  final passwordCount = 0.obs;
  RxBool isAttemptWrong = false.obs;
  FocusNode toWhomTextFocus = FocusNode();
  FocusNode memoTextFocus = FocusNode();
  FocusNode amountTextFocus = FocusNode();
  final toWhomTextController = TextEditingController();
  final memoTextController = TextEditingController();
  final amountTextController = TextEditingController();
  final isKeyboardVisible = false.obs;
  final useCustomerNumPad = false;
  RxString exceedAmountTxt = ''.obs;

  final KeyboardController keyboardController = KeyboardController();
  late Rx<Animation<Offset>?> offsetAnimation = Rx<Animation<Offset>?>(null);
  final GlobalKey amountTextFieldKey = GlobalKey();
  final GlobalKey toWhoTextFieldKey = GlobalKey();
  var moreSpace = 0.0.obs;

  //使用者強制從外部指定的手機號(如聯絡人 掃描二維碼等)
  String specificPhone = "";

  //使用者再輸入框輸入的手機號
  String userInputPhone = "";

  List<CurrencyModel> _legalCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> _cryptoCurrencyList = <CurrencyModel>[];

  //匹配聯繫人列表
  RxList<AccountContact> accountContactList = RxList<AccountContact>();

  //所有錢包
  RxList<CurrencyModel> totalWalletList = RxList<CurrencyModel>();

  //當前選擇的錢包
  Rxn<CurrencyModel> currentWallet = Rxn<CurrencyModel>();

  //當前選擇的錢包或是轉入轉出類型index
  RxInt selectedCurrencyIndex = RxInt(0);

  //是否可以送出劃轉(打api)
  RxBool isCanSend = RxBool(false);

  //手機號至少輸入幾位數才可以
  int minPhoneDigit = 8;

  //手機號錯誤提示文字
  RxString phoneErrorHint = RxString("");

  //要轉帳給對方的用戶資訊
  AccountContact? toUserInfo;

  //要轉帳給對方的用戶id
  RxInt toUserId = RxInt(0);

  //是否是從掃碼進來的
  bool isFromScanQRCode = false;

  TransferController(this.isFromScanQRCode);

  //是否顯示用戶匹配列表
  RxBool isShowMatchContact = RxBool(false);

  //前一頁傳入的貨幣種類
  String initCurrencyType = "USDT";

  Map? args;
  setKeyboardState(bool value) {
    if (useCustomerNumPad) {
      isKeyboardVisible(value);
    }
  }

  updateOffsetAnimation(Animation<Offset> animation) {
    offsetAnimation.value = animation;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    initData();

    // 監聽 memoTextController 的文本變化
    memoTextController.addListener(() {
      final remainingChars = 30 - memoTextController.text.characters.length;
      remainInputCountHandler(remainingChars);
    });
    toWhomTextFocus.addListener(_onToWhomFocusChange);
    memoTextFocus.addListener(_onMemoFocusChange);
    amountTextFocus.addListener(_onAmountFocusChange);
    toWhomTextController.addListener(() {
      if (userInputPhone == toWhomTextController.text.trim()) {
        return;
      }
      userInputPhone = toWhomTextController.text.trim();
      if (specificPhone == "" &&
          userInputPhone != "" &&
          (userInputPhone.length < minPhoneDigit)) {
        phoneErrorHint.value = localized(walletPleasEnterValidMobilePhone);
      } else {
        phoneErrorHint.value = "";
      }
      //當用戶輸入超過一定位數就呼叫查找用戶api
      if (specificPhone == "" && userInputPhone.length >= minPhoneDigit) {
        searchContactList();
      }
      // if (userInputPhone.length < minPhoneDigit) {
      //   toUserInfo = null;
      // toUserId.value = 0;
      // }
      specificPhone = "";
      setIsCanSend();
    });
    amountTextController.addListener(() {
      setIsCanSend();
    });
  }

  @override
  void onClose() {
    toUserInfo = null;
    toUserId.value = 0;
    toWhomTextFocus.removeListener(_onToWhomFocusChange);
    keyboardController.dispose();
    super.onClose();
  }

  void _onToWhomFocusChange() {
    if (toUserInfo != null && !toWhomTextFocus.hasFocus) {
      //當失去焦點的時候點檢查有無指定用戶
      setToUserText(
        toUserInfo!.uid!,
        toUserInfo!.nickname!,
        toUserInfo!.countryCode!,
        toUserInfo!.contact!,
      );
    }
  }

  void _onMemoFocusChange() {
    if (isShowMatchContact.value) {
      isShowMatchContact.value = false;
    }
  }

  void _onAmountFocusChange() {
    if (isShowMatchContact.value) {
      isShowMatchContact.value = false;
    }
  }

  //取得初始化資料
  initData() async {
    final args = Get.arguments;
    var accountId = args['accountId'];
    getUserInfo(accountId);

    final WalletAssetsModel? data =
        await walletServices.getUserAssets(isShowBox: true);
    if (data != null) {
      _legalCurrencyList = data.legalCurrencyInfo!;
      _cryptoCurrencyList = data.cryptoCurrencyInfo!;
      List<CurrencyModel> totalWallet = [];
      for (var element in _legalCurrencyList) {
        if (element.assetType == WalletTypeAPI.USER_AVAIL.name) {
          totalWallet.add(element);
          break;
        }
      }
      for (var element in _cryptoCurrencyList) {
        if (element.assetType == WalletTypeAPI.USER_AVAIL.name) {
          totalWallet.add(element);
          break;
        }
      }
      totalWalletList.assignAll(totalWallet);
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
  }

  //設置當前選擇的錢包
  setCurrentWallet(CurrencyModel wallet) {
    currentWallet.value = wallet;
    setIsCanSend();
  }

  //取得當前選擇的錢包index
  int getCurrentWalletIndex() {
    return totalWalletList.indexWhere(
      (element) => currentWallet.value?.currencyType == element.currencyType,
    );
  }

  void selectedCurrencyIndexHandler(index) {
    selectedCurrencyIndex.value = index;
  }

  void remainInputCountHandler(value) {
    remainInputCount.value = value;
  }

  //根據用戶輸入的電話號碼自動搜尋匹配
  searchContactList() async {
    accountContactList.clear();
    final AccountContactList data =
        await accountSearch(toWhomTextController.text);
    accountContactList.assignAll(data.contact ?? []);
    if (accountContactList.isNotEmpty) {
      //由於是絕對匹配所以先抓第一個人
      toUserInfo = accountContactList[0];
      toUserId.value = toUserInfo!.uid!;
      isShowMatchContact.value = true;
    } else {
      toUserId.value = 0;
      toUserInfo = null;
      isShowMatchContact.value = false;
    }
      if (accountContactList.isEmpty) {
      phoneErrorHint.value = localized(walletPhoneNotRegisterYet);
    } else {
      phoneErrorHint.value = "";
    }
  }

  void _setAmountError(String text) {
    exceedAmountTxt.value = text;
  }

  void _clearAmountError() {
    exceedAmountTxt.value = '';
  }

  //設置是否可以送出劃轉
  void setIsCanSend() {
    isCanSend.value = true;
    //String phone = toWhomTextController.text;
    double amount = double.tryParse(amountTextController.text) ?? 0;
    if (toUserId.value != 0 /*&&
        (phone.length >= minPhoneDigit)*/
        &&
        (amount > 0 && amount <= (currentWallet.value!.amount ?? 0))) {
      _clearAmountError();
      isCanSend.value = true;
    } else {
      if (amount > (currentWallet.value!.amount ?? 0)) {
        _setAmountError(localized(walletTransferExceedAvailBalance));
      } else {
        _clearAmountError();
      }
      isCanSend.value = false;
    }
  }

  //設定轉給誰的輸入框，並指定用戶
  void setToUserText(
    int userId,
    String nickName,
    String phoneCode,
    String phone, {
    String? userName,
  }) {
    toUserId.value = userId;
    if (userName != null && userName.isNotEmpty) {
      specificPhone = userName;
      toWhomTextController.text = "$nickName (${getHiddenStr(userName)})";
    } else {
      specificPhone = userId.toString();
      if (phone != "") {
        toWhomTextController.text = "$nickName ($phoneCode$phone)";
      } else {
        toWhomTextController.text = nickName;
      }
    }
  }

  //發送轉帳api
  Future<WalletTransferModel?> sendTransfer(
    BuildContext context,
    String password, {
    Map<String, String>? tokenMap,
  }) async {
    int toUserId = this.toUserId.value;
    String amount = amountTextController.text;
    String remark = memoTextController.text;
    WalletTransferModel? data;
    isLoading.value = true;
    ResponseData res = await walletServices.walletTransfer(
      toUserId,
      amount,
      currentWallet.value!.currencyType!,
      password,
      remark,
      tokenMap: tokenMap,
    );
    if (res.success()) {
      data = WalletTransferModel.fromJson(res.data);
      if (Get.isRegistered<WalletController>()) {
        Get.find<WalletController>().initWallet();
      }
    } else {
      isPasscodeIncorrect.value = true;
      if (res.code == ErrorCodeConstant.STATUS_MAX_TRY_PASSWORD_WRONG) {
        pinCodeController.clear();
        passwordCount.value = 5;
        otpFocus.canRequestFocus = false;
      } else if (res.code == ErrorCodeConstant.STATUS_PWD_INCORRECT) {
        showWarningToast(localized(incorrectPassword));
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
        showWarningToast(res.message);
        pinCodeController.clear();
      }
      data = null;
    }
    isLoading.value = false;
    return data;
  }

  //轉帳成功後取得交易詳情
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
      showWarningToast(
        res.message,
      );
      data = null;
    }
    return data;
  }

  //輸入匡刪除內容按鈕
  // void setShowAmountClearBtn(bool showBtn) {
  //   showBtn
  //       ? showAmountClearBtn.value = true
  //       : showAmountClearBtn.value = false;
  // }

  ///聯繫人底部彈窗相關
  final isSearching = false.obs;
  List<User> friendList = [];
  RxList<AZItem> azFriendList = <AZItem>[].obs;
  final TextEditingController searchController = TextEditingController();
  final searchParam = ''.obs;
  final _debouncer = Debounce(const Duration(milliseconds: 400));
  final FocusNode searchFocus = FocusNode();

  void getFriendList() {
    friendList = objectMgr.userMgr.friendWithoutBlacklist;
    updateAZFriendList();
  }

  void updateAZFriendList() {
    azFriendList.value = friendList
        .where((element) => element.deletedAt == 0)
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(azFriendList);
    azFriendList.refresh();
  }

  void search() {
    if (searchParam.value.isNotEmpty) {
      friendList = objectMgr.userMgr.friendWithoutBlacklist
          .where(
            (element) => objectMgr.userMgr
                .getUserTitle(element)
                .toLowerCase()
                .contains(searchParam.toLowerCase()),
          )
          .toList();
    } else {
      friendList = objectMgr.userMgr.friendWithoutBlacklist;
    }

    updateAZFriendList();
  }

  void clearSearching() {
    isSearching.value = false;
    if (!isSearching.value) {
      searchController.clear();
      searchParam.value = '';
    }
    search();
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => search());
  }

  //隱藏用戶名中間部分
  String getHiddenStr(String name) {
    if (name.length <= 4) {
      return name;
    } else {
      String str = "";
      String begin = name.substring(0, 2);
      String end = name.substring(name.length - 2, name.length);
      str = begin;
      for (int i = 0; i < name.length - 4; i++) {
        str += '*';
      }
      str += end;
      return str;
    }
  }

  Future<void> handeData(context, password) async {
    WalletTransferModel? data = await sendTransfer(context, password);
    if (data != null) {
      if (data.emailVcodeSend != null || data.phoneVcodeSend != null) {
        Map<String, String> tokenMap = await goSecondVerification(
          emailAuth: data.emailVcodeSend ?? false,
          phoneAuth: data.phoneVcodeSend ?? false,
        );
        if (tokenMap.isNotEmpty) {
          await handleResult(tokenMap, context, password, false);
        }
      } else {
        Navigator.pop(context); //關閉密碼彈窗
        showSuccessToast(
          localized(transferSuccess),
        );
        //導到交易詳情頁面
        common.WalletRecordTradeItem? recordData =
            await getRecordData(context, data.txID!);
        Get.back();
        common.sharedDataManager
            .gotoWalletRecordDetailPage(context, recordData);
      }
    }
  }

  handleResult(tokenMap, context, password, bool isPhoneAuth) async {
    WalletTransferModel? data =
        await sendTransfer(context, password, tokenMap: tokenMap);

    // Navigator.pop(context); //關閉密碼彈窗
    if (data != null) {
      Navigator.pop(context); //關閉密碼彈窗
      Navigator.pop(context);
      showSuccessToast(
        localized(transferSuccess),
      );
      //導到交易詳情頁面
      common.WalletRecordTradeItem? recordData =
          await getRecordData(context, data.txID!);
      Get.back();
      common.sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
    }
  }

  Future<void> onPressed(BuildContext context) async {
    //先關閉鍵盤
    FocusScope.of(context).unfocus();
    // if (toUserId.value == 0) {
    //   return;
    // }
    otpFocus = FocusNode();
    if (!otpFocus.hasFocus) {
      otpFocus.requestFocus();
    }
    pinCodeController = TextEditingController();
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
          step: 1,
          onCompleted: (
            password, {
            Function(String errorMsg)? showError,
            Function(bool isShow)? showDialog,
          }) async {
            handeData(context, password);
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
          amountText: amountTextController.text,
          currencyText: currentWallet.value?.currencyType ?? "usdt",
          title: localized(paymentPassword),
          buttonCancel: localized(buttonCancel),
          transferTypeValue: localized(transferMoney),
          transferTypeTitle: localized(walletPayType),
          myPaymentMethod: localized(myPaymentMethod),
          myPaymentMethodTip: localized(walletAvailableBalance),
          otpFocus: otpFocus,
          isAttemptWrong: isAttemptWrong,
        ),
      ),
    ).then((value) {
      isLoading.value = false;
    });
  }

  void onKeyboardNumberListener(String? value) {
    RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');
    String amountText = amountTextController.text;
    if (!pattern.hasMatch(amountTextController.text) &&
        amountTextController.text.isNotEmpty) {
      amountTextController.text = amountText.isNotEmpty
          ? amountText.substring(0, amountTextController.text.length - 1)
          : amountText;

      amountText = amountText.substring(0, amountText.length - 1);
    }
    if (amountTextController.text.indexOf("0") == 0 &&
        amountTextController.text.indexOf(".") != 1 &&
        amountTextController.text.length > 1) {
      amountTextController.text = amountText.substring(1);
      amountText = amountText.substring(1);
    }
    setIsCanSend();
  }

  getUserInfo(String? accountIdPass) async {
    if (accountIdPass == null) {
      return;
    }

    String userId = accountIdPass;
    try {
      User user = await getUser(userId: userId);
      String? nickName = user.nickname;
      String? phoneCode = user.countryCode;
      String? phone = user.contact;
      String? userName = user.username;

      setToUserText(
        user.uid,
        nickName,
        phoneCode,
        phone,
        userName: userName,
      );
    } catch (e) {
      String errorMessage = localized(unexpectedError);
      ImBottomToast(
        navigatorKey.currentContext!,
        title: errorMessage,
        icon: ImBottomNotifType.warning,
      );
    }
  }
}
