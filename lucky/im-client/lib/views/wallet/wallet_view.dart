import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/wallet/components/wallet_home_usdt.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../home/chat/controllers/chat_list_controller.dart';
import '../../main.dart';
import '../../utils/color.dart';
import '../component/new_appbar.dart';
import 'components/wallet_home_currency.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimaryAppBar(
          titleColor: Colors.white,
          title: localized(myWallet),
          bgColor: accentColor,
          trailing: [
            GestureDetector(
                onTap: () {
                  // Get.toNamed(RouteName.transactionHistoryView);
                  common.sharedDataManager.gotoWalletHistoryPage(
                      Routes.navigatorKey.currentContext!);
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      localized(walletTransactionHistory),
                      style: jxTextStyle.textStyle17(color: Colors.white),
                    ),
                  ),
                ))
          ],
          isBackButton: false,
          //CustomLeadingIcon的backButtonColor無法work,所以先自己寫樣式進去leading
          leading: getLeading()),
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
              height: double.infinity,
              child: ListView(
                physics: const ClampingScrollPhysics(), // 不允许滚动出边界
                children: [
                  ///頂部藍底區塊
                  Container(
                    color: accentColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ImGap.vGap20,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localized(totalAssetsConverted),
                                style: jxTextStyle.textStyle14(
                                    color: JXColors.white),
                              ),
                              ImGap.hGap8,
                              Text(
                                ' (${controller.walletBalanceCurrencyType})',
                                style: jxTextStyle.textStyle14(
                                  color: JXColors.secondaryTextWhite,
                                ),
                              )
                            ],
                          ),
                          ImGap.vGap8,
                          Obx(
                            () => Text(
                              controller.isShowValue.value
                                  ? controller.walletBalance == 0
                                      ? '0.00'
                                      : '${controller.walletBalance.toString().cFormat()} '
                                  : '${'* ' * 6}',
                              style: TextStyle(
                                color: JXColors.white,
                                fontSize: 32,
                                fontWeight: MFontWeight.bold6.value,
                                fontFamily: appFontfamily,
                              ),
                            ),
                          ),
                          getIconSection()
                        ],
                      ),
                    ),
                  ),

                  ///下方資料tab區塊
                  Stack(
                    children: [
                      //這塊Positioned位置在白色區塊上面的後方背景,
                      //目的是讓白色border區塊後面是accentColor背景色
                      Positioned(
                          child: Container(
                        color: accentColor,
                        height: 20,
                        width: double.infinity,
                      )),
                      Container(
                        padding:
                            const EdgeInsets.only(left: 16, right: 16, top: 20),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            )),
                        child: Column(
                          children: [
                            //Tabbar
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFf1f1f1),
                                  border: Border.all(
                                    width: 2,
                                    color: const Color(0xFFf1f1f1),
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              height: 36,
                              width: 204,
                              alignment: Alignment.center,
                              child: TabBar(
                                splashFactory: NoSplash.splashFactory,
                                overlayColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                controller: controller.walletHomeTabController,
                                isScrollable: true,
                                dividerColor: Colors.transparent,
                                tabAlignment: TabAlignment.center,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                indicatorColor: Colors.transparent,
                                labelStyle: TextStyle(
                                    color: JXColors.secondaryTextBlack,
                                    fontSize: 17,
                                    fontWeight: MFontWeight.bold5.value,
                                    leadingDistribution:
                                        TextLeadingDistribution.even,
                                    fontFamily: appFontfamily),
                                unselectedLabelColor: JXColors.black48,
                                labelPadding: EdgeInsets.zero,
                                tabs: [
                                  Tab(
                                    child: OpacityEffect(
                                      child: Container(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 5),
                                        alignment: Alignment.center,
                                        width: 100,
                                        height: 33,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svgs/wallet/wallet_cny_icon.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            ImGap.hGap4,
                                            Text(
                                              localized(currencyCNY),
                                              strutStyle: const StrutStyle(
                                                  fontSize: 17, height: 1),
                                              style: TextStyle(
                                                  height: 1,
                                                  fontSize:
                                                      MFontSize.size17.value,
                                                  fontWeight: MFontWeight.bold5.value,
                                                  fontFamily:
                                                      appFontfamily),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: OpacityEffect(
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: 100,
                                        height: 33,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svgs/wallet/wallet_usdt_icon.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            ImGap.hGap4,
                                            Text(
                                              'USDT',
                                              strutStyle: const StrutStyle(
                                                  fontSize: 17, height: 1),
                                              style: TextStyle(
                                                  height: 1,
                                                  fontSize:
                                                      MFontSize.size17.value,
                                                  fontWeight: MFontWeight.bold5.value,
                                                  fontFamily:
                                                      appFontfamily),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(
                                  maxHeight: 447, minHeight: 320),
                              child: TabBarView(
                                  controller:
                                      controller.walletHomeTabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    WalletHomeCurrency(),
                                    const WalletHomeUsdt(),
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
      bgColor: JXColors.whiteColor10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getIconItem(
              txt: localized(scanQRCode),
              svgPath: 'assets/svgs/wallet/wallet_qr_code_icon.svg',
              onTap: () {
                Get.find<ChatListController>().scanQRCode();
              }),
          getIconItem(
              txt: localized(receivePayment),
              svgPath: 'assets/svgs/wallet/wallet_receive_icon.svg',
              onTap: () {
                Get.toNamed(RouteName.myWalletQRView);
              }),
          getIconItem(
              txt: localized(transferMoney),
              svgPath: 'assets/svgs/wallet/wallet_transfer_icon.svg',
              onTap: () {
                Get.toNamed(RouteName.transferView, arguments: {
                  'isFromQRCode': false,
                });
              })
        ],
      ),
    );
  }

  getIconItem({txt, svgPath, onTap}) {
    return GestureDetector(
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
                fontFamily: appFontfamily),
          )
        ],
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
