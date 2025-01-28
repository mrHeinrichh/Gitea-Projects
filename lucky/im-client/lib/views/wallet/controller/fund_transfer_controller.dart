import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/payment_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/payment/bobi_asset_model.dart';
import 'package:jxim_client/object/payment/bobi_recharge_model.dart';
import 'package:jxim_client/object/payment/fund_transfer_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';
import 'package:im_common/im_common.dart' as common;

class FundTransferController extends GetxController
    with GetSingleTickerProviderStateMixin {

  final textController = TextEditingController();
  List<CurrencyModel> _legalCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> _cryptoCurrencyList = <CurrencyModel>[];

  //所有錢包
  RxList<CurrencyModel> totalWalletList = RxList<CurrencyModel>();

  //所有錢包幣種
  RxList<CurrencyModel> totalWalletTypeList = RxList<CurrencyModel>();

  //當前選擇的錢包
  Rxn<CurrencyModel> currentWallet = Rxn<CurrencyModel>();

  //所有可用的錢包轉入轉出類型
  List<WalletTransferType> walletTransferTypeList = List.from(WalletConfig.getWalletTransferList());

  //從哪個錢包類型轉出
  Rxn<WalletTransferType> fromWalletTransferType = Rxn<WalletTransferType>(WalletTransferType.transferRemain);

  //轉入哪個錢包類型
  Rxn<WalletTransferType> toWalletTransferType = Rxn<WalletTransferType>(WalletTransferType.transferSafe);

  //當前選擇的錢包或是轉入轉出類型index
  RxInt selectedIndex = RxInt(0);

  //是否可以送出劃轉(打api)
  RxBool isCanSend = RxBool(false);

  //前一頁傳入的貨幣種類
  String _initCurrencyType = "CNY";
  String get initCurrencyType => _initCurrencyType;
  set initCurrencyType(String type) {
    _initCurrencyType = type;
  }

  Widget? rechargeBobiView;

  FundTransferController(this._initCurrencyType);

  @override
  void onInit() {
    super.onInit();
    walletTransferTypeList = List.from(WalletConfig.getWalletTransferList(type: _initCurrencyType));
    initData();
    textController.addListener(() {
      setIsCanSend();
    });
  }

  @override
  void onClose() {
    super.onClose();
    rechargeBobiView = null;
  }

  //取得初始化資料
  initData () async {
    final WalletAssetsModel? data = await walletServices.getUserAssets(isShowBox: true);
    CurrencyModel bobiCurrencyModel = await getBobiAmount();
    if (data != null) {
      _legalCurrencyList = data.legalCurrencyInfo!;
      _cryptoCurrencyList = data.cryptoCurrencyInfo!;
      totalWalletList.assignAll(_legalCurrencyList..addAll(_cryptoCurrencyList)..add(bobiCurrencyModel));
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
    walletTransferTypeList = List.from(WalletConfig.getWalletTransferList(type: wallet.currencyType!));
    if (wallet.currencyType == "USDT" &&
        (fromWalletTransferType.value?.code == WalletConfig.bobiTransferCode ||
        toWalletTransferType.value?.code == WalletConfig.bobiTransferCode)) {
      //如果原本有選擇波幣的轉入或轉出則一律還原
      fromWalletTransferType.value = WalletTransferType.transferRemain;
      toWalletTransferType.value = WalletTransferType.transferSafe;
    }
    for (var element in totalWalletList) {
      if (wallet.currencyType == element.currencyType &&
          ((fromWalletTransferType.value?.code == WalletConfig.remainTransferCode
              && element.assetType == WalletTypeAPI.USER_AVAIL.name) ||
          (fromWalletTransferType.value?.code == WalletConfig.safeTransferCode
              && element.assetType == WalletTypeAPI.USER_BOX.name) ||
          (fromWalletTransferType.value?.code == WalletConfig.bobiTransferCode
              && element.assetType == "bobi"))) {
        currentWallet.value = element;
        break;
      }
    }
    setIsCanSend();
  }

  //取得當前選擇的錢包index
  int getCurrentWalletIndex() {
    return totalWalletTypeList.indexWhere(
            (element) => currentWallet.value?.currencyType == element.currencyType);
  }

  //取得當前選擇的轉出類型index
  int getCurrentFromTransferIndex() {
    return walletTransferTypeList.indexWhere(
            (element) => fromWalletTransferType.value?.code == element.code);
  }

  //取得當前選擇的轉入類型index
  int getCurrentToTransferIndex() {
    return walletTransferTypeList.indexWhere(
            (element) => toWalletTransferType.value?.code == element.code);
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
  void setIsCanSend() {
    double amount = double.tryParse(textController.text) ?? 0;
    if (amount > 0 && amount <= (currentWallet.value!.amount ?? 0)) {
      isCanSend.value = true;
    } else {
      isCanSend.value = false;
    }
  }

  //發送劃轉api
  Future<FundTransferModel?> sendTransfer(BuildContext context, String orderType, String password) async {
    String amount = textController.text;
    FundTransferModel? data;
    ResponseData res = await paymentServices.fundTransfer(
        amount: amount,
        currencyType: currentWallet.value!.currencyType!,
        orderType: orderType,
        password: password
    );
    if (res.success()) {
      data = FundTransferModel.fromJson(res.data);
    } else {
      ImBottomToast(context,
          title: res.message,
          icon: ImBottomNotifType.warning);
      data = null;
    }
    return data;
  }

  //劃轉成功後取得交易詳情
  Future<common.WalletRecordTradeItem?> getRecordData(BuildContext context, String txID) async {
    common.WalletRecordTradeItem? data;
    ResponseData res = await paymentServices.getRecordData(
      txID: txID,
    );
    if (res.success()) {
      data = common.WalletRecordTradeItem.fromJson(res.data);
    } else {
      ImBottomToast(context,
          title: res.message,
          icon: ImBottomNotifType.warning);
      data = null;
    }
    return data;
  }

  //根據用戶選取的轉入轉出類型取得api所需的order type
  String getOrderType() {
    String fromCode = fromWalletTransferType.value!.code;
    String toCode = toWalletTransferType.value!.code;
    String orderType = WalletTransferTypeAPI.BOB_WITHDRAW.name;   //預設用戶餘額轉到波幣
    if (fromCode == WalletConfig.safeTransferCode && toCode == WalletConfig.bobiTransferCode) {
      //保險櫃轉到波幣
      orderType = WalletTransferTypeAPI.BOB_WITHDRAW_FROM_USER_BOX.name;
    } else if (fromCode == WalletConfig.remainTransferCode && toCode == WalletConfig.safeTransferCode) {
      //用戶餘額轉到保險櫃
      orderType = WalletTransferTypeAPI.USER_AVAIL_TO_BOX.name;
    } else if (fromCode == WalletConfig.safeTransferCode && toCode == WalletConfig.remainTransferCode) {
      //保險櫃轉到用戶餘額
      orderType = WalletTransferTypeAPI.USER_BOX_TO_AVAIL.name;
    } else if (fromCode == WalletConfig.bobiTransferCode && toCode == WalletConfig.remainTransferCode) {
      //波幣轉到用戶餘額
      orderType = WalletTransferTypeAPI.BOB_RECHARGE.name;
    } else if (fromCode == WalletConfig.bobiTransferCode && toCode == WalletConfig.safeTransferCode) {
      //波幣轉到保險櫃
      orderType = WalletTransferTypeAPI.BOB_RECHARGE_TO_USER_BOX.name;
    }
    return orderType;
  }

  //發送從波幣充值api
  Future<BobiRechargeModel?> sendBobiRecharge(BuildContext context, String orderType) async {
    String amount = textController.text;
    BobiRechargeModel? data;
    ResponseData res = await paymentServices.bobiRecharge(
      amount: amount,
      orderType: orderType,
    );
    if (res.success()) {
      data = BobiRechargeModel.fromJson(res.data);
    } else {
      ImBottomToast(context,
          title: res.message,
          icon: ImBottomNotifType.warning);
      data = null;
    }
    return data;
  }

  //取得波幣餘額
  Future<CurrencyModel> getBobiAmount() async {
    CurrencyModel currencyModel = CurrencyModel();
    if (Config().isGameEnv) {
      final BobiAssetModel? data = await paymentServices.bobiGetAsset();

      if (data != null) {
        currencyModel.amount = double.tryParse(data.amount!) ?? 0;
        currencyModel.currencyType = "CNY";
        currencyModel.currencyName = "人民币";
        currencyModel.assetType = "bobi";
      }
      update();
    }
    return currencyModel;
  }
}
