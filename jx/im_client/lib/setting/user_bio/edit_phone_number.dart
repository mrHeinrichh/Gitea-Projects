import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_calendar_date_picker2/widgets/click_effect_button.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/login/components/country_picker.dart';

class EditPhoneNumber extends GetView<UserBioController> {
  const EditPhoneNumber({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserBioController>();
    controller.phoneController.clear();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(phoneNumber),
        trailing: [
          Obx(
            () => Visibility(
              visible: !controller.existingNumber.value &&
                  !controller.numberLengthError.value &&
                  !controller.wrongPhone.value,
              child: GestureDetector(
                onTap: () async {
                  await controller.editPhone();
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    child: Text(
                      localized(buttonDone),
                      style: jxTextStyle.textStyle17(
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        onPressedBackBtn: objectMgr.loginMgr.isDesktop
            ? () {
                Get.back(id: 3);
              }
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// phone prefix
            Container(
              decoration: BoxDecoration(
                color: colorSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        barrierColor: colorOverlay40,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            topLeft: Radius.circular(12),
                          ),
                        ),
                        builder: (context) {
                          return CountryPicker(
                            countryController: controller.countryController,
                            searchCountry: controller.searchCountry,
                            selectCountry: controller.selectCountry,
                            updatedCountryList: controller.updatedCountryList,
                          );
                        },
                      );
                    },
                    child: ForegroundOverlayEffect(
                      radius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(
                          () => Row(
                            children: [
                              if (!controller.isNotCountryAvailable.value)
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Image.asset(
                                    controller.country.value!.flagUri!,
                                    package: 'country_list_pick',
                                    width: 40,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  controller.isNotCountryAvailable.value
                                      ? localized(loginSelectCountry)
                                      : !controller.isEnglish
                                          ? controller.country.value?.zhName ??
                                              ''
                                          : controller.country.value?.name ??
                                              '',
                                  textAlign: TextAlign.start,
                                  style: jxTextStyle.titleSmallText(
                                    color: themeColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const CustomImage(
                                'assets/svgs/wide_arrow_down.svg',
                                size: 24,
                                color: colorTextPrimary,
                                padding: EdgeInsets.only(left: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: CustomDivider(),
                  ),

                  /// phone number
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 5),
                        child: SizedBox(
                          width: 40,
                          child: TextFormField(
                            contextMenuBuilder: im.textMenuBar,
                            focusNode: controller.countryCodeNode,
                            controller: controller.codeController,
                            onChanged: (code) =>
                                controller.checkCountryCode(code),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.center,
                            cursorColor: themeColor,
                            cursorRadius: const Radius.circular(1),
                            cursorWidth: 2,
                            style: jxTextStyle.headerText(color: themeColor),
                            keyboardType:
                                const TextInputType.numberWithOptions(),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+]')),
                              PlusSignInputFormatter()
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 22,
                        margin: const EdgeInsets.only(right: 12),
                        width: 1,
                        color: colorDivider,
                      ),
                      Expanded(
                          child: GetBuilder<UserBioController>(
                              id: 'phone',
                              builder: (logic) {
                                return TextField(
                                  contextMenuBuilder: im.textMenuBar,
                                  controller: controller.phoneController,
                                  onChanged: (phoneNumber) =>
                                      controller.checkPhoneNumber(phoneNumber),
                                  decoration: InputDecoration(
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: controller.initialCountryData
                                        ?.phoneMaskWithoutCountryCode,
                                    hintStyle: jxTextStyle.headerText(
                                      color: colorTextPlaceholder,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => controller.clearText(),
                                      behavior: HitTestBehavior.opaque,
                                      child: Obx(
                                        () => Visibility(
                                          visible:
                                              controller.showClearBtn.value,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/svgs/clear_icon.svg',
                                              color: colorTextSecondary,
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.fitWidth,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  cursorColor: themeColor,
                                  style: jxTextStyle.headerText(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    PhoneInputFormatter(
                                      allowEndlessPhone: true,
                                      shouldCorrectNumber: false,
                                      defaultCountryCode: controller
                                          .initialCountryData?.countryCode,
                                    ),
                                  ],
                                );
                              }))
                    ],
                  ),
                ],
              ),
            ),

            /// error text
            Obx(
              () => Visibility(
                visible: controller.existingNumber.value ||
                    controller.wrongPhone.value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                  child: Text(
                    controller.existingNumber.value
                        ? localized(homePhoneUsedTile)
                        : localized(homeWrongPhoneNumTile),
                    style: jxTextStyle.normalSmallText(color: colorRed),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8),
              child: Text(
                localized(aOtpWillBeSent),
                style: jxTextStyle.normalSmallText(color: colorTextLevelTwo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
