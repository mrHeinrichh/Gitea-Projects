import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/custom_encryption_bottom_sheet_view.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatEncryptionBottomSheet extends StatefulWidget {
  const ChatEncryptionBottomSheet(
      {required this.chat,
      this.qrCode,
      required this.signatureList,
      super.key});

  final Chat chat;
  final String? qrCode;
  final List<List<String>> signatureList;

  @override
  State<ChatEncryptionBottomSheet> createState() =>
      _ChatEncryptionBottomSheet();
}

class _ChatEncryptionBottomSheet extends State<ChatEncryptionBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  Widget _getContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.qrCode != null) const SizedBox(height: 16),
        if (widget.qrCode != null)
          QRCode(
            qrData: widget.qrCode!,
            qrSize: 250,
            roundEdges: false,
            color: colorQrCode,
          ),
        if (widget.qrCode != null) const SizedBox(height: 16),
        ...List.generate(
          widget.signatureList.length,
          (index) => SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...List.generate(
                  widget.signatureList[index].length,
                  (i2) => SizedBox(
                    width: 30,
                    child: Text(
                      widget.signatureList[index][i2],
                      style: jxTextStyle.textStyle14(color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.chat.isSingle
              ? localized(chatEncryptionContentHeader,
                  params: [widget.chat.name])
              : localized(chatEncryptionGroupContentHeader,
                  params: [localized(chatTagGroup)]),
          style: jxTextStyle.textStyle14(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          localized(widget.chat.isSingle
              ? chatEncryptionContentMiddle
              : chatEncryptionGroupContentMiddle),
          style: jxTextStyle.textStyle14(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (widget.qrCode != null)
          OpacityEffect(
            child: GestureDetector(
              onTap: () {
                scanQrCode();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/camera.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  Text(
                    localized(homeScanQR),
                    style: jxTextStyle.textStyle14(color: themeColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> scanQrCode() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;

    Get.toNamed(RouteName.qrCodeScanner, arguments: {
      'type': ScanQrCodeType.verifyPrivateKey,
      'chat': widget.chat,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomEncryptionBottomSheetView(
      title: localized(chatEncryptionPageTitle),
      leading: null,
      // showDoneButton: false,
      headerText: localized(groupEncryptionInfoHeader),
      subHeaderText: localized(groupEncryptionInfoSubHeader),
      content: _getContent(),
      showMainHeader: false,
      // listItems: [
      //   localized(groupEncryptionListWordAndAudio),
      //   localized(groupEncryptionListVideoAndAudio),
      //   localized(groupEncryptionListImageAndVideo),
      //   localized(groupEncryptionListLocation),
      //   localized(newQRCommunity),
      // ],
      // primaryButtonOnTap: () {
      // },
    );
  }
}
