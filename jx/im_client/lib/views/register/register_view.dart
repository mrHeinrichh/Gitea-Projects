import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/register/register_controller.dart';

final fieldNameKey = GlobalKey<FormFieldState>();
final fieldUsernameKey = GlobalKey<FormFieldState>();

class NewProfileView extends GetView<NewProfileController> {
  const NewProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    int clickCount = 0;
    int clickTime = 0;

    return WillPopScope(
      onWillPop: () async {
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        if (nowTime - clickTime > 2000) {
          clickCount = 1;
        } else {
          clickCount++;
        }
        clickTime = nowTime;
        if (clickCount == 1) {
          Toast.showToast(localized(toastExit));
          return false;
        }
        clickTime = 0;
        clickCount = 0;
        return true;
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          toolbarHeight: 0.0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              right: 16,
              left: 16,
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ///用户照片
                        Obx(
                          () => ClipRRect(
                            child: AnimatedAlign(
                              curve: Curves.easeInOutCubic,
                              heightFactor: 1,
                              alignment: Alignment.topCenter,
                              duration: kThemeAnimationDuration,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        controller.showPickPhotoOption(context),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 8,
                                      ),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color: themeColor.withOpacity(0.08),
                                      ),
                                      child: controller
                                              .avatarFile.value.path.isEmpty
                                          ? Center(
                                              child: SvgPicture.asset(
                                                'assets/svgs/camera.svg',
                                                width: 50,
                                                height: 50,
                                                color: themeColor,
                                              ),
                                            )
                                          : ClipOval(
                                              child: Image.file(
                                                controller.avatarFile.value,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                  OpacityEffect(
                                    child: GestureDetector(
                                      onTap: () => controller
                                          .showPickPhotoOption(context),
                                      child: Text(
                                        localized(setNewPhoto),
                                        style: jxTextStyle.headerText(
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        ///详情部分
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///name标题
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      localized(userName),
                                      style: jxTextStyle.normalSmallText(
                                        color: colorTextLevelTwo,
                                      ),
                                    ),
                                  ),
                                  Obx(
                                    () => Visibility(
                                      visible: controller.isValidName.value,
                                      child: Icon(
                                        Icons.check,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              ///name输入框
                              RegisterTextField(
                                controller: controller,
                                textController: controller.nameController,
                                textFieldKey: fieldNameKey,
                                hintText: localized(enterName),
                                remainingNum: controller.nameLength,
                                onChanged: (value) {
                                  controller.nameLength.value = 30 -
                                      getMessageLength(
                                        controller.nameController.text,
                                      );
                                  fieldNameKey.currentState!.validate();
                                },
                                validator: (value) {
                                  if (notBlank(value)) {
                                    String text = value!.trim();
                                    if (RegExp(r'^.{1,30}$').hasMatch(text)) {
                                      controller.setNameValidity(true);
                                    } else {
                                      controller.setNameValidity(false);
                                    }
                                  } else {
                                    controller.setNameValidity(false);
                                    return null;
                                  }
                                  return null;
                                },
                                maxLength: 30,
                              ),

                              ///name提示
                              Obx(
                                () {
                                  return Visibility(
                                    visible: !controller.isValidName.value,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        left: 16,
                                      ),
                                      child: Text(
                                          localized(setNameBetween1to30),
                                          style: jxTextStyle.normalSmallText(
                                            color: colorTextLevelTwo,
                                          )),
                                    ),
                                  );
                                },
                              ),

                              ///username标题
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        left: 16,
                                      ),
                                      child: Text(localized(homeUsername),
                                          style: jxTextStyle.normalSmallText(
                                            color: colorTextLevelTwo,
                                          )),
                                    ),
                                    Obx(
                                      () => Visibility(
                                        visible:
                                            controller.isValidUsername.value &&
                                                controller.username.isNotEmpty,
                                        child: Icon(
                                          Icons.check,
                                          color: themeColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ///username输入框
                              RegisterTextField(
                                controller: controller,
                                textController: controller.usernameController,
                                textFieldKey: fieldUsernameKey,
                                hintText: localized(optional),
                                remainingNum: controller.usernameLength,
                                onChanged: (value) {
                                  controller.usernameLength.value = 20 -
                                      getMessageLength(
                                        controller.usernameController.text,
                                      );
                                  fieldUsernameKey.currentState!.validate();
                                },
                                validator: (value) {
                                  if (value!.isNotEmpty) {
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
                                prefixIcon: Obx(
                                  () => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      '@',
                                      style: jxTextStyle.headerText(
                                        color: controller.username.isEmpty
                                            ? colorTextPlaceholder
                                            : colorTextPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                maxLength: 20,
                              ),

                              ///username提示
                              Obx(
                                () {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8, left: 16),
                                    child: Text(
                                      controller.getUsernameErrorMessage(),
                                      style: jxTextStyle.normalSmallText(
                                        color: !controller.isValidUsername.value
                                            ? colorRed
                                            : colorTextLevelTwo,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Obx(
                  () => controller.progressRegister.value
                      ? Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: BallCircleLoading(
                              radius: 10,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 2,
                                borderColor: themeColor,
                              ),
                            ),
                          ),
                        )
                      : CustomButton(
                          text: localized(buttonCreate),
                          isBold: true,
                          isDisabled: !controller.isValidated.value,
                          callBack: () {
                            if (controller.isValidated.value &&
                                !controller.registerComplete.value) {
                              controller.register(context);
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterTextField extends StatelessWidget {
  const RegisterTextField({
    super.key,
    required this.controller,
    required this.textController,
    required this.textFieldKey,
    required this.hintText,
    required this.remainingNum,
    required this.onChanged,
    required this.validator,
    required this.maxLength,
    this.prefixIcon,
  });

  final NewProfileController controller;
  final TextEditingController textController;
  final GlobalKey textFieldKey;
  final String hintText;
  final RxInt remainingNum;
  final Function(String) onChanged;
  final String? Function(String?) validator;
  final int maxLength;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        contextMenuBuilder: im.textMenuBar,
        autofocus: true,
        cursorColor: themeColor,
        key: textFieldKey,
        controller: textController,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        decoration: InputDecoration(
          fillColor: colorSurface,
          filled: true,
          contentPadding: const EdgeInsets.fromLTRB(16, 18, 10, 0),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: colorSurface, width: 1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: colorSurface, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(
            maxWidth: 35,
          ),
          suffixIcon: Center(
            child: Obx(
              () => Text(
                '${remainingNum.value}',
                style: jxTextStyle.supportText(
                  color: colorTextSupporting,
                ),
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            maxWidth: 50,
          ),
          hintText: hintText,
          hintStyle: jxTextStyle.headerText(color: colorTextPlaceholder),
        ),
        onChanged: onChanged,
        validator: validator,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (maxLength - getMessageLength(newValue.text) >= 0) {
              return newValue;
            } else {
              return oldValue;
            }
          }),
        ],
      ),
    );
  }
}
