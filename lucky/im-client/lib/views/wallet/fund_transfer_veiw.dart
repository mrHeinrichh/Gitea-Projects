import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/object/payment/bobi_recharge_model.dart';
import 'package:jxim_client/object/payment/fund_transfer_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/components/fund_transfer_out.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';
import 'package:jxim_client/views/wallet/wallet_config.dart';

import '../../utils/theme/text_styles.dart';
import 'components/fund_transfer_currency.dart';
import 'components/fund_transfer_in.dart';
import 'components/transaction_pwd_dialog.dart';

class FundTransferView extends GetView<FundTransferController> {
  FundTransferView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        title: '划转',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getTitle('币种类型'),
              getCurrentType(context),
              ImGap.vGap(24),
              getTitle('账户余额之间的转账'),
              getTransferGroup(context),
              ImGap.vGap(24),
              getTitle('划转金额'),
              getTextField(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, top: 10),
                child: Obx(
                    () => controller.currentWallet.value != null ? Text(
                      '账户可用余额: ${controller.currentWallet.value?.amount?.toStringAsFixed(2).cFormat()} '
                          '${controller.currentWallet.value?.currencyType}',
                      style: jxTextStyle.textStyle14(color: JXColors.orange),
                    ) : const SizedBox(),
                ),
              ),
              Obx(
                () => PrimaryButton(
                  title: '确认划转',
                  width: double.infinity,
                  disabled: !controller.isCanSend.value,
                  txtColor: Colors.white,
                  bgColor: accentColor,
                  disabledTxtColor: JXColors.black24,
                  disabledBgColor: JXColors.bgTertiaryColor,
                  onPressed:() async {
                    //先關閉鍵盤
                    FocusScope.of(context).unfocus();
                    //取得劃轉類型
                    String orderType = controller.getOrderType();
                    if (orderType == WalletTransferTypeAPI.BOB_RECHARGE.name ||
                        orderType == WalletTransferTypeAPI.BOB_RECHARGE_TO_USER_BOX.name) {
                      //從波幣轉出去要打波幣api
                      BobiRechargeModel? data = await controller.sendBobiRecharge(context, orderType);
                      if (data != null) {
                        //開啟web view
                        String appId = "bobi_recharge_${DateTime.now()}";
                        if (controller.rechargeBobiView != null) {
                          controller.rechargeBobiView = null;
                        }
                        imMiniAppManager.initMiniApp(
                            appId,
                            data.payUrl ?? "",
                            urlChange: (String url) async {
                              if (url.endsWith("PaySuccess")) {
                                //倘若網址以PaySuccess結尾代表充值成功
                                //導到交易詳情頁面
                                ImBottomToast(context,
                                    title: localized(fundTransferSuccess),
                                    icon: ImBottomNotifType.success);
                                WalletRecordTradeItem? recordData = await controller.getRecordData(context, data.txID!);
                                Get.back();
                                sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
                                // Get.until((route) => route.settings.name == RouteName.walletView);
                              }
                            });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    getRechargeWebView(appId))).then((value) {
                          controller.rechargeBobiView = null;
                        });
                      } else {
                        // ImBottomToast(context,
                        //     title: localized(fundTransferFail),
                        //     icon: ImBottomNotifType.warning);
                      }
                    } else {
                      //如果不是由波幣轉出去直接開啟密碼確認並打劃轉api
                      imShowBottomSheet(context, (context) => TransactionPwdDialog(
                        amount: controller.textController.text,
                        currencyUnit: controller
                            .currentWallet.value?.currencyType,
                        onConfirmFunc: (password,
                            {Function(String errorMsg)? showError,
                              Function(bool isShow)? showDialog}) async {
                          FundTransferModel? data = await controller.sendTransfer(context, orderType, password);
                          Navigator.pop(context); //關閉密碼彈窗
                          if (data != null) {
                            ImBottomToast(context,
                                title: localized(fundTransferSuccess),
                                icon: ImBottomNotifType.success);
                            WalletRecordTradeItem? recordData = await controller.getRecordData(context, data.txID!);
                            Get.back();
                            sharedDataManager.gotoWalletRecordDetailPage(context, recordData);
                            // Get.until((route) => route.settings.name == RouteName.walletView);
                          } else {
                            // ImBottomToast(context,
                            //     title: localized(fundTransferFail),
                            //     icon: ImBottomNotifType.warning);
                          }
                        },
                      ));
                    }
                  },
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  getCurrentType(context) {
    return GestureDetector(
      onTap: () {
        createTransferCurrencyBottomSheet(context);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 8.0,
          top: 4.0,
          bottom: 4.0,
        ),
        decoration: BoxDecoration(
          color: JXColors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            const Expanded(
                child: Text(
              '币种',
              style: const TextStyle(
                color: JXColors.black,
                fontSize: 16.0,
              ),
            )),
            Obx(()=>Text(
              controller.currentWallet.value != null ?
              controller.currentWallet.value!.currencyName ?? "" : "",
              style: const TextStyle(
                color: JXColors.secondaryTextBlack,
                fontSize: 16.0,
              ),
            ),),
            ImGap.hGap8,
            SvgPicture.asset(
              'assets/svgs/wallet/arrow_right.svg',
              width: 20,
              height: 20,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  getTransferGroup(context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        top: 4.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.exchangeWalletTransferType();
            },
            child: SvgPicture.asset(
              'assets/svgs/wallet/fund_transfer_icon.svg',
              width: 24,
              height: 24,
            ),
          ),
          ImGap.hGap16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => getTransferItem(
                      title: '从',
                      chosenItem: controller.fromWalletTransferType.value?.name,
                      onClick: () {
                        createTransferOutBottomSheet(context);
                      },
                      border: true),
                ),
                Obx(
                  () => getTransferItem(
                      title: '到',
                      chosenItem: controller.toWalletTransferType.value?.name,
                      onClick: () {
                        createTransferInBottomSheet(context);
                      }),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  getTitle(txt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        txt,
        style: jxTextStyle.textStyle14(
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }

  getTransferItem(
      {required String title,
      required chosenItem,
      required onClick,
      border = false}) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: border
                  ? JXColors.borderPrimaryColor
                  : Colors.transparent, // 边框颜色
              width: 0.3, // 边框宽度
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: JXColors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            Text(
              chosenItem,
              style: const TextStyle(
                color: JXColors.secondaryTextBlack,
                fontSize: 16.0,
              ),
            ),
            ImGap.hGap8,
            SvgPicture.asset(
              'assets/svgs/wallet/arrow_right.svg',
              width: 20,
              height: 20,
              color: Colors.black,
            ),
            ImGap.hGap8
          ],
        ),
      ),
    );
  }

  getTextField() {
    return Container(
      padding: const EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        right: 12.0,
      ),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TextField(
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,
        controller: controller.textController,
        style: jxTextStyle.textStyle16(),
        maxLines: 1,
        cursorColor: accentColor,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          hintText: '请输入金额',
          hintStyle: const TextStyle(
            color: JXColors.supportingTextBlack,
          ),
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: GestureDetector(
            onTap: () {
              controller.textController.text = (controller.currentWallet.value?.amount).toString();
            },
            child: Text(
              '全部',
              style: TextStyle(
                color: accentColor,
                fontSize: 16.0,
              ),
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  createTransferOutBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (BuildContext context) {
          return const FundTransferOut();
        });
  }

  createTransferInBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (BuildContext context) {
          return const FundTransferIn();
        });
  }

  createTransferCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (BuildContext context) {
          return const FundTransferCurrency();
        });
  }

  //取得進入充值的web
  getRechargeWebView(String appId) {
    return controller.rechargeBobiView ??= imMiniAppManager.startMiniApp(appId);
  }
}
