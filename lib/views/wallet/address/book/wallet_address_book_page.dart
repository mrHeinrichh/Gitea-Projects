import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_list_item.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page_argument.dart';

class WalletAddressBookPage extends GetView<WalletAddressBookController> {
  const WalletAddressBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: localized(walletAddressBook),
          trailing: [
            Visibility(
              visible: controller.hasData,
              child: Center(
                child: CustomTextButton(
                  controller.isEditMode
                      ? localized(buttonDone)
                      : localized(buttonEdit),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onClick: controller.setEditMode,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: !controller.hasData
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: NoContentView(
                          icon: 'empty_folder_icon',
                          title: localized(walletNoAvailableAddress),
                          subtitle: localized(walletSaveFavouriteAddress),
                          subtitleFontSize: MFontSize.size17.value,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: controller.addressList.length,
                        itemBuilder: (_, index) {
                          final model = controller.addressList[index];

                          return WalletAddressBookListItem(
                            key: UniqueKey(),
                            index: index,
                            model: model,
                            enableCheckBtn: controller.isEditMode,
                            onTap: () async {
                              if (!controller.isEditMode) {
                                Get.toNamed(
                                  RouteName.addressEditView,
                                  arguments: WalletAddressArguments(
                                    addrName: model.addrName,
                                    addrID: model.addrID,
                                    address: model.address,
                                    netType: model.netType,
                                  ).toJson(),
                                );
                              } else {
                                final value = controller.selectedAddressList
                                    .contains(model);
                                if (!value) {
                                  controller.addSelected(model);
                                } else {
                                  controller.removeSelected(model);
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
              !controller.isEditMode
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: CustomButton(
                        text: localized(walletAddNewAddress),
                        callBack: () async {
                          Get.toNamed(RouteName.addressEditView);
                        },
                      ),
                    )
                  : _showDeleteButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showDeleteButton(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: colorBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomTextButton(
            localized(selectAll),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            onClick: controller.addSelectedAll,
          ),
          CustomTextButton(
            localized(delete),
            isDisabled: controller.selectedAddressList.isEmpty,
            color: colorRed,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            onClick: controller.onDeleteAddress,
          ),
        ],
      ),
    );
  }
}
