import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_form.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/group_link_qr_code_dialog.dart';

class ManageGroupInviteLink extends StatefulWidget {
  const ManageGroupInviteLink({super.key});

  @override
  State<ManageGroupInviteLink> createState() => _ManageGroupInviteLinkState();
}

class _ManageGroupInviteLinkState extends State<ManageGroupInviteLink> {
  final controller = Get.find<GroupInviteLinkController>();

  @override
  Widget build(BuildContext context) {
    return CustomRoundContainer(
      title: localized(invitationLink),
      bottomText: localized(anyoneJoinGroupViaLink),
      child: Column(
        children: [
          Obx(
            () {
              final item = controller.permalinkInfo;
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
                subText: controller.permalinkInfo.used == 0
                    ? localized(notUsed)
                    : localized(
                        numHaveJoined,
                        params: [controller.permalinkInfo.used.toString()],
                      ),
                showDivider: true,
                onClick: () {
                  controller.selectedGroupInviteLink = controller.permalinkInfo;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: colorOverlay40,
                    builder: (BuildContext context) {
                      return Obx(
                        () {
                          final displayTitle =
                              (item.name == null || item.name?.isEmpty == true)
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
                            link: controller.permalinkInfo.link ?? '',
                            onCopyLink: controller.onCopyLink,
                            primaryButtonOnTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                barrierColor: colorOverlay40,
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
                                backgroundColor: Colors.transparent,
                                barrierColor: colorOverlay40,
                                builder: (BuildContext context) {
                                  return const GroupInviteLinkForm(
                                      isSliderEnabled: false);
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              height: 48,
              text: localized(shareGroupLink),
              callBack: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: colorOverlay40,
                  builder: (BuildContext context) {
                    return controller.forwardContainer();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
