import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page_argument.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import 'package:jxim_client/utils/get_utils.dart';

class WalletAddressEditController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final WalletController _walletController = Get.find<WalletController>();

  final addressController = TextEditingController();
  final addressNameController = TextEditingController();
  final addressLabelController = TextEditingController();

  WalletAddressArguments? data;

  late final bool isEditMode;

  var isValidateAddress = true.obs;
  var isOwnAddress = false.obs;
  var isInternalAddress = false.obs;

  RxBool isButtonEnabled = false.obs;

  String get address => addressController.text;

  String get addressName => addressNameController.text;
  String addrName = '';

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  final selectedChain = 'TRC20'.obs;
  final preselectedChain = 'TRC20'.obs;

  final isShowEmptyAddressError = false.obs;
  final labelWordCount = 30.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;
    if (arguments != null) {
      data = WalletAddressArguments.fromJson(arguments);
      addressController.text = data!.address;
      addrName = data!.addrName;
      addressNameController.text = addrName;
    }

    _initSelectChain();

    isEditMode = data != null;
  }

  void _initSelectChain() {
    final controller = Get.find<WithdrawController>();
    final withDrawSelectChain = controller.netType();
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
    _validateAddress();
  }

  void onClearAddress() {
    addressController.clear();
    isValidateAddress.value = true;
    update();
  }

  void onAddressNameChanged(String value) {
    addressNameController.text = value;
    _checkButtonEnabled();
  }

  void getCommentWordCount() {
    int count = 0;
    if (addressNameController.text.isNotEmpty) {
      for (int i = 0; i < addressNameController.text.runes.length; i++) {
        if (addressNameController.text[i].isChineseCharacter) {
          count += 2;
        } else {
          count += 1;
        }
      }
    }
    labelWordCount.value = 30 - count;
  }

  void _checkButtonEnabled() async {
    if (isEditMode) {
      isButtonEnabled.value = addressName.isNotEmpty && addrName != addressName;
    } else {
      isButtonEnabled.value = isValidateAddress.value && addressName.isNotEmpty;
    }
  }

  Future<void> _validateAddress() async {
    if (addressController.text.isNotEmpty) {
      final result = await walletServices.validateAddress(
        address: addressController.text,
        netType: selectedChain.value,
      );
      isValidateAddress.value = result['isValid'];
      isInternalAddress.value = result['isInternal'];
      isOwnAddress.value = result['isOwnAdr'];
    } else {
      isValidateAddress.value = true;
    }

    _checkButtonEnabled();
    update();
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
          showSuccessToast(localized(toastSaveSuccess));
        } else {
          showErrorToast(localized(toastSaveUnsuccessful));
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
          phoneAuth: res.needTwoFactorAuthPhone,
        );
        if (tokenMap.isNotEmpty) {
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
            showSuccessToast(localized(toastSaveSuccess));
            getFindOrNull<WithdrawController>()?.getUSDTAddressList();
          } else {
            showErrorToast(resAgain.message.toString());
          }
        } else {
          showErrorToast(localized(codeTipMessage));
        }
      }
    } else {
      Get.back();
      showErrorToast(localized(toastSaveUnsuccessful));
    }
  }
}
