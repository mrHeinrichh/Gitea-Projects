import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';
import 'package:jxim_client/views/wallet/controller/add_address_controller.dart';

import '../../main.dart';
import '../../managers/call_mgr.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';

class AddAddressView extends GetView<AddAddressController> {
  const AddAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.canExit) {
          return true;
        } else {
          controller.showLeavePrompt(context);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          title: localized(
              controller.isEdit ? walletEditAddress : walletAddAddress),
          onPressedBackBtn: () {
            if (controller.canExit) {
              Get.back();
            } else {
              controller.showLeavePrompt(context);
            }
          },
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
                      Text(
                        localized(walletAddressRemark),
                        style: const TextStyle(
                          color: JXColors.secondaryTextBlack,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: JXColors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(
                          child: TextField(
                            contextMenuBuilder: textMenuBar,
                            textInputAction: TextInputAction.done,
                            controller: controller.addressNameController,
                            onChanged: (value) {
                              controller.getNameWordCount();
                            },
                            inputFormatters: [
                              ChineseCharacterInputFormatter(max: 30),
                            ],
                            style: const TextStyle(fontSize: 16),
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
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: localized(walletAddressRemarkHint),
                              hintStyle: const TextStyle(
                                color: JXColors.supportingTextBlack,
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(maxHeight: 48),
                              suffixIcon: Obx(
                                () => Text(
                                  '${controller.nameWordCount.value}',
                                  style: TextStyle(
                                    color: JXColors.supportingTextBlack,
                                    fontWeight:MFontWeight.bold4.value,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        localized(walletCryptoCurrency),
                        style: const TextStyle(
                          color: JXColors.secondaryTextBlack,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      GestureDetector(
                        onTap: controller.isEdit
                            ? null
                            : () {
                                Get.toNamed(
                                    RouteName.addAddressSelectCryptoView);
                              },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            right: 12,
                            top: 4.0,
                            bottom: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: JXColors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Obx(
                            () => Row(
                              children: <Widget>[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Image.network(
                                    controller
                                        .selectedCurrencyModel.value.iconPath!,
                                    width: 40.0,
                                    height: 40.0,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    controller.selectedCurrencyModel.value
                                        .currencyType!,
                                    style: TextStyle(
                                      color: JXColors.black,
                                      fontSize: 16.0,
                                      fontWeight:MFontWeight.bold4.value,
                                    ),
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/svgs/wallet/arrow_right.svg',
                                  width: 20,
                                  height: 20,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        localized(walletChain),
                        style: const TextStyle(
                          color: JXColors.secondaryTextBlack,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 40.0,
                        child: Obx(
                          () => ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.selectedCurrencyModel.value
                                .supportNetType?.length,
                            itemBuilder: (BuildContext context, int index) {
                              final type = controller.selectedCurrencyModel
                                  .value.supportNetType?[index];
                              if (controller.isEdit) {
                                if (type != controller.addressModel?.netType) {
                                  return Container();
                                }
                              }
                              return Obx(
                                () => GestureDetector(
                                  onTap: controller.isEdit
                                      ? null
                                      : () => controller.selectChain(type),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 16.0),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          controller.selectedChain.value == type
                                              ? accentColor
                                              : JXColors.outlineColor,
                                      borderRadius:
                                          BorderRadius.circular(1000000),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: controller.selectedChain.value ==
                                                type
                                            ? JXColors.white
                                            : JXColors.secondaryTextBlack,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localized(walletAddress),
                            style: const TextStyle(
                              color: JXColors.secondaryTextBlack,
                              fontSize: 14.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.isEdit
                                ? null
                                : () async {
                              if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
                                Toast.showToast(localized(toastEndCallFirst));
                                return;
                              }
                                    final result = await Get.toNamed(
                                        RouteName.walletQRCodeScanner);
                                    if (result != null) {
                                      controller.addressController.text =
                                          result;
                                    }
                                  },
                            child: SvgPicture.asset(
                              'assets/images/common/qr_code.svg',
                              width: 20,
                              height: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          // vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: JXColors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: TextFormField(
                            contextMenuBuilder: textMenuBar,
                            readOnly: controller.isEdit,
                            textInputAction: TextInputAction.done,
                            controller: controller.addressController,
                            style: TextStyle(
                              fontSize: 16,
                              color: controller.isEdit
                                  ? JXColors.supportingTextBlack
                                  : JXColors.primaryTextBlack,
                            ),
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: localized(walletAddressHint),
                              hintStyle: const TextStyle(
                                color: JXColors.supportingTextBlack,
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(maxHeight: 62),
                              suffixIcon: Obx(
                                () => Visibility(
                                  visible: !controller.isEdit,
                                  child: GestureDetector(
                                    onTap: controller.isEdit
                                        ? null
                                        : () async {
                                            if (controller.addressTextLength >
                                                0) {
                                              controller.addressController
                                                  .clear();
                                              return;
                                            }

                                            final clipboardData =
                                                await Clipboard.getData(
                                                    Clipboard.kTextPlain);
                                            if (clipboardData != null) {
                                              controller.addressController
                                                  .text = clipboardData.text!;
                                              controller.getCanAdd();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            }
                                          },
                                    child: controller.addressTextLength > 0
                                        ? SvgPicture.asset(
                                            'assets/svgs/wallet/close.svg',
                                            width: 20,
                                            height: 20,
                                            color: JXColors.supportingTextBlack,
                                          )
                                        : Text(
                                            localized(withdrawPaste),
                                            style: jxTextStyle.textStyleBold14(
                                                color: accentColor),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Obx(
                () => FullScreenWidthButton(
                  title: localized(controller.isEdit ? saveButton : buttonAdd),
                  buttonColor: controller.canAdd.value
                      ? accentColor
                      : JXColors.darkGrey,
                  onTap: controller.isEdit
                      ? () => controller.editRecipientAddress()
                      : controller.canAdd.value
                          ? () => controller.addRecipient()
                          : null,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
