import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_image_picker.dart';

class DesktopConfirmCreateGroup
    extends GetView<CreateGroupBottomSheetController> {
  const DesktopConfirmCreateGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(createNewGroup),
        onPressedBackBtn: () => Get.back(id: 1),
        trailing: [
          Obx(
            () => CustomTextButton(
              localized(newGroupCreateButton),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              isDisabled: controller.groupNameIsEmpty.value,
              onClick: () => controller.onCreate(context),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 36, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                /// 群头像
                Obx(
                  () => GestureDetector(
                    onTap: () => controller.getGalleryPhoto(context),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: const Color(0xFFEBF4FF),
                      ),
                      width: 56,
                      height: 56,
                      child: controller.groupPhoto.value == null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              child: SvgPicture.asset(
                                'assets/svgs/edit_camera_icon.svg',
                                colorFilter: ColorFilter.mode(
                                    themeColor, BlendMode.srcIn),
                              ),
                            )
                          : GestureDetector(
                              onTapUp: (details) {
                                desktopGeneralDialog(
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
                              },
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(56)),
                                child: Image.file(
                                  controller.groupPhoto.value!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: controller.onGroupNameChanged,
                    controller: controller.groupNameTextController,
                    maxLength: 30,
                    style: const TextStyle(
                        fontSize: 14,
                        color: colorTextPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: localized(enterGroupName),
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: colorTextSupporting,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 36, left: 16, right: 16),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.selectedMembers.length,
                itemBuilder: (BuildContext context, int index) {
                  BorderRadius borderRadius = BorderRadius.zero;

                  if (index == 0) {
                    if (index == controller.selectedMembers.length - 1) {
                      borderRadius = borderRadius =
                          const BorderRadius.all(Radius.circular(12));
                    } else {
                      borderRadius = const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      );
                    }
                  } else if (index == controller.selectedMembers.length - 1) {
                    borderRadius = const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: Colors.white,
                    ),
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: 16,
                            right: 12,
                          ),
                          child: CustomAvatar.user(
                            controller.selectedMembers[index],
                            size: 40,
                          ),
                        ),
                        //const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 8,
                              left: 0,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              border: (index ==
                                      controller.selectedMembers.length - 1)
                                  ? const Border()
                                  : customBorder,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                NicknameText(
                                  uid: controller.selectedMembers[index].uid,
                                  fontSize: MFontSize.size16.value,
                                  isTappable: false,
                                ),
                                Obx(
                                  () => Text(
                                    UserUtils.onlineStatus(controller
                                        .selectedMembers[index].lastOnline),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: colorTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
