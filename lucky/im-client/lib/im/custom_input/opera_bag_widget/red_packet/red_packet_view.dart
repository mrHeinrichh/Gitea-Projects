import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_currency_modal_bottom_sheet.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/add_recipient.dart';

class RedPacketView extends GetView<RedPacketController> {
  RedPacketView({Key? key, required this.redPacketType}) : super(key: key) {
    controller.redPacketType.value = redPacketType;
    controller.toSpecificTab();
  }

  final RedPacketType redPacketType;

  @override
  Widget build(BuildContext context) {
    int numberLeft = 30;

    final commonInputBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    );

    final hintStyle =
        jxTextStyle.textStyle16(color: JXColors.supportingTextBlack);

    return Obx(
      () => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: false,
          appBar: PrimaryAppBar(
            bgColor: Colors.transparent,
            title: localized(sendRedPacket),
            onPressedBackBtn: () {
              Get.back();
              controller.clearData();
            },
          ),
          body: WillPopScope(
            onWillPop: () async {
              controller.clearData();
              return true;
            },
            child: SafeArea(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // TabBar NEED To Remove
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              width: 0.5, color: JXColors.outlineColor),
                        ),
                      ),
                      child: TabBar(
                        labelColor: controller.themedColor.value,
                        controller: controller.tabController,
                        indicatorColor: controller.themedColor.value,
                        unselectedLabelColor: JXColors.secondaryTextBlack,
                        labelPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        labelStyle: jxTextStyle.textStyle14(),
                        unselectedLabelStyle: jxTextStyle.textStyle14(),
                        isScrollable: false,
                        tabs: [
                          Text(
                            localized(lucky),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localized(normal),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            localized(exclusive),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        onTap: (index) {},
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            /// currency and amount
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // >> Red Envelop Type
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: ImText('红包类型',
                                            fontSize: 13,
                                            color: JXColors.secondaryTextBlack),
                                      ),
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
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                               ImText(
                                                '红包',
                                                // localized(addRecipients),
                                                fontSize: ImFontSize.large,
                                              ),
                                              Row(
                                                children: [
                                                  ImText(
                                                    controller.redPacketType.value.name.redPacketName,
                                                    color: ImColor.black48,
                                                    fontSize: ImFontSize.large,
                                                  ),
                                                  ImGap.hGap8,
                                                  SvgPicture.asset(
                                                    "assets/svgs/arrow_right.svg",
                                                    width: 17,
                                                    height: 17,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            ImColor.black48,
                                                            BlendMode.srcIn),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),

                                  ImGap.vGap24,

                                  // >> Currency Type
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16),
                                        child: Text(
                                          localized(currency),
                                          style: jxTextStyle.textStyle14(
                                              color:
                                                  JXColors.secondaryTextBlack),
                                        ),
                                      ),
                                      ImGap.vGap4,
                                      GestureDetector(
                                        onTap: () async {
                                          final data =
                                              await showModalBottomSheet(
                                            isScrollControlled: true,
                                            backgroundColor: JXColors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                              ),
                                            ),
                                            context: context,
                                            builder: (context) {
                                              return const RedPacketCurrencyModalBottomSheet();
                                            },
                                          );
                                          if (data != null) {
                                            controller
                                                .selectSelectedCurrency(data);
                                          }
                                          controller.submitCrypto('');
                                        },
                                        child: Container(
                                          height: 44,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              ImText(
                                                '币种',
                                                color: ImColor.black,
                                                fontSize: ImFontSize.large,
                                              ),
                                              Row(
                                                children: [
                                                  // Image.network(
                                                  //   controller.selectedCurrency.value
                                                  //           .iconPath ??
                                                  //       'https://s2.coinmarketcap.com/static/img/coins/64x64/825.png',
                                                  //   width: 30,
                                                  //   height: 30,
                                                  // ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
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
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            ImColor.black48,
                                                            BlendMode.srcIn),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),

                                  ImGap.vGap24,
                                ],
                              ),
                            ),

                            // >> Total amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    controller.redPacketType.value ==
                                            RedPacketType.luckyRedPacket
                                        ? localized(totalAmount)
                                        : localized(amount),
                                    style: jxTextStyle.textStyle14(
                                        color: JXColors.secondaryTextBlack),
                                  ),
                                ),
                                Container(
                                  height: 44,
                                  child: TextFormField(
                                    contextMenuBuilder: textMenuBar,
                                    textAlign: TextAlign.start,
                                    style: jxTextStyle.textStyle16(
                                        color: JXColors.secondaryTextBlack),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(15),
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,4}')),
                                    ],
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        final maxTransferAmount = double.parse(
                                            controller.getMaxTransferAmount());
                                        final minTransferAmount = double.parse(
                                            controller.getMinTransferAmount());

                                        if (double.parse(value) >
                                            maxTransferAmount) {
                                          return '${localized(maximumTransfer)} ${controller.selectedCurrency.value.currencyType}';
                                        }

                                        if (double.parse(value) <
                                            minTransferAmount) {
                                          return '${localized(minimumTransfer)} ${controller.selectedCurrency.value.currencyType}';
                                        }
                                      }

                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.next,
                                    controller: controller.amountController,
                                    onChanged: controller.calculateGasFee,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      hintText: '请输入，上限10000',
                                      hintStyle: hintStyle,
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                        minHeight: 35,
                                        maxWidth: 65,
                                      ),
                                      suffixIcon: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                // controller.__.clear();
                                              },
                                              behavior: HitTestBehavior.opaque,
                                              child: SvgPicture.asset(
                                                'assets/svgs/clear_icon.svg',
                                                color: JXColors.hintColor,
                                                width: 14,
                                                height: 14,
                                                fit: BoxFit.scaleDown,
                                              ),
                                            ),
                                            ImGap.hGap4,
                                            GestureDetector(
                                              onTap: () {
                                                controller.makeMaxAmount();
                                              },
                                              child: ImText(
                                                '最大',
                                                // localized(MAX),
                                                fontSize: ImFontSize.large,
                                                color: accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      enabledBorder: commonInputBorder,
                                      focusedBorder: commonInputBorder,
                                      focusedErrorBorder:
                                          commonInputBorder.copyWith(
                                              borderSide: BorderSide(
                                                  color: errorColor)),
                                      errorBorder: commonInputBorder.copyWith(
                                          borderSide:
                                              BorderSide(color: errorColor)),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, top: 4),
                                  child: ImText(
                                    '超出最高上限',
                                    fontSize: 13,
                                    color: JXColors.red,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 16, top: 4),
                                  child: ImText(
                                    '${localized(balance)}: ${controller.maxTransfer.toDoubleFloor(controller.selectedCurrency.value.getDecimalPoint)} ${controller.selectedCurrency.value.currencyType}',
                                    fontSize: 13,
                                    color: JXColors.brightOrange,
                                  ),
                                ),
                              ],
                            ),

                            ImGap.vGap24,

                            /// redPacket piece
                            if (controller.redPacketType.value !=
                                RedPacketType.exclusiveRedPacket)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ImText(
                                          localized(redPacketNumber),
                                          fontSize: 13,
                                          color: JXColors.secondaryTextBlack,
                                        ),
                                        const ImText(
                                          '群成员：6',
                                          fontSize: 13,
                                          color: JXColors.hintColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ImGap.vGap4,
                                  SizedBox(
                                    height: 44,
                                    child: TextFormField(
                                      contextMenuBuilder: textMenuBar,
                                      controller: controller.quantityController,
                                      validator: (value) {
                                        if (value != null &&
                                            value.isNotEmpty &&
                                            double.parse(value) < 1) {
                                          return '${localized(minimumQuantityIs)} 1';
                                        }
                                        if (value != null &&
                                            value.isNotEmpty &&
                                            int.parse(value) >
                                                controller
                                                    .getMaxSplitNumber()) {
                                          return '${localized(maximumQuantityIs)} ${controller.getMaxSplitNumber()}';
                                        }
                                        return null;
                                      },
                                      autovalidateMode: AutovalidateMode.always,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(5),
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*')),
                                      ],
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          controller.quantity.value =
                                              int.parse(value);
                                        } else {
                                          controller.quantity.value = 0;
                                        }
                                        controller.calculateTotalTransfer();
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        isDense: true,
                                        hintText: '请输入',
                                        hintStyle: hintStyle,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                        enabledBorder: commonInputBorder,
                                        focusedBorder: commonInputBorder,
                                        focusedErrorBorder:
                                            commonInputBorder.copyWith(
                                                borderSide: BorderSide(
                                                    color: errorColor)),
                                        errorBorder: commonInputBorder.copyWith(
                                            borderSide:
                                                BorderSide(color: errorColor)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            /// Receipt
                            if (controller.redPacketType.value ==
                                RedPacketType.exclusiveRedPacket)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          localized(recipient),
                                          style: jxTextStyle.textStyle14(
                                              color:
                                                  JXColors.secondaryTextBlack),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                            textAlign: TextAlign.end,
                                            '${localized(numberOfGroupMember)}: ${controller.groupMemberList.length}',
                                            style: jxTextStyle.textStyle12(
                                                color: JXColors
                                                    .secondaryTextBlack)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Get.to(() => const AddRecipient());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14.0,
                                        horizontal: 16,
                                      ),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: const BoxDecoration(
                                        color: JXColors.white,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      child: (controller
                                                  .selectedRecipients.length >
                                              0)
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const AvatarList(),
                                                Text(
                                                    '${controller.selectedRecipients.length} ${localized(people)}'),
                                              ],
                                            )
                                          : Text(
                                              textAlign: TextAlign.center,
                                              localized(addRecipients),
                                              style: jxTextStyle.textStyle14(),
                                            ),
                                    ),
                                  ),
                                ],
                              ),

                            ImGap.vGap24,
                            // Payee
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const ImText('收款者',
                                          //localized(recipient),
                                          fontSize: 13,
                                          color: JXColors.secondaryTextBlack),
                                      ImText(
                                        '群成员：${controller.groupMemberList.length}',
                                        // '${localized(numberOfGroupMember)}: ${controller.groupMemberList.length}',
                                        fontSize: 13,
                                        color: JXColors.hintColor,
                                      )
                                    ],
                                  ),
                                ),
                                ImGap.vGap4,
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
                                    child: (controller
                                                .selectedRecipients.length >
                                            0)
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const AvatarList(),
                                              ImText(
                                                  '${controller.selectedRecipients.length} ${localized(people)}'),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                               ImText(
                                                '发给谁',
                                                // localized(addRecipients),
                                                fontSize: ImFontSize.large,
                                              ),
                                              Row(
                                                children: [
                                                  ImText(
                                                    '选择',
                                                    color: ImColor.black48,
                                                    fontSize: ImFontSize.large,
                                                  ),
                                                  SvgPicture.asset(
                                                    "assets/svgs/arrow_right.svg",
                                                    width: 17,
                                                    height: 17,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            ImColor.black48,
                                                            BlendMode.srcIn),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                  ),
                                )
                              ],
                            ),

                            ImGap.vGap24,

                            /// Remarks
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ImText(localized(remark),
                                          fontSize: 13,
                                          color: JXColors.secondaryTextBlack),
                                      // bool isChinese = controller
                                      //     .commentController
                                      //     .text
                                      //     .isChineseCharacter;
                                      // if (isChinese) {
                                      // currentLength = getMessageLength(
                                      // controller
                                      //     .commentController.text);
                                      // }
                                      // var characterLeft =
                                      // maxLength! - currentLength;
                                      ImText(
                                        '${30 - controller.commentController.text.length}${localized(charactersLeft)}',
                                        fontSize: 12,
                                        color: JXColors.hintColor,
                                      )
                                    ],
                                  ),
                                ),
                                ImGap.vGap4,
                                SizedBox(
                                  height: 44,
                                  child: TextField(
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
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        enabledBorder: commonInputBorder,
                                        focusedBorder: commonInputBorder,
                                        focusedErrorBorder:
                                            commonInputBorder.copyWith(
                                          borderSide:
                                              BorderSide(color: errorColor),
                                        ),
                                      )),
                                ),
                              ],
                            ),
                            ImGap.vGap24,

                            /// Total Amount
                            // Container(
                            //   padding: const EdgeInsets.all(16),
                            //   decoration: const BoxDecoration(
                            //     color: JXColors.outlineColor,
                            //     borderRadius: const BorderRadius.all(
                            //       Radius.circular(10),
                            //     ),
                            //   ),
                            //   width: MediaQuery.of(context).size.width,
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text(
                            //         localized(totalAmount),
                            //       ),
                            //       RichText(
                            //         text: TextSpan(
                            //             text:
                            //                 '${controller.totalTransfer.value.toDoubleFloor(controller.selectedCurrency.value.getDecimalPoint)}',
                            //             style: const TextStyle(
                            //               color: JXColors.primaryTextBlack,
                            //               fontSize: 28,
                            //               fontWeight: MFontWeight.bold5.value,
                            //             ),
                            //             children: <TextSpan>[
                            //               TextSpan(
                            //                 text: " ",
                            //                 style:
                            //                     jxTextStyle.textStyleBold16(),
                            //               ),
                            //               TextSpan(
                            //                 text: controller.selectedCurrency
                            //                     .value.currencyType,
                            //                 style:
                            //                     jxTextStyle.textStyleBold16(),
                            //               ),
                            //             ]),
                            //       ),
                            //     ],
                            //   ),
                            // ),

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
                                    borderRadius:
                                        ImBorderRadius.borderRadius12),
                                alignment: Alignment.center,
                                child: const ImText('发送红包'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  _buildSelectTypeButton(name: localized(lucky), onTap: () {
                    controller.redPacketType.value = RedPacketType.luckyRedPacket;
                    controller.calculateTotalTransfer();
                    Navigator.pop(ctx);
                  }),
                  _buildSelectTypeButton(name: localized(normal), onTap: () {
                    controller.redPacketType.value = RedPacketType.normalRedPacket;
                    controller.calculateTotalTransfer();
                    Navigator.pop(ctx);
                  }),
                  _buildSelectTypeButton(name: localized(exclusive), onTap: () {
                    controller.redPacketType.value = RedPacketType.exclusiveRedPacket;
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
}

class AvatarList extends GetView<RedPacketController> {
  const AvatarList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: controller.selectedRecipients.length <= 5
            ? controller.selectedRecipients.length * 25
            : 5.7 * 25,
        child: Stack(
          children: controller.selectedRecipients.map(
            (element) {
              if (controller.selectedRecipients.indexOf(element) < 1) {
                return CustomAvatar(
                  key: UniqueKey(),
                  uid: element.uid,
                  size: 25,
                  headMin: Config().headMin,
                );
              } else if (controller.selectedRecipients.indexOf(element) < 5) {
                return Positioned(
                  left: 18 *
                      double.parse(controller.selectedRecipients
                          .indexOf(element)
                          .toString()),
                  child: CustomAvatar(
                    key: UniqueKey(),
                    uid: element.uid,
                    size: 25,
                    headMin: Config().headMin,
                  ),
                );
              } else {
                return Positioned(
                  right: 0,
                  child: ImText(
                    '... +${controller.selectedRecipients.length - 5}',
                  ),
                );
              }
            },
          ).toList(),
        ),
      ),
    );
  }
}

extension commentUtils on String {
  static final _chineseCharacterPattern =
      RegExp(r'[\u4E00-\u9FA5\u3000-\u303F\uFF00-\uFFEF\u2000-\u206F]');

  bool get isChineseCharacter {
    return _chineseCharacterPattern.hasMatch(this);
  }
}

class ChineseCharacterInputFormatter extends TextInputFormatter {
  ChineseCharacterInputFormatter({required this.max});

  final max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newCharacters = newValue.text.characters;
    var length = 0;
    String data = '';
    for (var character in newCharacters) {
      if (_isChineseCharacter(character)) {
        length += 2;
      } else {
        length += 1;
      }
      if (length <= max) {
        data = '$data$character';
      }
    }

    if (length > max) {
      oldValue = oldValue.copyWith(
        text: data,
        selection: TextSelection.fromPosition(
          TextPosition(offset: data.length),
        ),
      );
      return oldValue;
    }

    return newValue;
  }

  bool _isChineseCharacter(String character) {
    return character.isChineseCharacter;
  }
}

int getMessageLength(String message) {
  int length = 0;

  for (int i = 0; i < message.length; i++) {
    if (message[i].isChineseCharacter) {
      length += 2;
    } else {
      length += 1;
    }
  }

  return length;
}
