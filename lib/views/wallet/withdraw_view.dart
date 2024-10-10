import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:jxim_client/views/wallet/components/withdraw_chain_type.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/views/wallet/recipient_address_book_bottom_sheet.dart';

class WithdrawView extends GetView<WithdrawController> {
  const WithdrawView({super.key});

  @override
  WithdrawController get controller =>
      Get.findOrPut<WithdrawController>(WithdrawController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.onFocusChangedCallback?.call();
      controller.onFocusChangedCallback = null;
    });

    if (QrCodeWalletTask.currentTask != null &&
        QrCodeWalletTask.currentTask!.address != null) {
      controller.setRecipientAddress(QrCodeWalletTask.currentTask!.address!);
      QrCodeWalletTask.currentTask = null;
    }
    return GetBuilder(
      init: controller,
      builder: (_) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: colorBackground,
          appBar: PrimaryAppBar(
            title: localized(walletWithdraw),
          ),
          body: CustomScrollableListView(
            children: [
              // 链名称
              getAddressType(context),
              // 地址
              getAddressField(context),
              // 提现金额
              getAmountField(),
              // 评论文本字段
              getCommentTextField(),
              // 提交按钮 确认付款
              getBottomButton(context),
              // 使用 AnimatedContainer 进行动画过渡
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: controller.moreSpace.value,
              ),
              Container(
                color: colorBackground,
                height: MediaQuery.of(context).viewPadding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget subtitle({
    required String title,
    Color? color,
    double marginBottom = 0.0,
    Widget? rightWidget,
  }) {
    Widget textChild = Container(
      margin: EdgeInsets.only(left: 16, bottom: marginBottom).w,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: MFontWeight.bold4.value,
          color: color ?? colorTextPrimary.withOpacity(0.56),
          fontFamily: appFontfamily,
        ),
      ),
    );

    return rightWidget != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [textChild, rightWidget],
          )
        : textChild;
  }

  Widget getAddressType(BuildContext context) {
    return CustomRoundContainer(
      title: localized(walletChain),
      child: CustomListTile(
        height: 44,
        text: localized(walletTransferNetwork),
        rightText: controller.netType(),
        // onClick: () async => showWithdrawChainTypeDialog(context),
      ),
    );
  }

  Widget getAddressField(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAddressInput(
          title: localized(addressAddress),
          controller: controller.recipientController,
          focusNode: controller.recipientFocusNode,
          onChanged: controller.onChangedRecipient,
          onTapClearButton: controller.clearRecipientAddress,
          onAddressInput: () {
            // FocusManager.instance.primaryFocus
            //     ?.unfocus();
            // await controller.tabBarListener();
            // Get.to(() =>
            // const WithdrawRecipientBookView());
            showAddressBookBottomSheet(context).then((value) {
              if (value is AddressModel) {
                controller.setRecipientAddress(value.address);
              }
            });
          },
          onScanInput: () async {
            Get.find<ChatListController>().scanQRCode(
              didGetText: (text) {
                controller.setRecipientAddress(text);
                controller.recipientFocusNode.unfocus();
                // controller.onChangedRecipient(text);
              },
            );
          },
        ),
        Obx(
          () {
            bool isFieldEmpty = controller.recipientController.text.isEmpty;
            bool showInvalidAddress =
                (!controller.isValidAddress.value && !isFieldEmpty) ||
                    controller.isMyAddress.value;
            bool showNotInWhiteList =
                controller.recipientController.text.isNotEmpty &&
                    controller.addressWhiteListModeSwitch.value &&
                    controller.isAddressInWhiteList.value == false;
            String title = '';
            if (showInvalidAddress) {
              title = controller.isMyAddress.value
                  ? r"Cannot withdraw to your own address"
                  : localized(withdrawAddressIsNotValidOrNotMatchTheChain);
            }
            if (showNotInWhiteList) {
              title = localized(walletAddressNotWhitelist);
            }
            return Visibility(
              visible: showInvalidAddress || showNotInWhiteList,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0).w,
                child: subtitle(
                  title: title,
                  color: colorRed,
                ),
              ),
            );
          },
        ),
        Obx(
          () => controller.addressWhiteListModeSwitch.value
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(
                    localized(walletAddressWithdrawOnlyWithWhitelistBook),
                    style: jxTextStyle.textStyle13(color: themeColor),
                  ),
                )
              : const SizedBox(height: 0),
        ),
      ],
    );
  }

  Widget getAmountField() {
    return Obx(
      () => Column(
        children: [
          CustomInput(
            title: localized(walletWithdrawAmount),
            keyboardType: TextInputType.none,
            // controller.useCustomerNumPad ? TextInputType.none :
            //     const TextInputType.numberWithOptions(
            //   decimal: true,
            // ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,4}'),
              ),
            ],
            focusNode: controller.cryptoAmountFocusNode,
            controller: controller.cryptoAmountController,
            onTapInput: () {
              controller.keyboardController.showKeyboard(
                textController: controller.cryptoAmountController,
                focusNode: controller.cryptoAmountFocusNode,
                onCancel: () {
                  controller.onCryptoAmountChange(
                    controller.cryptoAmountController.text,
                  );
                },
                onDone: () {
                  controller.onCryptoAmountChange(
                    controller.cryptoAmountController.text,
                  );
                },
                onNumTap: (num1, allString) {
                  controller.onCryptoAmountChange(allString);
                },
                onDeleteTap: (num1, allString) {
                  controller.onCryptoAmountChange(allString);
                },
                updateMoreSpace: (space) {
                  controller.updateBottomSpace(space);
                },
              );
              controller
                  .onCryptoAmountChange(controller.cryptoAmountController.text);
            },
            onChanged: controller.onCryptoAmountChange,
            showTextButton: true,
            textButtonTitle: localized(numberAll),
            onTapTextButton: () => controller.makeMaxAmount(),
            hintText: controller.minHint.value,
            onTapClearButton: () => controller.onCryptoAmountChange(''),
            errorWidget: Obx(
              () => controller.amountIsGreaterThan.value
                  ? Text(
                      localized(walletWithdrawExceedingAvailBalance),
                      style: jxTextStyle.textStyle13(color: colorRed),
                    )
                  : const SizedBox.shrink(),
            ),
            descriptionWidget: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localized(walletAccountAvailableBalance)}: '
                    '${controller.maxTransfer.toDoubleFloor(controller.withdrawModel.selectedCurrency?.currencyType?.getDecimalPoint ?? 0).cFormat()} '
                    '${controller.currencyType()}',
                    style: jxTextStyle.textStyle13(color: colorOrange),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${localized(walletTransferFee)}: '
                    '${double.parse(controller.gasFeeInCryptoText.value).toStringAsFixed(2)} '
                    '${controller.currencyType()}',
                    style: jxTextStyle.textStyle13(color: colorOrange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getCommentTextField() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomInput(
            title: localized(withdrawComments),
            rightTitle:
                '${controller.commentWordCount.value}${localized(charactersLeft)}',
            controller: controller.commentController,
            keyboardType: TextInputType.text,
            maxLength: 30,
            hintText: localized(withdrawCommentsHintNew),
            onChanged: (value) => controller.getCommentWordCount(),
            onTapClearButton: () => controller.getCommentWordCount(),
            inputFormatters: [
              ChineseCharacterInputFormatter(max: 30),
            ],
          ),
          ImGap.vGap24,
          subtitle(title: localized(walletPaymentInstruction)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: subtitle(title: controller.withdrawDescription.value),
          ),
        ],
      ),
    );
  }

  Widget getBottomButton(BuildContext context) {
    return CustomButton(
      text: localized(confirmWithdrawal),
      isDisabled: !controller.isEnableNextButton(),
      callBack: () {
        // 点击了付款
        controller.addComment();
        controller.nextProgress(context);
      },
    );
  }

  Future<void> showWithdrawChainTypeDialog(BuildContext context) async {
    showModalBottomSheet(
      barrierColor: colorTextPrimary.withOpacity(0.40),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const WithdrawChainType(),
    );
  }

  Future showAddressBookBottomSheet(BuildContext context) {
    final controller = this.controller.getRecipientController();

    controller.getRecipientAddressList(currencyType: 'USDT');

    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => const RecipientAddressBookBottomSheet(),
    ).then(
      (value) {
        controller.clearSearch();
        return value;
      },
    );
  }
}
