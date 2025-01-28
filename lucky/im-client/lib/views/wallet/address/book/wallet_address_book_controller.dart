import 'package:get/get.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';

class WalletAddressBookController extends GetxController {
  RxBool _isEditMode = false.obs;

  bool get isEditMode => _isEditMode.value && hasData;

  final bookController = Get.find<RecipientAddressBookController>();

  List<AddressModel> get addressList => bookController.allRecipientList;

  bool get hasData => addressList.isNotEmpty;

  RxList<AddressModel> _selectedList = <AddressModel>[].obs;

  List<AddressModel> get selectedAddressList => _selectedList;

  @override
  void onInit() {
    super.onInit();
  }

  void setEditMode() {
    _isEditMode.value = !_isEditMode.value;
    _selectedList.clear();
  }

  void addSelected(AddressModel model) {
    _selectedList.add(model);
  }

  void addSelectedAll() {
    for (final model in addressList) {
      final isContains = selectedAddressList.contains(model);
      if (isContains) continue;
      _selectedList.add(model);
    }
  }

  void removeSelected(AddressModel model) {
    _selectedList.remove(model);
  }

  void onDeleteAddress() {
    Get.find<RecipientAddressBookController>()
        .deleteRecipientAddress(selectedAddressList);
  }
}
