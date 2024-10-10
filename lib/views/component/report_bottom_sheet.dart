import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class ReportBottomSheet extends StatefulWidget {
  const ReportBottomSheet({
    super.key,
    required this.confirmCallback,
    required this.cancelCallback,
  });

  final Function(String) confirmCallback;
  final Function() cancelCallback;

  @override
  State<ReportBottomSheet> createState() => ReportBottomSheetState();
}

class ReportBottomSheetState extends State<ReportBottomSheet> {
  final TextEditingController _textEditingController = TextEditingController();
  int _numOfWordsLeft = 30;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: CustomBottomSheetContent(
        title: localized(report),
        showCancelButton: true,
        trailing: CustomTextButton(
          localized(send),
          onClick: () => widget.confirmCallback(_textEditingController.text),
        ),
        middleChild: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomInput(
            title: localized(reportContent),
            rightTitle: '$_numOfWordsLeft${localized(charactersLeft)}',
            maxLength: 30,
            controller: _textEditingController,
            autofocus: true,
            keyboardType: TextInputType.text,
            hintText: localized(plzEnter),
            onChanged: (value) {
              setState(() => _numOfWordsLeft = 30 - value.runes.length);
            },
            onTapClearButton: () {
              setState(() => _numOfWordsLeft = 30);
            },
          ),
        ),
      ),
    );
  }
}
