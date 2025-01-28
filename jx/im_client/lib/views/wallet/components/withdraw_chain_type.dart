import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';

class WithdrawChainType extends GetView<WithdrawController> {
  const WithdrawChainType({super.key});

  @override
  Widget build(BuildContext context) {
    controller.preselectedChain.value =
        controller.withdrawModel.selectedCurrency?.netType ?? '';

    return CustomBottomSheetContent(
      title: localized(walletChain),
      showCancelButton: true,
      middleChild: CustomRoundContainer(
        margin: const EdgeInsets.all(16),
        title: localized(walletNetworkSelectProtocolForTransferNew),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              controller
                      .withdrawModel.selectedCurrency?.supportNetType?.length ??
                  0, (index) {
            final type = controller
                .withdrawModel.selectedCurrency!.supportNetType![index];

            return Obx(
              () => CustomSelectCheck(
                text: type,
                isSelected: type == controller.preselectedChain.value,
                showDivider: index !=
                    (controller.withdrawModel.selectedCurrency!.supportNetType!
                            .length -
                        1),
                onClick: () {
                  controller.changePreselectedNetWork(type);
                  controller.selectChain(controller.preselectedChain.value);
                  Get.back();
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
