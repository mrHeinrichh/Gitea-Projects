import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final FocusNode? focusNode;
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
    this.focusNode,
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
  late final FocusNode _focusNode;
  bool _enableInput = false;

  @override
  void initState() {
    super.initState();
    _enableInput = widget.autofocus;
    _focusNode = widget.focusNode ?? FocusNode();

    if (_enableInput) {
      _focusNode.requestFocus();
    }

    widget.controller.addListener(_updateClearIconVisibility);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateClearIconVisibility);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
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
              fontSize: 17,
              padding: const EdgeInsets.only(left: 12),
              onClick: () {
                widget.controller.clear();
                _focusNode.unfocus();

                if (!widget.autofocus) {
                  setState(() => _enableInput = false);
                }

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

        if (!widget.autofocus) {
          setState(() => _enableInput = true);
        }

        if (widget.onClick != null) {
          widget.onClick!();
        }
      },
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorBackground6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicWidth(
          stepWidth: _enableInput ? double.infinity : null,
          child: AbsorbPointer(
            absorbing: !_enableInput,
            child: Stack(
              children: [
                TextFormField(
                  contextMenuBuilder: im.textMenuBar,
                  controller: widget.controller,
                  focusNode: _focusNode,
                  cursorColor: themeColor,
                  cursorRadius: const Radius.circular(1),
                  cursorWidth: 2,
                  cursorHeight: 22,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.search,
                  style: getTextStyle(),
                  decoration: InputDecoration(
                    prefixIconConstraints: const BoxConstraints(maxHeight: 24),
                    prefixIcon: const CustomImage(
                      'assets/svgs/search_outlined.svg',
                      size: 24,
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                      ),
                    ),
                    suffix: const SizedBox(width: 32),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: localized(search),
                    hintStyle: getTextStyle(colorTextSupporting),
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                ),
                if (_enableInput && widget.controller.text.isNotEmpty)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 8,
                    child: Center(
                      child: CustomImage(
                        'assets/svgs/close_round_icon.svg',
                        size: 20,
                        fit: BoxFit.contain,
                        onClick: () {
                          widget.controller.clear();
                          _focusNode.requestFocus();

                          if (widget.onClearClick != null) {
                            widget.onClearClick!();
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
