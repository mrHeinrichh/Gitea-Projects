import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_image_picker.dart';

class UserBioView extends GetView<UserBioController> {
  const UserBioView({super.key});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? PrimaryAppBar(
              title: localized(myEditButton),
              onPressedBackBtn: () {
                Get.back(id: 3);
                Get.find<SettingController>().desktopSettingCurrentRoute = '';
                Get.find<SettingController>().selectedIndex.value = 101010;
              },
              trailing: [
                Obx(
                  () => controller.isLoading.value
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 25,
                            width: 25,
                            child: BallCircleLoading(
                              radius: 10,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 1,
                                borderColor: themeColor,
                              ),
                            ),
                          ),
                        )
                      : CustomTextButton(
                          localized(buttonDone),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          isDisabled: !controller.validProfile.value,
                          onClick: () {
                            controller.onUpdateProfile(context);
                          },
                        ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 7),
                children: [
                  /// Profile Picture
                  Stack(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        child: Obx(
                          () => Column(
                            children: [
                              GestureDetector(
                                onTap: objectMgr.loginMgr.isDesktop
                                    ? null
                                    : () =>
                                        controller.showPickPhotoOption(context),
                                onTapUp: objectMgr.loginMgr.isDesktop
                                    ? (details) {
                                        if (controller.isClear.value) {
                                          controller.getGalleryPhoto(context);
                                        } else {
                                          desktopGeneralDialog(
                                            context,
                                            color: Colors.transparent,
                                            widgetChild: DesktopImagePicker(
                                              offset: details.globalPosition,
                                              onFilePicker: () async {
                                                Get.back();
                                                controller
                                                    .getGalleryPhoto(context);
                                              },
                                              onDelete: () {
                                                Get.back();
                                                controller.clearPhoto();
                                              },
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                child: Stack(
                                  children: [
                                    if (controller.meUser.value != null)
                                      CustomAvatar.user(
                                        controller.meUser.value!,
                                        size: objectMgr.loginMgr.isDesktop
                                            ? 128
                                            : 100,
                                        headMin: Config().headMin,
                                        isShowInitial: controller.isClear.value,
                                        withEditEmptyPhoto: true,
                                      ),
                                    if (controller.avatarFile.value != null)
                                      Container(
                                        width: objectMgr.loginMgr.isDesktop
                                            ? 128
                                            : 100,
                                        height: objectMgr.loginMgr.isDesktop
                                            ? 128
                                            : 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          color: Colors.white,
                                        ),
                                        child: ClipOval(
                                          child: Image.file(
                                            controller.avatarFile.value!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              objectMgr.loginMgr.isDesktop
                                  ? const SizedBox(height: 12)
                                  : ImGap.vGap12,
                              if (!objectMgr.loginMgr.isDesktop)
                                GestureDetector(
                                  onTap: () =>
                                      controller.showPickPhotoOption(context),
                                  child: OpacityEffect(
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
                      if (objectMgr.loginMgr.isMobile) ...{
                        Positioned(
                          top: 0,
                          left: 0,
                          child: OpacityEffect(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Get.back(),
                              child: Container(
                                height: 44,
                                alignment: Alignment.topCenter,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  localized(cancel),
                                  style: jxTextStyle.textStyle17(
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Obx(
                            () => controller.isLoading.value
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: BallCircleLoading(
                                        radius: 10,
                                        ballStyle: BallStyle(
                                          size: 4,
                                          color: themeColor,
                                          ballType: BallType.solid,
                                          borderWidth: 1,
                                          borderColor: themeColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : AbsorbPointer(
                                    absorbing: !controller.validProfile.value,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        controller.onUpdateProfile(context);
                                      },
                                      child: OpacityEffect(
                                        child: Container(
                                          height: 44,
                                          alignment: Alignment.topCenter,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            localized(buttonDone),
                                            style: jxTextStyle.headerText(
                                              color:
                                                  controller.validProfile.value
                                                      ? themeColor
                                                      : colorTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      },
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Name
                        customTextField(
                          controller.nicknameController,
                          localized(userEnterName),
                          controller.nameWordCountKey,
                          30,
                          onChange: (name) {
                            controller.checkName(name);
                            if (controller.nicknameController.text.isEmpty) {
                              controller.setShowClearBtn(
                                false,
                                type: 'nickname',
                              );
                            } else {
                              controller.setShowClearBtn(
                                true,
                                type: 'nickname',
                              );
                            }
                          },
                          onTap: () {
                            if (controller.nicknameController.text.isEmpty) {
                              controller.setShowClearBtn(
                                false,
                                type: 'nickname',
                              );
                            } else {
                              controller.setShowClearBtn(
                                true,
                                type: 'nickname',
                              );
                            }
                          },
                          suffixIcon: GestureDetector(
                            onTap: () {
                              controller.nicknameController.clear();
                              controller.checkName(
                                controller.nicknameController.text,
                              );
                              controller.setShowClearBtn(
                                false,
                                type: 'nickname',
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Obx(
                              () => Visibility(
                                visible: controller.showNameClearBtn.value,
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
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 4, left: 16, right: 16),
                          child: Obx(
                            () => controller.invalidName.value
                                ? Text(
                                    localized(userNameValidate),
                                    style: jxTextStyle.normalSmallText(
                                      color: colorRed,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        localized(userEnterName),
                                        style: jxTextStyle.normalSmallText(
                                          color: colorTextLevelTwo,
                                        ),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${controller.nameWordCount.value}${localized(charactersLeft)}",
                                          style: jxTextStyle.normalSmallText(
                                            color: colorTextPlaceholder,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Bio
                        customTextField(
                          controller.bioController,
                          localized(chatProfileBio),
                          controller.descriptionWordCountKey,
                          140,
                          onChange: (bio) {
                            controller.checkBio(bio);
                            if (controller.bioController.text.isEmpty) {
                              controller.setShowClearBtn(false, type: 'bio');
                            } else {
                              controller.setShowClearBtn(true, type: 'bio');
                            }
                          },
                          onTap: () {
                            if (controller.bioController.text.isEmpty) {
                              controller.setShowClearBtn(false, type: 'bio');
                            } else {
                              controller.setShowClearBtn(true, type: 'bio');
                            }
                          },
                          suffixIcon: GestureDetector(
                            onTap: () {
                              controller.bioController.clear();
                              controller
                                  .checkBio(controller.bioController.text);
                              controller.setShowClearBtn(false, type: 'bio');
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Obx(
                              () => Visibility(
                                visible: controller.showBioClearBtn.value,
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Obx(
                            () => controller.invalidBio.value
                                ? Text(
                                    localized(userBioValidate),
                                    style: jxTextStyle.normalSmallText(
                                      color: colorRed,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        localized(userEnterDescription),
                                        style: jxTextStyle.normalSmallText(
                                          color: colorTextLevelTwo,
                                        ),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${controller.descriptionWordCount.value}${localized(charactersLeft)}",
                                          style: jxTextStyle.normalSmallText(
                                            color: colorTextPlaceholder,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        objectMgr.loginMgr.isDesktop
                            ? const SizedBox(height: 24)
                            : ImGap.vGap24,

                        /// change number and username
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          clipBehavior: Clip.hardEdge,
                          decoration: boxDecoration,
                          child: Column(
                            children: [
                              Obx(
                                () => SettingItem(
                                  title: localized(homeUsername),
                                  rightTitle: '@${controller.username.value}',
                                  onTap: () {
                                    showCustomBottomAlertDialog(
                                      context,
                                      title: localized(
                                          areYouSureToEditYourUsername),
                                      subtitle: localized(
                                          usernameCanOnlyBeChangedOnceAYear),
                                      confirmText: localized(editUsername),
                                      onConfirmListener: () {
                                        if (objectMgr.loginMgr.isDesktop) {
                                          Get.toNamed(
                                            RouteName.editUsername,
                                            arguments: controller.meUser,
                                            id: 3,
                                          );
                                        } else {
                                          Get.toNamed(
                                            RouteName.editUsername,
                                            arguments: controller.meUser,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              Obx(
                                () => SettingItem(
                                  title: localized(contactPhone),
                                  rightTitle: controller.getPhoneNumber(),
                                  onTap: () {
                                    showCustomBottomAlertDialog(
                                      Get.context!,
                                      title: localized(
                                          areYouSureToChangeTheNumber),
                                      subtitle:
                                          localized(afterChangePhoneNumber),
                                      confirmText: localized(changeNewNumber),
                                      onConfirmListener: () {
                                        if (objectMgr.loginMgr.isDesktop) {
                                          Get.toNamed(
                                            RouteName.editPhoneNumber,
                                            id: 3,
                                          );
                                        } else {
                                          Get.toNamed(
                                              RouteName.editPhoneNumber);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              Obx(
                                () {
                                  return SettingItem(
                                    title: localized(contactEmail),
                                    titleColor: colorTextPrimary,
                                    rightTitle: controller.getEmail(),
                                    withBorder: false,
                                    onTap: () {
                                      if (objectMgr.loginMgr.isDesktop) {
                                        Get.toNamed(
                                          RouteName.addEmail,
                                          id: 3,
                                        );
                                      } else {
                                        Get.toNamed(RouteName.addEmail);
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customTextField(
    TextEditingController textController,
    String hintText,
    String wordCountKey,
    int max, {
    Function(String)? onChange,
    suffixIcon,
    onTap,
  }) {
    return Container(
      height: objectMgr.loginMgr.isDesktop ? 48 : 44,
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          contextMenuBuilder: im_common.textMenuBar,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.multiline,
          controller: textController,
          onChanged: onChange ?? (_) {},
          onTap: onTap,
          inputFormatters: [
            ChineseCharacterInputFormatter(max: max),
          ],
          style: jxTextStyle.headerText(),
          maxLines: 1,
          maxLength: max,
          buildCounter: (
            BuildContext context, {
            required int currentLength,
            required int? maxLength,
            required bool isFocused,
          }) {
            return null;
          },
          textAlignVertical: TextAlignVertical.center,
          cursorColor: themeColor,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: jxTextStyle.headerText(color: colorTextPlaceholder),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          ),
        ),
      ),
    );
  }
}
