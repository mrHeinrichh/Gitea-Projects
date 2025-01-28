import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page_argument.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import '../../../../utils/get_utils.dart';

class WalletAddressEditController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final WalletController _walletController = Get.find<WalletController>();

  final addressController = TextEditingController();
  final addressNameController = TextEditingController();

  WalletAddressArguments? data;

  late final bool isEditMode;

  bool _isValidateAddress = false;

  RxBool isButtonEnabled = false.obs;

  String get address => addressController.text;

  String get addressName => addressNameController.text;

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  final selectedChain = 'TRC20'.obs;
  final preselectedChain = 'TRC20'.obs;

  final isShowEmptyAddressError = false.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;
    if (arguments != null) {
      data = WalletAddressArguments.fromJson(arguments);
      addressController.text = data!.address;
      addressNameController.text = data!.addrName;
    }

    _initSelectChain();

    isEditMode = data != null;
    isButtonEnabled.value = isEditMode;
  }

  void _initSelectChain() {
    final controller = Get.find<WithdrawController>();
    final withdrawModel = controller.withdrawModel;
    final withDrawSelectChain = withdrawModel.selectedCurrency!.netType!;
    selectedChain.value = withDrawSelectChain;
    preselectedChain.value = withDrawSelectChain;
  }

  void changeNetwork(String value) {
    selectedChain.value = value;
    _validateAddress();
    update();
  }

  void changePreselectedNetWork(String value) {
    preselectedChain.value = value;
  }

  void onAddressChanged(String value) {
    addressController.text = value;
    if (value.isNotEmpty) {
      _validateAddress();
    }
  }

  void onAddressNameChanged(String value) {
    addressNameController.text = value;
    _checkButtonEnabled();

  }

  void _checkButtonEnabled() async {
    if (isEditMode) {
      isButtonEnabled.value = addressName.isNotEmpty;
    } else {
      isButtonEnabled.value = _isValidateAddress && addressName.isNotEmpty;
    }
  }

  Future<bool> validateAddress() async {
    try {
      final ret = await walletServices.validateAddress(
        address: addressController.text,
        netType: selectedChain.value,
      ).then((value) => value['isValid'] as bool);
      return ret;
    } catch (e) {
      return false;
    }
  }

  Future<void> _validateAddress() async {
    final isValid = await validateAddress();

    _isValidateAddress = isValid;
    _checkButtonEnabled();
  }

  void onSave() {
    walletServices
        .editRecipientAddress(
      addrID: data!.addrID,
      addrName: addressName,
    )
        .then(
      (value) {
        if (value) {
          Get.find<RecipientAddressBookController>()
              .getRecipientAddressList(currencyType: 'USDT');
          Get.back();
          showSuccessToast('保存成功');
        } else {
          showErrorToast('保存失败');
        }
      },
    );
  }

  Future<void> onAdd() async {
    final res = await walletServices.addRecipientAddress(
      currencyType: 'USDT',
      netType: selectedChain.value,
      addrName: addressName,
      address: address,
    );

    if (res.success()) {
      if (res.needTwoFactorAuthPhone || res.needTwoFactorAuthEmail) {
        Map<String, String> tokenMap = await goSecondVerification(
            emailAuth: res.needTwoFactorAuthEmail,
            phoneAuth: res.needTwoFactorAuthPhone);
        final resAgain = await walletServices.addRecipientAddress(
          tokenMap: tokenMap,
          currencyType: 'USDT',
          netType: selectedChain.value,
          addrName: addressName,
          address: address,
        );
        if (resAgain.success()) {
          Get.find<RecipientAddressBookController>()
              .getRecipientAddressList(currencyType: 'USDT');
          Get.back();
          showSuccessToast('添加成功');
          getFindOrNull<WithdrawController>()?.getUSDTAddressList();
        } else {
          showErrorToast(resAgain.message.toString());
        }
      } else {
        showErrorToast('添加失败');
      }
    } else {
      Get.back();
      showErrorToast('添加失败');
    }
  }
}
