import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/wallet/currency_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';
import 'package:jxim_client/views/wallet/components/wallet_passcode_modal_bottom_sheet.dart';

import '../../../utils/theme/text_styles.dart';

class TransactionSummary extends StatefulWidget {
  final dynamic controller;
  final String transferType;
  final String amountText;
  final String currencyText;
  final bool isLoading;
  final Function(String value) onCompleted;

  const TransactionSummary({
    super.key,
    required this.controller,
    required this.amountText,
    required this.currencyText,
    required this.transferType,
    required this.isLoading,
    required this.onCompleted,
  });

  @override
  State<TransactionSummary> createState() => _TransactionSummaryState();
}

class _TransactionSummaryState extends State<TransactionSummary> {
  int step = 0;

  @override
  void didUpdateWidget(TransactionSummary oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      setState(() {});
    }
  }

  onTapNext() {
    if (step == 0) {
      setState(() {
        step = 1;
      });
    } else {
      // 开始转账
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: Container(
        // padding: const EdgeInsets.all(12.0),
        child: IntrinsicHeight(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: Get.back,
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                localized(totalAmount),
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8.0),
              RichText(
                text: TextSpan(
                  text: '${double.parse(widget.amountText).toDoubleFloor()}',
                  // text: widget.controller.withdrawModel.amount.toString(),
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: MFontWeight.bold5.value,
                    color: JXColors.black,
                  ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: ' ${widget.currencyText}',
                      // text: widget.controller.withdrawModel.selectedCurrency!.currencyType,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: MFontWeight.bold5.value,
                        color: JXColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      localized(transferType),
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: JXColors.supportingTextBlack,
                      ),
                    ),
                    // if (widget.controller.isInternalAddress.value)
                    Text(
                      localized(widget.transferType),
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: JXColors.supportingTextBlack,
                      ),
                    ),
                  ],
                ),
              ),
              if (step == 1) ...{
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Divider(
                    thickness: 1,
                  ),
                ),
                Obx(
                  () => WalletPasscodeModalBottomSheet(
                    attemptRetry: widget.controller.passwordCount.value,
                    isEnabled: widget.controller.passwordCount.value < 5,
                    pinController: widget.controller.pinCodeController,
                    onCompleted: widget.onCompleted,
                    isLoading: widget.isLoading,
                  ),
                )
              } else
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 12,
                    bottom: 24,
                  ),
                  child: FullScreenWidthButton(
                    title: localized(buttonConfirm),
                    onTap: onTapNext,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
