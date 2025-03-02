import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';

class FundTransferIn extends GetView<FundTransferController> {
  const FundTransferIn({super.key});

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    controller.selectedIndexHandler(controller.getCurrentToTransferIndex());
    return CustomBottomSheetContent(
      title: localized(walletTransferIn),
      showCancelButton: true,
      middleChild: CustomRoundContainer(
        margin: const EdgeInsets.all(16),
        title: localized(walletTransferWalletTypeIn),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            controller.walletTransferTypeList.length,
            (index) => Obx(
              () => CustomSelectCheck(
                text: controller.walletTransferTypeList[index].name,
                isSelected: index == controller.selectedIndex.value,
                showDivider:
                    index != (controller.walletTransferTypeList.length - 1),
                onClick: () {
                  controller.selectedIndexHandler(index);

                  if (controller.fromWalletTransferType.value?.code ==
                      controller
                          .walletTransferTypeList[
                              controller.selectedIndex.value]
                          .code) {
                    controller.exchangeWalletTransferType();
                  } else {
                    controller.setWalletTransferType(
                      controller.fromWalletTransferType.value!,
                      controller.walletTransferTypeList[
                          controller.selectedIndex.value],
                    );
                  }

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
