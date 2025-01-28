import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/payment/bobi_asset_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/views/wallet/controller/transaction_controller.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';

import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:intl/intl.dart';

class WalletController extends GetxController with GetTickerProviderStateMixin {
  final WalletServices walletServices = WalletServices();
  CurrencyModel selectedCurrency = CurrencyModel();

  late final TabController walletHomeTabController;
  late TabController tabController;

  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();

  double walletBalance = 0.00;
  String walletBalanceCurrencyType = 'USD';

  // List<CurrencyModel> legalCurrencyList = <CurrencyModel>[];

  List<CurrencyModel> _cryptoCurrencyList = <CurrencyModel>[];
  List<CurrencyModel> get cryptoCurrencyList {
    var finalList = _cryptoCurrencyList.map((e) {
      // 需求要求 trc20 的协议在前面
      List<dynamic>? temp = [];
      for (var element in (e.supportNetType ?? [])) {
        if (element == 'TRC20') {
          temp.insert(0, element);
        } else {
          temp.add(element);
        }
      }
      e.supportNetType = temp;
      return e;
    }).toList();
    return finalList;
  }

  DateTime updateTime = DateTime.now();

  CurrencyModel selectedTabCurrency = CurrencyModel();
  CurrencyModel? legalAvailCurrency; //法幣用戶可用金額
  CurrencyModel? legalBoxCurrency; //法幣保險櫃金額
  CurrencyModel? cryptoAvailCurrency; //虛擬幣用戶可用金額
  CurrencyModel? cryptoBoxCurrency; //虛擬幣保險櫃金額
  double totalCryptoMoney = 0; //總共虛擬幣金額
  // double totalLegalMoney = 0;    //總共法幣金額

  BobiAssetModel? bobiAssetModel;

  final isShowValue = true.obs;

  Timer? _debounce;

  final Connectivity _connectivity = Connectivity();

  @override
  Future<void> onInit() async {
    super.onInit();
    walletHomeTabController = TabController(length: 1, vsync: this);
    await initWallet();
    tabController =
        TabController(vsync: this, length: cryptoCurrencyList.length);
    tabController.addListener(tabBarListener);
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    final result = objectMgr.localStorageMgr.read(LocalStorageMgr.HIDE_VALUE);
    if (result != null) {
      isShowValue.value = result;
    }
  }

  @override
  void onClose() {
    walletHomeTabController.dispose();
    super.onClose();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      initWallet();
    }
  }

  Future<void> initWallet() async {
    if (!serversUriMgr.isKiWiConnected) {
      final data = await objectMgr.localStorageMgr.read(LocalStorageMgr.WALLET);
      final result = WalletAssetsModel.fromJson(json.decode(data));
      walletBalance = result.totalAmt!;
      walletBalanceCurrencyType = result.totalAmtCurrencyType!;
      // legalCurrencyList = result.legalCurrencyInfo!;
      _cryptoCurrencyList = result.cryptoCurrencyInfo!;
      updateTime = result.updateTime!;
    } else {
      final WalletAssetsModel? data =
          await walletServices.getUserAssets(currency: "USD", isShowBox: true);

      if (data != null) {
        walletBalance = data.totalAmt!;
        walletBalanceCurrencyType = data.totalAmtCurrencyType!;
        // legalCurrencyList = data.legalCurrencyInfo!;
        _cryptoCurrencyList = data.cryptoCurrencyInfo!;
        updateTime = data.updateTime!;
      }
    }

    // legalCurrencyList.forEach((element) {
    //   if (element.assetType == WalletTypeAPI.USER_AVAIL.name) {
    //     legalAvailCurrency = element;
    //   } else if (element.assetType == WalletTypeAPI.USER_BOX.name) {
    //     legalBoxCurrency = element;
    //   }
    // });
    for (var element in cryptoCurrencyList) {
      if (element.assetType == WalletTypeAPI.USER_AVAIL.name) {
        cryptoAvailCurrency = element;
      } else if (element.assetType == WalletTypeAPI.USER_BOX.name) {
        cryptoBoxCurrency = element;
      }
    }
    calculateTotalAmount();

    update();
  }

  //計算法幣跟虛擬幣的總金額
  calculateTotalAmount() {
    totalCryptoMoney = 0;
    // totalLegalMoney = 0;
    for (var element in cryptoCurrencyList) {
      totalCryptoMoney = NumUtils.add(totalCryptoMoney, element.amount ?? 0);
    }
    // legalCurrencyList.forEach((element) {
    //   totalLegalMoney = NumUtils.add(totalLegalMoney, element.amount ?? 0);
    // });
  }

  String getUpdateTime() {
    return '${localized(walletLastUpdateOn)} ${DateFormat('yyyy-MM-dd HH:mm:00').format(updateTime)}';
  }

  String getSpecificUpdateTime(int timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:00')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Future<void> navigateCryptoDetails(int index) async {
    tabController.index = index;
    selectedTabCurrency = cryptoCurrencyList[index];
    selectedTabCurrency.netType =
        cryptoCurrencyList[index].supportNetType!.first;
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    Get.toNamed(RouteName.cryptoView);
  }

  Future<void> navigateMyAddress() async {
    selectedTabCurrency = cryptoCurrencyList[tabController.index];
    selectedTabCurrency.netType = selectedTabCurrency.supportNetType!.first;

    Get.toNamed(RouteName.myAddressView);
  }

  Future<void> tabBarListener() async {
    if (tabController.indexIsChanging) {
      pdebug(tabController.index);
      if (cryptoCurrencyList[tabController.index].enableFlag) {
        selectedTabCurrency = cryptoCurrencyList[tabController.index];
        selectedTabCurrency.netType =
            cryptoCurrencyList[tabController.index].supportNetType!.first;
        final TransactionController transactionController =
            Get.find<TransactionController>();
        if (transactionController.selectedCurrencyType !=
            selectedTabCurrency.currencyType) {
          transactionController.allTransactionList.clear();
          transactionController.formattedTransactionMap.clear();
          transactionController.page = 0;
          transactionController.selectedCurrencyType =
              selectedTabCurrency.currencyType!;
          transactionController.loadMoreData();
        }
      } else {
        Toast.showToast(
          '暂不支持 ${cryptoCurrencyList[tabController.index].currencyName} 币种',
        );
        tabController.index = tabController.previousIndex;
      }

      update();
    }
  }

  void navigateToTransactionHistory() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Get.toNamed(RouteName.transactionHistoryView);
      sharedDataManager.gotoWalletHistoryPage(navigatorKey.currentContext!);
    });
  }
}
