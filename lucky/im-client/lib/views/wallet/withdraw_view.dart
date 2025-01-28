import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import '../../home/chat/controllers/chat_list_controller.dart';

import '../component/new_appbar.dart';

import 'components/fullscreen_width_button.dart';
import 'recipient_address_book_bottom_sheet.dart';

class WithdrawView extends GetView<WithdrawController> {
  const WithdrawView({Key? key}) : super(key: key);

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
              fontSize: 14,
              fontWeight: MFontWeight.bold4.value,
              color: color ?? JXColors.black48,
              fontFamily: appFontfamily),
        ));

    return rightWidget != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [textChild, rightWidget],
          )
        : textChild;
  }

  Widget listItem(
      {String? title,
      Widget? leadingWidget,
      bool isWithArrow = false,
      Widget? rightWidget,
      GestureTapCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          alignment: Alignment.center,
          height: 44.w,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: JXColors.white,
            borderRadius: BorderRadius.circular(12.w),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leadingWidget ??
                  Expanded(
                    child: Text(
                      title ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: MFontWeight.bold4.value,
                        fontFamily: appFontfamily,
                        color: JXColors.black,
                      ),
                    ),
                  ),
              rightWidget ?? const SizedBox(),
              if (isWithArrow)
                SvgPicture.asset(
                  'assets/svgs/arrow_right.svg',
                  width: 22.w,
                  height: 22.w,
                  colorFilter:
                      ColorFilter.mode(JXColors.black48, BlendMode.srcIn),
                )
            ],
          )),
    );
  }

  createBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return WithdrawChainType();
      },
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

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: backgroundColor,
          appBar: PrimaryAppBar(title: '付款' //localized(walletWithdraw),
              ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        subtitle(
                          title: '地址', //localized(addressAddress)
                        ),
                        ImGap.vGap8,
                        listItem(
                          leadingWidget: Expanded(
                            child: TextFormField(
                              contextMenuBuilder: textMenuBar,
                              cursorColor: accentColor,
                              textInputAction: TextInputAction.done,
                              controller: controller.recipientController,
                              focusNode: controller.recipientFocusNode,
                              onChanged: controller.onChangedRecipient,
                              style: TextStyle(fontSize: 16.sp),
                              maxLines: 2,
                              minLines: 1,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '长按粘贴',
                                //localized(addressAddressHint),
                                hintStyle: TextStyle(
                                  color: JXColors.supportingTextBlack,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          rightWidget: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Obx(() => Visibility(
                                    visible: controller
                                                .recipientAddressTextLength >
                                            0 &&
                                        controller.recipientFocusNode.hasFocus,
                                    child: GestureDetector(
                                      onTap: controller.clearRecipientAddress,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12.0).w,
                                        child: SvgPicture.asset(
                                          'assets/svgs/wallet/close.svg',
                                          width: 15,
                                          height: 15,
                                          colorFilter: const ColorFilter.mode(
                                              JXColors.black24,
                                              BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                  )),
                              ImGap.hGap12,
                              GestureDetector(
                                onTap: () {
                                  // FocusManager.instance.primaryFocus
                                  //     ?.unfocus();
                                  // await controller.tabBarListener();
                                  // Get.to(() =>
                                  // const WithdrawRecipientBookView());
                                  showAddressBookBottomSheet(context)
                                      .then((value) {
                                    if (value is AddressModel) {
                                      controller
                                          .setRecipientAddress(value.address);
                                    }
                                  });
                                },
                                child: SvgPicture.asset(
                                  'assets/svgs/wallet/contact1.svg',
                                  width: 20,
                                  height: 20,
                                  color: JXColors.black,
                                ),
                              ),
                              ImGap.hGap12,
                              GestureDetector(
                                onTap: () async {
                                  Get.find<ChatListController>().scanQRCode(
                                      didGetText: (text) {
                                    controller.setRecipientAddress(text);
                                    controller.recipientFocusNode.unfocus();
                                    controller.onChangedRecipient(text);
                                  });
                                },
                                child: SvgPicture.asset(
                                  'assets/svgs/wallet/scan1.svg',
                                  width: 20,
                                  height: 20,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          // rightWidget: Obx(
                          //       () => controller.recipientAddressTextLength >
                          //       0
                          //       ? GestureDetector(
                          //     onTap:
                          //     controller.clearRecipientAddress,
                          //     child: Padding(
                          //       padding: const EdgeInsets.only(
                          //           left: 5.0),
                          //       child: SvgPicture.asset(
                          //         'assets/svgs/wallet/close.svg',
                          //         width: 20,
                          //         height: 20,
                          //         color:
                          //         JXColors.supportingTextBlack,
                          //       ),
                          //     ),
                          //   )
                          //       : GestureDetector(
                          //     onTap: () async {
                          //       final clipboardData =
                          //       await Clipboard.getData(
                          //           Clipboard.kTextPlain);
                          //       if (clipboardData != null) {
                          //         controller.setRecipientAddress(
                          //             clipboardData.text!);
                          //         FocusManager.instance.primaryFocus
                          //             ?.unfocus();
                          //       }
                          //     },
                          //     child: Padding(
                          //       padding: const EdgeInsets.only(
                          //           left: 5.0),
                          //       child: Text(
                          //         localized(withdrawPaste),
                          //         style:
                          //         jxTextStyle.textStyleBold14(
                          //             color: accentColor),
                          //         textAlign: TextAlign.center,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ),
                        Obx(
                          () {
                            bool showInvalidAddress =
                                !controller.isValidAddress.value ||
                                    controller.isMyAddress.value;
                            bool showNotInWhiteList = controller
                                    .recipientController.text.isNotEmpty &&
                                controller.addressWhiteListModeSwitch.value &&
                                controller.isAddressInWhiteList.value == false;
                            String title = '';
                            if (showInvalidAddress) {
                              title = controller.isMyAddress.value
                                  ? r"Cannot withdraw to your own address"
                                  : localized(
                                      withdrawAddressIsNotValidOrNotMatchTheChain);
                            }
                            if (showNotInWhiteList) {
                              title = '地址不在白名单中';
                            }
                            return Visibility(
                              visible: showInvalidAddress || showNotInWhiteList,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0).w,
                                child: subtitle(
                                  title: title,
                                  color: JXColors.red,
                                ),
                              ),
                            );
                          },
                        ),
                        Obx(
                          () => controller.addressWhiteListModeSwitch.value
                              ? const Padding(
                                  padding: EdgeInsets.only(
                                      top: 8, left: 16, right: 16),
                                  child: Text(
                                    "地址白名单已启用，您只可以提币至您的地址薄内的地址。",
                                    style: TextStyle(
                                        color: JXColors.blue, fontSize: 14),
                                  ),
                                )
                              : const SizedBox(height: 0),
                        ),
                        ImGap.vGap24,
                        subtitle(title: '链名称' //localized(walletChain)
                            ),
                        ImGap.vGap8,
                        listItem(
                            title: '转账网络',
                            onTap: () => createBottomSheet(context),
                            rightWidget: Text(
                                '${controller.withdrawModel.selectedCurrency!.netType}',
                                style: TextStyle(
                                    color: JXColors.black48,
                                    fontFamily: appFontfamily,
                                    fontWeight:MFontWeight.bold4.value,
                                    fontSize: 16)),
                            isWithArrow: true),
                        ImGap.vGap24,
                        subtitle(
                          title: '数量',
                          //localized(walletWithdrawAmount)
                        ),
                        ImGap.vGap8,
                        Container(
                          height: 44.w,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ).w,
                          decoration: BoxDecoration(
                            color: JXColors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: TextFormField(
                              contextMenuBuilder: textMenuBar,
                              cursorColor: accentColor,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,4}'),
                                ),
                              ],
                              focusNode: controller.cryptoAmountFocusNode,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              textInputAction: TextInputAction.done,
                              controller: controller.cryptoAmountController,
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              onChanged: controller.onCryptoAmountChange,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintText: '最少20',
                                //controller.minHint.value,
                                hintStyle: const TextStyle(
                                  color: JXColors.supportingTextBlack,
                                ),
                                suffixIconConstraints:
                                    const BoxConstraints(maxHeight: 48),
                                suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Obx(
                                        () => Visibility(
                                            visible: controller
                                                        .cryptoAmountTextLength >
                                                    0 &&
                                                controller.cryptoAmountFocusNode
                                                    .hasFocus,
                                            child: GestureDetector(
                                              onTap: () {},
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                            horizontal: 12.0)
                                                        .w,
                                                child: SvgPicture.asset(
                                                  'assets/svgs/wallet/close.svg',
                                                  width: 15,
                                                  height: 15,
                                                  colorFilter:
                                                      const ColorFilter.mode(
                                                          JXColors.black24,
                                                          BlendMode.srcIn),
                                                ),
                                              ),
                                            )),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          controller.makeMaxAmount();
                                        },
                                        child: Text(
                                          localized(walletAll),
                                          style: jxTextStyle.textStyleBold14(
                                              color: accentColor),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Obx(() => Column(
                              children: [
                                if (controller.amountIsGreaterThan.value) ...[
                                  ImGap.vGap8,
                                  subtitle(
                                      title: '超出可用余额', color: JXColors.red),
                                ],
                              ],
                            )),
                        ImGap.vGap8,
                        subtitle(
                            title:
                                '账户可用余额: ' //'${localized(withdrawAvailableAmount)}: '
                                '${controller.maxTransfer.toDoubleFloor(controller.withdrawModel.selectedCurrency!.currencyType!.getDecimalPoint)} '
                                '${controller.withdrawModel.selectedCurrency!.currencyType}',
                            color: const Color(0xFFE49E4C)),
                        subtitle(
                            title:
                                '转账手续费: ' //'${localized(withdrawAvailableAmount)}: '
                                '${controller.gasFeeInCryptoText} '
                                '${controller.withdrawModel.selectedCurrency!.currencyType}',
                            color: const Color(0xFFE49E4C)),
                        ImGap.vGap24,
                        subtitle(
                            title: localized(withdrawComments),
                            rightWidget: Obx(
                              () => Text(
                                '${controller.commentWordCount.value}字剩余',
                                style: TextStyle(
                                  color: JXColors.black24,
                                  fontWeight:MFontWeight.bold4.value,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )),
                        ImGap.vGap8,
                        Container(
                          height: 44.w,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ).w,
                          decoration: BoxDecoration(
                            color: JXColors.white,
                            borderRadius: BorderRadius.circular(12.0.w),
                          ),
                          child: Center(
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              textInputAction: TextInputAction.done,
                              controller: controller.commentController,
                              cursorColor: accentColor,
                              onChanged: (value) {
                                controller.getCommentWordCount();
                              },
                              inputFormatters: [
                                ChineseCharacterInputFormatter(max: 30),
                              ],
                              style: TextStyle(fontSize: 16.sp),
                              maxLines: 1,
                              maxLength: 30,
                              buildCounter: (
                                BuildContext context, {
                                required int currentLength,
                                required int? maxLength,
                                required bool isFocused,
                              }) {
                                return null;
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '请输入（选填）',
                                //localized(withdrawCommentsHint),
                                hintStyle: TextStyle(
                                  color: JXColors.supportingTextBlack,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        ImGap.vGap24,
                        subtitle(title: '付款说明'),
                        subtitle(title: controller.withdrawDescription.value),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 24),
                          child: FullScreenWidthButton(
                            title: localized(walletWithdraw),
                            buttonColor: controller.isEnableNextButton()
                                ? accentColor
                                : JXColors.black.withOpacity(0.06),
                            textColor: controller.isEnableNextButton()
                                ? Colors.white
                                : JXColors.black24,
                            fontWeight:MFontWeight.bold6.value,
                            padding: EdgeInsets.zero,
                            height: 48.w,
                            onTap: controller.isEnableNextButton()
                                ? () {
                                    controller.addComment();
                                    controller.nextProgress(context);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewPadding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WithdrawChainType extends GetView<WithdrawController> {
  const WithdrawChainType({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.preselectedChain.value =
        controller.withdrawModel.selectedCurrency!.netType!;
    return Container(
      height: 260.w,
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            height: 60.w,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 0.0,
            ).w,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(localized(walletCancel),
                            style: jxTextStyle.textStyle17(color: accentColor)),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '协议',
                    style: jxTextStyle.appTitleStyle(
                        color: JXColors.primaryTextBlack),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      controller.selectChain(controller.preselectedChain.value);
                      Navigator.pop(context);
                    },
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(localized(buttonDone),
                            style: jxTextStyle.textStyle17(color: accentColor)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ImGap.vGap24,
          Container(
              margin: EdgeInsets.only(left: 32, bottom: 8).w,
              alignment: Alignment.centerLeft,
              child: Text(
                '选择转账的网络协议',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: MFontWeight.bold4.value,
                    color: JXColors.black48,
                    fontFamily: appFontfamily),
              )),
          BorderContainer(
            borderRadius: 12,
            horizontalPadding: 0,
            verticalPadding: 5,
            horizontalMargin: 18,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller
                      .withdrawModel.selectedCurrency?.supportNetType?.length ??
                  0,
              itemBuilder: (BuildContext context, int index) {
                final type = controller
                    .withdrawModel.selectedCurrency?.supportNetType?[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => controller.changePreselectedNetWork(type),
                      child: Container(
                        height: 44.w,
                        color: Colors.transparent, //不可拿掉,會影響點擊熱區
                        padding:
                            const EdgeInsets.only(left: 16, top: 11, bottom: 11)
                                .w,
                        child: Obx(() => Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(right: 16).w,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ImText(
                                                type,
                                                fontSize: ImFontSize.large,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                type == controller.preselectedChain.value
                                    ? SvgPicture.asset(
                                        'assets/svgs/check1.svg',
                                        width: 24.w,
                                        height: 24.w,
                                      )
                                    : SizedBox(
                                        width: 24.w,
                                      ),
                                ImGap.hGap16,
                              ],
                            )),
                      ),
                    ),
                    if (controller.withdrawModel.selectedCurrency!
                                .supportNetType!.length -
                            1 !=
                        index)
                      Divider(
                        color: JXColors.black.withOpacity(0.08),
                        thickness: 0.3,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
