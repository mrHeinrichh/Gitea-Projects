import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart'  as common;
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_font_size.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/border_container.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_controller.dart';

class WalletAddressEditPage extends GetView<WalletAddressEditController> {
  const WalletAddressEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          title: controller.isEditMode ? '编辑地址' : '添加地址',
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getTitle(leftTitle: '链名称'),
                getCurrentType(context),
                ImGap.vGap(24),
                getTitle(leftTitle: '地址'),
                listItem(
                  leadingWidget: Expanded(
                    child: IgnorePointer(
                      ignoring: controller.isEditMode,
                      child: TextFormField(
                        controller: controller.addressController,
                        contextMenuBuilder: common.textMenuBar,
                        cursorColor: accentColor,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontSize: 16.sp),
                        maxLines: 2,
                        minLines: 1,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '长按粘贴',
                          hintStyle: TextStyle(
                            color: JXColors.supportingTextBlack,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: controller.onAddressChanged,
                      ),
                    ),
                  ),
                  rightWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Get.find<ChatListController>().scanQRCode(
                              didGetText: (text) {
                            controller.onAddressChanged(text);
                            controller.addressController.text = text;
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
                ),
                ImGap.vGap(24),
                getTitle(leftTitle: '地址标签', rightTitle: '30字剩余'),
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
                    child: TextFormField(
                      initialValue: controller.addressName,
                      contextMenuBuilder: common.textMenuBar,
                      cursorColor: accentColor,
                      textInputAction: TextInputAction.done,
                      onChanged: controller.onAddressNameChanged,
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
                        hintText: '请输入地址标签',
                        //localized(withdrawCommentsHint),
                        hintStyle: TextStyle(
                          color: JXColors.supportingTextBlack,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                ImGap.vGap(24),
                PrimaryButton(
                  title: controller.isEditMode ? '保存' : '添加',
                  width: double.infinity,
                  disabled: !controller.isButtonEnabled.value,
                  txtColor: Colors.white,
                  bgColor: accentColor,
                  disabledTxtColor: JXColors.black24,
                  disabledBgColor: JXColors.bgTertiaryColor,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    controller.isEditMode
                        ? controller.onSave()
                        : controller.onAdd();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getTitle({leftTitle, rightTitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            leftTitle,
            style: jxTextStyle.textStyle14(
              color: JXColors.secondaryTextBlack,
            ),
          ),
          if (rightTitle != null)
            Text(
              rightTitle,
              style: jxTextStyle.textStyle13(
                color: JXColors.hintColor,
              ),
            ),
        ],
      ),
    );
  }

  getCurrentType(context) {
    return IgnorePointer(
      ignoring: controller.isEditMode,
      child: GestureDetector(
        onTap: () {
          createBottomSheet(context);
        },
        child: Container(
          height: 44.w,
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: JXColors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              const Expanded(
                  child: Text(
                '转账网络',
                style: const TextStyle(
                  color: JXColors.black,
                  fontSize: 16.0,
                ),
              )),
              Text(
                controller.selectedChain.value,
                style: const TextStyle(
                  color: JXColors.secondaryTextBlack,
                  fontSize: 16.0,
                ),
              ),
              ImGap.hGap8,
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
    );
  }

  listItem(
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
                      const ColorFilter.mode(JXColors.black48, BlendMode.srcIn),
                )
            ],
          )),
    );
  }

  createBottomSheet(context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return const WalletEditAddressType();
      },
    );
  }
}

class WalletEditAddressType extends GetView<WalletAddressEditController> {
  const WalletEditAddressType({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 260.w,
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              height: 60.w,
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 0.0,
              ),
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
                              style:
                                  jxTextStyle.textStyle17(color: accentColor)),
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
                        controller
                            .changeNetwork(controller.preselectedChain.value);
                        Navigator.pop(context);
                      },
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(localized(buttonDone),
                              style:
                                  jxTextStyle.textStyle17(color: accentColor)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ImGap.vGap24,
            Container(
                margin: const EdgeInsets.only(left: 32, bottom: 8).w,
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
                itemCount:
                    controller.cryptoCurrencyList[0].supportNetType?.length,
                itemBuilder: (BuildContext context, int index) {
                  final type =
                      controller.cryptoCurrencyList[0].supportNetType?[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => controller.changePreselectedNetWork(type),
                        child: Container(
                          height: 44.w,
                          color: Colors.transparent, //不可拿掉,會影響點擊熱區
                          padding: const EdgeInsets.only(
                                  left: 16, top: 11, bottom: 11)
                              .w,
                          child: Obx(() => Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.only(right: 16).w,
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
                      if (controller.cryptoCurrencyList[0].supportNetType!
                                  .length -
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
        ));
  }
}
