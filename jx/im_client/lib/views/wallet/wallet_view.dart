import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_usdt.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColor,
      appBar: PrimaryAppBar(
        titleColor: Colors.white,
        title: localized(myWallet),
        bgColor: themeColor,
        trailing: [
          GestureDetector(
            onTap: () {
              common.sharedDataManager.gotoWalletHistoryPage(
                navigatorKey.currentContext!,
              );
            },
            child: OpacityEffect(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    localized(walletTransactionHistory),
                    style: jxTextStyle.textStyle17(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
        isBackButton: false,
        leading: getLeading(),
      ),
      body: GetBuilder<WalletController>(
        init: controller,
        builder: (_) {
          return RefreshIndicator(
            onRefresh: () async {
              controller.initWallet();
            },
            edgeOffset: -500.0,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0,
                  color: themeColor,
                ),
                color: colorWhite,
              ),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Container(
                      color: themeColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ImGap.vGap(14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  localized(totalAssetsConverted),
                                  style: jxTextStyle.textStyle14(
                                    color: colorWhite,
                                  ),
                                ),
                                ImGap.hGap8,
                                Text(
                                  ' (${controller.walletBalanceCurrencyType})',
                                  style: jxTextStyle.textStyle14(
                                    color: colorWhite.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            ImGap.vGap8,
                            Obx(
                              () => Text(
                                controller.isShowValue.value
                                    ? controller.walletBalance == 0
                                        ? '0.00'
                                        : '${controller.walletBalance.toString().cFormat()} '
                                    : '* ' * 6,
                                style: TextStyle(
                                  color: colorWhite,
                                  fontSize: 32,
                                  fontWeight: MFontWeight.bold6.value,
                                  fontFamily: appFontfamily,
                                ),
                              ),
                            ),
                            getIconSection(),
                          ],
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        Positioned(
                          child: Container(
                            color: themeColor,
                            height: 20,
                            width: double.infinity,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 24,
                          ),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: colorSurface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 447,
                                  minHeight: 320,
                                ),
                                child: TabBarView(
                                  controller:
                                      controller.walletHomeTabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: const [
                                    WalletHomeUsdt(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  getIconSection() {
    return common.BorderContainer(
      verticalPadding: 16,
      verticalMargin: 16,
      horizontalPadding: 32,
      borderRadius: 16,
      bgColor: Colors.white.withOpacity(0.10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getIconItem(
            txt: localized(scanQRCode),
            svgPath: 'assets/svgs/wallet/wallet_qr_code_icon.svg',
            onTap: () {
              Get.find<ChatListController>().scanQRCode();
            },
          ),
          getIconItem(
            txt: localized(receivePayment),
            svgPath: 'assets/svgs/wallet/wallet_receive_icon.svg',
            onTap: () {
              Get.toNamed(RouteName.myWalletQRView);
            },
          ),
          getIconItem(
            txt: localized(transferMoney),
            svgPath: 'assets/svgs/wallet/wallet_transfer_icon.svg',
            onTap: () {
              Get.toNamed(
                RouteName.transferView,
                arguments: {
                  'isFromQRCode': false,
                },
              );
            },
          ),
        ],
      ),
    );
  }

  getIconItem({txt, svgPath, onTap}) {
    return OpacityEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SvgPicture.asset(
              svgPath,
              width: 40,
              height: 40,
            ),
            ImGap.vGap4,
            Text(
              txt,
              style: TextStyle(
                fontSize: MFontSize.size17.value,
                fontWeight: MFontWeight.bold5.value,
                color: Colors.white,
                fontFamily: appFontfamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getLeading() {
    return OpacityEffect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.back(),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/Back.svg',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                localized(buttonBack),
                style: TextStyle(
                  fontSize: objectMgr.loginMgr.isDesktop
                      ? MFontSize.size13.value
                      : MFontSize.size17.value,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
