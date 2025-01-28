import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';

import 'package:jxim_client/utils/toast.dart';
import 'package:intl/intl.dart';

class MyAddressesController extends GetxController
    with GetTickerProviderStateMixin {
  final WalletController _walletController = Get.find<WalletController>();
  final WalletServices walletServices = WalletServices();

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  late TabController tabController;

  final selectedChain = ''.obs;
  final preselectedChain = ''.obs;

  final erc20Address = "".obs;
  final trc20Address = "".obs;
  final paymentDescription = ''.obs;

  TextEditingController addressNameController = TextEditingController();
  final isShowEmptyAddressError = false.obs;

  @override
  void onInit() {
    super.onInit();
    getPaymentDescription();
    tabController =
        TabController(vsync: this, length: cryptoCurrencyList.length);

    tabController.addListener(tabListener);

    selectedChain.value = cryptoCurrencyList.isNotEmpty
        ? cryptoCurrencyList[tabController.index].supportNetType?.first
        : 'TRC20';

    getMyAddressList(netType: selectedChain.value);
    getMyAddressList(netType: 'ERC20');
  }

  void tabListener() {
    if (tabController.indexIsChanging) {
      if (cryptoCurrencyList[tabController.index].enableFlag) {
        selectedChain.value =
            cryptoCurrencyList[tabController.index].supportNetType?.first;
        getMyAddressList(
          netType: selectedChain.value,
        );
      } else {
        Toast.showToast(
          '暂不支持 ${cryptoCurrencyList[tabController.index].currencyName} 币种',
        );
        tabController.index = tabController.previousIndex;
      }
    }
  }

  void getMyAddressList({String? currencyType, String? netType}) async {
    final data = await walletServices.getCryptoAddress(netType: netType);
    if (netType == "ERC20") {
      erc20Address.value = data.first.address;
    } else {
      trc20Address.value = data.first.address;
    }
  }

  void changeNetwork(String value) {
    selectedChain.value = value;
    getMyAddressList(
      netType: selectedChain.value,
    );
    update();
  }

  void changePreselectedNetWork(String value) {
    preselectedChain.value = value;
  }

  String getAddress() {
    if (selectedChain.value == "ERC20") {
      return erc20Address.value;
    } else {
      return trc20Address.value;
    }
  }

  void downloadQR(Widget widget, BuildContext context) async {
    await saveImageWidgetToGallery(
        imageWidget: widget,
        imgName:
            'JX_Image_${selectedChain.value}_Address${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.png',
        afterSaveCallBack: () =>
            Toast.showToast(localized(addressImageDownloaded)));
  }

  Future<void> getPaymentDescription() async {
    final result = await walletServices.getReceiveAndPayExpalinData();
    String fee = '1.00USDT';
    if (result.success()) {
      String feeValue = result.data['withdrawalFee'] ?? "1.00";
      fee = "${feeValue}USDT";
    }
    paymentDescription.value =
        "${localized(paymentStaticDescriptionPart1)}\n${localized(paymentStaticDescriptionPart2)} $fee。";
    update();
  }
}
