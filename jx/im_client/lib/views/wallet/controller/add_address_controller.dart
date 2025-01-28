import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

class AddAddressController extends GetxController {
  final WalletController _walletController = Get.find<WalletController>();
  final WalletServices walletServices = WalletServices();

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  bool isEdit = false;
  AddressModel? addressModel;

  Rx<CurrencyModel> selectedCurrencyModel = CurrencyModel().obs;
  RxString selectedChain = ''.obs;

  final TextEditingController addressNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  Rx<bool> canAdd = false.obs;
  Rx<int> nameTextLength = 0.obs;
  Rx<int> addressTextLength = 0.obs;

  final nameWordCount = 30.obs;

  @override
  void onInit() {
    super.onInit();
    // selectedCurrencyModel.value = cryptoCurrencyList.first;
    // selectedChain.value = selectedCurrencyModel.value.supportNetType?.first;

    addressNameController.addListener(() {
      nameTextLength.value = addressNameController.text.length;
      getCanAdd();
    });

    addressController.addListener(() {
      addressTextLength.value = addressController.text.length;
      getCanAdd();
    });

    final args = Get.arguments;
    if (args != null && args.isNotEmpty) {
      if (args.containsKey('edit')) {
        isEdit = true;
        addressModel = args['address'];
        addressController.text = addressModel!.address;
        addressNameController.text = addressModel!.addrName;
        selectedCurrencyModel.value = cryptoCurrencyList.firstWhereOrNull(
              (element) => addressModel!.currencyType == element.currencyType,
            ) ??
            cryptoCurrencyList.first;
        selectedChain.value = addressModel!.netType;
      }

      if (args.containsKey('crypto')) {
        selectedCurrencyModel.value = args['crypto'];
      }
      if (args.containsKey('chain')) {
        selectedChain.value = args['chain'];
      }
    }
  }

  Future<void> selectChain(String value) async {
    selectedChain.value = value;
  }

  bool get canExit {
    if (addressModel != null) {
      return addressNameController.text == addressModel!.addrName &&
          addressController.text == addressModel!.address &&
          selectedChain.value == addressModel!.netType &&
          selectedCurrencyModel.value.currencyType ==
              addressModel!.currencyType;
    }

    return addressNameController.text.isEmpty && addressController.text.isEmpty;
  }

  Future<void> getCanAdd() async {
    final validate = await validateAddress();
    canAdd.value = addressNameController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        validate;
  }

  void showLeavePrompt(BuildContext context) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(areYouSureYouWantToDiscard),
      confirmText: localized(discardButton),
      onConfirmListener: () => Get.back(),
    );
  }

  selectNewCurrencyModel(CurrencyModel model) {
    selectedCurrencyModel.value = model;
    selectedChain.value = selectedCurrencyModel.value.supportNetType?.first;
  }

  Future<bool> validateAddress() async {
    try {
      await walletServices.validateAddress(
        address: addressController.text,
        netType: selectedChain.value,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void addRecipient() async {
    final result = await walletServices.addRecipientAddress(
      currencyType: selectedCurrencyModel.value.currencyType!,
      netType: selectedChain.value,
      addrName: addressNameController.text,
      address: addressController.text,
    );

    Get.back(result: result);
  }

  void editRecipientAddress() async {
    final result = await walletServices.editRecipientAddress(
      addrID: addressModel!.addrID,
      addrName: addressNameController.text,
    );

    if (result) {
      addressModel!.addrName = addressNameController.text;
      Toast.showToast(localized(editSuccess));
      Get.back(result: addressModel);
    } else {
      Toast.showToast(localized(editFailed));
      Get.back(result: addressModel);
    }
  }

  void getNameWordCount() {
    int count = 0;
    if (addressNameController.text.isNotEmpty) {
      for (int i = 0; i < addressNameController.text.length; i++) {
        if (addressNameController.text[i].isChineseCharacter) {
          count += 2;
        } else {
          count += 1;
        }
      }
    }
    nameWordCount.value = 30 - count;
  }
}
