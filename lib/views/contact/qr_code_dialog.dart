import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/components/download_qr_name_card.dart';
import 'package:jxim_client/views/contact/download_qr_code.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';

void showQRCodeDialog(
  BuildContext context, {
  bool isShareQRCode = true,
  bool isFriend = false,
  User? user,
  Function()? onCloseClick,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: colorWhite,
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
            GetBuilder<QRCodeViewController>(
              init: QRCodeViewController.create(
                user ?? objectMgr.userMgr.mainUser,
              ),
              builder: (value) {
                value.generateNameCardData();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildQRCode(value),
                      const SizedBox(height: 12),
                      _shareTitle(isFriend),
                      const SizedBox(height: 16),
                      _copyURLContainer(user ?? objectMgr.userMgr.mainUser),
                      const SizedBox(height: 16),
                      _shareQRCodeButton(isShareQRCode, value, user, ctx),
                      const SizedBox(height: 16),
                      _downloadQRCodeTextButton(value, user),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  ).then((value) => onCloseClick != null ? onCloseClick() : null);
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

Widget _buildQRCode(QRCodeViewController value) {
  return QRCode(
    qrData: value.nameCardData.value,
    qrSize: 180,
    roundEdges: false,
  );
}

Widget _shareTitle(bool isFriend) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        isFriend ? localized(friendContactCard) : localized(shareContactCard),
        style: jxTextStyle.textStyleBold16(),
      ),
      const SizedBox(height: 4),
      Text(
        localized(useQrAddFriend),
        style: jxTextStyle.textStyle14(color: colorTextSecondary),
      ),
    ],
  );
}

Widget _copyURLContainer(User? user) {
  final link = ShareLinkUtil.generateFriendShareLink(user?.uid);
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
            link,
            style: jxTextStyle.textStyle17(),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        CustomImage(
          'assets/svgs/copyURL_icon.svg',
          size: 24,
          color: colorTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          onClick: () => copyToClipboard(link),
        ),
      ],
    ),
  );
}

Widget _shareQRCodeButton(
  bool isShareQRCode,
  QRCodeViewController value,
  User? user,
  BuildContext ctx,
) {
  return CustomButton(
    text: localized(shareQRCode),
    height: 48,
    callBack: () {
      if (isShareQRCode) {
        value.shareQRToAnotherApp(
          DownloadQRNameCard(
            user: user ?? objectMgr.userMgr.mainUser,
            data: value.nameCardData.value,
          ),
          user != null ? user.uid : objectMgr.userMgr.mainUser.uid,
        );
      } else {
        Navigator.pop(ctx);
      }
    },
  );
}

Widget _downloadQRCodeTextButton(QRCodeViewController value, User? user) {
  return CustomTextButton(
    localized(download),
    isBold: true,
    color: colorTextPrimary,
    padding: const EdgeInsets.all(13),
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
  );
}

void qrCodeDialogMyMoneyCode(
  BuildContext context, {
  Function()? onLeftBtnClick,
  Function()? onCloseClick,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _doneButton(context),
            separateDivider(indent: 0.0),
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
                        localized(walletQrReceivePayment),
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
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: colorTextPrimary.withOpacity(0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(scanQRCode),
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
                                value.downloadQR(
                                  DownloadQRCode(
                                    downloadLink: value.nameCardData.value,
                                  ),
                                  objectMgr.userMgr.mainUser.uid,
                                );
                              },
                              child: ForegroundOverlayEffect(
                                overlayColor: colorTextPrimary.withOpacity(0.3),
                                radius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                  bottom: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    localized(download),
                                    style: jxTextStyle.textStyleBold14(
                                      color: Colors.white,
                                    ),
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
