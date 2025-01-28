import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/contact/edit_contact_controller.dart';

class EditContactView extends GetView<EditContactController> {
  const EditContactView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
                            color: accentColor,
                            ballType: BallType.solid,
                            borderWidth: 2,
                            borderColor: accentColor,
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
                                child: CustomAvatar(
                                  uid: controller.user.value?.uid ?? 0,
                                  size: 100,
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
                                            : null);
                                  },
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        const EdgeInsets.only(top: 3, left: 16),
                                    child: Text(
                                      localized(buttonCancel),
                                      style: jxTextStyle.textStyle17(
                                          color: accentColor),
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
                                      Toast.showToast(localized(
                                          connectionFailedPleaseCheckTheNetwork));
                                    } else {
                                      controller.changeFriendDetails();
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(
                                        top: 3, right: 16),
                                    child: Obx(
                                      () => Text(
                                        localized(buttonDone),
                                        style: jxTextStyle.textStyle17(
                                          color: controller.canSubmit.value
                                              ? accentColor
                                              : accentColor.withOpacity(0.2),
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
                                  contextMenuBuilder: textMenuBar,
                                  enabled:
                                      (controller.user.value?.deletedAt) != 0
                                          ? false
                                          : true,
                                  controller: controller.aliasController,
                                  style: const TextStyle(
                                    color: JXColors.primaryTextBlack,
                                    fontSize: 17,
                                    decorationThickness: 0,
                                  ),
                                  cursorColor: accentColor,
                                  decoration: InputDecoration(
                                    hintText: localized(pleaseEnterFriendAlias),
                                    hintStyle: jxTextStyle.textStyle17(
                                      color: JXColors.hintColor,
                                    ),
                                    filled: true,
                                    fillColor: controller.user.value?.deletedAt != 0 ? JXColors.outlineColor: JXColors.bgSecondaryColor,
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
                                        visible:
                                            controller.showClearBtn.value,
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
                                              color: JXColors.hintColor,
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
                                    if (controller
                                        .aliasController.text.isEmpty) {
                                      controller.setShowClearBtn(false);
                                    } else {
                                      controller.setShowClearBtn(true);
                                    }
                                  },
                                  onChanged: (name) {
                                    controller.checkName(name);

                                    if (controller
                                        .aliasController.text.isEmpty) {
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
                                              left: 16, top: 8),
                                          child: Text(
                                            localized(userNameValidate),
                                            style: jxTextStyle.textStyle14(
                                              color: errorColor,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                const SizedBox(height: 24),
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
                                        color: JXColors.bgSecondaryColor,
                                      ),
                                      child: Container(
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
                                          "${localized(contactUnfriend)} ${objectMgr.userMgr.getUserTitle(controller.user.value)}",
                                          style: jxTextStyle.textStyle17(
                                              color: errorColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
            )),
      ),
    );
  }
}
