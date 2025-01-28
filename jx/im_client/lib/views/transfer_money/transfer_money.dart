import 'package:cashier/im_cashier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/transfer_money/transfer_money_controller.dart';

class TransferMoney extends GetView<TransferMoneyController> {
  const TransferMoney({super.key});

  void _hideKeyboard() => controller.hideKeyboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      resizeToAvoidBottomInset: false,
      appBar: PrimaryAppBar(title: localized(transferMoney)),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollableListView(
              children: [
                CustomRoundContainer(
                  title: localized(currencyType),
                  titleColor: colorTextLevelTwo,
                  child: CustomListTile(
                    text: localized(currency),
                    rightText: controller.currency.title,
                    // remove CNY
                    // onClick: () async {
                    //   imShowBottomSheet(
                    //     context,
                    //     (context) =>
                    //         CurrencySelectionDialog(controller.currency),
                    //   ).then((value) {
                    //     if (value is CurrencyALLType) {
                    //       controller.updateCurrency(value);
                    //     }
                    //   });
                    // },
                  ),
                ),
                CustomInput(
                  title: localized(amountTransfer),
                  controller: controller.amountController,
                  focusNode: controller.amountFocusNode,
                  hintText: localized(walletHintEnterAmount),
                  onTapClearButton: () {
                    controller.clearError();
                    controller.setAmount(0.0);
                  },
                  onTapInput: () => controller.showKeyboard(),
                  errorWidget: Obx(
                    () => controller.error.isNotEmpty
                        ? Text(
                            controller.error,
                            style: jxTextStyle.normalSmallText(color: colorRed),
                            maxLines: 2,
                          )
                        : const SizedBox.shrink(),
                  ),
                  descriptionWidget: Obx(
                    () => Text(
                      '${localized(walletAccountBalance)}：${controller.currencyAmount ?? "-"} ${controller.currency.title}',
                      style: jxTextStyle.normalSmallText(color: colorOrange),
                    ),
                  ),
                ),
                Obx(
                  () => CustomInput(
                    title: localized(remark),
                    focusNode: controller.noteFocusNode,
                    rightTitle:
                        '${30 - controller.remarkTextLength.value}${localized(charactersLeft)}',
                    controller: controller.remarkController,
                    hintText: localized(enterRemark),
                    maxLength: 30,
                    keyboardType: TextInputType.text,
                    onTapInput: () => controller.setKeyboardValue(false),
                    onChanged: (value) {
                      controller.remarkTextLength.value =
                          value.characters.length;
                    },
                  ),
                ),
                Obx(
                  () => CustomButton(
                    text: localized(transferMoney),
                    isDisabled: !controller.isNextEnabled,
                    callBack: () async {
                      _hideKeyboard();
                      controller.pinCodeController = TextEditingController();
                      controller.otpFocus = FocusNode();
                      if (!controller.otpFocus.hasFocus) {
                        controller.otpFocus.requestFocus();
                      }
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: Get.context!,
                        backgroundColor: colorBackground,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                        builder: (context) => CashierViewBottomSheet(
                          onCompleted: controller.onConfirmed,
                          isLoading: controller.isLoading.value,
                          onForgetPasscodeTap: () {
                            PasscodeController passCodeController;
                            if (Get.isRegistered<PasscodeController>()) {
                              passCodeController =
                                  Get.find<PasscodeController>();
                            } else {
                              passCodeController =
                                  Get.put(PasscodeController());
                            }
                            passCodeController.walletPasscodeOptionClick(
                              'resetPasscode',
                              isFromChatRoom: true,
                            );
                          },
                          isPasscodeIncorrect: controller.isPasscodeIncorrect,
                          controller: controller,
                          amountText: controller.amount,
                          currencyText: controller.currency.title,
                          title: localized(paymentPassword),
                          buttonCancel: localized(buttonCancel),
                          transferTypeValue: localized(transferMoney),
                          transferTypeTitle: localized(walletTransactionType),
                          myPaymentMethod:
                              localized(walletTransactionDeduction),
                          step: 1,
                          myPaymentMethodTip:
                              localized(transferFundsWillDeductedFromWallet),
                          otpFocus: controller.otpFocus,
                          isAttemptWrong: controller.isAttemptWrong,
                        ),
                      ).then((value) {
                        controller.isLoading.value = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.isKeyboardVisible) {
              return im.KeyboardNumber(
                controller: controller.amountController,
                showTopButtons: true,
                onTap: (key) {
                  final double inputValue;

                  String newText = controller.amountController.text;

                  if (newText.isEmpty) {
                    inputValue = 0.0;
                    controller.clearError();
                    controller.setAmount(inputValue);
                  } else {
                    RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');

                    if (pattern.hasMatch(newText) == false) {
                      controller.amountController.text = newText.isNotEmpty
                          ? newText.substring(0, newText.length - 1)
                          : newText;
                      newText = newText.substring(0, newText.length - 1);
                    }

                    if (controller.amountController.text.indexOf("0") == 0 &&
                        controller.amountController.text.indexOf(".") != 1 &&
                        controller.amountController.text.length > 1) {
                      controller.amountController.text = newText.substring(1);
                      newText = newText.substring(1);
                    }

                    if (controller.amountController.text.isEmpty) {
                      inputValue = 0.0;
                      controller.setAmount(inputValue);
                    } else {
                      final value = double.tryParse(newText);
                      if (value != null) {
                        controller.setAmount(value);
                      }
                    }
                  }

                  EasyDebounce.debounce(
                    'transferMoneyAmount',
                    const Duration(milliseconds: 500),
                    () {
                      if (controller.isOverWalletAmount &&
                          controller.currencyAmount != null) {
                        controller.setError(
                          localized(walletTransferExceedAvailBalance),
                        );
                      } else {
                        controller.clearError();
                      }
                    },
                  );
                },
                onTapCancel: _hideKeyboard,
                onTapConfirm: _hideKeyboard,
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
