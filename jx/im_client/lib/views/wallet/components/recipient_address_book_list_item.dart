import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/wallet/components/encrypt_string.dart';
import 'package:jxim_client/views/wallet/controller/recipient_address_book_controller.dart';

class RecipientAddressBookListItem extends StatelessWidget {
  final int index;
  final String addressName;
  final String chainNetwork;
  final String walletAddress;
  final int? historyTransfer;
  final String? totalHistoryTransferAmount;
  final VoidCallback? onTap;

  const RecipientAddressBookListItem({
    super.key,
    required this.index,
    required this.addressName,
    required this.chainNetwork,
    required this.walletAddress,
    this.historyTransfer,
    this.totalHistoryTransferAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final RecipientAddressBookController controller =
        Get.find<RecipientAddressBookController>();

    final bool isFirstIndex = index == 0;
    final bool isLastIndex =
        index == (controller.filterRecipientAddressList.length - 1);

    final BorderRadius borderRadius = BorderRadius.vertical(
      top: Radius.circular(isFirstIndex ? 8 : 0),
      bottom: Radius.circular(isLastIndex ? 8 : 0),
    );

    return GestureDetector(
      onTap: onTap,
      child: ForegroundOverlayEffect(
        radius: borderRadius,
        child: Container(
          height: 65,
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: borderRadius,
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    addressName,
                                    style: jxTextStyle.textStyle17(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: colorBackground6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    chainNetwork,
                                    style: jxTextStyle.textStyle12(
                                      color: colorTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (historyTransfer != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              '${localized(walletPayment)}$historyTransfer${localized(walletNextPay)}',
                              style: jxTextStyle.textStyle12(color: colorGreen),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              walletAddress,
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ).encryptString(
                              start: 13,
                              end: 6,
                              style: EncryptionStyle.period,
                            ),
                          ),
                          if (totalHistoryTransferAmount != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              '${localized(total)} ${totalHistoryTransferAmount}USDT',
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
