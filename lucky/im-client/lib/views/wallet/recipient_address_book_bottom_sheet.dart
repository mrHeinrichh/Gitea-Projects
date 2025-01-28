import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as c;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';

import '../../managers/object_mgr.dart';
import '../../utils/color.dart';
import '../../utils/theme/text_styles.dart';
import '../component/click_effect_button.dart';
import '../component/searching_app_bar.dart';

class RecipientAddressBookBottomSheet extends StatelessWidget {
  const RecipientAddressBookBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RecipientAddressBookController controller =
        Get.find<RecipientAddressBookController>();
    return Obx(
      () => Container(
        height: ObjectMgr.screenMQ!.size.height * 0.95,
        decoration: BoxDecoration(
          color: surfaceBrightColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: !controller.isSearching.value ? 52 : 0,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed(
                          RouteName.addressSecuritySettingView,
                          preventDuplicates: false,
                        );
                      },
                      child: OpacityEffect(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: SvgPicture.asset(
                            'assets/svgs/wallet/wallet_guard_icon.svg',
                            height: 24.w,
                            width: 24.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Get.toNamed(
                        RouteName.addressBookView,
                        preventDuplicates: false,
                      ),
                      child: OpacityEffect(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            '地址簿',
                            style: jxTextStyle.textStyle17(
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '选择地址',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
                top: 8,
              ),
              child: SearchingAppBar(
                onTap: () => controller.isSearching(true),
                onChanged: controller.filterRecipient,
                onCancelTap: () {
                  controller.searchFocus.unfocus();
                  controller.clearSearch();
                },
                isSearchingMode: controller.isSearching.value,
                isAutoFocus: false,
                focusNode: controller.searchFocus,
                controller: controller.filterRecipientController,
                suffixIcon: Visibility(
                  visible: controller.filterRecipientController.text.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      controller.clearSearch();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: JXColors.iconSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 1.h,
              color: JXColors.outlineColor,
            ),
            Expanded(
              child: controller.filterRecipientAddressList.isEmpty
                  ? Container(
                      height: double.infinity,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: c.EmptyWidget(
                        title: '暂无地址',
                        subTitle: '将常用地址保存在地址博,可以在将来直接使用!',
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      child: createAddressBookCard(
                        Column(
                          children: List.generate(
                            controller.filterRecipientAddressList.length,
                            (index) {
                              final model =
                                  controller.filterRecipientAddressList[index];
                              return GestureDetector(
                                onTap: () {
                                  Get.back(result: model);
                                },
                                child: addressBookItemList(
                                  addressName: model.addrName,
                                  chainNetwork: model.netType,
                                  walletAddress: model.address,
                                  historyTransfer: model.rechargeNum,
                                  totalHistoryTransferAmount: model.rechargeAmt,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget createAddressBookCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.w),
      ),
      padding: EdgeInsets.only(left: 16.w),
      child: child,
    );
  }

  Widget addressBookItemList({
    required String addressName,
    required String chainNetwork,
    required String walletAddress,
    int? historyTransfer,
    String? totalHistoryTransferAmount,
  }) {
    return Container(
      height: 64.w,
      padding: EdgeInsets.symmetric(vertical: 10.5.w),
      decoration: BoxDecoration(border: customBorder),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                addressName,
                style: jxTextStyle.textStyle16(),
              ),
              ImGap.hGap4,
              Container(
                height: 21.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.w),
                  color: JXColors.black3,
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  chainNetwork,
                  style: jxTextStyle.textStyleBold12(color: JXColors.black48),
                ),
              ),
              if (historyTransfer != null) ...[
                const Spacer(),
                Text(
                  '付款$historyTransfer次',
                  style: jxTextStyle.textStyle12(color: JXColors.green),
                )
              ],
              ImGap.hGap16,
            ],
          ),
          Row(
            children: [
              Text(
                walletAddress,
                style: jxTextStyle.textStyle12(
                  color: JXColors.black48,
                ),
              ).encryptString(start: 13, end: 6, style: EncryptionStyle.period),
              if (totalHistoryTransferAmount != null) ...[
                const Spacer(),
                Text(
                  '总计 ${totalHistoryTransferAmount}USDT',
                  style: jxTextStyle.textStyle12(
                    color: JXColors.black48,
                  ),
                ),
              ],
              ImGap.hGap16,
            ],
          )
        ],
      ),
    );
  }
}
