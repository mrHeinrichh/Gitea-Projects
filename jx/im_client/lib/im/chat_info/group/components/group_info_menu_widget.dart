import 'package:agora/agora_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/chat_encryption_bottom_sheet.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/group/components/group_alias_bottom_sheet.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
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
          /// tool button
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
          Container(
            clipBehavior: Clip.hardEdge,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _buildContent().length,
              itemBuilder: (context, index) {
                Widget item = _buildContent()[index];
                return item;
              },
              separatorBuilder: (BuildContext context, int index) {
                return const CustomDivider(
                  indent: 16,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopMenu(BuildContext context) {
    return FittedBox(
      child: Row(
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
              style: ElevatedButton.styleFrom(
                padding:
                    EdgeInsets.zero, // Remove padding to fill the container
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ForegroundOverlayEffect(
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: toolButton(
                      'assets/svgs/message.svg',
                      localized(homeChat),
                      true,
                    ),
                  ),
                ),
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
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.zero, // Remove padding to fill the container
                ),
                key: controller.notificationKey,
                onPressed: () => controller.onNotificationTap(context),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: ForegroundOverlayEffect(
                    radius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                      bottom: Radius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: toolButton(
                        controller.getMuteIcon(),
                        controller.isMute.value
                            ? localized(unmute)
                            : localized(mute),
                        controller.chat.value!.isValid,
                      ),
                    ),
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
                padding: EdgeInsets.zero,
              ),
              onPressed: () async {
                if (!controller.chat.value!.isDisband) {
                  controller.onChatTap(
                    context,
                    searching: true,
                  );
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ForegroundOverlayEffect(
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: toolButton(
                      'assets/svgs/Search.svg',
                      localized(search),
                      !controller.chat.value!.isDisband,
                    ),
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
              key: controller.moreVertKey,
              onPressed: () => controller.showMoreOptionPopup(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ForegroundOverlayEffect(
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(8),
                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  /// 多功能选项按钮
  Widget toolButton(
    String imageUrl,
    String text,
    bool enableState,
  ) {
    return Container(
      padding: objectMgr.loginMgr.isDesktop
          ? null
          : const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(height: 2),
          Text(
            text,
            style: jxTextStyle.textStyle12(
              color: enableState
                  ? controller.isMuteOpen.value || controller.isMoreOpen.value
                      ? themeColor.withOpacity(0.2)
                      : themeColor
                  : themeColor.withOpacity(0.2),
            ),
          ),
        ],
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
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          themeColor,
          BlendMode.srcIn,
        ),
        child: Lottie.asset(
          key: ValueKey(imageUrl),
          imageUrl,
          width: 22,
          height: 22,
          repeat: false,
        ),
      );
    }
    return SvgPicture.asset(
      imageUrl,
      width: 22,
      height: 22,
      color: enableState
          ? controller.isMuteOpen.value || controller.isMoreOpen.value
              ? themeColor.withOpacity(0.2)
              : themeColor
          : themeColor.withOpacity(0.2),
    );
  }

  List<Widget> _buildContent() {
    List<Widget> widgetList = [];

    if (controller.group.value != null && controller.group.value!.isTmpGroup) {
      widgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localized(groupExpiry),
                style: jxTextStyle.normalText(),
              ),
              const SizedBox(height: 4),
              Obx(() {
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
            ],
          ),
        ),
      );
    }

    if (notBlank(controller.group.value?.profile)) {
      widgetList.add(
        OverlayEffect(
          overlayColor: colorBackground8,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localized(description),
                  style: jxTextStyle.normalText(),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    controller.updateGroupChatDescExpanded(
                      !controller.isGroupChatDescExpanded.value,
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final span = TextSpan(
                        text: controller.group.value?.profile ?? "",
                        style: jxTextStyle.headerText(),
                      );

                      final tp = TextPainter(
                        text: span,
                        textDirection: TextDirection.ltr,
                      );
                      tp.layout(maxWidth: constraints.maxWidth);

                      //get text lines
                      int numLines = tp.computeLineMetrics().length;
                      numLines = numLines < 3 ? numLines : 3;

                      return Obx(
                        () => Text(
                          controller.group.value?.profile ?? "",
                          style: jxTextStyle.headerText(),
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
              ],
            ),
          ),
        ),
      );
    }

    widgetList.add(
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showModalBottomSheet(
            context: Get.context!,
            barrierColor: colorOverlay40,
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
            },
          );
        },
        child: OverlayEffect(
          overlayColor: colorBackground8,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Text(
                    localized(groupAliasTitle),
                    style: jxTextStyle.headerText(),
                  ),
                  Expanded(
                    child: Obx(
                      () => Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          controller.myGroupAlias.value,
                          style: jxTextStyle.headerText(
                            color: colorTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/svgs/right_arrow_thick.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      colorTextSupporting,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (controller.isEncrypted.value) {
      widgetList.add(
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (controller.allowOpeningEncryptionTile()) {
              showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                barrierColor: colorOverlay40,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  return ChatEncryptionBottomSheet(
                    chat: controller.chat.value!,
                    signatureList: controller.signatureList,
                  );
                },
              );
            } else {
              imBottomToast(
                Get.context!,
                title: localized(unableToViewEncryptionPanel),
                icon: ImBottomNotifType.warning,
              );
            }
          },
          child: OverlayEffect(
            overlayColor: colorBackground8,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localized(settingEncryptedConversation),
                        style: jxTextStyle.headerText(),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/svgs/right_arrow_thick.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        colorTextSupporting,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgetList;
  }
}
