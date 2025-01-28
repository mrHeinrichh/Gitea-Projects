import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final CurrencyALLType selectedCurrency;

  const CurrencySelectionDialog(
    this.selectedCurrency, {
    super.key,
  });

  @override
  State<CurrencySelectionDialog> createState() =>
      _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  late CurrencyALLType _selectedCurrency;

  final List<CurrencyALLType> _currencyList = CurrencyALLType.values
      .where((element) => element != CurrencyALLType.currencyUnknown)
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency;
  }

  @override
  Widget build(BuildContext context) {
    return ImSheetOnBottom(
      title: '货币选择',
      showCancelText: true,
      rightWidget: ImTextButton(
        title: localized(buttonDone),
        onClick: () => Navigator.of(context).pop(_selectedCurrency),
      ),
      middleChildPadding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ).w,
      middleChild: ImRoundContainer(
        title: '选择币种',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _currencyList.length,
            (index) => ImSelectItem(
              title: _currencyList[index].title,
              isSelected: _selectedCurrency == _currencyList[index],
              showDivider: index != (_currencyList.length - 1),
              onClick: () {
                setState(() {
                  _selectedCurrency = _currencyList[index];
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
