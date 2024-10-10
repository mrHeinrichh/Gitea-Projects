import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';

class FundTransferView extends GetView<FundTransferController> {
  const FundTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(walletFundTransfer),
      ),
      body: Obx(
        () => CustomScrollableListView(
          children: [
            CustomRoundContainer(
              title: localized(currencyTypeInWallet),
              child: CustomListTile(
                text: localized(currencyInWallet),
                rightText: controller.currentWallet.value != null
                    ? controller.currentWallet.value!.currencyName ?? ""
                    : "",
              ),
            ),
            _buildTransferAccountBalances(context),
            _buildTransferAmountInput(),
            CustomButton(
              text: localized(walletFundTransferConfirm),
              isDisabled: !controller.isCanSend.value,
              callBack: () async {
                controller.onPressed(context);
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: controller.moreSpace.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferAccountBalances(BuildContext context) {
    return CustomRoundContainer(
      title: localized(walletFundTransferBetweenAccounts),
      child: Row(
        children: [
          CustomImage(
            'assets/svgs/wallet/fund_transfer_icon.svg',
            size: 24,
            padding: const EdgeInsets.all(16),
            onClick: () => controller.exchangeWalletTransferType(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => CustomListTile(
                    text: localized(walletFrom),
                    rightText: controller.fromWalletTransferType.value?.name,
                    marginLeft: 0,
                    showDivider: true,
                  ),
                ),
                Obx(
                  () => CustomListTile(
                    text: localized(walletTo),
                    rightText: controller.toWalletTransferType.value?.name,
                    marginLeft: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferAmountInput() {
    return CustomInput(
      title: localized(walletFundTransferAmount),
      controller: controller.textController,
      hintText: localized(walletHintEnterAmount),
      focusNode: controller.moneyTextFieldFocus,
      onTapInput: () {
        controller.keyboardController.showKeyboard(
          textController: controller.textController,
          focusNode: controller.moneyTextFieldFocus,
          updateMoreSpace: (space) {
            controller.moreSpace.value = space;
          },
          onNumTap: (num1, allString) {},
        );
      },
      keyboardType: TextInputType.none,
      showTextButton: true,
      textButtonTitle: localized(walletAll),
      onTapTextButton: () {
        controller.textController.text =
            (controller.currentWallet.value?.amount).toString();
      },
      errorWidget: Obx(
        () => controller.exceedAmountTxt.value.isNotEmpty
            ? Text(
                localized(walletTransferExceedAvailBalance),
                style: jxTextStyle.textStyle13(color: colorRed),
              )
            : const SizedBox.shrink(),
      ),
      descriptionWidget: Obx(
        () => controller.currentWallet.value != null
            ? Text(
                '${localized(walletAccountAvailableBalance)}: ${controller.currentWallet.value?.amount?.toStringAsFixed(2).cFormat()} '
                '${controller.currentWallet.value?.currencyType}',
                style: jxTextStyle.textStyle13(color: colorOrange),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
