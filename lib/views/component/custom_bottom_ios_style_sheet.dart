import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/lang_util.dart';

import 'package:jxim_client/views/component/click_effect_button.dart';

Future<void> customBottomIosStyleSheet(
  BuildContext context, {
  String? title,
  FontWeight titleFontWeight = FontWeight.w600,
  String? subtitle,
  Widget? content,
  String? confirmText,
  String? cancelText,
  bool showItems = false,
  List<Widget>? items,
  required Function()? onCancelListener,
  required Function()? onConfirmListener,
  bool isDismissible = true,
  TextStyle? cancelTextStyle,
  TextStyle? confirmTextStyle,
  Widget? contentWidget,
  Color? dividerColor,
}) async {
  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    isDismissible: isDismissible,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8).w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: showItems
                        ? items ?? []
                        : [
                            Padding(
                              padding: const EdgeInsets.all(16).w,
                              child: Column(
                                children: [
                                  if (title != null)
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: titleFontWeight,
                                        fontSize: 17,
                                      ),
                                    ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                      maxLines: 5,
                                    ),
                                  ],
                                  if (contentWidget != null) ...[contentWidget],
                                  if (content != null) ...[
                                    const SizedBox(height: 12),
                                    content,
                                  ],
                                ],
                              ),
                            ),
                            Divider(
                              height: 1.w,
                              thickness: 0.3.w,
                              color: dividerColor ??
                                  const Color(0xD1121212).withOpacity(0.2),
                            ),
                            _CustomBottomAlertItem(
                              text: confirmText ?? localized(buttonConfirm),
                              textStyle: confirmTextStyle,
                              showDivider: false,
                              onClick: onConfirmListener,
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _CustomBottomAlertItem(
                    text: cancelText ?? localized(buttonCancel),
                    showDivider: false,
                    onClick: onCancelListener,
                    textStyle: cancelTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CustomBottomAlertItem extends StatelessWidget {
  final String text;
  final bool showDivider;
  final Function()? onClick;
  final TextStyle? textStyle;

  const _CustomBottomAlertItem({
    required this.text,
    this.showDivider = true,
    this.onClick,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: ForegroundOverlayEffect(
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      width: 0.3.w,
                      color: colorBorder,
                    ),
                  )
                : null,
          ),
          child: Text(
            text,
            style: textStyle ??
                jxTextStyle.textStyle20(
                  color: themeColor,
                ),
          ),
        ),
      ),
    );
  }
}
