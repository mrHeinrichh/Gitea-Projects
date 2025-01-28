import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class FundTransferCurrency extends GetView<FundTransferController> {
  const FundTransferCurrency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    controller.selectedIndexHandler(controller.getCurrentWalletIndex());
    return SafeArea(
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60.w,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16).w,
                        child: Text(
                          localized(cancel),
                          style: jxTextStyle.textStyle17(color: accentColor),
                        ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      controller.setCurrentWallet(controller
                          .totalWalletTypeList[controller.selectedIndex.value]);
                      Navigator.pop(context);
                    },
                    child: OpacityEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16).w,
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(color: accentColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 16,
            ).w,
            child: ImRoundContainer(
              title: '货币类型',
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.totalWalletTypeList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Obx(
                    () => ImSelectItem(
                      title:
                          controller.totalWalletTypeList[index].currencyName ??
                              "",
                      isSelected: index == controller.selectedIndex.value,
                      showDivider:
                          controller.totalWalletTypeList.length - 1 != index,
                      onClick: () => controller.selectedIndexHandler(index),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
