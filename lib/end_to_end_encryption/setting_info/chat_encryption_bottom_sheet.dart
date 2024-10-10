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
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatEncryptionBottomSheet extends StatefulWidget {
  const ChatEncryptionBottomSheet(
      {required this.chat,
      required this.qrCode,
      required this.signatureText,
      super.key});

  final Chat chat;
  final String qrCode;
  final String signatureText;

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
        const SizedBox(height: 16),
        QRCode(
          qrData: widget.qrCode,
          qrSize: MediaQuery.of(Get.context!).size.width,
          roundEdges: false,
          color: colorQrCode,
        ),
        // Text(
        //   widget.signatureText,
        //   style: jxTextStyle.textStyle14(color: Colors.black),
        //   textAlign: TextAlign.center,
        // ),
        // const SizedBox(height: 16),
        Text(
          localized(chatEncryptionContentHeader, params: [widget.chat.name]),
          style: jxTextStyle.textStyle14(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Text(
        //   localized(chatEncryptionContentMiddle, params: [widget.chat.name]),
        //   style: jxTextStyle.textStyle14(color: Colors.black),
        //   textAlign: TextAlign.center,
        // ),
        // const SizedBox(height: 16),
        // RichText(
        //   text: TextSpan(
        //     children: [
        //       TextSpan(
        //         text: localized(chatEncryption),
        //         style: jxTextStyle.textStyle14(color: Colors.black),
        //       ),
        //       TextSpan(
        //         text: " " + localized(officialSite),
        //         style: jxTextStyle.textStyle14(color: themeColor),
        //         recognizer: TapGestureRecognizer()
        //           ..onTap = () {
        //             // Get.back();
        //             // redirectToWebDownload(data?.url);
        //           },
        //       ),
        //     ],
        //   ),
        // ),
        const SizedBox(height: 16),
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

    final PermissionStatus status = await Permission.camera.status;
    Map<String, dynamic> args = {
      'type': ScanQrCodeType.verifyPrivateKey,
      'chat': widget.chat,
    };

    if (status.isGranted) {
      Get.toNamed(RouteName.qrCodeScanner, arguments: args);
    } else {
      final bool rationale = await Permission.camera.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied) {
        openSettingPopup(Permissions().getPermissionName(Permission.camera));
      } else {
        final PermissionStatus status = await Permission.camera.request();
        if (status.isGranted) {
          Get.toNamed(RouteName.qrCodeScanner, arguments: args);
        }
        if (status.isPermanentlyDenied) {
          openSettingPopup(Permissions().getPermissionName(Permission.camera));
        }
      }
    }
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
