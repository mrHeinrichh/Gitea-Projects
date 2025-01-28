import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_form.dart';
import 'package:jxim_client/object/group_invite_link.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/group_link_qr_code_dialog.dart';

class ManageGroupOtherLinks extends StatefulWidget {
  const ManageGroupOtherLinks({super.key});

  @override
  State<ManageGroupOtherLinks> createState() => _ManageGroupOtherLinksState();
}

class _ManageGroupOtherLinksState extends State<ManageGroupOtherLinks> {
  final controller = Get.find<GroupInviteLinkController>();

  @override
  Widget build(BuildContext context) {
    return CustomRoundContainer(
      title: localized(otherLinks),
      titleColor: colorTextLevelTwo,
      bottomText: localized(additionalTimeInvitationLinks),
      child: Column(
        children: [
          Obx(
            () => CustomListTile(
              leading: Container(
                width: 40,
                alignment: Alignment.center,
                child: CustomImage(
                  'assets/svgs/add.svg',
                  size: 24,
                  color: themeColor,
                ),
              ),
              text: localized(createNewLink),
              textColor: themeColor,
              showDivider: controller.validLinks.isNotEmpty,
              onClick: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  barrierColor: colorOverlay40,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return const GroupInviteLinkForm(isEdit: false);
                  },
                );
              },
            ),
          ),
          Obx(
            () {
              if (controller.validLinks.isEmpty) return const SizedBox.shrink();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: controller.validLinks.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = controller.validLinks[index];
                  final displayLink =
                      (item.name == null || item.name?.isEmpty == true)
                          ? item.link
                          : item.name;
                  return CustomListTile(
                    height: 56,
                    leading: Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: themeColor,
                        shape: const CircleBorder(),
                      ),
                      child: const CustomImage(
                        'assets/svgs/invite_link_outlined.svg',
                        color: colorWhite,
                        size: 20,
                      ),
                    ),
                    text: displayLink ?? '',
                    subText: getSubText(item),
                    showDivider: index != (controller.validLinks.length - 1),
                    onClick: () {
                      controller.selectedGroupInviteLink = item;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        barrierColor: colorOverlay40,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return Obx(
                            () {
                              final item = controller.selectedGroupInviteLink;
                              final displayTitle = (item.name == null ||
                                      item.name?.isEmpty == true)
                                  ? localized(invitationLink)
                                  : item.name;
                              return CustomShareBottomSheetView(
                                titlePadding:
                                    const EdgeInsets.symmetric(horizontal: 70),
                                showMainHeader: false,
                                title: displayTitle ?? '',
                                leading: CustomImage(
                                  'assets/svgs/qrCode.svg',
                                  size: 24,
                                  color: themeColor,
                                  onClick: () {
                                    showGroupLinkQRCodeDialog(context);
                                  },
                                ),
                                link: controller.selectedGroupInviteLink.link ??
                                    '',
                                onCopyLink: controller.onCopyLink,
                                primaryButtonOnTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    barrierColor: colorOverlay40,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return controller.forwardContainer();
                                    },
                                  );
                                },
                                secondaryButtonText: localized(buttonEdit),
                                secondaryButtonOnTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    barrierColor: colorOverlay40,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return const GroupInviteLinkForm();
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  String getSubText(GroupInviteLink item) {
    if (item.limited == 0 && item.duration == 0) {
      // 人数无限制，时间无限制
      return item.used == 0
          ? localized(noOneHasJoined)
          : localized(numHaveJoined, params: [item.used!.toString()]);
    } else if (item.limited != 0 && item.duration == 0) {
      // 人数有限制，时间无限制
      return item.used == 0
          ? localized(noOneHasJoined)
          : localized(canJoinNum, params: ['${item.limited! - item.used!}']);
    } else if (item.duration != 0) {
      final now = DateTime.now();
      final expiredTime = item.expireTime! * 1000;
      final newDate = DateTime.fromMillisecondsSinceEpoch(expiredTime);
      final preText = item.used == 0
          ? localized(noOneHasJoined)
          : localized(numHaveJoined, params: [item.used!.toString()]);
      String expiredDate = '';
      if (newDate.day == now.day) {
        DateFormat formatter = DateFormat('HH:mm');
        String formattedDate = formatter.format(newDate);
        return '$preText · ${localized(linkExpiresInTime, params: [
              formattedDate
            ])}';
      } else if (newDate.day - now.day == 1) {
        return '$preText · ${localized(linkEpiresInOneDay)}';
      } else if (newDate.day - now.day > 1) {
        if (newDate.day - now.day > 7) {
          DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
          String formattedDate = formatter.format(newDate);
          expiredDate = localized(linkExpiresInTime, params: [formattedDate]);
        } else {
          expiredDate =
              localized(expiresInNumDays, params: ['${newDate.day - now.day}']);
        }
      }

      // 人数无限制，时间有限制
      if (item.limited == 0) {
        return '$preText · $expiredDate';
      } else {
        // 人数有限制，时间有限制
        return '$preText · $expiredDate';
      }
    }
    return '';
  }
}
