import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/manage/manage_group_invitation_links.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/group_link_qr_code_dialog.dart';

class ShareLinkBottomSheet extends StatefulWidget {
  const ShareLinkBottomSheet({super.key});

  @override
  State<ShareLinkBottomSheet> createState() => _ShareLinkBottomSheetState();
}

class _ShareLinkBottomSheetState extends State<ShareLinkBottomSheet> {
  late GroupInviteLinkController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GroupInviteLinkController>();
    // 初始化 selectedGroupInviteLink，不然打开该弹窗无法获得 copyLink
    controller.selectedGroupInviteLink = controller.permalinkInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return CustomShareBottomSheetView(
          leading: CustomImage(
            'assets/svgs/qrCode.svg',
            size: 24,
            color: themeColor,
            onClick: () => showGroupLinkQRCodeDialog(context),
          ),
          link: controller.permalinkInfo.link ?? '',
          onCopyLink: controller.onCopyLink,
          primaryButtonOnTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            barrierColor: colorOverlay40,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return controller.forwardContainer();
            },
          ),
          secondaryButtonTextColor: themeColor,
          showSecondaryButton: controller.isJoined.value,
          secondaryButtonOnTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            barrierColor: colorOverlay40,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return const ManageGroupInvitationLinks();
            },
          ),
        );
      },
    );
  }
}
