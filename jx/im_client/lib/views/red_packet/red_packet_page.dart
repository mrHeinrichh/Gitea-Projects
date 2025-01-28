import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/add_recipient.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/red_packet/components/red_packet_type_bottom_sheet.dart';

class RedPacketPage extends StatefulWidget {
  RedPacketPage({required String tag, super.key}) {
    Get.put(RedPacketController(tag: tag));
  }

  @override
  State<RedPacketPage> createState() => _RedPacketPageState();
}

class _RedPacketPageState extends State<RedPacketPage> {
  late RedPacketController controller;

  final _amountFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  List redPacketItemList = [];

  @override
  void initState() {
    super.initState();
    controller = Get.find<RedPacketController>();
    redPacketItemList = controller.getRedPacketTypeItems();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _quantityFocusNode.dispose();
    Get.findAndDelete<RedPacketController>();
    super.dispose();
  }

  void _hideKeyboard() {
    controller.setKeyboardState(false);
    _amountFocusNode.unfocus();
    _quantityFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(sendRedPacket),
        onPressedBackBtn: () {
          Get.back();
          controller.clearData();
        },
      ),
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: CustomScrollableListView(
                children: [
                  CustomRoundContainer(
                    title: localized(redPocketType),
                    titleColor: colorTextLevelTwo,
                    child: CustomListTile(
                      text: localized(redPacket),
                      rightText:
                          controller.redPacketType.value.name.redPacketName,
                      onArrowClick: () async =>
                          _showRedEnvelopeTypeBottomSheet(context),
                    ),
                  ),
                  CustomRoundContainer(
                    title: localized(currencyType),
                    titleColor: colorTextLevelTwo,
                    child: CustomListTile(
                      text: localized(currency),
                      rightText:
                          controller.selectedCurrency.value.currencyType ?? '',
                    ),
                  ),
                  CustomInput(
                    title: controller.redPacketType.value ==
                            RedPacketType.luckyRedPacket
                        ? localized(totalAmount)
                        : localized(amount),
                    controller: controller.amountController,
                    focusNode: _amountFocusNode,
                    hintText: localized(
                      redPocketEnterLimitAmount,
                      params: [
                        (controller.maxTransfer.toDoubleFloor(
                          controller.selectedCurrency.value.getDecimalPoint,
                        )),
                      ],
                    ),
                    errorText: controller.amountError.value,
                    showTextButton: true,
                    onTapTextButton: () {
                      controller.amountController.text =
                          controller.maxTransfer.toDoubleFloor(
                        controller.selectedCurrency.value.getDecimalPoint,
                      );
                      controller.amountError.value = '';
                      controller.calculateTotalTransfer();
                    },
                    onTapClearButton: () {
                      controller.totalTransfer.value = 0;
                      controller.amountError.value = '';
                    },
                    onTapInput: () {
                      controller.isKeyboardVisible(true);
                      controller.currentKeyboardController(
                        controller.amountController,
                      );
                    },
                    descriptionWidget: Text(
                      '${localized(amountAvailableInAccount)}: ${controller.maxTransfer == 0.0 ? '-.--' : controller.maxTransfer.toDoubleFloor(controller.selectedCurrency.value.getDecimalPoint)} ${controller.selectedCurrency.value.currencyType ?? ''}',
                      style: jxTextStyle.normalSmallText(color: colorOrange),
                    ),
                  ),
                  (controller.redPacketType.value ==
                          RedPacketType.exclusiveRedPacket)
                      ? CustomRoundContainer(
                          title: localized(recipient),
                          rightTitle:
                              '${localized(redPocketGroupMembers)}${controller.groupMemberList.length}',
                          child: CustomListTile(
                            text: localized(redPocketToWhom),
                            rightText: controller.selectedRecipients.isNotEmpty
                                ? controller.selectedRecipients.length
                                    .toString()
                                : localized(select),
                            onArrowClick: () async {
                              showModalBottomSheet(
                                context: context,
                                isDismissible: false,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Colors.transparent,
                                builder: (BuildContext context) {
                                  return const AddRecipient();
                                },
                              );
                            },
                          ),
                        )
                      : CustomInput(
                          controller: controller.quantityController,
                          focusNode: _quantityFocusNode,
                          errorText: controller.redPacketMaxMemError.value,
                          title: localized(redPacketNumber),
                          rightTitle:
                              '${localized(redPocketGroupMembers)}${controller.groupMemberList.length}',
                          onTapInput: () {
                            controller.isKeyboardVisible(true);
                            controller.currentKeyboardController(
                              controller.quantityController,
                            );
                          },
                          hintText: localized(plzEnter),
                          onTapClearButton: () {
                            controller.quantity.value = 0;
                            controller.redPacketMaxMemError.value = '';
                          },
                        ),
                  CustomInput(
                    controller: controller.commentController,
                    title: localized(remark),
                    rightTitle:
                        '${controller.remarkRemainLength.value}${localized(charactersLeft)}',
                    hintText: localized(enterRemark),
                    keyboardType: TextInputType.text,
                    maxLength: 30,
                    onChanged: (value) {
                      controller.remarkRemainLength.value =
                          30 - value.characters.length;
                    },
                    onTapInput: () {
                      controller.isKeyboardVisible.value = false;
                    },
                    onTapClearButton: () {
                      controller.remarkRemainLength.value = 30;
                    },
                  ),
                  // Send Button
                  CustomButton(
                    isDisabled: !controller.isEnableNext(),
                    callBack: () async {
                      _hideKeyboard();
                      controller.navigateConfirmPage(context);
                    },
                    text: localized(sendRedPacket),
                  ),
                ],
              ),
            ),
            if (controller.isKeyboardVisible.value &&
                MediaQuery.of(context).viewInsets.bottom == 0)
              im.KeyboardNumber(
                controller: controller.currentKeyboardController.value,
                cancelColor: themeColor,
                doneColor: themeColor,
                showTopButtons: true,
                onTap: (value) {
                  num input = 0;

                  final currentKBController =
                      controller.currentKeyboardController.value;
                  if (currentKBController == controller.amountController) {
                    RegExp pattern = RegExp(r'^\d+(\.\d{0,2})?$');
                    String amountText = currentKBController.text;

                    if (!pattern.hasMatch(currentKBController.text) &&
                        currentKBController.text.isNotEmpty) {
                      currentKBController.text = amountText.isNotEmpty
                          ? amountText.substring(
                              0,
                              currentKBController.text.length - 1,
                            )
                          : amountText;

                      amountText =
                          amountText.substring(0, amountText.length - 1);
                    }
                    if (currentKBController.text.indexOf("0") == 0 &&
                        currentKBController.text.indexOf(".") != 1 &&
                        currentKBController.text.length > 1) {
                      currentKBController.text = amountText.substring(1);
                      amountText = amountText.substring(1);
                    }

                    if (amountText.isNotEmpty) {
                      input = num.parse(amountText);
                    }

                    controller.amountError.value =
                        input > controller.maxTransfer
                            ? localized(redPocketExceedMaxLimit)
                            : '';
                    controller.calculateTotalTransfer();
                  }

                  if (currentKBController == controller.quantityController) {
                    if (value == '.') {
                      currentKBController.text = currentKBController.text
                          .substring(0, currentKBController.text.length - 1);
                    }

                    final quantityText = currentKBController.text;

                    if (quantityText.isNotEmpty) {
                      input = num.parse(quantityText);
                    }

                    controller.redPacketMaxMemError.value =
                        input > controller.groupMemberList.length
                            ? localized(thisRedPacketExceedMaxNumPeople)
                            : '';

                    controller.quantity.value = input.toInt();
                    controller.calculateTotalTransfer();
                  }
                },
                onTapCancel: _hideKeyboard,
                onTapConfirm: _hideKeyboard,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRedEnvelopeTypeBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => RedPacketTypeBottomSheet(
        redPacketItemList: redPacketItemList,
      ),
    );
  }
}
