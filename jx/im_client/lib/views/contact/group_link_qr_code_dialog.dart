import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/components/group_qr_card.dart';
import 'package:jxim_client/views/contact/download_qr_code.dart';
import 'package:jxim_client/views/contact/qr_code.dart';

void showGroupLinkQRCodeDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    barrierColor: colorOverlay40,
    backgroundColor: colorSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (BuildContext ctx) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _doneButton(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQRCode(),
                  const SizedBox(height: 12),
                  _shareTitle(),
                  const SizedBox(height: 16),
                  _copyURLContainer(),
                  const SizedBox(height: 16),
                  _shareQRCodeButton(context),
                  const SizedBox(height: 16),
                  _downloadQRCodeTextButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _doneButton(BuildContext ctx) {
  return Container(
    alignment: Alignment.centerRight,
    child: CustomTextButton(
      localized(buttonDone),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      onClick: () => Navigator.pop(ctx),
    ),
  );
}

Widget _buildQRCode() {
  final controller = Get.find<GroupInviteLinkController>();
  return QRCode(
    qrData: controller.selectedGroupInviteLink.link ?? '',
    qrSize: 180,
    roundEdges: false,
  );
}

Widget _shareTitle() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        localized(scanQRCodeTitle),
        style: jxTextStyle.headerText(fontWeight: MFontWeight.bold5.value),
      ),
      const SizedBox(height: 4),
      Text(
        localized(joinGroupByQrCode),
        style: jxTextStyle.textStyle14(color: colorTextSecondary),
      ),
    ],
  );
}

Widget _copyURLContainer() {
  final controller = Get.find<GroupInviteLinkController>();
  return Container(
    decoration: BoxDecoration(
      color: colorTextPrimary.withOpacity(0.03),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.only(left: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            controller.selectedGroupInviteLink.link ?? '',
            style: jxTextStyle.textStyle17(),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        CustomImage(
          'assets/svgs/copyURL_icon.svg',
          size: 24,
          color: colorTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          onClick: () {
            copyToClipboard(
              controller.copyLink,
              toastMessage: localized(copyInvitationLinkSuccess),
            );
          },
        ),
      ],
    ),
  );
}

Widget _shareQRCodeButton(
  BuildContext context,
) {
  final controller = Get.find<GroupInviteLinkController>();
  return CustomButton(
    text: localized(shareQRCode),
    height: 48,
    callBack: () async {
      await controller.forwardGroupViaQR(
        GroupQRNameCard(
          group: controller.group!,
          data: controller.selectedGroupInviteLink.link ?? '',
        ),
        controller.groupId!,
      );

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: colorOverlay40,
        isDismissible: true,
        isScrollControlled: true,
        builder: (BuildContext context) {
          final msg = MessageImage();
          msg.filePath = controller.shareQRFilePath;
          msg.height = 410;
          msg.width = 265;
          Message message = Message();
          message.content = jsonEncode(msg);
          message.typ = messageTypeImage;
          return ForwardContainer(
            forwardMsg: [message],
            onSaveAction: () {
              controller.downloadQR(
                GroupQRNameCard(
                  group: controller.group!,
                  data: controller.selectedGroupInviteLink.link ?? '',
                ),
                controller.groupId!,
              );
            },
            onShareAction: (message) {
              controller.getGroupCardFile(
                DownloadQRCode(downloadLink: controller.downloadLink),
                1,
                isShare: true,
              );
            },
          );
        },
      );
    },
  );
}

Widget _downloadQRCodeTextButton() {
  final controller = Get.find<GroupInviteLinkController>();
  return CustomTextButton(
    localized(download),
    isBold: true,
    color: themeColor,
    padding: const EdgeInsets.all(13),
    onClick: () {
      controller.downloadQR(
        GroupQRNameCard(
          group: controller.group!,
          data: controller.selectedGroupInviteLink.link ?? '',
        ),
        controller.groupId!,
      );
    },
  );
}
