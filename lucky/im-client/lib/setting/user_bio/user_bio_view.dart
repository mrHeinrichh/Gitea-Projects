import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../home/setting/setting_item.dart';
import '../../im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import '../../utils/im_toast/im_gap.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../views_desktop/component/desktop_image_picker.dart';
import '../../views_desktop/component/desktop_general_dialog.dart';

class UserBioView extends GetView<UserBioController> {
  const UserBioView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (objectMgr.loginMgr.isDesktop)
              Container(
                height: 52,
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: const Border(
                    bottom: BorderSide(
                      color: JXColors.outlineColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  /// 普通界面
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    OpacityEffect(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(id: 3);
                          Get.find<SettingController>()
                              .desktopSettingCurrentRoute = '';
                          Get.find<SettingController>().selectedIndex.value =
                              101010;
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svgs/Back.svg',
                                width: 18,
                                height: 18,
                                color: JXColors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                localized(buttonBack),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: JXColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: JXColors.black,
                      ),
                    ),
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
                                    color: accentColor,
                                    ballType: BallType.solid,
                                    borderWidth: 1,
                                    borderColor: accentColor,
                                  ),
                                ),
                              ),
                            )
                          : OpacityEffect(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (controller.validProfile.value) {
                                    controller.onUpdateProfile(context);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    localized(buttonDone),
                                    style: jxTextStyle.textStyle13(
                                      color: (controller.validProfile.value)
                                          ? accentColor
                                          : accentColor.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
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
                              controller.avatarFile.value != null
                                  ? Container(
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
                                    )
                                  : GestureDetector(
                                      onTapUp: (details) {
                                        if (objectMgr.loginMgr.isDesktop) {
                                          DesktopGeneralDialog(
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
                                        } else {
                                          controller
                                              .showPickPhotoOption(context);
                                        }
                                      },
                                      child: CustomAvatar(
                                        uid: controller.meUser.value?.uid ?? 0,
                                        size: objectMgr.loginMgr.isDesktop
                                            ? 128
                                            : 100,
                                        headMin: Config().messageMin,
                                        isShowInitial: controller.isClear.value,
                                        withEditEmptyPhoto: true,
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
                                      style: jxTextStyle.textStyle16(
                                        color: accentColor,
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
                                      color: accentColor),
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
                                          color: accentColor,
                                          ballType: BallType.solid,
                                          borderWidth: 1,
                                          borderColor: accentColor,
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
                                              horizontal: 16),
                                          child: Text(
                                            localized(buttonDone),
                                            style: jxTextStyle.textStyle17(
                                              color: controller
                                                      .validProfile.value
                                                  ? accentColor
                                                  : JXColors.secondaryTextBlack,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      }
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
                          '${localized(userEnterName)}',
                          controller.nameWordCountKey,
                          30,
                          onChange: (name) {
                            controller.checkName(name);
                            if (controller.nicknameController.text.isEmpty) {
                              controller.setShowClearBtn(false,
                                  type: 'nickname');
                            } else {
                              controller.setShowClearBtn(true,
                                  type: 'nickname');
                            }
                          },
                          onTap: () {
                            if (controller.nicknameController.text.isEmpty) {
                              controller.setShowClearBtn(false,
                                  type: 'nickname');
                            } else {
                              controller.setShowClearBtn(true,
                                  type: 'nickname');
                            }
                          },
                          suffixIcon: GestureDetector(
                            onTap: () {
                              controller.nicknameController.clear();
                              controller.checkName(
                                  controller.nicknameController.text);
                              controller.setShowClearBtn(false,
                                  type: 'nickname');
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
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 16),
                          child: Obx(
                            () => controller.invalidName.value
                                ? Text(
                                    localized(userNameValidate),
                                    style: jxTextStyle.textStyle12(
                                        color: errorColor),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        localized(userEnterName),
                                        style: jxTextStyle.textStyle12(
                                          color: JXColors.secondaryTextBlack,
                                        ),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${controller.nameWordCount.value} ${localized(charactersLeft)}",
                                          style: jxTextStyle.textStyle12(
                                            color: JXColors.black24,
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 10, 0),
                          child: Obx(
                            () => controller.invalidBio.value
                                ? Text(
                                    localized(userBioValidate),
                                    style: jxTextStyle.textStyle12(
                                        color: errorColor),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        localized(userEnterDescription),
                                        style: jxTextStyle.textStyle12(
                                            color: JXColors.secondaryTextBlack),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${controller.descriptionWordCount.value} ${localized(charactersLeft)}",
                                          style: jxTextStyle.textStyle12(
                                            color: JXColors.black24,
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
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (BuildContext context) {
                                        return CustomConfirmationPopup(
                                          title:
                                              '${localized(areYouSureToEditYourUsername)}',
                                          subTitle: localized(
                                              usernameCanOnlyBeChangedOnceAYear),
                                          confirmButtonText:
                                              localized(editUsername),
                                          cancelButtonText:
                                              localized(buttonCancel),
                                          cancelButtonColor: accentColor,
                                          confirmCallback: () {
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
                                          cancelCallback: () =>
                                              Navigator.of(context).pop(),
                                        );
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
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (BuildContext context) {
                                        return CustomConfirmationPopup(
                                          title: localized(
                                              areYouSureToChangeTheNumber),
                                          subTitle:
                                              localized(afterChangePhoneNumber),
                                          confirmButtonText:
                                              localized(changeNewNumber),
                                          cancelButtonText:
                                              localized(buttonCancel),
                                          cancelButtonColor: accentColor,
                                          confirmCallback: () {
                                            if (objectMgr.loginMgr.isDesktop) {
                                              Get.toNamed(
                                                  RouteName.editPhoneNumber,
                                                  id: 3);
                                            } else {
                                              Get.toNamed(
                                                  RouteName.editPhoneNumber);
                                            }
                                          },
                                          cancelCallback: () =>
                                              Navigator.of(context).pop(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              Obx(
                                () {
                                  return SettingItem(
                                    ///TODO: need to update to localized text
                                    title: localized(contactEmail),
                                    titleColor: JXColors.primaryTextBlack,
                                    rightTitle: controller.getEmail(),
                                    withBorder: false,
                                    onTap: () {
                                      Get.toNamed(RouteName.addEmail);
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

  Widget customTextField(TextEditingController textController, String hintText,
      String wordCountKey, int max,
      {Function(String)? onChange, suffixIcon, onTap}) {
    return Container(
      height: objectMgr.loginMgr.isDesktop ? 48 : 44,
      decoration: BoxDecoration(
        color: JXColors.white,
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
          style: jxTextStyle.textStyle16(),
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
          cursorColor: accentColor,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: objectMgr.loginMgr.isDesktop
                ? const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  )
                : const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
            hintText: hintText,
            hintStyle: const TextStyle(
              color: JXColors.supportingTextBlack,
            ),
            suffixIconConstraints: const BoxConstraints(maxHeight: 44),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
