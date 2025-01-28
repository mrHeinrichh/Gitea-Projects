import 'package:flutter/cupertino.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/custom_input/v2/custom_input_view2.dart';
import 'package:jxim_client/utils/config.dart';

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
      return Container();
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
      return Container();
    } else {
      // return CustomInputView(
      //   tag: tag,
      // );
      return CustomInputViewV2(tag);
    }
  }
}
