import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart' as im_font;
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/contact/edit_contact_controller.dart';

class EditContactView extends GetView<EditContactController> {
  const EditContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 7).w,
          child: Obx(
            () => controller.user.value == null
                ? Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
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
                : Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.only(top: 24),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32).w,
                            child: Center(
                              child: CustomAvatar.user(
                                controller.user.value!,
                                size: 100,
                                headMin: Config().headMin,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            left: 0,
                            child: OpacityEffect(
                              child: GestureDetector(
                                onTap: () {
                                  final id = Get.find<HomeController>()
                                              .pageIndex
                                              .value ==
                                          0
                                      ? 1
                                      : 2;
                                  Get.back(
                                    id: objectMgr.loginMgr.isDesktop
                                        ? id
                                        : null,
                                  );
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding:
                                      const EdgeInsets.only(top: 3, left: 16),
                                  child: Text(
                                    localized(buttonCancel),
                                    style: TextStyle(
                                      fontSize: im_font.MFontSize.size17.value,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 0,
                            child: OpacityEffect(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (connectivityMgr.connectivityResult ==
                                      ConnectivityResult.none) {
                                    Toast.showToast(
                                      localized(
                                        connectionFailedPleaseCheckTheNetwork,
                                      ),
                                    );
                                  } else {
                                    controller.changeFriendDetails();
                                  }
                                },
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(
                                    top: 3,
                                    right: 16,
                                  ),
                                  child: Obx(
                                    () => Text(
                                      localized(buttonDone),
                                      style: TextStyle(
                                        fontSize:
                                            im_font.MFontSize.size17.value,
                                        color: controller.canSubmit.value
                                            ? themeColor
                                            : themeColor.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 24),
                              TextFormField(
                                contextMenuBuilder: im.textMenuBar,
                                enabled: (controller.user.value?.deletedAt) != 0
                                    ? false
                                    : true,
                                controller: controller.aliasController,
                                style: const TextStyle(
                                  color: colorTextPrimary,
                                  fontSize: 17,
                                  decorationThickness: 0,
                                ),
                                cursorColor: themeColor,
                                decoration: InputDecoration(
                                  hintText: localized(pleaseEnterFriendAlias),
                                  hintStyle: jxTextStyle.headerText(
                                    color: colorTextPlaceholder,
                                  ),
                                  filled: true,
                                  fillColor:
                                      controller.user.value?.deletedAt != 0
                                          ? colorDivider
                                          : colorWhite,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: Obx(
                                    () => Visibility(
                                      visible: controller.showClearBtn.value,
                                      child: GestureDetector(
                                        onTap: () => controller.clearName(),
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 16,
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/svgs/clear_icon.svg',
                                            color: colorTextPlaceholder,
                                            width: 14,
                                            height: 14,
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  if (controller.aliasController.text.isEmpty) {
                                    controller.setShowClearBtn(false);
                                  } else {
                                    controller.setShowClearBtn(true);
                                  }
                                },
                                onChanged: (name) {
                                  controller.checkName(name);

                                  if (controller.aliasController.text.isEmpty) {
                                    controller.setShowClearBtn(false);
                                  } else {
                                    controller.setShowClearBtn(true);
                                  }
                                },
                              ),
                              // Error message
                              Obx(
                                () => controller.invalidName.value
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          top: 8,
                                        ),
                                        child: Text(
                                          localized(userNameValidate),
                                          style: jxTextStyle.textStyle14(
                                            color: colorRed,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                              const SizedBox(height: 24),

                              if (!controller.isDeletedAccount)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: colorWhite,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          localized(
                                              editContactBlockFriendTitle),
                                          style: jxTextStyle.headerText(),
                                        ),
                                      ),
                                      Positioned(
                                        right: 16,
                                        child: Obx(
                                          () => CustomCupertinoSwitch(
                                            value: controller.isBlocked.value,
                                            callBack: (value) =>
                                                controller.onTapBlock(value),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!controller.isDeletedAccount)
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    localized(editContactBlockFriendDesc),
                                    style: jxTextStyle.normalSmallText(
                                      color: colorTextLevelTwo,
                                    ),
                                  ),
                                ),
                              if (!controller.isDeletedAccount)
                                const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () =>
                                    controller.confirmUnfriend(context),
                                child: ForegroundOverlayEffect(
                                  radius: const BorderRadius.vertical(
                                    top: Radius.circular(10),
                                    bottom: Radius.circular(10),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: colorWhite,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        localized(editContactDeleteFriendTitle),
                                        style: jxTextStyle.headerText(
                                          color: colorRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  localized(editContactDeleteFriendSubtitle),
                                  style: jxTextStyle.normalSmallText(
                                    color: colorTextLevelTwo,
                                  ),
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
    );
  }
}
