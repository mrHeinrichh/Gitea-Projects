import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import '../../home/component/custom_divider.dart';
import '../../main.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import 'components/download_qr_name_card.dart';
import 'download_qr_code.dart';

void qrCodeDialog(
  BuildContext context, {
  Function()? onLeftBtnClick,
  Function()? onCloseClick,
}) {
  double btnHeight = 48;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                child: Text(
                  localized(buttonDone),
                  style: jxTextStyle.textStyle17(color: accentColor),
                ),
              ),
            ),
            SeparateDivider(indent: 0.0),
            GetBuilder<QRCodeViewController>(
              init: QRCodeViewController.create(objectMgr.userMgr.mainUser),
              builder: (value) {
                value.generateNameCardData();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    children: [
                      QRCode(
                        qrData: value.nameCardData.value,
                        qrSize: 180,
                        roundEdges: false,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localized(useQrAddFriend),
                        style: jxTextStyle.textStyle16(),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onLeftBtnClick ??
                                  () => Navigator.pop(context),
                              child: OverlayEffect(
                                radius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                  bottom: Radius.circular(12),
                                ),
                                child: Container(
                                  height: btnHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: JXColors.borderPrimaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(scanQrCode),
                                    style: jxTextStyle.textStyleBold14(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                value.generateNameCardData();
                                value.downloadQR(DownloadQRNameCard(
                                    user: objectMgr.userMgr.mainUser,
                                    data: value.nameCardData.value));
                              },
                              child: ForegroundOverlayEffect(
                                overlayColor:
                                    JXColors.primaryTextBlack.withOpacity(0.3),
                                radius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                  bottom: Radius.circular(12),
                                ),
                                child: Container(
                                  height: btnHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(download),
                                    style: jxTextStyle.textStyleBold14(
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  ).then((value) => onCloseClick!());
}

void qrCodeDialogMyMoneyCode(BuildContext context,
    {Function()? onLeftBtnClick, Function()? onCloseClick}) {
  double btnHeight = 48;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                child: Text(
                  localized(buttonDone),
                  style: jxTextStyle.textStyle17(color: accentColor),
                ),
              ),
            ),
            SeparateDivider(indent: 0.0),
            GetBuilder<QRCodeViewController>(
              init: QRCodeViewController.create(objectMgr.userMgr.mainUser)
                ..generateNameCardData(),
              builder: (value) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    children: [
                      QRCode(
                        qrData: QrCodeWalletTask.generateAcceptMoneyStr(),
                        qrSize: 180,
                        roundEdges: false,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '使用二维码来收款',
                        style: jxTextStyle.textStyle16(),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onLeftBtnClick ??
                                  () => Navigator.pop(context),
                              child: OverlayEffect(
                                radius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                  bottom: Radius.circular(12),
                                ),
                                child: Container(
                                  height: btnHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: JXColors.borderPrimaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(scanQrCode),
                                    style: jxTextStyle.textStyleBold14(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                value.downloadQR(DownloadQRCode(
                                    downloadLink: value.nameCardData.value));
                              },
                              child: ForegroundOverlayEffect(
                                overlayColor:
                                    JXColors.primaryTextBlack.withOpacity(0.3),
                                radius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                  bottom: Radius.circular(12),
                                ),
                                child: Container(
                                  height: btnHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(download),
                                    style: jxTextStyle.textStyleBold14(
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  ).then((value) => onCloseClick!());
}
