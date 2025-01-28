
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

import '../../../api/wallet_services.dart';
import '../../../object/wallet/currency_model.dart';

import '../../../utils/toast.dart';
import 'package:intl/intl.dart';

class MyAddressesController extends GetxController
    with GetSingleTickerProviderStateMixin {
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

    selectedChain.value =
        cryptoCurrencyList[tabController.index].supportNetType?.first;

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
            '暂不支持 ${cryptoCurrencyList[tabController.index].currencyName} 币种');
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

  void changePreselectedNetWork(String value){
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
    if (await Permission.storage.isGranted) {
      Toast.showToast("后台下载中 . . .");
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      await ImageGallerySaver.saveImage(bytes,
          quality: 100,
          name:
              'JX_Image_${selectedChain.value}_Address${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.png');
      Toast.showToast(localized(addressImageDownloaded));
    } else {
      await Permission.storage.request().isGranted;
    }
  }

  Future<void> getPaymentDescription() async {
    final res = await walletServices.postRechargeExplain();
    if (res.code == 0) {
      paymentDescription.value = res.data['content'];
    } else {
      paymentDescription.value = '';
    }
  }
}
