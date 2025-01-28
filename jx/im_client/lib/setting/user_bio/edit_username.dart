import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class EditUsername extends GetView<UserBioController> {
  const EditUsername({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameField = GlobalKey<FormFieldState>();
    final UserBioController controller = Get.find<UserBioController>();

    /// get Current User info
    // controller.getCurrentUser();

    /// initialize username availability
    controller.isInitialUsername();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(homeChangeUsername),
        trailing: [
          Obx(
            () => Visibility(
              visible: controller.usernameValidated.value,
              child: GestureDetector(
                onTap: () {
                  if (controller.usernameValidated.value) {
                    controller.changeUsername();
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    child: Text(
                      localized(buttonDone),
                      style: jxTextStyle.textStyle17(color: themeColor),
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
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localized(homeUsername),
                    style: jxTextStyle.normalSmallText(
                      color: colorTextLevelTwo,
                    ),
                  ),
                  Obx(() {
                    return Text(
                      '${controller.usernameWordCount.value}${localized(charactersLeft)}',
                      style: jxTextStyle.supportText(
                        color: colorTextPlaceholder,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: colorSurface,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: TextFormField(
                contextMenuBuilder: im.textMenuBar,
                key: usernameField,
                controller: controller.usernameController,
                cursorColor: colorTextPrimary,
                style: jxTextStyle.headerText(),
                maxLines: 1,
                maxLength: 20,
                buildCounter: (
                  BuildContext context, {
                  required int currentLength,
                  required int? maxLength,
                  required bool isFocused,
                }) {
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '@',
                      style: jxTextStyle.headerText(
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minHeight: 0),
                  suffixIconConstraints: const BoxConstraints(minHeight: 0),
                  suffixIcon: Visibility(
                    visible: controller.usernameController.text.isNotEmpty,
                    child: GestureDetector(
                      onTap: () {
                        controller.getUsernameWordCount('');
                        controller.usernameController.text = '';
                        usernameField.currentState?.validate();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SvgPicture.asset(
                          'assets/svgs/close_round_icon.svg',
                          width: 20,
                          height: 20,
                          color: colorTextSupporting,
                        ),
                      ),
                    ),
                  ),
                ),
                onChanged: (value) {
                  controller.getUsernameWordCount(value);
                  if (value != controller.meUser.value?.username) {
                    controller.updatedUsername.value = value;
                    controller.checkUsernameAvailability(value);
                    usernameField.currentState?.validate();
                  } else {
                    controller.isInitialUsername();
                  }
                },
                validator: (value) {
                  if (value!.isNotEmpty) {
                    ///https://regex101.com/r/Ly1nmz/1
                    // r'^(?=[\w]{6,19}$)(?=.*?^[a-zA-Z])(?!.*_.*_)(?!.*_$)'
                    if (RegExp(
                      r'^(?=[\w]{6,19}$)(?=.*?^[a-zA-Z0-9])(?!.*_.*_)',
                    ).hasMatch(value)) {
                      controller.setUsernameValidity(true);
                    }
                    controller.usernameErrorDecider(value);
                  } else {
                    controller.setUsernameValidity(false);
                  }
                  return null;
                },
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.usernameValidated.value ||
                    controller.usernameError.value,
                child: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: controller.usernameValidated.value
                        ? Text(
                            "\t${localized(userUsernameAvailable)}",
                            style: jxTextStyle.normalText(
                              color: Colors.green,
                            ),
                          )
                        : Text(
                            "\t${localized(userUsernameTaken)}",
                            style: jxTextStyle.normalText(color: Colors.red),
                          )),
              ),
            ),
            Obx(
              () => Container(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: controller.usernameLength.value
                                ? themeColor
                                : Colors.grey,
                          ),
                          SizedBox(
                            width: 5.w,
                          ),
                          Expanded(
                            child: Text(
                              localized(homeChangeUsernameValidChar),
                              style: jxTextStyle.headerSmallText(
                                color: colorTextLevelTwo,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: controller.usernameFormat.value
                                ? themeColor
                                : Colors.grey,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              localized(homeChangeUsernameValidOnly),
                              style: jxTextStyle.headerSmallText(
                                color: colorTextLevelTwo,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: controller.usernameUnderscore.value
                                ? themeColor
                                : Colors.grey,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              localized(homeChangeUsernameValidNorStart),
                              style: jxTextStyle.headerSmallText(
                                color: colorTextLevelTwo,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
