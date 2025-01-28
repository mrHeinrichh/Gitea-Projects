import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/im/custom_input/component/input_ui_component.dart';

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

  List<Widget> buildContent(BuildContext context) {
    return [
      buildAddWidget(context),
      Expanded(
        child: Obx(() {
          if (controller.isVoiceMode.value) {
            return buildHoldToTalk(context);
          }

          return Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 0 : 0),
            child: RawKeyboardListener(
                focusNode: FocusNode(onKeyEvent: (node, event) {
                  if ((HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.shiftLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.shiftRight)) &&
                      event.logicalKey.keyId == 8589935117) {
                    return KeyEventResult.handled;
                  } else
                    return KeyEventResult.ignored;
                }),
                onKey: (RawKeyEvent event) {
                  onKey(event, context);
                },
                child: Stack(
                  children: [
                    buildInput(context),
                    Positioned(
                      top: isDesktop ? 0 : null,
                      right: 0,
                      bottom: 0,
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
                    )
                  ],
                )),
          );
        }),
      ),
      if (!isDesktop) buildRightWidget(),
      if (isDesktop) buildDesktopSend(),
    ];
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
    return JXColors.primaryTextBlack;
  }

  @override
  InputDecoration getInputDecoration(
      CustomInputController controller, bool isDesktop) {
    final borderStyle = OutlineInputBorder(
      borderRadius: jxDimension.textInputRadius(),
      borderSide: const BorderSide(
        color: JXColors.borderPrimaryColor,
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
                      color: inputHintTextColor.withOpacity(0.6)),
                )
              ],
            ),
      hintText: isTextingAllowed
          ? localized(isDesktop ? enterMessage : chatInputting)
          : null,
      hintStyle: isDesktop
          ? jxTextStyle.textStyle14(color: JXColors.iconTertiaryColor)
          : jxTextStyle.textStyle16(color: JXColors.iconTertiaryColor),
      isDense: true,
      fillColor: Colors.white,
      filled: true,
      isCollapsed: isDesktop ? false : true,
      counterText: '',
      contentPadding: jxDimension.chatTextFieldInputPadding().copyWith(
            left: 16,
            right: controller.chatController.chat.autoDeleteEnabled &&
                    controller.autoDeleteInterval != 0
                ? (isDesktop ? 50 : 41.0) + 34.0
                : isDesktop
                    ? 50
                    : 41.0,
            top: isDesktop ? 18 : 7,
            bottom: isDesktop ? 18 : 7,
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
  return '${dSecond}${localized(secondSF)}';
}
