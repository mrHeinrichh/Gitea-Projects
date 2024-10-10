import 'package:agora/agora_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/group_chat_encryption_bottom_sheet.dart';
import 'package:jxim_client/im/chat_info/group/components/group_alias_bottom_sheet.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:lottie/lottie.dart';

class GroupInfoMenuWidget extends StatelessWidget {
  const GroupInfoMenuWidget({
    super.key,
    required this.controller,
  });

  final GroupChatInfoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isMobile = objectMgr.loginMgr.isMobile;
      return isMobile ? _mobileMenu(context) : _desktopMenu(context);
    });
  }

  Container _mobileMenu(BuildContext context) {
    return Container(
      key: controller.childKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 0),
            child: Row(
              children: [
                Visibility(
                  visible: controller.isOwner.value ||
                      controller.adminList
                          .contains(objectMgr.userMgr.mainUser.uid),
                  child: Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (controller.chat.value!.isValid) {
                          if (objectMgr.callMgr.getCurrentState() !=
                              CallState.Idle) {
                            Toast.showToast(localized(toastEndCall));
                          } else {
                            audioManager.audioStateBtnClick(context);
                          }
                        } else {
                          Toast.showToast(localized(youAreNoLongerInThisGroup));
                        }
                      },
                      child: toolButton(
                        'assets/svgs/chat_info_call_icon.svg',
                        localized(call),
                        controller.chat.value!.isValid,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: controller.isOwner.value ||
                      controller.adminList
                          .contains(objectMgr.userMgr.mainUser.uid),
                  child: ImGap.hGap8,
                ),
                Expanded(
                  child: GestureDetector(
                    key: controller.notificationKey,
                    onTap: () => controller.onNotificationTap(context),
                    child: toolButton(
                      controller.getMuteIcon(),
                      controller.isMute.value
                          ? localized(cancelUnmute)
                          : localized(mute),
                      controller.chat.value!.isValid,
                    ),
                  ),
                ),
                ImGap.hGap8,
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (!controller.chat.value!.isDisband) {
                        controller.onChatTap(
                          context,
                          searching: true,
                        );
                      }
                    },
                    child: toolButton(
                      'assets/svgs/chat_info_search.svg',
                      localized(search),
                      !controller.chat.value!.isDisband,
                    ),
                  ),
                ),
                ImGap.hGap8,
                Expanded(
                  child: GestureDetector(
                    key: controller.moreVertKey,
                    onTap: () => controller.showMoreOptionPopup(context),
                    child: toolButton(
                      'assets/svgs/chat_info_more.svg',
                      localized(searchMore),
                      true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (controller.group.value!.isTmpGroup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
              ),
              margin: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized(groupExpiry),
                    style: jxTextStyle.textStyle14(),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Obx(() {
                      return Text(
                        controller.isGroupExpireSoon.value
                            ? localized(
                                temporaryChatInfoCountdown,
                                params: [
                                  formatToLocalTime(
                                    controller.group.value!.expireTime,
                                  ),
                                  controller.remainingTime.value,
                                ],
                              )
                            : formatToLocalTime(
                                controller.group.value!.expireTime,
                              ),
                        style: jxTextStyle.headerText(
                          color: controller.isGroupExpireSoon.value
                              ? colorRed
                              : colorTextPrimary,
                        ),
                      );
                    }),
                  ),
                  _buildDescriptionTile(),
                  Visibility(
                    visible: controller.isEncrypted.value,
                    child: _buildEncryptionTile(context),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
              ),
              margin: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescriptionTile(hasBorder: false),
                  Visibility(
                    visible: controller.isEncrypted.value,
                    child: _buildEncryptionTile(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _desktopMenu(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            onPressed: () async => controller.onChatTap(context),
            child: toolButton(
              'assets/svgs/message.svg',
              localized(homeChat),
              true,
            ),
          ),
        ),
        // Expanded(
        //   child: GestureDetector(
        //     onTap: () {
        //       audioManager
        //           .audioStateBtnClick(context);
        //     },
        //     child: toolButton(
        //         'assets/svgs/call.svg',
        //         localized(call),
        //         controller.chat.value!.isValid),
        //   ),
        // ),
        const SizedBox(width: 10),
        Obx(
          () => Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              key: controller.notificationKey,
              onPressed: () => controller.onNotificationTap(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: toolButton(
                  controller.getMuteIcon(),
                  controller.isMute.value ? localized(unmute) : localized(mute),
                  controller.chat.value!.isValid,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
            ),
            onPressed: () async {
              if (!controller.chat.value!.isDisband) {
                controller.onChatTap(
                  context,
                  searching: true,
                );
              }
            },
            child: toolButton(
              'assets/svgs/Search.svg',
              localized(search),
              !controller.chat.value!.isDisband,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            key: controller.moreVertKey,
            onPressed: () => controller.showMoreOptionPopup(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: toolButton(
                'assets/svgs/chat_info_more.svg',
                localized(searchMore),
                true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 多功能选项按钮
  Widget toolButton(
    String imageUrl,
    String text,
    bool enableState,
  ) {
    return ForegroundOverlayEffect(
      radius: const BorderRadius.vertical(
        top: Radius.circular(12),
        bottom: Radius.circular(12),
      ),
      child: Container(
        padding: objectMgr.loginMgr.isDesktop ? null : const EdgeInsets.symmetric(vertical: 8.0),
        width: MediaQuery.of(Get.context!).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuIcon(
              imageUrl: imageUrl,
              text: text,
              enableState: enableState,
            ),
            SizedBox(height: objectMgr.loginMgr.isDesktop ? 2 : 2.w),
            Text(
              text,
              style: jxTextStyle.textStyle12(
                color: enableState
                    ? controller.isMuteOpen.value || controller.isMoreOpen.value
                        ? themeColor.withOpacity(0.3)
                        : themeColor
                    : themeColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon({
    required String imageUrl,
    required String text,
    required bool enableState,
  }) {
    bool isLottie = imageUrl.endsWith(".json");
    if (isLottie) {
      return Lottie.asset(
        key: ValueKey(imageUrl),
        imageUrl,
        width: 22,
        height: 22,
        repeat: false,
      );
    }
    return SvgPicture.asset(
      imageUrl,
      width: 22,
      height: 22,
      color: enableState
          ? controller.isMuteOpen.value || controller.isMoreOpen.value
              ? themeColor.withOpacity(0.3)
              : themeColor
          : themeColor.withOpacity(0.3),
    );
  }

  Widget _buildEncryptionTile(BuildContext context, {bool hasBorder = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBorder)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 0.33,
              color: colorTextPrimary.withOpacity(0.2),
            ),
          ),
        //取得簡介文字行數
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                // Get.put(GroupInviteLinkController());
                return const GroupChatEncryptionBottomSheet();
              },
            );
          },
          child: OpacityEffect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localized(settingEncryptedConversation),
                  style: jxTextStyle.textStyle17(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SvgPicture.asset(
                    'assets/svgs/right_arrow_thick.svg',
                    color: colorTextSupporting,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        colorTextPrimary.withOpacity(0.2), BlendMode.srcIn),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDescriptionTile({bool hasBorder = true}) {
    List<Widget> children = [];
    if (hasBorder) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: 0.33,
            color: colorTextPrimary.withOpacity(0.2),
          ),
        ),
      );
    }

    // Group Description
    if (notBlank(controller.group.value?.profile)) {
      children.addAll([
        Text(
          localized(description),
          style: jxTextStyle.textStyle14(),
        ),
        const SizedBox(height: 4),
        //取得簡介文字行數
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              controller.updateGroupChatDescExpanded(
                !controller.isGroupChatDescExpanded.value,
              );
            },
            child: OverlayEffect(
              radius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(8),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final span = TextSpan(
                    text: controller.group.value?.profile ?? "",
                    style: jxTextStyle.textStyle17(),
                  );

                  final tp = TextPainter(
                    text: span,
                    textDirection: TextDirection.ltr,
                  );
                  tp.layout(maxWidth: constraints.maxWidth);

                  //get text lines
                  int numLines = tp.computeLineMetrics().length;
                  numLines = numLines < 3 ? numLines : 3;
                  controller.profileTextNumLines = numLines;

                  return Obx(
                    () => Text(
                      controller.group.value?.profile ?? "",
                      style: jxTextStyle.textStyle17(),
                      maxLines: controller.isGroupChatDescExpanded.value
                          ? null
                          : numLines,
                      overflow: controller.isGroupChatDescExpanded.value
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ]);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: 0.33,
            color: colorTextPrimary.withOpacity(0.2),
          ),
        ),
      );
    }

    // Group Alias
    children.add(
      Column(
        children: [
          const SizedBox(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              showModalBottomSheet(
                  context: Get.context!,
                  backgroundColor: Colors.transparent,
                  isDismissible: true,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: GroupAliasBottomSheet(
                        name: controller.myGroupAlias.value,
                        confirmCallback: (name) {
                          controller.modifyGroupAlias(name);
                        },
                        cancelCallback: () => Get.back(),
                      ),
                    );
                  });
            },
            child: OpacityEffect(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        localized(groupAliasTitle),
                        style: jxTextStyle.textStyle17(),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Obx(() {
                                return Text(
                                  controller.myGroupAlias.value,
                                  style: jxTextStyle.textStyle17(
                                      color: colorTextSupporting),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/svgs/right_arrow_thick.svg',
                            color: colorTextSupporting,
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                                colorTextPrimary.withOpacity(0.2), BlendMode.srcIn),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
