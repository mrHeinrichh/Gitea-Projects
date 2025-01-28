import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class FundTransferIn extends GetView<FundTransferController> {
  const FundTransferIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    controller.selectedIndexHandler(controller.getCurrentToTransferIndex());
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
                    '转入',
                    style: jxTextStyle.appTitleStyle(
                        color: JXColors.primaryTextBlack),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      if (controller.fromWalletTransferType.value?.code ==
                          controller
                              .walletTransferTypeList[
                                  controller.selectedIndex.value]
                              .code) {
                        controller.exchangeWalletTransferType();
                      } else {
                        controller.setWalletTransferType(
                            controller.fromWalletTransferType.value!,
                            controller.walletTransferTypeList[
                                controller.selectedIndex.value]);
                      }
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
              title: '选择转入的钱包',
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.walletTransferTypeList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Obx(
                    () => ImSelectItem(
                      title: controller.walletTransferTypeList[index].name,
                      isSelected: index == controller.selectedIndex.value,
                      showDivider:
                          controller.walletTransferTypeList.length - 1 != index,
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
