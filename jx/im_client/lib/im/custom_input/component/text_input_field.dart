import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/component/input_ui_component.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TextInputView extends InputUIComponent {
  const TextInputView({
    super.key,
    super.onMoreOpen = false,
    super.isTextingAllowed = true,
    super.isShowSticker = true,
    super.isShowAttachment = true,
    required super.tag,
    super.showBottomAttachment = true,
  });

  @override
  List<Widget> buildContent(BuildContext context) {
    return [
      buildAddWidget(context),
      Expanded(
        child: Obx(() {
          if (controller.isVoiceMode.value) {
            return buildHoldToTalk(context);
          }

          return
            isDesktop
                ? RawKeyboardListener(
                    focusNode: FocusNode(
                      onKeyEvent: (node, event) {
                        if ((HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.shiftLeft) ||
                            HardwareKeyboard.instance.logicalKeysPressed
                                .contains(LogicalKeyboardKey.shiftRight)) &&
                            event.logicalKey.keyId == 8589935117) {
                          return KeyEventResult.handled;
                        } else {
                          return KeyEventResult.ignored;
                        }
                      },
                    ),
                    onKey: (RawKeyEvent event) {
                      onKey(event, context);
                    },
                    child:inputFrame(context),
                  )
                :inputFrame(context);
        }),
      ),

      ///最底層輸入框最右邊按鈕
      if (!isDesktop) buildRightWidget(),
      if (isDesktop) buildDesktopSend(),
    ];
  }

  Widget inputFrame(BuildContext context){
    return Stack(
      children: <Widget>[
        buildInput(context),
        Positioned(
          top: null,
          right: 0,
          bottom: objectMgr.loginMgr.isDesktop ? 6 : 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildAutoDeleteIntervalText(context),
              if (objectMgr.loginMgr.isDesktop)
                buildDesktopEmoji(context)
              else ...{
                buildEmojiWidget(context),
              },
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool getEnabled() {
    return isTextingAllowed;
  }

  @override
  bool getReadOnly() {
    return false;
  }

  @override
  Color getInputFieldColor() {
    return colorTextPrimary;
  }

  @override
  InputDecoration getInputDecoration(
    CustomInputController controller,
    bool isDesktop,
  ) {
    final borderStyle = OutlineInputBorder(
      borderRadius: jxDimension.textInputRadius(),
      borderSide: BorderSide(
        color: colorTextPrimary.withOpacity(0.2),
        width: 0.3,
      ),
    );

    return InputDecoration(
      prefixIcon: isTextingAllowed
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text(
                  localized(textNotAllowed),
                  style: TextStyle(
                    fontSize: MFontSize.size17.value,
                    color: colorTextSecondary,
                  ),
                ),
              ],
            ),
      hintText: isTextingAllowed
          ? localized(isDesktop ? enterMessage : chatInputting)
          : null,
      hintStyle: isDesktop
          ? const TextStyle(
              fontSize: 14,
              color: colorTextSecondary,
            )
          : jxTextStyle.textStyle16(color: colorTextSecondary),
      isDense: true,
      fillColor: Colors.white,
      filled: true,
      isCollapsed: isDesktop ? false : true,
      counterText: '',
      contentPadding: jxDimension.chatTextFieldInputPadding().copyWith(
            left: 16,
            right: controller.chatController.chat.autoDeleteEnabled &&
                    controller.autoDeleteInterval.value != 0
                ? (isDesktop ? 50 : 41.0) + 34.0
                : isDesktop
                    ? 50
                    : 41.0,
            top: isDesktop ? 9 : 7,
            bottom: isDesktop ? 13 : 7,
          ),
      focusedBorder: borderStyle,
      enabledBorder: borderStyle,
      disabledBorder: borderStyle,
    );
  }
}

String parseAutoDeleteInterval(int dSecond) {
  if (dSecond ~/ (3600 * 24 * 30) > 0) {
    return '${dSecond ~/ (3600 * 24 * 30)}${localized(monthSF)}';
  }
  if (dSecond ~/ (3600 * 24 * 7) > 0) {
    return '${dSecond ~/ (3600 * 24 * 7)}${localized(weekSF)}';
  }
  if (dSecond ~/ (3600 * 24) > 0) {
    return '${dSecond ~/ (3600 * 24)}${localized(daySF)}';
  }
  if (dSecond ~/ 3600 > 0) {
    return '${dSecond ~/ 3600}${localized(hourSF)}';
  }
  if (dSecond ~/ 60 > 0) {
    return '${dSecond ~/ 60}${localized(minuteSF)}';
  }
  return '$dSecond${localized(secondSF)}';
}
