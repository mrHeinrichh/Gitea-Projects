import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';

class FundTransferCurrency extends GetView<FundTransferController> {
  const FundTransferCurrency({super.key});

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    controller.selectedIndexHandler(controller.getCurrentWalletIndex());
    return CustomBottomSheetContent(
      title: localized(currencyType),
      showCancelButton: true,
      middleChild: CustomRoundContainer(
        margin: const EdgeInsets.all(16),
        title: localized(currencyType),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            controller.totalWalletTypeList.length,
            (index) => Obx(
              () => CustomSelectCheck(
                text: controller.totalWalletTypeList[index].currencyName ?? "",
                isSelected: index == controller.selectedIndex.value,
                showDivider:
                    index != (controller.totalWalletTypeList.length - 1),
                onClick: () {
                  controller.selectedIndexHandler(index);
                  controller.setCurrentWallet(
                    controller
                        .totalWalletTypeList[controller.selectedIndex.value],
                  );

                  Get.back();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
