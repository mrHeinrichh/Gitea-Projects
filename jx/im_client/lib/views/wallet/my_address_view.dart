import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';
import 'package:jxim_client/views/wallet/controller/my_addresses_controller.dart';

class MyAddressView extends GetView<MyAddressesController> {
  const MyAddressView({super.key});

  @override
  MyAddressesController get controller =>
      Get.findOrPut<MyAddressesController>(MyAddressesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(title: localized(walletDeposit)),
      body: FutureBuilder(
        future: Future<String>(() {
          return Future.delayed(
            const Duration(milliseconds: 500),
            () => controller.getAddress(),
          );
        }),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBody(context),
                const SizedBox(height: 24),
                _buildBottomButtons(context, snapshot.data!),
              ],
            );
          }

          return Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: BallCircleLoading(
                radius: 20,
                ballStyle: BallStyle(
                  size: 4,
                  color: themeColor,
                  ballType: BallType.solid,
                  borderWidth: 5,
                  borderColor: themeColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 160,
          width: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: colorBackground6),
            color: colorWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Obx(
                  () => QRCode(
                    qrSize: 160,
                    qrData: controller.getAddress(),
                    roundEdges: false,
                  ),
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 5,
                      color: colorWhite,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomAvatar.user(
                    objectMgr.userMgr.mainUser,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          objectMgr.userMgr.mainUser.nickname,
          style: TextStyle(
            fontSize: MFontSize.size17.value,
            fontWeight: MFontWeight.bold5.value,
            letterSpacing: 0.8,
            color: colorTextPrimary,
            overflow: TextOverflow.ellipsis,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          objectMgr.userMgr.mainUser.username,
          style: TextStyle(
            fontSize: MFontSize.size17.value,
            fontWeight: MFontWeight.bold4.value,
            letterSpacing: 0.8,
            color: colorTextSecondary,
            overflow: TextOverflow.ellipsis,
          ),
          textAlign: TextAlign.center,
        ).encryptString(),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomRoundContainer(
          title: localized(walletChain),
          child: Obx(
            () => CustomListTile(
              text: localized(walletTransferNetwork),
              rightText: controller.selectedChain.value,
              // onClick: () async => _showPaymentAddressTypeDialog(context),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomRoundContainer(
          constraints: const BoxConstraints(minHeight: 64),
          title: localized(walletPaymentAddress),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          child: Obx(
            () => Text(
              controller.getAddress(),
              style: TextStyle(
                fontSize: MFontSize.size17.value,
                fontWeight: MFontWeight.bold4.value,
                color: colorTextPrimary,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localized(walletPaymentInstructions),
                style: jxTextStyle.textStyle13(
                  color: colorTextPrimary.withOpacity(0.56),
                ),
              ),
              Text(
                controller.paymentDescription.value,
                style: jxTextStyle.textStyle13(
                  color: colorTextPrimary.withOpacity(0.56),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, String qrData) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: localized(addressCopyAddress),
            textColor: colorTextPrimary,
            color: colorWhite,
            callBack: () async {
              Clipboard.setData(ClipboardData(text: controller.getAddress()));
              Toast.showToast(localized(toastCopySuccess));
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: localized(addressSaveImage),
            callBack: () {
              controller.downloadQR(_buildDownloadQR(qrData), context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadQR(String qrData) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      alignment: Alignment.center,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: colorBackground6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QRCode(
            qrSize: 200,
            qrData: qrData,
            roundEdges: false,
          ),
          const SizedBox(height: 24),
          Text(
            objectMgr.userMgr.mainUser.nickname,
            style: TextStyle(
              fontSize: MFontSize.size17.value,
              fontWeight: MFontWeight.bold5.value,
              letterSpacing: 0.8,
              color: colorTextPrimary,
              overflow: TextOverflow.ellipsis,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '(${objectMgr.userMgr.mainUser.username})',
            style: TextStyle(
              fontSize: MFontSize.size17.value,
              fontWeight: MFontWeight.bold4.value,
              letterSpacing: 0.8,
              color: colorTextSecondary,
              overflow: TextOverflow.ellipsis,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
