import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final EdgeInsets padding;
  final void Function()? onClick;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmitted;
  final void Function()? onCancelClick;
  final void Function()? onClearClick;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onClick,
    this.onChanged,
    this.onSubmitted,
    this.onCancelClick,
    this.onClearClick,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _enableInput = false;

  @override
  void initState() {
    super.initState();
    _enableInput = widget.autofocus;

    if (_enableInput) {
      _focusNode.requestFocus();
    }

    widget.controller.addListener(_updateClearIconVisibility);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateClearIconVisibility);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateClearIconVisibility() => setState(() {});

  TextStyle getTextStyle([Color color = colorTextPrimary]) {
    return TextStyle(
      color: color,
      fontSize: MFontSize.size17.value,
      decorationThickness: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          Expanded(child: buildTextField()),
          if (_enableInput)
            CustomTextButton(
              localized(cancel),
              padding: const EdgeInsets.only(left: 12),
              onClick: () {
                widget.controller.clear();
                _focusNode.unfocus();
                setState(() => _enableInput = false);

                if (widget.onCancelClick != null) {
                  widget.onCancelClick!();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget buildTextField() {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
        setState(() => _enableInput = true);

        if (widget.onClick != null) {
          widget.onClick!();
        }
      },
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorBorder,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IntrinsicWidth(
          stepWidth: _enableInput ? double.infinity : null,
          child: AbsorbPointer(
            absorbing: !_enableInput,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              cursorColor: themeColor,
              cursorRadius: const Radius.circular(2),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: getTextStyle(),
              decoration: InputDecoration(
                prefixIconConstraints: const BoxConstraints(maxHeight: 24),
                prefixIcon: const CustomImage(
                  'assets/svgs/search_outlined.svg',
                  size: 24,
                  padding: EdgeInsets.only(left: 8, right: 4),
                  color: colorTextSecondary,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: localized(search),
                hintStyle: getTextStyle(colorTextSecondary),
                border: InputBorder.none,
                suffixIconConstraints: const BoxConstraints(maxHeight: 20),
                suffixIcon: _enableInput && widget.controller.text.isNotEmpty
                    ? CustomImage(
                        'assets/svgs/close_round_icon.svg',
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: colorTextSecondary,
                        size: 20,
                        onClick: () {
                          widget.controller.clear();
                          _focusNode.requestFocus();

                          if (widget.onClearClick != null) {
                            widget.onClearClick!();
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ),
      ),
    );
  }
}
