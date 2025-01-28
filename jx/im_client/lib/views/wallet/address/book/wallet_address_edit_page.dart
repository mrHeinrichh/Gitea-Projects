import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_controller.dart';


class WalletAddressEditPage extends GetView<WalletAddressEditController> {
  const WalletAddressEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    var arguments = Get.arguments;
    if (arguments != null) {
      controller.addressLabelController.text = arguments['addrName'] ?? "";
      controller.addressController.text = arguments['address'] ?? "";
    }
    return Obx(
      () => Scaffold(
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: controller.isEditMode
              ? localized(walletEditAddress)
              : localized(walletAddAddress),
        ),
        body: CustomScrollableListView(
          children: [
            getCurrentType(context),
            getAddressField(),
            getCommentField(),
            getBottomButton(context),
          ],
        ),
      ),
    );
  }

  getCurrentType(context) {
    return IgnorePointer(
      ignoring: controller.isEditMode,
      child: CustomRoundContainer(
        title: localized(walletChain),
        child: CustomListTile(
          text: localized(walletTransferNetwork),
          rightText: controller.selectedChain.value,
          // onClick: controller.isEditMode
          //     ? null
          //     : () async => _showWalletAddressEditTypeDialog(context),
        ),
      ),
    );
  }

  getAddressField() {
    return Column(
      children: [
        CustomAddressInput(
          title: localized(addressAddress),
          controller: controller.addressController,
          onChanged: controller.onAddressChanged,
          netType: controller.selectedChain.value,
          onTapClearButton: () {
            controller.onClearAddress();
          },
          withAddressField: false,
          onAddressChanged: (value) {
            controller.onAddressChanged(value);
          },
          isEnabled: !controller.isEditMode,
        ),
        getAddressValidateTip(),
      ],
    );
  }

  getAddressValidateTip() {
    return Obx(
      () {
        bool isFieldEmpty = controller.addressController.text.isEmpty;
        bool isVisible = !controller.isValidateAddress.value && !isFieldEmpty;
        return Visibility(
          visible: isVisible,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0).w,
            child: subtitle(
              title: localized(
                withdrawAddressIsNotValidOrNotMatchTheChain,
              ),
              color: colorRed,
            ),
          ),
        );
      },
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

  getCommentField() {
    controller.getCommentWordCount();
    return Obx(
      () => CustomInput(
        //initialValue: controller.addressName,
        title: localized(walletAddressLabel),
        rightTitle:
            '${controller.labelWordCount.value}${localized(charactersLeft)}',
        controller: controller.addressNameController,
        onChanged: (value) {
          controller.getCommentWordCount();
          controller.onAddressNameChanged(value);
        },
        onTapClearButton: () => controller.getCommentWordCount(),
        keyboardType: TextInputType.text,
        maxLength: 30,
        hintText: localized(walletAddressLabelHint),
        inputFormatters: [
          ChineseCharacterInputFormatter(max: 30),
        ],
      ),
    );
  }

  getBottomButton(BuildContext context) {
    return CustomButton(
      text:
          controller.isEditMode ? localized(saveButton) : localized(buttonAdd),
      isDisabled: !controller.isButtonEnabled.value,
      callBack: () {
        FocusScope.of(context).unfocus();
        controller.isEditMode ? controller.onSave() : controller.onAdd();
      },
    );
  }
}
