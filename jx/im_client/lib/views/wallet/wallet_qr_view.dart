import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

class WalletQRView extends GetWidget<WalletController> {
  const WalletQRView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColor,
      resizeToAvoidBottomInset: false,
      appBar: PrimaryAppBar(
        title: localized(walletQrCodePayment),
        backButtonColor: colorWhite,
        bgColor: Colors.transparent,
        titleColor: colorWhite,
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              CustomRoundContainer(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(33, 60, 33, 40),
                child: Column(
                  children: [
                    FittedBox(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QRCode(
                            qrSize: 180,
                            qrData: QrCodeWalletTask.generateAcceptMoneyStr(),
                            roundEdges: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      objectMgr.userMgr.mainUser.nickname,
                      style: TextStyle(
                        fontSize: MFontSize.size17.value,
                        fontWeight: MFontWeight.bold6.value,
                        letterSpacing: 0.8,
                        color: colorTextPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      objectMgr.userMgr.mainUser.username,
                      style: TextStyle(
                        fontSize: MFontSize.size14.value,
                        fontWeight: MFontWeight.bold4.value,
                        letterSpacing: 0.8,
                        color: colorTextSecondary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.center,
                    ).encryptString(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomRoundContainer(
                child: Column(
                  children: [
                    CustomListTile(
                      height: 56,
                      leading: CustomImage(
                        'assets/svgs/wallet/qr_check.svg',
                        size: 29,
                        color: themeColor,
                      ),
                      text: localized(walletQrScanToPay),
                      textFontWeight: MFontWeight.bold5.value,
                      showDivider: true,
                      onArrowClick: () async {
                        Get.find<ChatListController>().scanQRCode();
                      },
                    ),
                    CustomListTile(
                      height: 56,
                      leading: CustomImage(
                        'assets/svgs/wallet/wallet_transfer_outlined.svg',
                        size: 29,
                        color: themeColor,
                      ),
                      text: localized(walletQrTransferToFriend),
                      textFontWeight: MFontWeight.bold5.value,
                      onArrowClick: () async {
                        if (Get.isRegistered<TransferController>()) {
                          Get.delete<TransferController>();
                        }
                        Get.toNamed(
                          RouteName.transferView,
                          arguments: {'isFromQRCode': false},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
