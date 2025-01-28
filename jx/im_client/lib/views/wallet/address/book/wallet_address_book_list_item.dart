import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_controller.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';

class WalletAddressBookListItem extends StatelessWidget {
  final int index;
  final AddressModel model;
  final bool enableCheckBtn;
  final VoidCallback? onTap;

  const WalletAddressBookListItem({
    super.key,
    required this.index,
    required this.model,
    this.enableCheckBtn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokenType = model.addrName;
    final tokenTypePrefix = model.netType;
    final tokenAddress = model.address;
    final controller = Get.find<WalletAddressBookController>();

    final bool isFirstIndex = index == 0;
    final bool isLastIndex = index == (controller.addressList.length - 1);

    final BorderRadius borderRadius = BorderRadius.vertical(
      top: Radius.circular(isFirstIndex ? 8 : 0),
      bottom: Radius.circular(isLastIndex ? 8 : 0),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: ForegroundOverlayEffect(
        radius: borderRadius,
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(
                      () => AnimatedCrossFade(
                        duration: const Duration(milliseconds: 100),
                        alignment: Alignment.centerLeft,
                        crossFadeState: enableCheckBtn
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: CheckTickItem(
                            circleSize: 24,
                            circlePaddingValue: 6.5,
                            isCheck:
                                controller.selectedAddressList.contains(model),
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tokenType,
                                  style: jxTextStyle.textStyle17(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: colorBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tokenTypePrefix,
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tokenAddress,
                            style: jxTextStyle.textStyle12(
                              color: colorTextSecondary,
                            ),
                          ).encryptString(
                            start: 13,
                            end: 6,
                            style: EncryptionStyle.period,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!enableCheckBtn)
                      CustomImage(
                        'assets/svgs/right_arrow_thick.svg',
                        padding: const EdgeInsets.only(right: 16),
                        color: colorTextPrimary.withOpacity(0.38),
                      ),
                  ],
                ),
              ),
              if (!isLastIndex) const CustomDivider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
