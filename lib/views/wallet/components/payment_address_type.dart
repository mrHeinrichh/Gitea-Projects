import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/controller/my_addresses_controller.dart';

class PaymentAddressType extends GetView<MyAddressesController> {
  const PaymentAddressType({super.key});

  @override
  Widget build(BuildContext context) {
    controller.preselectedChain.value = controller.selectedChain.value;
    return CustomBottomSheetContent(
      title: localized(walletChain),
      showCancelButton: true,
      middleChild: CustomRoundContainer(
        margin: const EdgeInsets.all(16),
        title: localized(walletNetworkSelectProtocolForTransferNew),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            controller.cryptoCurrencyList[0].supportNetType?.length ?? 0,
            (index) {
              final type =
                  controller.cryptoCurrencyList[0].supportNetType?[index];
              return Obx(
                () => CustomSelectCheck(
                  text: type,
                  isSelected: type == controller.preselectedChain.value,
                  showDivider: index !=
                      (controller.cryptoCurrencyList[0].supportNetType!.length -
                          1),
                  onClick: () {
                    controller.changePreselectedNetWork(type);
                    controller.changeNetwork(controller.preselectedChain.value);
                    Get.back();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
