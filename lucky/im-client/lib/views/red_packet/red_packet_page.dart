import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/add_recipient.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import '../../object/enums/enum.dart';
import '../transfer_money/currency_selection_dialog.dart';

class RedPacketPage extends StatefulWidget {
  RedPacketPage({required String tag, super.key}) {
    Get.put(RedPacketController(tag: tag));
  }

  @override
  State<RedPacketPage> createState() => _RedPacketPageState();
}

class _RedPacketPageState extends State<RedPacketPage> {
  late RedPacketController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<RedPacketController>();
  }

  @override
  void dispose() {
    Get.findAndDelete<RedPacketController>();
    super.dispose();
  }

  Future _showShareViewDialog(BuildContext context) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return _buildMobileShareView(context);
      },
    );
  }

  _buildMobileShareView(ctx) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSelectTypeButton(
                      name: localized(lucky),
                      onTap: () {
                        controller.redPacketType.value =
                            RedPacketType.luckyRedPacket;
                        controller.calculateTotalTransfer();
                        Navigator.pop(ctx);
                      }),
                  _buildSelectTypeButton(
                      name: localized(normal),
                      onTap: () {
                        controller.redPacketType.value =
                            RedPacketType.normalRedPacket;
                        controller.calculateTotalTransfer();
                        Navigator.pop(ctx);
                      }),
                  _buildSelectTypeButton(
                      name: localized(exclusive),
                      onTap: () {
                        controller.redPacketType.value =
                            RedPacketType.exclusiveRedPacket;
                        controller.calculateTotalTransfer();
                        Navigator.pop(ctx);
                      })
                ],
              ),
            ),
            ImGap.vGap8,
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                child: Text(
                  localized(cancel),
                  style: jxTextStyle.textStyle17(color: ImColor.accentColor),
                ),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildSelectTypeButton({required String name, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: OverlayEffect(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: JXColors.borderPrimaryColor,
                width: 0.33,
              ),
            ),
          ),
          height: 56,
          alignment: Alignment.center,
          child: Text(
            name,
            style: jxTextStyle.textStyle17(color: accentColor),
          ),
        ),
      ),
    );
  }

  _buildFieldHeader({required left, right}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ImText(
            left,
            fontSize: 13,
            color: JXColors.secondaryTextBlack,
          ),
          if (right != null)
            ImText(
              right,
              fontSize: 13,
              color: JXColors.hintColor,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commonInputBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    );

    final hintStyle =
        jxTextStyle.textStyle16(color: JXColors.supportingTextBlack);

    return Scaffold(
      backgroundColor: ImColor.systemBg,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFieldHeader(left: '红包类型'),
                  ImGap.vGap4,
                  GestureDetector(
                    onTap: () {
                      // Logic Red Envelop Type Selection
                      _showShareViewDialog(context);
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: JXColors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           ImText(
                            '红包',
                            // localized(addRecipients),
                            fontSize: ImFontSize.large,
                          ),
                          Row(
                            children: [
                              ImText(
                                controller
                                    .redPacketType.value.name.redPacketName,
                                color: ImColor.black48,
                                fontSize: ImFontSize.large,
                              ),
                              ImGap.hGap8,
                              SvgPicture.asset(
                                "assets/svgs/arrow_right.svg",
                                width: 17,
                                height: 17,
                                colorFilter: ColorFilter.mode(
                                    ImColor.black48, BlendMode.srcIn),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  ImGap.vGap24,

                  // >> Currency Type
                  _buildFieldHeader(left: '货币类型'),
                  GestureDetector(
                    onTap: () async {
                      final currencyType = CurrencyALLType.fromValue(
                          controller.selectedCurrency.value.currencyType!);
                      imShowBottomSheet(
                        context,
                        (context) => CurrencySelectionDialog(currencyType),
                      ).then((value) {
                        if (value is CurrencyALLType) {
                          final currencyList = <CurrencyModel>[];
                          currencyList.addAll(controller.cryptoCurrencyList);
                          currencyList.addAll(controller.legalCurrencyList);
                          final selectCurrency = currencyList.firstWhere(
                              (element) => element.currencyType == value.type,
                              orElse: () => controller.selectedCurrency.value);
                          controller.maxTransfer = selectCurrency.amount ?? 0;
                          controller.selectedCurrency.value = selectCurrency;
                        }
                      });
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ImText(
                            localized(currency),
                            color: ImColor.black,
                            fontSize: ImFontSize.large,
                          ),
                          Row(
                            children: [
                              ImText(
                                '${controller.selectedCurrency.value.currencyType}',
                                color: ImColor.black48,
                                fontSize: ImFontSize.large,
                              ),
                              ImGap.hGap8,
                              SvgPicture.asset(
                                "assets/svgs/arrow_right.svg",
                                width: 17,
                                height: 17,
                                colorFilter: ColorFilter.mode(
                                    ImColor.black48, BlendMode.srcIn),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  ImGap.vGap24,

                  // amount
                  ImTextField(
                    inputFormatters:[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    title: controller.redPacketType.value ==
                            RedPacketType.luckyRedPacket
                        ? localized(totalAmount)
                        : localized(amount),
                    controller: controller.amountController,
                    hintText:
                        '请输入，上限${controller.maxTransfer.toDoubleFloor(controller.selectedCurrency.value.getDecimalPoint)}',
                    errorText: controller.amountError.value,
                    showClearButton: false,
                    showTextButton: true,
                    textButtonTitle: '最大',
                    onTapTextButton: () {
                      controller.amountController.text = controller.maxTransfer
                          .toDoubleFloor(controller
                              .selectedCurrency.value.getDecimalPoint);
                    },
                    onTapInput: () {
                      controller.isKeyboardVisible(true);
                      controller.currentKeyboardController(
                          controller.amountController);
                    },
                    onTapClearButton: () {
                      controller.amountController.clear();
                    },
                    onChanged: (String value) {
                      final input = double.tryParse(value);
                      if(input==null){
                        controller.amountController.text="";
                        return;
                      }
                      controller.amountError.value =
                          input > controller.maxTransfer ? '超出最高上限' : '';
                    },
                    descriptionWidget: ImText(
                      '${localized(balance)}: ${controller.maxTransfer.toDoubleFloor(controller.selectedCurrency.value.getDecimalPoint)} ${controller.selectedCurrency.value.currencyType}',
                      fontSize: 13,
                      color: ImColor.orange,
                    ),
                  ),

                  //redPacket piece NEW
                  if (controller.redPacketType.value !=
                      RedPacketType.exclusiveRedPacket) ...[
                    ImGap.vGap24,
                    ImTextField(
                      inputFormatters:[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      title: localized(redPacketNumber),
                      rightTitleWidget: ImText(
                        '群成员：${controller.groupMemberList.length - 1}',
                        fontSize: 13,
                        color: JXColors.hintColor,
                      ),
                      onTapInput: () {
                        controller.isKeyboardVisible(true);
                        controller.currentKeyboardController(
                            controller.quantityController);
                      },
                      controller: controller.quantityController,
                      hintText: '请输入',
                      showClearButton: false,
                      onTapClearButton: () {},
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final quantity =int.tryParse(value);
                          if(quantity==null){
                            controller.quantity.value = 0;
                            return;
                          }
                          controller.quantity.value = quantity;
                        } else {
                          controller.quantity.value = 0;
                        }
                        controller.calculateTotalTransfer();
                      },
                    ),
                  ],

                  // Payee
                  if (controller.redPacketType.value ==
                      RedPacketType.exclusiveRedPacket) ...[
                    ImGap.vGap24,
                    _buildFieldHeader(
                        left: '收款者',
                        right: '群成员：${controller.groupMemberList.length - 1}'),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const AddRecipient());
                      },
                      child: Container(
                        height: 44,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: JXColors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             ImText(
                              '发给谁',
                              // localized(addRecipients),
                              fontSize: ImFontSize.large,
                            ),
                            Row(
                              children: [
                                ImText(
                                  controller.selectedRecipients.length > 0
                                      ? controller.selectedRecipients.length
                                          .toString()
                                      : '选择',
                                  color: ImColor.black48,
                                  fontSize: ImFontSize.large,
                                ),
                                SvgPicture.asset(
                                  "assets/svgs/arrow_right.svg",
                                  width: 17,
                                  height: 17,
                                  colorFilter: ColorFilter.mode(
                                      ImColor.black48, BlendMode.srcIn),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ImGap.vGap24,
                  // Remark New
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ImText(
                          localized(remark),
                          fontSize: 13,
                          color: ImColor.black48,
                        ),
                        ImText(
                          '${controller.remarkRemainLength.value}${localized(charactersLeft)}',
                          fontSize: 13,
                          color: JXColors.hintColor,
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    contextMenuBuilder: textMenuBar,
                    controller: controller.commentController,
                    maxLines: null,
                    buildCounter: (
                      BuildContext context, {
                      required int currentLength,
                      required int? maxLength,
                      required bool isFocused,
                    }) {
                      return null;
                    },
                    maxLength: 30,
                    inputFormatters: [
                      ChineseCharacterInputFormatter(max: 30),
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: localized(enterRemark),
                      hintStyle: hintStyle,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: commonInputBorder,
                      focusedBorder: commonInputBorder,
                      focusedErrorBorder: commonInputBorder.copyWith(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                    onChanged: (value) {
                      controller.remarkRemainLength.value = 30 - value.length;
                    },
                    onTap: (){
                      controller.isKeyboardVisible.value=false;
                    },
                  ),
                  ImGap.vGap24,
                  GestureDetector(
                    onTap: controller.isEnableNext()
                        ? () {
                            controller.navigateConfirmPage(context);
                          }
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          color: controller.isEnableNext()
                              ? ImColor.accentColor
                              : ImColor.black6,
                          borderRadius: ImBorderRadius.borderRadius12),
                      alignment: Alignment.center,
                      child: ImText('发送红包',
                          color: controller.isEnableNext()
                              ? ImColor.white
                              : ImColor.black48,
                          fontSize: ImFontSize.large,
                          fontWeight: MFontWeight.bold6.value),
                    ),
                  ),

                  ImGap.vGap24,
                ],
              ),
            ),
            if (controller.isKeyboardVisible.value)
              KeyboardNumber(
                controller: controller.currentKeyboardController.value,
                showTopButtons: true,
                onTap: (value) {
                  final currentKBController =
                      controller.currentKeyboardController.value;
                  if (currentKBController == controller.amountController) {
                    final amountText = currentKBController.text;
                   dynamic input;
                    if (amountText.isNotEmpty) {
                      input = double.tryParse(amountText);
                      if(input==null){
                        controller.amountController.text="";
                        return;
                      }
                      controller.amountError.value =
                      input > controller.maxTransfer ? '超出最高上限' : '';
                    }
                  }

                  if (currentKBController == controller.quantityController) {
                    final quantityText = currentKBController.text;
                     dynamic input ;
                    if (quantityText.isNotEmpty) {
                      input = int.tryParse(quantityText);
                      if(input==null){
                        controller.quantityController.text="";
                        return;
                      }
                    }
                    controller.quantity.value = input;
                    controller.calculateTotalTransfer();
                  }
                },
                onTapCancel: () => controller.setKeyboardState(false),
                onTapConfirm: () => controller.setKeyboardState(false),
              )
          ],
        ),
      ),
    );
  }
}
