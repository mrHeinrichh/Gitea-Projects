import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart' as c;
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import '../../utils/color.dart';
import '../component/new_appbar.dart';
import 'package:get/get.dart';

class WalletQRView extends GetWidget<WalletController> {
  const WalletQRView({
    Key? key,
    // required this.address
  }) : super(key: key);

  // final AddressModel address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: const PrimaryAppBar(
        title: '二维码收钱',
        backButtonColor: Colors.white,
        bgColor: Colors.transparent,
        titleColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // height: 276.w,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40).w,
              decoration: BoxDecoration(
                  color: JXColors.white,
                  borderRadius: BorderRadius.circular(12.w)),
              child: Column(
                children: [
                  Container(
                    height: 160.w,
                    width: 160.w,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(
                          color: JXColors.black24,
                          width: 0.3,
                        )),
                    child: FittedBox(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QRCode(
                            qrSize: 160.w,
                            qrData: QrCodeWalletTask.generateAcceptMoneyStr(),
                            roundEdges: false,
                          ),
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(width: 5, color: Colors.white),
                                shape: BoxShape.circle),
                            child: CustomAvatar(
                                uid: objectMgr.userMgr.mainUser.uid,
                                size: 45.w),
                          )
                        ],
                      ),
                    ),
                  ),
                  ImGap.vGap12,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${objectMgr.userMgr.mainUser.nickname}',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: MFontWeight.bold6.value,
                              letterSpacing: 0.8,
                              color: JXColors.black,
                              overflow: TextOverflow.ellipsis),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          objectMgr.userMgr.mainUser.username,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight:MFontWeight.bold4.value,
                              letterSpacing: 0.8,
                              color: JXColors.black,
                              overflow: TextOverflow.ellipsis),
                          textAlign: TextAlign.center,
                        ).encryptString(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ImGap.vGap24,
            // Container(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text('{address.currencyType} Address'),
            //       const SizedBox(height: 15),
            //       Text('{address.address}'),
            //     ],
            //   ),
            // ),
            c.ImRoundContainer(
                child: Column(
              children: [
                c.ImListItem(
                  leading: Padding(
                    padding: const EdgeInsets.all(4.0).w,
                    child: SvgPicture.asset(
                      'assets/svgs/wallet/qr_check.svg',
                      height: 24.w,
                      width: 24.w,
                    ),
                  ),
                  title: '扫码付钱',
                  titleColor: JXColors.black,
                  verticalPadding: 12.w,
                  showArrow: true,
                  showDivider: true,
                  onClick: () async {
                    Get.find<ChatListController>().scanQRCode();
                  },
                ),
                c.ImListItem(
                  leading: Padding(
                    padding: const EdgeInsets.all(4.0).w,
                    child: SvgPicture.asset(
                      'assets/svgs/wallet/friends.svg',
                      height: 24.w,
                      width: 24.w,
                    ),
                  ),
                  title: '向好友转账',
                  titleColor: JXColors.black,
                  verticalPadding: 12.w,
                  showArrow: true,
                  onClick: () {
                    Get.toNamed(RouteName.transferView, arguments: {
                      'isFromQRCode': false,
                    });
                  },
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
