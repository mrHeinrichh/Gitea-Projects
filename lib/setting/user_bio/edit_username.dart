import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:get/get.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                border: Border.all(
                  color: const Color(0xFFE9E9EB),
                ),
              ),
              child: Obx(
                () => TextFormField(
                  contextMenuBuilder: textMenuBar,
                  key: usernameField,
                  controller: controller.usernameController,
                  cursorColor: Colors.black,
                  textAlignVertical: TextAlignVertical.center,
                  style: jxTextStyle.textStyle16(),
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
                        style: jxTextStyle.textStyle16(
                          color: colorTextSupporting,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minHeight: 0),
                    suffixIconConstraints: const BoxConstraints(minHeight: 0),
                    suffixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${controller.usernameWordCount.value}',
                        style: jxTextStyle.textStyleBold12(
                          color: colorTextSupporting,
                        ),
                        textAlign: TextAlign.center,
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
            ),
            Obx(
              () => Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 15.h),
                child: controller.usernameValidated.value
                    ? Text(
                        "\t${localized(userUsernameAvailable)}",
                        style: jxTextStyle.normalText(
                            color: Colors.green,
                            fontWeight: MFontWeight.bold5.value),
                      )
                    : controller.usernameError.value
                        ? Text(
                            "\t${localized(userUsernameTaken)}",
                            style: jxTextStyle.normalText(
                                color: Colors.red,
                                fontWeight: MFontWeight.bold5.value),
                          )
                        : Text(
                            " ",
                            style: jxTextStyle.normalText(),
                          ),
              ),
            ),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          SizedBox(
                            width: 5.w,
                          ),
                          Expanded(
                            child: Text(
                              localized(homeChangeUsernameValidOnly),
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
                          SizedBox(
                            width: 5.w,
                          ),
                          Expanded(
                            child: Text(
                              localized(homeChangeUsernameValidNorStart),
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
