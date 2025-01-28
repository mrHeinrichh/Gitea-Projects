import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';

import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../component/click_effect_button.dart';

class TransferCurrency extends GetView<TransferController> {
  const TransferCurrency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    controller.selectedCurrencyIndexHandler(controller.getCurrentWalletIndex());
    return SafeArea(
      bottom: true,
      child: Container(
        height: 228.w,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(localized(cancel),
                              style:
                              jxTextStyle.textStyle17(color: accentColor)),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '货币类型',
                      style: jxTextStyle.appTitleStyle(
                          color: JXColors.primaryTextBlack),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        controller.setCurrentWallet(controller.totalWalletList[controller.selectedCurrencyIndex.value]);
                        Navigator.pop(context);
                      },
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(localized(buttonDone),
                              style:
                              jxTextStyle.textStyle17(color: accentColor)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
                margin: EdgeInsets.only(left: 32, bottom: 8).w,
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择币种',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: MFontWeight.bold4.value,
                      color: JXColors.black48,
                      fontFamily: appFontfamily),
                )),
            Expanded(
              child: BorderContainer(
                horizontalMargin: 20,
                horizontalPadding: 0,
                verticalPadding: 0,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.totalWalletList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                controller.selectedCurrencyIndexHandler(index),
                            child: Container(
                              height: 44.w,
                              color: Colors.transparent, //不可拿掉,會影響點擊熱區
                              padding: const EdgeInsets.only(
                                  left: 16, top: 11, bottom: 11)
                                  .w,
                              child: Obx(() => Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding:
                                      const EdgeInsets.only(right: 16)
                                          .w,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                ImText(
                                                  controller
                                                      .totalWalletList[
                                                  index].currencyName ?? "",
                                                  fontSize:
                                                  ImFontSize.large,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  index ==
                                      controller
                                          .selectedCurrencyIndex.value
                                      ? CIcon(
                                    icon: CIconModel.iconSelect3,
                                    width: 24.w,
                                    colorFilter: ImColor.accentColor,
                                  )
                                      : SizedBox(
                                    width: 24.w,
                                  ),
                                  ImGap.hGap16,
                                ],
                              )),
                            ),
                          ),
                          if (controller.totalWalletList.length - 1 !=
                              index)
                            Divider(
                              color: JXColors.black.withOpacity(0.08),
                              thickness: 0.3,
                              height: 1,
                              endIndent: 16,
                              indent: 16,
                            )
                        ],
                      );
                    }),
              ),
            ),
            ImGap.vGap(48)
          ],
        ),
      ),
    );
  }
}
