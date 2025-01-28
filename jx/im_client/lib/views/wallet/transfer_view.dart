import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/account_contact.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/components/transfer_currency.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';
import 'package:jxim_client/views/wallet/transfer_contact_bottom_sheet.dart';

class TransferView extends GetView<TransferController> {
  const TransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(transferMoney),
      ),
      body: common.KeyboardHideWidget(
        child: GestureDetector(
          onTap: () {
            controller.isShowMatchContact.value = false;
          },
          child: Obx(
            () => getContent(context),
          ),
        ),
      ),
    );
  }

  Widget getContent(BuildContext context) {
    return Stack(
      children: [
        CustomScrollableListView(children: [
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getToWhomTextField(context),
                  getPhoneErrorHintWidget(),
                  ImGap.vGap(24),
                  getCurrentType(context),
                  ImGap.vGap(24),
                  getAmountTextField(),
                  ImGap.vGap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getTitle(localized(withdrawComments)),
                      Obx(() {
                        if (controller.initialized) {
                          return Text(
                            '${controller.remainInputCount.value}${localized(charactersLeft)}',
                            style: jxTextStyle.textStyle13(
                              color: Colors.black.withOpacity(0.24),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }),
                    ],
                  ),
                  getMemoTextField(),
                  ImGap.vGap(24),
                  Obx(
                    () => CustomButton(
                      text: localized(walletTransferConfirm),
                      isDisabled: !controller.isCanSend.value,
                      callBack: () => controller.onPressed(context),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: controller.moreSpace.value,
                  ),
                ],
              ),
              Obx(() {
                return controller.isShowMatchContact.value &&
                        controller.accountContactList.isNotEmpty
                    ? Positioned(
                        top: MediaQuery.of(context).viewInsets.top + 82,
                        left: 0,
                        right: 0,
                        child: getToWhomList(controller.accountContactList),
                      )
                    : const SizedBox();
              }),
            ],
          ),
        ]),
        if (controller.isKeyboardVisible.value && controller.useCustomerNumPad)
          common.KeyboardNumber(
            controller: controller.amountTextController,
            cancelColor: themeColor,
            doneColor: themeColor,
            onTap: (value) {
              controller.onKeyboardNumberListener(value);
            },
            showTopButtons: true,
            onTapCancel: () => controller.setKeyboardState(false),
            onTapConfirm: () => controller.setKeyboardState(false),
          ),
      ],
    );
  }

  getToWhomList(List<AccountContact> contactList) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      height: contactList.length > 1 ? 89 : 45,
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: contactList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              AccountContact data = contactList[index];
              controller.setToUserText(
                data.uid!,
                data.nickname!,
                data.countryCode!,
                data.contact!,
              );
              controller.isShowMatchContact.value = false;
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 16),
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contactList[index].nickname ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: jxTextStyle.textStyle16(),
                        ),
                      ),
                      Text(
                        "${contactList[index].countryCode}${contactList[index].contact}",
                        style: jxTextStyle.textStyle16(
                          color: colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (contactList.length != index + 1)
                  Container(
                    height: 0.3,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  getToWhomTextField(context) {
    return CustomAddressInput(
      title: localized(walletTransferToWhom),
      controller: controller.toWhomTextController,
      focusNode: controller.toWhomTextFocus,
      maxLines: 1,
      keyboardType: TextInputType.phone,
      onChanged: (txt) {
        if (controller.toWhomTextController.text.isEmpty) {
          controller.isShowMatchContact.value = false;
        }
      },
      onTapClearButton: () => controller.isShowMatchContact.value = false,
      onTapInput: () => controller.setKeyboardState(false),
      readOnly: controller.isFromScanQRCode,
      hintText: localized(walletHintEnterPhoneNum),
      onAddressInput: () async {
        showTransferContactBottomSheet(context);
      },
      onScanInput: () {
        Get.find<ChatListController>().scanQRCode(
          didGetText: (text) {
            var mapRe = json.decode(text);
            String accountId = mapRe["profile"] ?? '';
            if (accountId.isNotEmpty) {
              controller.getUserInfo(accountId);
            } else {
              common.showErrorToast(
                localized(toastFormatIncorrect),
              );
            }
          },
        );
      },
    );
  }

  Future showTransferContactBottomSheet(BuildContext context) {
    TransferController controller = Get.find<TransferController>();
    controller.getFriendList();
    return showModalBottomSheet(
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => const TransferContactBottomSheet(),
    ).then(
      (value) => controller.clearSearching(),
    );
  }

  getPhoneErrorHintWidget() {
    return Obx(
      () => Visibility(
        visible: controller.phoneErrorHint.isNotEmpty,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
          child: Text(
            controller.phoneErrorHint.value,
            style: jxTextStyle.textStyle14(
              color: colorRed,
            ),
          ),
        ),
      ),
    );
  }

  getAmountTextField() {
    return Obx(
      () => CustomInput(
        key: controller.amountTextFieldKey,
        title: localized(amountTransfer),
        controller: controller.amountTextController,
        focusNode: controller.amountTextFocus,
        keyboardType: controller.useCustomerNumPad
            ? TextInputType.none
            : TextInputType.none,
        onTapInput: () {
          controller.keyboardController.showKeyboard(
            globalKey: controller.amountTextFieldKey,
            textController: controller.amountTextController,
            focusNode: controller.amountTextFocus,
            updateAnimation: (animation) {
              controller.updateOffsetAnimation(animation);
            },
            updateMoreSpace: (space) {
              controller.moreSpace.value = space;
            },
            onNumTap: (n1, allString) {},
          );
        },
        hintText: localized(walletHintEnterAmount),
        errorText: controller.exceedAmountTxt.value.isNotEmpty
            ? localized(walletTransferExceedAvailBalance)
            : '',
        descriptionWidget: controller.currentWallet.value != null
            ? Text(
                '${localized(withdrawAvailableAmount)}: ${controller.currentWallet.value?.amount?.toStringAsFixed(2).cFormat()} '
                '${controller.currentWallet.value?.currencyType}',
                style: jxTextStyle.textStyle14(color: colorOrange),
              )
            : const SizedBox(),
      ),
    );
  }

  getMemoTextField() {
    return CustomInput(
      controller: controller.memoTextController,
      focusNode: controller.memoTextFocus,
      keyboardType: TextInputType.text,
      maxLength: 30,
      hintText: localized(withdrawCommentsHint),
      onTapInput: () => controller.setKeyboardState(false),
    );
  }

  getTitle(txt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Text(
        txt,
        style: jxTextStyle.textStyle13(
          color: colorTextSecondary,
        ),
      ),
    );
  }

  getCurrentType(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getTitle(localized(currencyType)),
        GestureDetector(
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 8.0,
              top: 4.0,
              bottom: 4.0,
            ),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    localized(currencyInWallet),
                    style: const TextStyle(
                      color: colorTextPrimary,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Obx(
                  () => Text(
                    controller.currentWallet.value != null
                        ? controller.currentWallet.value!.currencyName ?? ""
                        : "",
                    style: const TextStyle(
                      color: colorTextSecondary,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                ImGap.hGap8,
              ],
            ),
          ),
        ),
      ],
    );
  }

  createTransferCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return const TransferCurrency();
      },
    );
  }
}
