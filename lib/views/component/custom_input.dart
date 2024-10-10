import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

enum ClearButtonType {
  small,
  big,
}

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String? title;
  final String? rightTitle;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? hintText;
  final String errorText;
  final Widget? errorWidget;
  final Widget? descriptionWidget;
  final bool showTextButton;
  final String? textButtonTitle;
  final void Function()? onTapInput;
  final void Function()? onTapClearButton;
  final void Function()? onTapTextButton;
  final void Function(String)? onChanged;
  final void Function(PointerDownEvent)? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final ClearButtonType clearButtonType;

  const CustomInput({
    super.key,
    required this.controller,
    this.title,
    this.rightTitle,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType = TextInputType.none,
    this.maxLength,
    this.hintText,
    this.errorText = '',
    this.errorWidget,
    this.descriptionWidget,
    this.showTextButton = false,
    this.textButtonTitle,
    this.onTapInput,
    this.onTapClearButton,
    this.onTapTextButton,
    this.onChanged,
    this.onTapOutside,
    this.inputFormatters,
    this.clearButtonType = ClearButtonType.big,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateClearIconVisibility);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateClearIconVisibility);
    super.dispose();
  }

  void _updateClearIconVisibility() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null || widget.rightTitle != null) _buildHeader(),
        Flexible(child: _buildTextField()),
        _buildBottomWidget(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title ?? '',
            style: jxTextStyle.textStyle13(
              color: colorTextPrimary.withOpacity(0.56),
            ),
          ),
          Text(
            widget.rightTitle ?? '',
            style: jxTextStyle.textStyle13(color: colorTextPlaceholder),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    bool isClearButtonBig = widget.clearButtonType == ClearButtonType.big;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
      },
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        contextMenuBuilder: common.textMenuBar,
        inputFormatters: widget.inputFormatters ??
            [LengthLimitingTextInputFormatter(widget.maxLength)],
        minLines: 1,
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        showCursor: true,
        readOnly: widget.keyboardType == TextInputType.none,
        cursorColor: themeColor,
        cursorRadius: const Radius.circular(2),
        style: TextStyle(
          fontSize: MFontSize.size17.value,
          color: colorTextPrimary,
          decorationThickness: 0,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorWhite,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 16,
          ),
          hintText: widget.hintText,
          hintStyle: jxTextStyle.textStyle17(color: colorTextPlaceholder),
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty && _hasFocus)
                  CustomImage(
                    'assets/svgs/close_round_icon.svg',
                    size: isClearButtonBig ? 20 : 14,
                    color: isClearButtonBig
                        ? colorTextSecondary
                        : colorTextPrimary.withOpacity(0.24),
                    padding: const EdgeInsets.only(left: 12),
                    onClick: () {
                      widget.controller.clear();
                      if (widget.onTapClearButton != null) {
                        widget.onTapClearButton!();
                      }
                    },
                  ),
                if (widget.showTextButton)
                  CustomTextButton(
                    widget.textButtonTitle ?? localized(redPocketMax),
                    color: themeColor,
                    padding: const EdgeInsets.only(left: 12),
                    onClick: widget.onTapTextButton,
                  ),
              ],
            ),
          ),
        ),
        onTap: widget.onTapInput,
        onChanged: widget.onChanged,
        onTapOutside: widget.onTapOutside,
      ),
    );
  }

  Widget _buildBottomWidget() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.errorText.isNotEmpty || widget.errorWidget != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: widget.errorWidget ??
                  Text(
                    widget.errorText,
                    style: jxTextStyle.textStyle13(color: colorRed),
                    maxLines: 2,
                  ),
            ),
          if (widget.descriptionWidget != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: widget.descriptionWidget!,
            ),
        ],
      ),
    );
  }
}
