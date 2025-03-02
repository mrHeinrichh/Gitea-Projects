import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie_tgs/lottie.dart';

class MomentPublishDialog extends StatefulWidget {
  final bool isSending;
  final bool isDone;
  final bool isFailed;
  final String sendingLocalizationKey;
  final String doneLocalizationKey;
  final String failedLocalizationKey;

  const MomentPublishDialog({
    super.key,
    required this.isSending,
    required this.isDone,
    this.isFailed = false,
    this.sendingLocalizationKey = momentBtnStatusSending,
    this.doneLocalizationKey = momentBtnStatusDone,
    this.failedLocalizationKey = loadFailed,
  });

  @override
  State<MomentPublishDialog> createState() => _MomentPublishDialogState();
}

class _MomentPublishDialogState extends State<MomentPublishDialog> {
  @override
  void didUpdateWidget(MomentPublishDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone != oldWidget.isDone && widget.isDone) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isDone) {
          return true;
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: colorOverlay90,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              child: Column(
                key: widget.isSending
                    ? const ValueKey('animate_loading')
                    // : widget.isFailed ? const ValueKey('animate_failed'):const ValueKey('animate_success'),
                    :const ValueKey('animate_success'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  widget.isSending
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            colorWhite,
                            BlendMode.srcIn,
                          ),
                          child: Lottie.asset(
                            "assets/lottie/animate_loading.json",
                            height: 50,
                            width: 50,
                          ),
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            colorWhite,
                            BlendMode.srcIn,
                          ),
                          child: Lottie.asset(
                            widget.isFailed?"assets/lottie/animate_failed.json":"assets/lottie/animate_success.json",
                            height: 50,
                            width: 50,
                            repeat: false,
                          ),
                        ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.isSending
                        ? localized(widget.sendingLocalizationKey)
                        : widget.isFailed?localized(widget.failedLocalizationKey):localized(widget.doneLocalizationKey),
                    style: jxTextStyle.textStyle16(color: colorWhite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
