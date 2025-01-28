import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../contact/qr_code.dart';
import '../contact/qr_code_wallet.dart';
import 'controller/my_addresses_controller.dart';

class MyAddressView extends GetView<MyAddressesController> {
  const MyAddressView({Key? key}) : super(key: key);



  Widget subtitle({
    required String title,
    Color? color, double
    marginBottom = 0.0
  }){
    return Container(
      margin: EdgeInsets.only(left: 16, bottom: marginBottom).w,
      alignment: Alignment.centerLeft,
      child: Text(title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: MFontWeight.bold4.value,
          color: color ?? JXColors.black48,
          fontFamily: appFontfamily
        ),
      )
    );
  }

  Widget listItem({
  required String title,
  bool isWithArrow = false,
  Widget? rightWidget,
  GestureTapCallback? onTap
}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(
          minHeight: 44.w
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.w),
        decoration: BoxDecoration(
          color: JXColors.white,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: MFontWeight.bold4.value,
                  fontFamily: appFontfamily,
                  color: JXColors.black,
                ),
                maxLines: 3,
              ),
            ),
            rightWidget ?? const SizedBox(),
            if(isWithArrow) SvgPicture.asset(
              'assets/svgs/arrow_right.svg',
              width: 22.w,
              height: 22.w,
              colorFilter: ColorFilter.mode(
              JXColors.black48, BlendMode.srcIn),
            )
          ],
        )
      ),
    );
  }

  createBottomSheet(BuildContext context){
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return PaymentAddressType();
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JXColors.bgPrimaryColor,
      appBar: PrimaryAppBar(
        title: localized(walletIncoming),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0).w,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24).w,
              child: FutureBuilder(
                future: Future<String>(() {
                  return Future.delayed(
                    const Duration(milliseconds: 500),
                        () => controller.getAddress(),
                  );
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return Container(
                      padding: const EdgeInsets.all(21),
                      child: Center(
                        child: SizedBox(
                          width: 160.w,
                          height: 160.w,
                          child: BallCircleLoading(
                            radius: 20,
                            ballStyle: BallStyle(
                              size: 4,
                              color: accentColor,
                              ballType: BallType.solid,
                              borderWidth: 5,
                              borderColor: accentColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasData){
                    return Obx(()=>Column(
                      children: [
                        Container(
                          height: 160.w,
                          width: 160.w,
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: JXColors.lightGrey,
                              ),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12).w),
                          child: FittedBox(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                QRCode(
                                  qrSize: 160.w,
                                  qrData: QrCodeWalletTask.generateAcceptMoneyStr(address: '${controller.getAddress()}'),
                                  roundEdges: false,
                                ),
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 5,
                                          color: Colors.white
                                      ),
                                      shape: BoxShape.circle
                                  ),
                                  child: CustomAvatar(uid:
                                  objectMgr.userMgr.mainUser.uid, size: 45.w),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.w),
                        Container(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(
                              //       horizontal: 16.0),
                              //   child: Text(
                              //     '${controller.selectedChain.value} ${localized(addressAddress)}',
                              //     style: const TextStyle(
                              //       color: JXColors.darkGrey,
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(
                              //   height: 5,
                              // ),
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
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      objectMgr.userMgr.mainUser.username,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: MFontWeight.bold4.value,
                                        letterSpacing: 0.8,
                                        color: JXColors.black,
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      textAlign: TextAlign.center,
                                    ).encryptString(),
                                  ],
                                ),
                              ),
                              ImGap.vGap24,
                            ],
                          ),
                        ),



                        subtitle(title: '协议', marginBottom: 8),
                        listItem(
                            title: '转账网络',
                            onTap: ()=> createBottomSheet(context),
                            rightWidget: Obx(()=>Text('${controller.selectedChain.value}',
                              style: TextStyle(
                                  color: JXColors.black48,
                                  fontFamily: appFontfamily,
                                  fontWeight:MFontWeight.bold4.value,
                                  fontSize: 16
                              ),)),
                            isWithArrow: true
                        ),
                        ImGap.vGap24,
                        subtitle(title: '收款地址', marginBottom: 8),
                        listItem(title: controller.getAddress()),
                        ImGap.vGap24,
                        subtitle(title: '收款说明'),
                        subtitle(title: controller.paymentDescription.value),

                        ImGap.vGap24,
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                        text: controller
                                            .getAddress()),
                                  );
                                  Toast.showToast(
                                    localized(toastCopySuccess),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                  color: JXColors.white,
                                  ),
                                  height: 48.w,
                                  child: Center(
                                    child: Text(
                                      localized(addressCopyAddress),
                                      style: jxTextStyle.textStyleBold14(
                                        color: JXColors.primaryTextBlack,
                                        fontWeight: MFontWeight.bold6.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  controller.downloadQR(
                                    Container(
                                      constraints:
                                      const BoxConstraints(
                                        maxHeight: 400,
                                      ),
                                      margin:
                                      const EdgeInsets.all(10),
                                      padding:
                                      const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                            JXColors.lightGrey,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(
                                              12).w),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              child: QRCode(
                                                qrSize: 200,
                                                qrData:
                                                snapshot.data!,
                                                roundEdges: false,
                                              ),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0, vertical: 8).w,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${objectMgr.userMgr.mainUser.nickname}',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:MFontWeight.bold6.value,
                                                    letterSpacing: 0.8,
                                                    color: JXColors.black,
                                                  ),
                                                ),
                                                Text(
                                                  ' (${objectMgr.userMgr.mainUser.username})',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:MFontWeight.bold4.value,
                                                    letterSpacing: 0.8,
                                                    color: JXColors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    context,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius:
                                    BorderRadius.circular(12).w,
                                  ),
                                  height:48.w,
                                  child: Center(
                                    child: Text(
                                      localized(addressSaveImage),
                                      style: jxTextStyle.textStyleBold14(
                                        color: JXColors.primaryTextWhite,
                                        fontWeight: MFontWeight.bold6.value,
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
                  } else
                    return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class PaymentAddressType extends  GetView<MyAddressesController> {
  const PaymentAddressType({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    controller.preselectedChain.value = controller.selectedChain.value;
    return Container(
      height: 260.w,
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            height: 60.w,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 0.0,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: OpacityEffect(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                            localized(walletCancel),
                            style: jxTextStyle.textStyle17(
                                color: accentColor)),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '链名称',
                    style: jxTextStyle.appTitleStyle(
                        color: JXColors.primaryTextBlack),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      controller
                          .changeNetwork(controller.preselectedChain.value);
                      Navigator.pop(context);
                    },
                    child: OpacityEffect(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                            localized(buttonDone),
                            style: jxTextStyle.textStyle17(
                                color: accentColor)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ImGap.vGap24,
          Container(
              margin: EdgeInsets.only(left: 32, bottom: 8).w,
              alignment: Alignment.centerLeft,
              child: Text('选择转账的网络协议',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: MFontWeight.bold4.value,
                    color:JXColors.black48,
                    fontFamily: appFontfamily
                ),
              )
          ),
          BorderContainer(
            borderRadius: 12,
            horizontalPadding: 0,
            verticalPadding: 5,
            horizontalMargin: 18,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.cryptoCurrencyList[0].supportNetType?.length,
              itemBuilder: (BuildContext context, int index) {
                final type =  controller.cryptoCurrencyList[0].supportNetType?[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: ()=> controller.changePreselectedNetWork(type),
                      child: Container(
                        height: 44.w,
                        color: Colors.transparent, //不可拿掉,會影響點擊熱區
                        padding: const EdgeInsets.only(left: 16, top: 11, bottom: 11).w,
                        child: Obx(()=>Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(right: 16).w,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ImText(
                                            type,
                                            fontSize: ImFontSize.large,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            type == controller.preselectedChain.value
                                ? SvgPicture.asset(
                              'assets/svgs/check1.svg',
                              width: 24.w,
                              height: 24.w,
                            )
                                : SizedBox(
                              width: 24.w,
                            ),
                            ImGap.hGap16,
                          ],
                        )),
                      ),
                    ),
                    if ( controller.cryptoCurrencyList[0].supportNetType!.length - 1 != index)
                      Divider(
                        color:JXColors.black.withOpacity(0.08),
                        thickness: 0.3,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      )
                  ],
                );
              },
            ),
          ),
        ],
      )
    );
  }
}

