import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/get_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

class RecipientAddressBookController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final WalletController _walletController = Get.find<WalletController>();
  final WalletServices walletServices = WalletServices();

  final TextEditingController filterRecipientController =
      TextEditingController();

  final isRecipientNameExits = false.obs;
  final isSearching = false.obs;
  final FocusNode searchFocus = FocusNode();

  late TabController tabController;

  RxList<AddressModel> filterRecipientAddressList = <AddressModel>[].obs;

  RxList<AddressModel> allRecipientList = <AddressModel>[].obs;

  List<CurrencyModel> get cryptoCurrencyList {
    return _walletController.cryptoCurrencyList;
  }

  final selectedChain = ''.obs;

  Rx<CurrencyModel> selectedCurrency = CurrencyModel().obs;

  Timer? _debounce;

  RxBool isLoading = true.obs;
  RxBool isMultiSelect = false.obs;
  RxList<AddressModel> selectedAddressList = <AddressModel>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    tabController =
        TabController(vsync: this, length: cryptoCurrencyList.length);
    tabBarListener();
    tabController.addListener(tabBarListener);
    isLoading.value = false;
  }

  Future<void> tabBarListener() async {
    if (cryptoCurrencyList[tabController.index].enableFlag) {
      selectedCurrency.value = cryptoCurrencyList[tabController.index];
      selectedChain.value = selectedCurrency.value.supportNetType?.first;

      getRecipientAddressList(
        currencyType: selectedCurrency.value.currencyType!,
      );
    } else {
      Toast.showToast(
        '暂不支持 ${cryptoCurrencyList[tabController.index].currencyName} 币种',
      );
      tabController.index = tabController.previousIndex;
    }
  }

  Future<void> selectChain(String value) async {
    selectedChain.value = value;

    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(
      allRecipientList
          .where((element) => element.netType == selectedChain.value),
    );
    filterRecipientController.clear();
  }

  void getRecipientAddressList({
    required String currencyType,
    String? netType,
  }) async {
    final data = await walletServices.getRecipientsAddress(
      currencyType: currencyType,
      netType: netType,
    );
    allRecipientList.clear();
    filterRecipientAddressList.clear();
    allRecipientList.addAll(data);
    if (netType == null) {
      filterRecipientAddressList.addAll(
        allRecipientList
            .where((e) => e.netType == selectedChain.value)
            .toList(),
      );
    } else {
      filterRecipientAddressList.addAll(allRecipientList);
    }
    filterRecipientAddressList.sort(
      (a, b) => multiLanguageSort(
        a.addrName.toLowerCase(),
        b.addrName.toLowerCase(),
      ),
    );
  }

  void addRecipient(AddressModel result) {
    allRecipientList.add(result);
    if (result.netType == selectedChain.value) {
      filterRecipientAddressList.add(result);
    }
    filterRecipientAddressList.sort(
      (a, b) => multiLanguageSort(
        a.addrName.toLowerCase(),
        b.addrName.toLowerCase(),
      ),
    );
  }

  Future<void> deleteRecipientAddress(List<AddressModel> addrList) async {
    try {
      await Future.forEach(addrList, (addr) async {
        final result =
            await walletServices.deleteRecipientAddress(addrID: addr.addrID);
        if (result) {
          filterRecipientAddressList
              .removeWhere((element) => element.addrID == addr.addrID);
          allRecipientList
              .removeWhere((element) => element.addrID == addr.addrID);
        }
      });
      //确保所有请求完成之后再刷新钱包列表
      getFindOrNull<WithdrawController>()?.getUSDTAddressList();

      Toast.showToast(localized(deletedSuccess));
    } catch (e) {
      Toast.showToast(localized(deletedFailed));
    } finally {
      selectedAddressList.clear();
      isMultiSelect.value = false;
    }
  }

  void onTapAddress(AddressModel model) async {
    if (isMultiSelect.value) {
      if (selectedAddressList.contains(model)) {
        selectedAddressList.remove(model);
      } else {
        selectedAddressList.add(model);
      }
    } else {
      final addressModel = await Get.toNamed(
        RouteName.addAddressView,
        arguments: {
          'edit': true,
          'address': model,
        },
      );

      final int idx = filterRecipientAddressList
          .indexWhere((element) => element.addrID == addressModel.addrID);

      if (idx != -1) {
        filterRecipientAddressList[idx] = addressModel;
      }
      filterRecipientAddressList.sort(
        (a, b) => multiLanguageSort(
          a.addrName.toLowerCase(),
          b.addrName.toLowerCase(),
        ),
      );
    }
  }

  void onLongPressAddress(AddressModel model) {
    if (!isMultiSelect.value) {
      isMultiSelect.value = true;
      selectedAddressList.add(model);
    }
  }

  void showDeletePrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CustomConfirmationPopup(
          title: localized(
            areYouSureYouWantToDeleteAddress,
            params: [selectedAddressList.length.toString()],
          ),
          confirmButtonText: localized(delete),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () => deleteRecipientAddress(selectedAddressList),
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void filterRecipient(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      filterRecipientAddressList.clear();
      filterRecipientAddressList.addAll(
        allRecipientList
            .where(
              (element) =>
                  element.addrName
                      .toLowerCase()
                      .contains(value.toLowerCase()) &&
                  element.netType == selectedChain.value,
            )
            .toList(),
      );
    });
  }

  void submitRecipient(String value) {
    filterRecipientAddressList.clear();
    filterRecipientAddressList.addAll(
      allRecipientList
          .where(
            (element) =>
                element.addrName.toLowerCase().contains(value.toLowerCase()) &&
                element.netType == selectedChain.value,
          )
          .toList(),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void clearSearch() {
    filterRecipientController.clear();
    filterRecipient(filterRecipientController.text);
    isSearching.value = false;
    searchFocus.unfocus();
  }
}
