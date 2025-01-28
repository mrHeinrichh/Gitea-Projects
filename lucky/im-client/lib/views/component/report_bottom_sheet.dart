import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ReportBottomSheet extends StatefulWidget {
  const ReportBottomSheet({
    Key? key,
    required this.confirmCallback,
    required this.cancelCallback,
  }) : super(key: key);

  final Function(String) confirmCallback;
  final Function() cancelCallback;

  @override
  State<ReportBottomSheet> createState() => ReportBottomSheetState();
}

class ReportBottomSheetState extends State<ReportBottomSheet> {
  late FocusNode focusNode;
  double popupHeight = 400.0;
  TextEditingController textEditingController = TextEditingController();
  bool isShowClearButton = false;

  @override
  void initState() {
    focusNode = FocusNode();
    focusNode.addListener(onFocusChange);
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: popupHeight,
        child: DefaultTextStyle(
          style: jxTextStyle.textStyle14(),
          child: CupertinoActionSheet(
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/reportPopupIcon.svg',
                      width: 148,
                      height: 148,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                      child: Text(
                        localized(tellUsMoreReportedIssue),
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextBlack,
                        ),
                      ),
                    ),
                    CupertinoTextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      style: jxTextStyle.textStyle16(),
                      maxLines: 1,
                      cursorColor: accentColor,
                      decoration: BoxDecoration(
                        color: JXColors.primaryTextBlack.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      textAlign: (focusNode.hasFocus ||
                              notBlank(textEditingController.text))
                          ? TextAlign.start
                          : TextAlign.center,
                      placeholder: focusNode.hasFocus
                          ? ""
                          : localized(additionalInformation),
                      placeholderStyle: jxTextStyle.textStyle16(
                        color: JXColors.hintColor,
                      ),
                      suffix: Visibility(
                        visible: isShowClearButton,
                        child: GestureDetector(
                          onTap: () {
                            textEditingController.clear();
                            setClearBtn(false);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            child: SvgPicture.asset(
                              'assets/svgs/clearIcon.svg',
                              color: JXColors.secondaryTextBlack,
                              width: 14,
                              height: 14,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (value) => onTextChange(value),
                    ),
                    GestureDetector(
                      onTap: () =>
                          widget.confirmCallback(textEditingController.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        color: Colors.white,
                        child: Text(
                          localized(report),
                          style: jxTextStyle.textStyle16(
                            color: accentColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => widget.cancelCallback(),
              child: Text(
                localized(buttonCancel),
                style: jxTextStyle.textStyle16(color: accentColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      popupHeight = 720.0;
    } else {
      popupHeight = 400.0;
    }
  }

  void onTextChange(String value) {
    bool status = false;
    if (notBlank(value)){
      status = true;
    }
    setClearBtn(status);
  }

  void setClearBtn(bool status){
    setState(() {
      isShowClearButton = status;
    });
  }
}
