import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class GroupAliasBottomSheet extends StatefulWidget {
  const GroupAliasBottomSheet({
    super.key,
    required this.name,
    required this.confirmCallback,
    required this.cancelCallback,
  });

  final String name;
  final Function(String) confirmCallback;
  final Function() cancelCallback;

  @override
  State<GroupAliasBottomSheet> createState() => _GroupAliasBottomSheetState();
}

class _GroupAliasBottomSheetState extends State<GroupAliasBottomSheet> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController textController = TextEditingController();
  final showClearBtn = false.obs;
  final charsLeft = 30.obs;
  String groupAlias = "";

  @override
  void initState() {
    super.initState();
    getName();

    onTextChanged(groupAlias);
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom + 5
              : 16,
          right: 16,
          left: 16,
        ),
        decoration: const BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OpacityEffect(
                      child: GestureDetector(
                        onTap: widget.cancelCallback,
                        child: Text(
                          localized(cancel),
                          style: jxTextStyle.textStyle17(
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    OpacityEffect(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          widget.confirmCallback(textController.text.trim());
                        },
                        child: Text(
                          localized(buttonConfirm),
                          style: TextStyle(
                            fontSize: MFontSize.size17.value,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  localized(groupAliasTitle),
                  style: jxTextStyle.textStyleBold17(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localized(groupAliasDesc),
                    style: jxTextStyle.textStyle13(
                      color: colorTextPrimary.withOpacity(0.56),
                    ),
                  ),
                  Obx(() {
                    return Text(
                      '${charsLeft.value}${localized(charactersLeft)}',
                      style: jxTextStyle.textStyle13(
                        color: colorTextPrimary.withOpacity(0.56),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              contextMenuBuilder: textMenuBar,
              focusNode: focusNode,
              autofocus: true,
              controller: textController,
              style: const TextStyle(
                color: colorTextPrimary,
                fontSize: 17,
                decorationThickness: 0,
              ),
              inputFormatters: [CustomInputFormatter()],
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                return null;
              },
              minLines: 1,
              maxLines: 3,
              cursorColor: themeColor,
              maxLength: 30,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorWhite,
                isDense: true,
                hintText: localized(plzEnter),
                hintStyle: jxTextStyle.textStyle17(
                  color: colorTextPlaceholder,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: Obx(
                  () => Visibility(
                    visible: showClearBtn.value,
                    child: GestureDetector(
                      onTap: () => clearRemark(),
                      behavior: HitTestBehavior.opaque,
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/clear_icon.svg',
                            color: colorTextPlaceholder,
                            width: 14,
                            height: 14,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () {
                if (textController.text.isEmpty) {
                  setShowClearBtn(false);
                } else {
                  setShowClearBtn(true);
                }
              },
              onChanged: onTextChanged,
            ),
          ],
        ),
      ),
    );
  }

  onTextChanged(String text) {
    charsLeft.value = 30 - text.runes.length;
    setShowClearBtn(text.isNotEmpty);
  }

  clearRemark() {
    textController.clear();
    charsLeft.value = 30;
    setShowClearBtn(false);
  }

  setShowClearBtn(bool value) {
    showClearBtn.value = value;
  }

  getName() {
    String currentRemark = widget.name;
    if (currentRemark.length <= 30) {
      groupAlias = currentRemark;
    } else {
      groupAlias = currentRemark.substring(0, 30);
    }
    textController.text = groupAlias;
  }
}
