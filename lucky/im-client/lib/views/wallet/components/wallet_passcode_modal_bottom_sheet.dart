import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../../../views/login/components/otp_box.dart';
import '../../../../views/wallet/components/number_pad.dart';

class WalletPasscodeModalBottomSheet extends StatelessWidget {
  final TextEditingController pinController;
  final int attemptRetry;
  final bool isEnabled;
  final bool isLoading;
  final Function(String) onCompleted;
  const WalletPasscodeModalBottomSheet({
    Key? key,
    required this.pinController,
    required this.onCompleted,
    required this.isLoading,
    required this.attemptRetry,
    this.isEnabled = true,
  }) : super(key: key);

  void onNumberTap(String number) {
    if (pinController.text.length >= 4 || !isEnabled || isLoading) return;
    final currentValue = pinController.text;
    final newText = currentValue + number;
    pinController.text = newText;
  }

  void onDeleteTap() {
    if (pinController.text.isEmpty) return;

    final newText =
        pinController.text.substring(0, pinController.text.length - 1);
    pinController.text = newText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const SizedBox(height: 32.0),
          Text(
            localized(walletEnterPasscode),
            style: const TextStyle(
              color: JXColors.darkGrey,
            ),
          ),
          const SizedBox(height: 32.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: OTPBox(
              length: 4,
              autoFocus: false,
              readOnly: true,
              obscureText: true,
              autoDisposeControllers: true,
              enabled: isEnabled,
              controller: pinController,
              onChanged: (String _) => null,
              onCompleted: isLoading ? (String _) => null : onCompleted,
              pinBoxColor: backgroundColor,
            ),
          ),
          Visibility(
            visible: isEnabled && attemptRetry > 0 && attemptRetry < 5,
            child: Container(
              width: double.infinity,
              // alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                localized(invalidPinRemainingAttemptWithParam,
                    params: ["${5 - attemptRetry}"]),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: JXColors.red),
              ),
            ),
          ),
          Visibility(
            visible: attemptRetry >= 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                localized(walletPinMax),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: JXColors.red,
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              height: 100.0,
              child: BallCircleLoading(
                radius: 20,
                ballStyle: BallStyle(
                  size: 5,
                  color: accentColor,
                  ballType: BallType.solid,
                  borderWidth: 1,
                  borderColor: accentColor,
                ),
              ),
            )
          else
            NumberPad(onNumTap: onNumberTap, onDeleteTap: onDeleteTap),
          SizedBox(
            height: MediaQuery.of(context).viewPadding.bottom,
          ),
        ],
      ),
    );
  }
}
