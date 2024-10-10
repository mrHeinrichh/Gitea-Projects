import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/download_qr_code.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/share_controller.dart';

class ShareView extends GetView<ShareController> {
  const ShareView({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildMobileShareView(context);
  }

  Widget _buildMobileShareView(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        color: colorWhite,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _doneButton(ctx),
                  _buildQRCode(),
                  const SizedBox(height: 12),
                  _shareTitle(),
                  const SizedBox(height: 16),
                  _copyURLContainer(),
                  const SizedBox(height: 16),
                  _shareQRCodeButton(),
                  const SizedBox(height: 16),
                  _downloadQRCodeTextButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneButton(BuildContext ctx) {
    return Align(
      alignment: Alignment.centerRight,
      child: CustomTextButton(
        localized(buttonDone),
        padding: const EdgeInsets.symmetric(vertical: 19),
        onClick: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _shareTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          localized(shareHeyTalk, params: [Config().appName]),
          style: jxTextStyle.textStyleBold16(),
        ),
        const SizedBox(height: 4),
        Text(
          localized(scanToDownloadApp),
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Obx(
        () => controller.isLoading.value
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: themeColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            : QRCode(
                qrData: controller.downloadLink.value,
                qrSize: 180,
                roundEdges: false,
              ),
      ),
    );
  }

  Widget _copyURLContainer() {
    return Container(
      decoration: BoxDecoration(
        color: colorTextPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Obx(() {
            return Expanded(
              child: Text(
                controller.downloadLink.value,
                style: jxTextStyle.textStyle17(),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            );
          }),
          CustomImage(
            'assets/svgs/copyURL_icon.svg',
            size: 24,
            color: colorTextPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            onClick: () {
              copyToClipboard(
                localized(
                  invitationWithLink,
                  params: [Config().appName, controller.downloadLink.value],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shareQRCodeButton() {
    return CustomButton(
      text: localized(shareQRCode),
      height: 48,
      callBack: () {
        controller.downloadAppQR(
          DownloadQRCode(downloadLink: controller.downloadLink.value),
          isShare: true,
        );
      },
    );
  }

  Widget _downloadQRCodeTextButton() {
    return CustomTextButton(
      localized(download),
      isBold: true,
      color: colorTextPrimary,
      padding: const EdgeInsets.all(13),
      onClick: () {
        controller.downloadAppQR(
          DownloadQRCode(downloadLink: controller.downloadLink.value),
        );
      },
    );
  }
}
