import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/components/recipient_address_book_list_item.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';

class RecipientAddressBookBottomSheet extends StatelessWidget {
  const RecipientAddressBookBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final RecipientAddressBookController controller =
        Get.find<RecipientAddressBookController>();

    return Obx(
      () => CustomBottomSheetContent(
        height: ObjectMgr.screenMQ!.size.height * 0.95,
        headerHeight: 66,
        useBottomSafeArea: false,
        showHeader: !controller.isSearching.value,
        title: localized(walletSelectAddress),
        leading: CustomImage(
          'assets/svgs/wallet/wallet_guard_icon.svg',
          size: 24,
          padding: const EdgeInsets.only(right: 16),
          color: themeColor,
          onClick: () async {
            Get.toNamed(
              RouteName.addressSecuritySettingView,
              preventDuplicates: false,
            );
          },
        ),
        trailing: CustomTextButton(
          localized(walletAddressesBook),
          padding: const EdgeInsets.only(left: 16),
          onClick: () async {
            Get.toNamed(
              RouteName.addressBookView,
              preventDuplicates: false,
            );
          },
        ),
        topChild: CustomSearchBar(
          controller: controller.filterRecipientController,
          onChanged: controller.filterRecipient,
          onClick: () => controller.isSearching(true),
          onClearClick: controller.clearSearch,
          onCancelClick: controller.clearSearch,
        ),
        showDivider: true,
        middleChild: controller.filterRecipientAddressList.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                child: NoContentView(
                  icon: 'empty_folder_icon',
                  alignment: Alignment.topCenter,
                  title: localized(walletNoAvailableAddress),
                  subtitle: localized(walletSaveFavouriteAddress),
                  subtitleFontSize: MFontSize.size17.value,
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewPadding.bottom,
                ),
                itemCount: controller.filterRecipientAddressList.length,
                itemBuilder: (_, int index) {
                  final model = controller.filterRecipientAddressList[index];

                  return RecipientAddressBookListItem(
                    key: UniqueKey(),
                    index: index,
                    addressName: model.addrName,
                    chainNetwork: model.netType,
                    walletAddress: model.address,
                    historyTransfer: model.rechargeNum,
                    totalHistoryTransferAmount: model.rechargeAmt,
                    onTap: () => Get.back(result: model),
                  );
                },
              ),
      ),
    );
  }
}
