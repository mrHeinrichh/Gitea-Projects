import 'package:flutter/material.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import '../../managers/utils.dart';
import '../../utils/localization/app_localizations.dart';

class SelectionBottomSheet extends StatelessWidget {
  const SelectionBottomSheet({
    Key? key,
    required this.context,
    this.title = "",
    required this.selectionOptionModelList,
    required this.callback,
  }) : super(key: key);

  final BuildContext context;
  final String? title;
  final List<SelectionOptionModel> selectionOptionModelList;
  final Function(int index) callback;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                children: getSelectionList(),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Colors.white,
                ),
                child: OverlayEffect(
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      localized(buttonCancel),
                      style: jxTextStyle.textStyle16(color: accentColor),
                      textAlign: TextAlign.center,
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

  List<Widget> getSelectionList() {
    final List<Widget> list = [];

    if (notBlank(title)) {
      final widget = Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: JXColors.outlineColor, width: 1),
          ),
        ),
        child: Text(
          textAlign: TextAlign.center,
          title ?? "",
          style: jxTextStyle.textStyle16(),
        ),
      );
      list.add(widget);
    }

    if (selectionOptionModelList.isNotEmpty) {
      for (int i = 0; i < selectionOptionModelList.length; i++) {
        final item = selectionOptionModelList.elementAt(i);
        final widget = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.pop(context);
            callback(i);
          },
          child: OverlayEffect(
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                border: (i == selectionOptionModelList.length - 1)
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: JXColors.outlineColor, width: 1),
                      ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                textAlign: TextAlign.center,
                item.title ?? "",
                style: jxTextStyle.textStyle16(color: item.color ?? accentColor),
              ),
            ),
          ),
        );

        list.add(widget);
      }
    }
    return list;
  }
}
