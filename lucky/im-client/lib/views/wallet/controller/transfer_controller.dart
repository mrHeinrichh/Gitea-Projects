import 'package:azlistview/azlistview.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/payment_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/account_contact.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/object/wallet/wallet_transfer_model.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';

import '../../../main.dart';
import '../../../object/azItem.dart';
import '../../../object/user.dart';
import '../../../utils/debounce.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/second_verification_utils.dart';
import '../../../utils/utility.dart';
import 'package:im_common/im_common.dart' as common;

class TransferController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final remainInputCount = 30.obs;

  FocusNode toWhomTextFocus = FocusNode();
  FocusNode memoTextFocus = FocusNode();
  FocusNode amountTextFocus = FocusNode();
  final toWhomTextController = TextEditingController();
  final memoTextController = TextEditingController();
  final amountTextController = TextEditingController();
  RxBool showToWhomTextClearBtn = false.obs;
  RxBool showAmountClearBtn = false.obs;

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
  TransferController (this.isFromScanQRCode);

  //是否顯示用戶匹配列表
  RxBool isShowMatchContact = RxBool(false);

  //前一頁傳入的貨幣種類
  String _initCurrencyType = "CNY";
  String get initCurrencyType => _initCurrencyType;
  set initCurrencyType(String type) {
    _initCurrencyType = type;
  }

  @override
  void onInit() {
    super.onInit();
    initData();

    // 監聽 memoTextController 的文本變化
    memoTextController.addListener(() {
      final remainingChars = 30 - memoTextController.text.length;
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
      if (specificPhone == "" && userInputPhone != "" && (userInputPhone.length < minPhoneDigit)) {
        phoneErrorHint.value = "请输入合法的手机号";
      } else {
        phoneErrorHint.value = "";
      }
      //當用戶輸入超過一定位數就呼叫查找用戶api
      if (specificPhone == "" && userInputPhone.length >= minPhoneDigit) {
        searchContactList();
      }
      // if (userInputPhone.length < minPhoneDigit) {
      //   toUserInfo = null;
      //   toUserId.value = 0;
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
    super.onClose();
  }

  void _onToWhomFocusChange() {
    if (toUserInfo != null && !toWhomTextFocus.hasFocus) {
      //當失去焦點的時候點檢查有無指定用戶
      setToUserText(toUserInfo!.uid!, toUserInfo!.nickname!, toUserInfo!.countryCode!, toUserInfo!.contact!);
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
  initData () async {
    final WalletAssetsModel? data = await walletServices.getUserAssets(isShowBox: true);
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
            (element) => currentWallet.value?.currencyType == element.currencyType);
  }

  void selectedCurrencyIndexHandler(index) {
    selectedCurrencyIndex.value = index;
  }

  void remainInputCountHandler(value) {
    remainInputCount.value = value;
  }

  //根據用戶輸入的電話號碼自動搜尋匹配
  searchContactList () async {
    accountContactList.clear();
    final AccountContactList? data = await accountSearch(toWhomTextController.text);
    if (data != null) {
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
    }
    if (accountContactList.isEmpty) {
      phoneErrorHint.value = "该手机号未注册账号";
    } else {
      phoneErrorHint.value = "";
    }
  }

  //設置是否可以送出劃轉
  void setIsCanSend() {
    double amount = double.tryParse(amountTextController.text) ?? 0;
    if (toUserId.value != 0 && (amount > 0
        && amount <= (currentWallet.value!.amount ?? 0))) {
      isCanSend.value = true;
    } else {
      isCanSend.value = false;
    }
  }

  //設定轉給誰的輸入框，並指定用戶
  void setToUserText(int userId, String nickName, String phoneCode, String phone, {String? userName}) {
    toUserId.value = userId;
    if (userName != null && userName.length > 0) {
      specificPhone = userName;
      toWhomTextController.text = "${nickName} (${getHiddenStr(userName)})";
    } else {
      specificPhone = userId.toString();
      if (phone != "") {
        toWhomTextController.text = "${nickName} (${phoneCode}${phone})";
      } else {
        toWhomTextController.text = "${nickName}";
      }
    }
  }

  //發送轉帳api
  Future<WalletTransferModel?> sendTransfer(BuildContext context, String password,{
    Map<String,String>? tokenMap,
  }) async {
    int toUserId = this.toUserId.value;
    String amount = amountTextController.text;
    String remark = memoTextController.text;
    WalletTransferModel? data;
    ResponseData res = await walletServices.walletTransfer(
        toUserId,
        amount,
        currentWallet.value!.currencyType!,
        password,
        remark,
       tokenMap:tokenMap
    );
    if (res.success()) {
      data = WalletTransferModel.fromJson(res.data);
      if (Get.isRegistered<WalletController>()) {
        Get.find<WalletController>().initWallet();
      }
    } else {
      showWarningToast(res.message,);
      data = null;
    }
    return data;
  }

  //轉帳成功後取得交易詳情
  Future<common.WalletRecordTradeItem?> getRecordData(BuildContext context, String txID) async {
    common.WalletRecordTradeItem? data;
    ResponseData res = await paymentServices.getRecordData(
      txID: txID,
    );
    if (res.success()) {
      data = common.WalletRecordTradeItem.fromJson(res.data);
    } else {
      showWarningToast(res.message,);
      data = null;
    }
    return data;
  }

  //輸入匡刪除內容按鈕
  void setShowClearBtn(bool showBtn) {
    showBtn ? showToWhomTextClearBtn.value = true : showToWhomTextClearBtn.value = false;
  }

  //輸入匡刪除內容按鈕
  void setShowAmountClearBtn(bool showBtn) {
    showBtn ? showAmountClearBtn.value = true : showAmountClearBtn.value = false;
  }


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
          .where((element) => objectMgr.userMgr
          .getUserTitle(element)
          .toLowerCase()
          .contains(searchParam.toLowerCase()))
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
    WalletTransferModel? data =
        await sendTransfer(
        context, password);
    if (data != null) {
      if (data.emailVcodeSend!=null ||data.phoneVcodeSend!=null){
        Map<String,String> tokenMap=  await  goSecondVerification(emailAuth: data.emailVcodeSend??false,phoneAuth:  data.phoneVcodeSend??false);
        if(tokenMap.isNotEmpty){
          await handleResult(tokenMap,context,password,false);
        }
      }else{
        Navigator.pop(context); //關閉密碼彈窗
        if (data != null) {
          showSuccessToast(localized(transferSuccess),);
          //導到交易詳情頁面
          common.WalletRecordTradeItem? recordData =
          await getRecordData(context, data.txID!);
          Get.back();
          common.sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
        }
      }
    }
  }

  handleResult(tokenMap, context, password, bool isPhoneAuth) async {
    WalletTransferModel? data =
        await sendTransfer(
        context, password,tokenMap:tokenMap);

    Navigator.pop(context); //關閉密碼彈窗
    if (data != null) {
      Navigator.pop(context);
      showSuccessToast(localized(transferSuccess),);
      //導到交易詳情頁面
      common.WalletRecordTradeItem? recordData =
          await getRecordData(context, data.txID!);
      Get.back();
      common.sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
    }
  }
}
