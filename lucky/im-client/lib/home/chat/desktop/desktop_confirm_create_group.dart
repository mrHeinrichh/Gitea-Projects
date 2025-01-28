import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../utils/user_utils.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views_desktop/component/desktop_image_picker.dart';
import '../../../views/component/nickname_text.dart';
import '../../../views/component/custom_avatar.dart';
import '../../../views_desktop/component/desktop_general_dialog.dart';
import '../../component/custom_divider.dart';
import '../create_chat/create_group_bottom_sheet_controller.dart';

class DesktopConfirmCreateGroup
    extends GetView<CreateGroupBottomSheetController> {
  const DesktopConfirmCreateGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 0.0,
            ),
            child: Row(
              children: [
                OpacityEffect(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(id: 1);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
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
                Expanded(
                  child: Center(
                    child: Text(
                      localized(createNewGroup),
                      style: jxTextStyle.textStyleBold17(),
                    ),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      if (!controller.groupNameIsEmpty.value) {
                        controller.onCreate(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        localized(newGroupCreateButton),
                        style: jxTextStyle.textStyle13(
                            color: !controller.groupNameIsEmpty.value
                                ? accentColor
                                : accentColor.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),
          Container(
            margin: const EdgeInsets.only(top: 36, left: 16, right: 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                /// 群头像
                Container(
                  alignment: Alignment.center,
                  child: Obx(
                    () => Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTapUp: (details) {
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
                          },
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: JXColors.outlineColor,
                            ),
                            width: 66,
                            height: 66,
                            child: ClipOval(
                              child: controller.groupPhoto.value == null
                                  ? FittedBox(
                                      fit: BoxFit.fill,
                                      child: Image.asset(
                                        'assets/icons/group_avatar.png',
                                      ),
                                    )
                                  : Image.file(
                                      controller.groupPhoto.value!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),

                        /// profile picture path empty show camera icon
                        ElevatedButton(
                          onPressed: () {
                            // controller.showPickPhotoOption(context);
                          },
                          child: GestureDetector(
                            onTapUp: (details) {
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
                            },
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: accentColor,
                            minimumSize: const Size(10, 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: controller.onGroupNameChanged,
                    controller: controller.groupNameTextController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: localized(enterGroupName),
                      hintStyle: jxTextStyle.textStyle16(
                        color: JXColors.supportingTextBlack,
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
                          child: CustomAvatar(
                            uid: controller.selectedMembers[index].uid,
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
                                    style: jxTextStyle.textStyle12(
                                        color: JXColors.secondaryTextBlack),
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
