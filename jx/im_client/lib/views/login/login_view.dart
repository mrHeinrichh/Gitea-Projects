import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/setting/network_diagnose/network_diagnose_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/floating/floating.dart';
import 'package:jxim_client/views/login/components/country_picker.dart';
import 'package:jxim_client/views/login/components/email_text_field.dart';
import 'package:jxim_client/views/login/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.phoneFocusNode.unfocus();
        controller.emailFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: colorWhite,
        body: Padding(
          padding: EdgeInsets.only(
            top: 44,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  controller: controller.scrollController,
                  child: Column(
                    children: <Widget>[
                      _buildLoginLogoSelection(context),
                      const SizedBox(height: 18),
                      Obx(
                        () => AnimatedCrossFade(
                          duration: const Duration(milliseconds: 150),
                          crossFadeState:
                              controller.selectMode.value == PHONE_NUMBER
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                          firstChild: _buildPhoneView(context),
                          secondChild: _buildEmailView(),
                        ),
                      ),
                      _buildTermServiceView(),
                    ],
                  ),
                ),
              ),
              Obx(
                () => CustomButton(
                  text: localized(continueProcessing),
                  isLoading: controller.isLoading.value,
                  isDisabled: !controller.validInformation.value ||
                      controller.isDiagnosing.value,
                  callBack: controller.successVerification,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLogoSelection(BuildContext context) {
    return Obx(
      () => TweenAnimationBuilder(
          tween: controller.selectMode.value == PHONE_NUMBER
              ? Tween<double>(begin: 1, end: 0)
              : Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 150),
          builder: (_, double anim, __) {
            return Column(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    if (details.primaryDelta! < -10 &&
                        controller.selectMode.value != EMAIL_ADDRESS) {
                      controller.selectMode.value = EMAIL_ADDRESS;
                      controller.checkEmailFormat('');
                      controller.phoneController.clear();
                      controller.isCheckTermService.value = false;
                      controller.emailFocusNode.requestFocus();
                      controller.diagnoseStatus.value = 0;
                    }
                    if (details.primaryDelta! > 10 &&
                        controller.selectMode.value != PHONE_NUMBER) {
                      controller.selectMode.value = PHONE_NUMBER;
                      controller.checkPhoneNumber('');
                      controller.emailController.clear();
                      controller.isCheckTermService.value = false;
                      controller.phoneFocusNode.requestFocus();
                      controller.diagnoseStatus.value = 0;
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 40.0),
                    padding: const EdgeInsets.symmetric(horizontal: 47.0),
                    height: 85,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            if (controller.selectMode.value != PHONE_NUMBER) {
                              controller.selectMode.value = PHONE_NUMBER;
                              controller.checkPhoneNumber('');
                              controller.emailController.clear();
                              controller.isCheckTermService.value = false;
                              controller.diagnoseStatus.value = 0;
                            }
                          },
                          child: AnimatedAlign(
                            alignment:
                                controller.selectMode.value == PHONE_NUMBER
                                    ? Alignment.center
                                    : Alignment.centerLeft,
                            duration: const Duration(milliseconds: 150),
                            child: Opacity(
                              opacity: 1 - (0.44 * anim),
                              child: Image.asset(
                                'assets/images/login_phone.png',
                                height: 84 - (40 * anim),
                                width: 84 - (40 * anim),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (controller.selectMode.value != EMAIL_ADDRESS) {
                              controller.selectMode.value = EMAIL_ADDRESS;
                              controller.checkEmailFormat('');
                              controller.phoneController.clear();
                              controller.isCheckTermService.value = false;
                              controller.diagnoseStatus.value = 0;
                            }
                          },
                          child: AnimatedAlign(
                            alignment:
                                controller.selectMode.value == EMAIL_ADDRESS
                                    ? Alignment.center
                                    : Alignment.centerRight,
                            duration: const Duration(milliseconds: 150),
                            child: Opacity(
                              opacity: 1 - lerpDouble(0.44, 0, anim),
                              child: Image.asset(
                                'assets/images/login_email.png',
                                height: 84 - lerpDouble(40, 0, anim),
                                width: 84 - lerpDouble(40, 0, anim),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 4,
                      width: lerpDouble(8, 12, anim),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2)),
                        color: Color.lerp(
                          colorTextSecondarySolid,
                          const Color(0xFFCCCCCC),
                          anim,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 4,
                      width: lerpDouble(8, 12, anim),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2)),
                        color: Color.lerp(
                          const Color(0xFFCCCCCC),
                          colorTextSecondarySolid,
                          anim,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
    );
  }

  Widget _buildPhoneView(BuildContext context) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          localized(loginPhone),
          style: jxTextStyle.titleText(fontWeight: MFontWeight.bold5.value),
        ),
        const SizedBox(height: 8),
        Text(
          localized(pleaseEnterAValidPhoneNumber),
          style: jxTextStyle.textStyle17(color: colorTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            controller.countryController.text = "";
            controller.updatedCountryList.value = controller.countryCodeList;
            showModalBottomSheet(
              isScrollControlled: true,
              useSafeArea: true,
              context: context,
              barrierColor: colorOverlay40,
              backgroundColor: colorBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              builder: (context) {
                //选择国家的主键
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
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: colorDivider,
                    width: 0.33,
                  ),
                ),
              ),
              child: Obx(
                () => Row(
                  children: [
                    if (!controller.isNotCountryAvailable.value)
                      Container(
                        width: 28,
                        height: 18,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.33,
                            color: colorDivider,
                          ),
                          image: DecorationImage(
                            image: AssetImage(
                              controller.country.value?.flagUri ??
                                  controller.defaultCountry!.flagUri!,
                              package: 'country_list_pick',
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        controller.isNotCountryAvailable.value
                            ? localized(loginSelectCountry)
                            : (!controller.isEnglish
                                    ? controller.country.value?.zhName
                                    : controller.country.value?.name) ??
                                (!controller.isEnglish
                                    ? controller.defaultCountry!.zhName!
                                    : controller.defaultCountry!.name!),
                        style: jxTextStyle.textStyle20(color: themeColor),
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
        Container(
          height: 56,
          decoration: BoxDecoration(border: customBorder),
          child: Row(
            children: [
              SizedBox(
                width: 65,
                child: TextFormField(
                  contextMenuBuilder: im.textMenuBar,
                  controller: controller.codeController,
                  onChanged: controller.checkCountryCode,
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
                  style: jxTextStyle.textStyle20(),
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(4),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    PlusSignInputFormatter()
                  ],
                ),
              ),
              Container(
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                width: 1,
                color: colorDivider,
              ),
              Expanded(
                child: TextFormField(
                  contextMenuBuilder: im.textMenuBar,
                  focusNode: controller.phoneFocusNode,
                  controller: controller.phoneController,
                  onChanged: controller.checkPhoneNumber,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: controller.country.value?.code == 'DE' ||
                            controller.country.value?.code == 'VN' ||
                            controller.country.value?.code == 'MY' ||
                            controller.isNotCountryAvailable.value
                        ? localized(pleaseEnterYourPhoneNumber)
                        : controller.country.value?.mobileNumber ??
                            controller.initialCountryData
                                ?.phoneMaskWithoutCountryCode,
                    hintStyle: jxTextStyle.textStyle20(
                      color: colorTextSupporting,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: themeColor,
                  cursorRadius: const Radius.circular(1),
                  cursorWidth: 2,
                  style: jxTextStyle.textStyle20(),
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    FilteringTextInputFormatter.digitsOnly,
                    controller.isNotCountryAvailable.value
                        ? FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                        : controller.country.value?.mobileNumber != null
                            ? StringPatternInputFormatter(
                                controller.country.value!.mobileNumber!,
                                maxLength: 20)
                            : PhoneInputFormatter(
                                allowEndlessPhone: true,
                                shouldCorrectNumber: false,
                                defaultCountryCode:
                                    controller.initialCountryData?.countryCode,
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Visibility(
            visible: controller.diagnoseStatus.value > 0 ||
                notBlank(controller.phoneError.value),
            child: controller.phoneError.value == localized(invalidPhoneNumber)
                ? Container(
                    padding: const EdgeInsets.only(top: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.phoneError.value,
                      style: jxTextStyle.textStyle17(color: colorRed),
                    ),
                  )
                : _buildNetworkDiagnoseWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailView() {
    return Column(
      key: const ValueKey('email'),
      children: [
        Text(
          localized(mailBox),
          style: jxTextStyle.titleText(fontWeight: MFontWeight.bold5.value),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          localized(pleaseEnterAValidEmailAddress),
          style: jxTextStyle.textStyle17(color: colorTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          height: 56,
          decoration: BoxDecoration(border: customBorder),
          alignment: Alignment.center,
          child: EmailTextField(
            focusNode: controller.emailFocusNode,
            textEditingController: controller.emailController,
            style: jxTextStyle.textStyle20(),
            hintStyle: jxTextStyle.textStyle20(color: colorTextSupporting),
            onChanged: controller.checkEmailFormat,
          ),
        ),
        Obx(
          () => Visibility(
            visible: controller.diagnoseStatus.value > 0 ||
                notBlank(controller.emailError.value),
            child: controller.emailError.value ==
                    localized(pleaseEnterAValidEmailAddress)
                ? Container(
                    padding: const EdgeInsets.only(top: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.emailError.value,
                      style: jxTextStyle.textStyle17(color: colorRed),
                    ),
                  )
                : _buildNetworkDiagnoseWidget(),
          ),
        ),
      ],
    );
  }

  String? _taskResult(NetworkDiagnoseTask task) {
    switch (task.status.value) {
      case ConnectionTaskStatus.processing:
        if (controller.diagnoseStatus.value >= 3) {
          return null;
        }
        return localized(diagnoseTaskProcessing);
      case ConnectionTaskStatus.success:
      case ConnectionTaskStatus.failure:
      default:
        return task.description;
    }
  }

  Widget _taskResultIcon(NetworkDiagnoseTask task) {
    switch (task.status.value) {
      case ConnectionTaskStatus.processing:
        if (controller.diagnoseStatus.value >= 3) {
          return SvgPicture.asset(
            "assets/svgs/network_none.svg",
          );
        }
        return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: themeColor,
          ),
        );
      case ConnectionTaskStatus.success:
        return SvgPicture.asset(
          "assets/svgs/network_check.svg",
        );
      case ConnectionTaskStatus.failure:
        return SvgPicture.asset(
          "assets/svgs/network_error.svg",
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTermServiceView() {
    return Obx(
      () => GestureDetector(
        onTap: controller.checkTermService,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CheckTickItem(
                  isCheck: controller.isCheckTermService.value,
                  circleSize: 16,
                  circlePaddingValue: 3,
                ),
              ),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    text: localized(iHaveReadAndAgree),
                    style: jxTextStyle.textStyle14(),
                    children: [
                      TextSpan(
                        text: localized(termOfService),
                        style: jxTextStyle.textStyle14(color: themeColor),
                        recognizer: TapGestureRecognizer()
                          ..onTap = controller.showTermService,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkDiagnoseWidget() {
    return AnimatedSize(
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 300),
      child: controller.diagnoseStatus.value == 0
          ? const SizedBox()
          : Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colorBackground3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Obx(() {
                      return Text(
                        controller.networkWarningTitle.value,
                        style: jxTextStyle.headerText(
                          fontWeight: MFontWeight.bold5.value,
                          color: controller.diagnoseStatus.value != 2
                              ? colorOrange
                              : colorTextPrimary,
                        ),
                      );
                    }),
                  ),
                  const CustomDivider(),
                  Obx(() {
                    return SettingItem(
                      titleWidget: Text(
                        controller.taskStatuses[0].name,
                        style: jxTextStyle.headerText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                      subtitle: _taskResult(controller.taskStatuses[0]),
                      subtitleStyle: jxTextStyle.normalSmallText(
                        color: colorTextSecondary,
                      ),
                      paddingVerticalMobile: 8,
                      rightWidget: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _taskResultIcon(controller.taskStatuses[0]),
                      ),
                      withArrow: false,
                      withEffect: false,
                      withBorder: false,
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: CustomDivider(),
                  ),
                  Obx(() {
                    return SettingItem(
                      titleWidget: Text(
                        controller.taskStatuses[1].name,
                        style: jxTextStyle.headerText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                      subtitle: _taskResult(controller.taskStatuses[1]),
                      subtitleStyle: jxTextStyle.normalSmallText(
                        color: colorTextSecondary,
                      ),
                      paddingVerticalMobile: 8,
                      rightWidget: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _taskResultIcon(controller.taskStatuses[1]),
                      ),
                      withArrow: false,
                      withEffect: false,
                      withBorder: false,
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: CustomDivider(),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Obx(() {
                      return Text(
                        "${controller.currentCountry.value}, ${controller.currentIP.value}",
                        style: jxTextStyle.normalSmallText(
                          color: colorTextSecondary,
                        ),
                      );
                    }),
                  )
                ],
              ),
            ),
    );
  }
}
