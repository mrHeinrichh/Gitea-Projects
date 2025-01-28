import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';
import 'package:jxim_client/views/contact/components/download_qr_name_card.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';


class DesktopQrCodeDialog extends StatelessWidget {
  final User? user;
  final bool isFriend;

  const DesktopQrCodeDialog({
    super.key,
    this.user,
    this.isFriend = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
            width: 360,
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: GetBuilder<QRCodeViewController>(
              init: QRCodeViewController.create(
                user ?? objectMgr.userMgr.mainUser,
              ),
              builder: (value) {
                value.generateNameCardData();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTopBar(),
                    const SizedBox(height: 16),
                    buildQRCode(value),
                    const SizedBox(height: 12),
                    _shareTitle(),
                    const SizedBox(height: 16),
                    _copyURLContainer(user ?? objectMgr.userMgr.mainUser, context),
                    const SizedBox(height: 16),
                    _downloadQRCodeButton(value, user),
                  ],
                );
              },
            )),
      ),
    );
  }

  Widget buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        border: customBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: CustomImage(
              'assets/svgs/close_round_outlined.svg',
              color: themeColor,
              padding: const EdgeInsets.only(left: 20),
              size: 24,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 110),
            child: Text('好友名片'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildQRCode(QRCodeViewController value) {
    return QRCode(
      qrData: value.nameCardData.value,
      qrSize: 180,
      roundEdges: false,
    );
  }

  Widget _shareTitle() {
    return Column(
      children: [
        Text(
          isFriend ? localized(friendContactCard) : localized(shareContactCard),
          style: jxTextStyle.headerText(fontWeight: MFontWeight.bold5.value),
        ),
        const SizedBox(height: 4),
        Text(
          localized(useQrAddFriend),
          style: jxTextStyle.normalText(color: colorTextSecondary),
        ),
      ],
    );
  }

  Widget _copyURLContainer(User? user, BuildContext context) {
    final link = ShareLinkUtil.generateFriendShareLink(user?.uid);
    return Container(
      decoration: BoxDecoration(
        color: colorTextPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.only(left: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              link,
              style: jxTextStyle.textStyle14(),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          CustomImage(
            'assets/svgs/copyURL_icon.svg',
            size: 24,
            color: colorTextPrimary,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            onClick: () {
              imBottomToast(
                context,
                title: '已复制至剪贴板',
                icon: ImBottomNotifType.copy,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _downloadQRCodeButton(QRCodeViewController value, User? user) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(
          color: colorDivider,
          width: 0.33,
        )),
      ),
      child: Center(
        child: CustomTextButton(
          localized(download),
          fontSize: 14,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 11,
          ),
          onClick: () {
            value.generateNameCardData();
            value.downloadQR(
              DownloadQRNameCard(
                user: user ?? objectMgr.userMgr.mainUser,
                data: value.nameCardData.value,
              ),
              user != null ? user.uid : objectMgr.userMgr.mainUser.uid,
            );
          },
        ),
      ),
    );
  }
}
