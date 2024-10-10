import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelCommentChatField extends StatefulWidget {
  const ReelCommentChatField({
    super.key,
    this.isDarkMode = false,
    required this.controller,
    this.focusNode,
    this.onTap,
    this.onTapOutside,
  });

  final bool isDarkMode;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function()? onTap;
  final void Function(PointerDownEvent)? onTapOutside;

  @override
  ReelCommentChatFieldState createState() => ReelCommentChatFieldState();
}

class ReelCommentChatFieldState extends State<ReelCommentChatField> {
  late ValueNotifier<bool> isTextEmptyNotifier;

  @override
  void initState() {
    super.initState();
    isTextEmptyNotifier = ValueNotifier(widget.controller.text.trim().isEmpty);
    widget.controller.addListener(_textChangeListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_textChangeListener);
    isTextEmptyNotifier.dispose();
    super.dispose();
  }

  void _textChangeListener() {
    isTextEmptyNotifier.value = widget.controller.text.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final outlineStyle = OutlineInputBorder(
      borderSide: const BorderSide(color: colorBorder, width: 0.5),
      borderRadius: BorderRadius.circular(20),
    );

    final inputFieldDecoration = InputDecoration(
      counterText: '', // 隱藏字數計數器
      isDense: true,
      hintText: localized(postComment),
      filled: true,
      fillColor: widget.isDarkMode ? colorWhite.withOpacity(0.20) : colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintStyle: jxTextStyle.textStyle16(
        color: widget.isDarkMode
            ? colorWhite.withOpacity(0.40)
            : colorTextPrimary.withOpacity(0.40),
      ),
      border: outlineStyle,
      enabledBorder: outlineStyle,
      errorBorder: outlineStyle,
      focusedErrorBorder: outlineStyle,
      focusedBorder: outlineStyle,
    );

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.black : colorBackground,
        border: const Border(
          top: BorderSide(
            width: 1,
            color: colorBorder,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                contextMenuBuilder: textMenuBar,
                controller: widget.controller,
                cursorColor: widget.isDarkMode ? colorWhite : themeColor,
                cursorRadius: const Radius.circular(2),
                decoration: inputFieldDecoration,
                focusNode: widget.focusNode,
                textAlignVertical: TextAlignVertical.center,
                maxLength: 242,
                style: TextStyle(
                  fontSize: MFontSize.size16.value,
                  color: widget.isDarkMode ? colorWhite : colorTextPrimary,
                  decorationThickness: 0,
                ),
                minLines: 1,
                maxLines: 2,
                onTapOutside: widget.onTapOutside,
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<bool>(
              valueListenable: isTextEmptyNotifier,
              builder: (context, isTextEmpty, child) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (!isTextEmpty) widget.onTap?.call();
                  },
                  child: OpacityEffect(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDarkMode
                            ? colorRed
                            : isTextEmpty
                                ? colorTextPrimary.withOpacity(0.20)
                                : themeColor,
                      ),
                      child: const CustomImage(
                        'assets/svgs/send_arrow.svg',
                        padding: EdgeInsets.all(5.0),
                        color: colorWhite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
