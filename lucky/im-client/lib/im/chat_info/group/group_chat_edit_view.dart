import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_controller.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_setting_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../../utils/loading/ball.dart';
import '../../../views_desktop/component/desktop_image_picker.dart';
import '../../../views_desktop/component/desktop_general_dialog.dart';

class GroupChatEditView extends GetView<GroupChatEditController> {
  const GroupChatEditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MoreSettingController moreSettingController =
        Get.put(MoreSettingController());
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.only(top: 24, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child:

                          /// 群头像
                          Container(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: objectMgr.loginMgr.isDesktop
                              ? null
                              : () {
                                  controller.showPickPhotoOption(context);
                                },
                          onTapUp: objectMgr.loginMgr.isDesktop
                              ? (details) {
                                  DesktopGeneralDialog(
                                    context,
                                    color: Colors.transparent,
                                    widgetChild: DesktopImagePicker(
                                      offset: details.globalPosition,
                                      onFilePicker: () async {
                                        Get.back();
                                        controller.getGalleryPhoto(context);
                                      },
                                      onDelete: () {
                                        Get.back();
                                        controller.clearPhoto();
                                      },
                                    ),
                                  );
                                }
                              : null,
                          child: Obx(
                            () => Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  child: CustomAvatar(
                                    uid: controller.group.value!.uid,
                                    size: objectMgr.loginMgr.isDesktop
                                        ? 100
                                        : 100,
                                    isGroup: true,
                                    isShowInitial: controller.isClear.value,
                                    withEditEmptyPhoto: true,
                                  ),
                                ),
                                if (controller.avatarFile.value != null)
                                  Container(
                                    // margin: EdgeInsets.all(
                                    //     objectMgr.loginMgr.isDesktop ? 10 : 10.w),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: ClipOval(
                                      child: Image.file(
                                        controller.avatarFile.value!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (controller.avatarFile.value != null)
                                  Container(
                                    // margin: EdgeInsets.all(
                                    //     objectMgr.loginMgr.isDesktop ? 10 : 10.w),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
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
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      left: 0,
                      child: OpacityEffect(
                        child: GestureDetector(
                          onTap: () {
                            if (objectMgr.loginMgr.isDesktop) {
                              Get.back(id: 1);
                            } else {
                              Get.back();
                            }
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(top: 3, left: 16),
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
                      child: Obx(
                        () => controller.isLoading.value
                            ? Container(
                                padding:
                                    const EdgeInsets.only(top: 3, right: 16),
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
                            : Visibility(
                                visible: !controller.groupNameIsEmpty.value,
                                child: OpacityEffect(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (!controller.groupNameIsEmpty.value) {
                                        await controller.updateGroupInfo();
                                        Get.back(
                                            id: objectMgr.loginMgr.isDesktop
                                                ? 1
                                                : null);
                                      }
                                    },
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                          top: 3, right: 16),
                                      child: Text(
                                        localized(buttonDone),
                                        style: jxTextStyle.textStyle17(
                                            color: accentColor),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                GestureDetector(
                  onTap: () {
                    if (!objectMgr.loginMgr.isDesktop)
                      controller.showPickPhotoOption(context);
                  },
                  child: GestureDetector(
                    onTapUp: objectMgr.loginMgr.isDesktop
                        ? (details) {
                            DesktopGeneralDialog(
                              context,
                              color: Colors.transparent,
                              widgetChild: DesktopImagePicker(
                                offset: details.globalPosition,
                                onFilePicker: () async {
                                  Get.back();
                                  controller.getGalleryPhoto(context);
                                },
                                onDelete: () {
                                  Get.back();
                                  controller.clearPhoto();
                                },
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      localized(setNewPhoto),
                      style: jxTextStyle.textStyle16(color: accentColor),
                    ),
                  ),
                ),

                /// 群名字 & 簡介
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.only(left: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              contextMenuBuilder: textMenuBar,
                              controller: controller.groupNameTextController,
                              cursorColor: accentColor,
                              maxLength: 30,
                              decoration: InputDecoration(
                                hintText: localized(groupName),
                                hintStyle: const TextStyle(
                                  color: JXColors.black24,
                                  fontSize: 16,
                                ),
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                  right: 8,
                                  top: 12,
                                  bottom: 12,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    if (controller.showClearBtn.value) {
                                      controller.groupNameTextController
                                          .clear();
                                      controller.setShowClearBtn(false,
                                          type: 'name');
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Obx(
                                    () => Visibility(
                                      visible: controller.showClearBtn.value,
                                      child: Padding(
                                        padding: objectMgr.loginMgr.isDesktop
                                            ? const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 16,
                                              )
                                            : const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 16,
                                              ).w,
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
                                    .groupNameTextController.text.isEmpty) {
                                  controller.setShowClearBtn(false,
                                      type: 'name');
                                } else {
                                  controller.setShowClearBtn(true,
                                      type: 'name');
                                }
                              },
                              onChanged: (name) {
                                if (controller
                                    .groupNameTextController.text.isEmpty) {
                                  controller.setShowClearBtn(false,
                                      type: 'name');
                                } else {
                                  controller.setShowClearBtn(true,
                                      type: 'name');
                                }
                              },
                            ),
                            SeparateDivider(),
                            TextField(
                              contextMenuBuilder: textMenuBar,
                              controller: controller.groupDescTextController,
                              cursorColor: accentColor,
                              onChanged: (value) => controller.onChanged(value),
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              maxLines: null,
                              maxLength: 120,
                              decoration: InputDecoration(
                                hintText: localized(groupDescription),
                                hintStyle: const TextStyle(
                                  color: JXColors.black24,
                                  fontSize:
                                      16,
                                ),
                                counterText: "",
                                // to hide default max length
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                  right: 8,
                                  top: 12,
                                  bottom: 12,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    if (controller.showDecClearBtn.value) {
                                      controller.groupDescTextController
                                          .clear();
                                      controller.setShowClearBtn(false,
                                          type: 'describe');
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Obx(() => Visibility(
                                      visible: controller.showDecClearBtn.value,
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
                                      ))),
                                ),
                              ),
                              onTap: () {
                                if (controller
                                    .groupDescTextController.text.isEmpty) {
                                  controller.setShowClearBtn(false,
                                      type: 'describe');
                                } else {
                                  controller.setShowClearBtn(true,
                                      type: 'describe');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Container(
                //   padding:
                //       const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                //   alignment: Alignment.bottomRight,
                //   child: Obx(() => Text(
                //         '${controller.charLeft.value} ${localized(withdrawCharactersLeft)}',
                //         style: TextStyle(
                //           color: systemColor,
                //           fontSize: 12.sp,
                //         ),
                //       )),
                // ),

                /// 成員權限
                if (moreSettingController.isOwner)
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildListItem(
                            title: localized(permissions),
                            onTap: () {
                              moreSettingController.toPermission();
                            },
                            icon: 'right_arrow_thick',
                            bottomBorder: false)
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildListItem(
      {required title,
      required onTap,
      required icon,
      rightTxt = '',
      bottomBorder = true}) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SettingItem(
          iconName: 'auth_icon',
          title: localized(permissions),
          withBorder: false,
          onTap: onTap,
      ),
    );
  }
}
