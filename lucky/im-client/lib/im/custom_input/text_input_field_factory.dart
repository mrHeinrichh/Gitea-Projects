import 'package:flutter/cupertino.dart';

import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/im/custom_input/component/game_text_input_field.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/custom_input/custom_input_view.dart';
import 'package:jxim_client/im/custom_input/game_custom_input_view.dart';

class TextInputFieldFactory {
  static Widget createComponent({
    required String tag,
    Key? key,
    bool onMoreOpen = false,
    bool isTextingAllowed = true,
    bool isShowSticker = true,
    bool isShowAttachment = true,
    bool isNormalUserCanInput = false,
    bool showBottomAttachment = true,
  }) {
    if (Config().orgChannel == 2) {
      return GameTextInputView(
        tag: tag,
        onMoreOpen: onMoreOpen,
        isTextingAllowed: isTextingAllowed,
        isShowSticker: isShowSticker,
        isShowAttachment: isShowAttachment,
        showBottomAttachment: showBottomAttachment,
      );
    } else {
      return TextInputView(
        tag: tag,
        onMoreOpen: onMoreOpen,
        isTextingAllowed: isTextingAllowed,
        isShowSticker: isShowSticker,
        isShowAttachment: isShowAttachment,
        showBottomAttachment: showBottomAttachment,
      );
    }
  }

  static Widget createCustomInputViewComponent({
    required String tag,
    Key? key,
    bool onMoreOpen = false,
    bool isTextingAllowed = true,
    bool isShowSticker = true,
    bool isShowAttachment = true,
    bool isNormalUserCanInput = false,
    bool showBottomAttachment = true,
  }) {
    if (Config().orgChannel == 2) {
      return GameCustomInputView(
        tag: tag,
      );
    } else {
      return CustomInputView(
        tag: tag,
      );
    }
  }
}
