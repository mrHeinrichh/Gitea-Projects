import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelSearchInput extends StatefulWidget {
  final bool isDarkMode;
  final TextEditingController? controller;
  final void Function()? onClick;
  final void Function()? onBackClick;
  final void Function() onClearClick;
  final void Function() onSearchClick;
  final void Function(String) onChanged;
  final FocusNode focusNode;
  final bool hasAutoFocus;

  const ReelSearchInput({
    super.key,
    this.isDarkMode = false,
    this.controller,
    this.onClick,
    this.onBackClick,
    this.hasAutoFocus = true,
    required this.onClearClick,
    required this.onSearchClick,
    required this.onChanged,
    required this.focusNode,
  });

  @override
  State<ReelSearchInput> createState() => _ReelSearchInputState();
}

class _ReelSearchInputState extends State<ReelSearchInput> {
  RxBool isTextEmpty = false.obs;

  @override
  void initState() {
    super.initState();
    isTextEmpty.value = widget.controller?.text.isEmpty ?? true;

    //點歷史標籤近來也能判斷刪除按鈕的顯示
    widget.controller?.addListener(() {
      _onTextChanged(widget.controller!.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _onTextChanged(String value) {
    isTextEmpty.value = value.isEmpty;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: widget.isDarkMode ? Colors.transparent : colorBackground,
        padding: EdgeInsets.only(top: widget.isDarkMode ? 0 : MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              CustomImage(
                'assets/svgs/Back.svg',
                size: 24,
                color: widget.isDarkMode ? colorWhite : themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onClick: widget.onBackClick ?? () => Get.back(),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? colorWhite.withOpacity(0.06)
                        : colorTextPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: TextField(
                      contextMenuBuilder: textMenuBar,
                      controller: widget.controller,
                      // onChanged: _onTextChanged,
                      onTapOutside: (_) => widget.focusNode.unfocus(),
                      onTap: widget.onClick,
                      autofocus: widget.hasAutoFocus,
                      focusNode: widget.focusNode,
                      cursorColor: widget.isDarkMode ? colorWhite : themeColor,
                      maxLines: 1,
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        color: widget.isDarkMode ? colorWhite : colorTextPrimary,
                        fontSize: MFontSize.size16.value,
                        decorationThickness: 0,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        prefixIconConstraints:
                            const BoxConstraints(maxWidth: 32),
                        prefixIcon: CustomImage(
                          'assets/svgs/reel_search_icon.svg',
                          size: 24,
                          color: widget.isDarkMode
                              ? colorWhite.withOpacity(0.40)
                              : colorTextPrimary.withOpacity(0.40),
                          padding: const EdgeInsets.only(right: 8),
                        ),
                        hintText: localized(hintSearch),
                        hintStyle: jxTextStyle.textStyle16(
                          color: widget.isDarkMode
                              ? colorWhite
                              : colorTextPrimary.withOpacity(0.24),
                        ),
                        suffixIconConstraints:
                            const BoxConstraints(maxWidth: 28),
                        suffixIcon: isTextEmpty.value
                            ? null
                            : CustomImage(
                                'assets/svgs/close_round_icon.svg',
                                size: 20,
                                color: widget.isDarkMode
                                    ? colorWhite.withOpacity(0.48)
                                    : colorTextSecondary,
                                padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                onClick: () {
                                  widget.onClearClick();
                                  widget.focusNode.requestFocus();
                                },
                              ),
                      ),
                      onSubmitted: (value) => widget.onSearchClick(),
                    ),
                  ),
                ),
              ),
              CustomTextButton(
                localized(search),
                color: widget.isDarkMode ? colorWhite : themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onClick: widget.onSearchClick,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
