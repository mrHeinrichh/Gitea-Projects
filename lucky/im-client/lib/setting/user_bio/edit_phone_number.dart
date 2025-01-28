import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../utils/color.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../views/login/components/country_picker.dart';
import '../../views/login/components/phone_text_field.dart';

class EditPhoneNumber extends GetView<UserBioController> {
  const EditPhoneNumber({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserBioController>();
    controller.phoneController.clear();

    return Scaffold(
      backgroundColor: backgroundColor,
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
                      style: jxTextStyle.textStyle14(
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
        onPressedBackBtn: objectMgr.loginMgr.isDesktop ? (){
          Get.back(id: 3);
        }
            : null,
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// phone prefix
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        border: Border.all(
                          color: Colors.white,
                        ),
                      ),
                      child: Obx(
                        () => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1),
                                ),
                                child: Image.asset(
                                  controller.country.value!.flagUri!,
                                  package: 'country_list_pick',
                                  width: 40,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  textAlign: TextAlign.start,
                                  controller.country.value!.name!,
                                  style: jxTextStyle.textStyle16(),
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                textAlign: TextAlign.center,
                                controller.country.value!.dialCode!,
                                style: jxTextStyle.textStyle16(),
                              ),
                              SvgPicture.asset(
                                'assets/svgs/arrow_right.svg',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// phone number
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12),
                      ),
                      border: Border.all(
                        color: Colors.white,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    child: Center(
                      child: Obx(
                        () => PhoneTextField(
                          textEditingController: controller.phoneController,
                          onChanged: (phoneNumber) =>
                              controller.checkPhoneNumber(phoneNumber),
                          trailingWidget: controller.checkingPhoneNumber.value
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: BallCircleLoading(
                                    radius: 8,
                                    ballStyle: BallStyle(
                                      size: 4,
                                      color: accentColor,
                                      ballType: BallType.solid,
                                      borderWidth: 1,
                                      borderColor: accentColor,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          hintText: localized(newPhoneNumber),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              /// error text
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    controller.existingNumber.value
                        ? '\t${localized(homePhoneUsedTile)}'
                        : (controller.wrongPhone.value
                            ? '\t${localized(homeWrongPhoneNumTile)}'
                            : ' '),
                    style: jxTextStyle.textStyle12(color: errorColor),
                  ),
                ),
              ),

              Text(
                localized(aOtpWillBeSent),
                style:
                    jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
