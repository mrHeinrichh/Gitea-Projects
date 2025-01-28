import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class SelectionBottomSheet extends StatelessWidget {
  const SelectionBottomSheet({
    super.key,
    required this.context,
    this.title = "",
    required this.selectionOptionModelList,
    required this.callback,
    this.cancelButtonTextStyle,
    this.titleTextStyle,
    this.itemTextStyle,
    this.onTapCancel,
  });

  final BuildContext context;
  final String? title;
  final List<SelectionOptionModel> selectionOptionModelList;
  final Function(int index) callback;
  final TextStyle? cancelButtonTextStyle;
  final TextStyle? titleTextStyle;
  final TextStyle? itemTextStyle;
  final Function()? onTapCancel;

  @override
  Widget build(BuildContext context) {
    const double width = double.infinity;
    const double radius = 12;
    final decoration = BoxDecoration(
      color: colorWhite,
      borderRadius: BorderRadius.circular(radius),
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width,
              clipBehavior: Clip.hardEdge,
              decoration: decoration,
              child: Column(children: getSelectionList()),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onTapCancel ?? () => Get.back(),
              child: ForegroundOverlayEffect(
                radius: BorderRadius.circular(radius),
                child: Container(
                  width: width,
                  height: 56,
                  decoration: decoration,
                  alignment: Alignment.center,
                  child: Text(
                    localized(buttonCancel),
                    style: cancelButtonTextStyle ??
                        jxTextStyle.textStyle20(color: themeColor),
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
    const double width = double.infinity;
    const double height = 56;

    if (notBlank(title)) {
      final widget = Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: customBorder),
        child: Text(
          title ?? "",
          style: titleTextStyle ?? jxTextStyle.textStyle16(),
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
            Get.back();
            callback(i);
          },
          child: ForegroundOverlayEffect(
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: (i == selectionOptionModelList.length - 1)
                    ? null
                    : customBorder,
              ),
              child: Text(
                item.title ?? "",
                style: item.titleTextStyle ??
                    jxTextStyle.textStyle20(color: item.color ?? themeColor),
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
