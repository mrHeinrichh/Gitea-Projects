import 'dart:convert';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

double getReceiveHasAvatarWidth() {
  double screenWidth = 1.sw;
  if (screenWidth == 390) {
    return 288.w;
  }
  double k = (285 / 390);
  double width = (screenWidth) * k;
  return width;
}

double bubbleSpace = 24.w;

Map<String, NewLineBean> newLineTypeMap = {};

NewLineBean calculateTextMaxWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  required bool isReceiver,
  String? reply,
  bool showReplyContent = false,
  bool showTranslationContent = false,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  double minWidth = 100.0,
}) {
  if (maxWidth < 1 || extraWidth < 1) {
    pdebug(" 换行代文本，入参 代码有误");
    return NewLineBean(GroupTextMessageReadType.none, maxWidth);
  }

  if (messageText.isEmpty &&
      (reply == null || reply.isEmpty) &&
      translationText.isEmpty) {
    return NewLineBean(GroupTextMessageReadType.none, maxWidth);
  }
  bool isEdit = message.edit_time > 0;

  TextStyle textStyle = jxTextStyle.normalBubbleText(bubblePrimary);
  double replyWidth = 0;
  if (reply != null && reply.isNotEmpty) {
    if (!showOriginalContent) {
      messageText = reply;
    }
    if (messageText.length < reply.length) {
      replyWidth = calculatedReplyTextWidth(
          reply: reply,
          textStyle: textStyle,
          maxWidth: maxWidth,
          messageText: messageText,
          showPinned: showPinned,
          isEdit: isEdit,
          isReceiver: isReceiver,
          emojiUserList: emojiUserList);
    }
  }
  if (messageText.isEmpty) {
    return NewLineBean(GroupTextMessageReadType.none, maxWidth);
  }
  messageText = newConvertSpecialText(messageText, message);

  if (emojiUserList.isNotEmpty) {
    NewLineBean bean = containsEmojiBubbleWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      textStyle: textStyle,
    );
    return bean;
  }

  if (showTranslationContent) {
    if (showTranslationContent) {
      messageText = translationText;
    }
    if (messageText.isEmpty) {
      pdebug(" 换行代文本，入参 代码有误");
      return NewLineBean(GroupTextMessageReadType.none, maxWidth);
    }
    NewLineBean bean = calculateAllTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );
    if (bean.type == GroupTextMessageReadType.beakLineType) {
      bean.type = GroupTextMessageReadType.none;
    }
    bean.minWidth = getTranslateMinWidth(isReceiver, showPinned, message, bean);
    bean.replyWidth = replyWidth;
    return bean;
  } else {
    if (messageText.isEmpty) {
      pdebug(" 换行代文本，入参 代码有误");
      return NewLineBean(GroupTextMessageReadType.none, maxWidth);
    }
    if (messageEmojiOnly) {
      double size = fontSizeWithEmojiLength(messageText);
      textStyle =
          jxTextStyle.normalBubbleText(bubblePrimary).copyWith(fontSize: size);
    }

    if (showPinned && (message.edit_time > 0)) {
      NewLineBean bean = calculateEditAndPinTextMaxWidth(
        message: message,
        messageText: messageText,
        maxWidth: maxWidth,
        extraWidth: extraWidth,
        reply: reply,
        isReceiver: isReceiver,
        showTranslationContent: showTranslationContent,
        translationText: translationText,
        showOriginalContent: showOriginalContent,
        messageEmojiOnly: messageEmojiOnly,
        isPlayingSound: isPlayingSound,
        isWaitingRead: isWaitingRead,
        showPinned: showPinned,
        emojiUserList: emojiUserList,
        showReplyContent: showReplyContent,
        textStyle: textStyle,
      );
      bean.replyWidth = replyWidth;
      return bean;
    } else if (showPinned) {
      NewLineBean bean = calculateOnlyPinTextMaxWidth(
        message: message,
        messageText: messageText,
        maxWidth: maxWidth,
        extraWidth: extraWidth,
        reply: reply,
        isReceiver: isReceiver,
        showTranslationContent: showTranslationContent,
        translationText: translationText,
        showOriginalContent: showOriginalContent,
        messageEmojiOnly: messageEmojiOnly,
        isPlayingSound: isPlayingSound,
        isWaitingRead: isWaitingRead,
        showPinned: showPinned,
        emojiUserList: emojiUserList,
        showReplyContent: showReplyContent,
        textStyle: textStyle,
      );
      bean.replyWidth = replyWidth;
      return bean;
    } else if (message.edit_time > 0) {
      NewLineBean bean = calculateOnlyEditTextMaxWidth(
        message: message,
        messageText: messageText,
        maxWidth: maxWidth,
        extraWidth: extraWidth,
        reply: reply,
        isReceiver: isReceiver,
        showTranslationContent: showTranslationContent,
        translationText: translationText,
        showOriginalContent: showOriginalContent,
        messageEmojiOnly: messageEmojiOnly,
        isPlayingSound: isPlayingSound,
        isWaitingRead: isWaitingRead,
        showPinned: showPinned,
        emojiUserList: emojiUserList,
        showReplyContent: showReplyContent,
        textStyle: textStyle,
      );
      bean.replyWidth = replyWidth;
      return bean;
    } else {
      NewLineBean bean = calculateNormalTextMaxWidth(
        message: message,
        messageText: messageText,
        maxWidth: maxWidth,
        extraWidth: extraWidth,
        reply: reply,
        isReceiver: isReceiver,
        showTranslationContent: showTranslationContent,
        translationText: translationText,
        showOriginalContent: showOriginalContent,
        messageEmojiOnly: messageEmojiOnly,
        isPlayingSound: isPlayingSound,
        isWaitingRead: isWaitingRead,
        showPinned: showPinned,
        emojiUserList: emojiUserList,
        showReplyContent: showReplyContent,
        minWidth: minWidth,
        textStyle: textStyle,
      );
      if (bean.calculatedWidth > maxWidth) {
        bean.calculatedWidth = maxWidth;
      }
      bean.replyWidth = replyWidth;
      return bean;
    }
  }
}

double getTranslateMinWidth(
  bool isReceiver,
  bool showPinned,
  Message message,
  NewLineBean bean,
) {
  if (!isReceiver) {
    if (showPinned && (message.edit_time > 0)) {
      return GroupTextPlaceHolderType.isMeEditAndPin.translateMultilingualWidth;
    } else if (showPinned) {
      return GroupTextPlaceHolderType.isMeOnlyPin.translateMultilingualWidth;
    } else if (message.edit_time > 0) {
      return GroupTextPlaceHolderType.isMeOnlyEdit.translateMultilingualWidth;
    } else {
      return GroupTextPlaceHolderType.isMeNone.translateMultilingualWidth;
    }
  } else {
    if (showPinned && (message.edit_time > 0)) {
      return GroupTextPlaceHolderType
          .isSendEditAndPin.translateMultilingualWidth;
    } else if (showPinned) {
      return GroupTextPlaceHolderType.isSendOnlyPin.translateMultilingualWidth;
    } else if (message.edit_time > 0) {
      return GroupTextPlaceHolderType.isSendOnlyEdit.translateMultilingualWidth;
    } else {
      return GroupTextPlaceHolderType.isSendNone.translateMultilingualWidth;
    }
  }
}

NewLineBean calculateNormalTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    return calculateIsMeNormalTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderNormalTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderNormalTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsSenderNormalTextHasNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderNormalTextHasNotNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderNormalTextHasNotNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderNormalTextHasNotNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderNormalTextHasNotNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderNormalTextHasNotNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendNone,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderNormalTextHasNotNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendNone,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderNormalTextHasNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderNormalTextHasNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderNormalTextHasNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderNormalTextHasNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendNone,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderNormalTextHasNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendNone,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeNormalTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsMeNormalTextHasNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeNormalTextHasNotNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeNormalTextHasNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeNormalTextHasNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeNormalTextHasNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeNormalTextHasNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeNone,
    minWidth: minWidth,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeNormalTextHasNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeNone,
    minWidth: minWidth,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeNormalTextHasNotNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeNormalTextHasNotNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeNormalTextHasNotNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeNormalTextHasNotNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeNone,
    minWidth: minWidth,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeNormalTextHasNotNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required double minWidth,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeNone,
    minWidth: minWidth,
    textStyle: textStyle,
  );
}

NewLineBean calculateOnlyEditTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    return calculateIsMeOnlyEditTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyEditTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyEditTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsMeOnlyEditHasNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyEditHasNotNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyEditHasNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeOnlyEditHasNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyEditHasNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyEditHasNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyEditHasNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyEditHasNotNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeOnlyEditHasNotNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyEditHasNotNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyEditHasNotNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyEditHasNotNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyEditTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsSenderOnlyEditHasNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyEditHasNotNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyEditHasNotNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderOnlyEditHasNotNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyEditHasNotNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyEditHasNotNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyEditHasNotNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyEditHasNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderOnlyEditHasNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyEditHasNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyEditHasNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyEditHasNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyEdit,
    textStyle: textStyle,
  );
}

NewLineBean calculateOnlyPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    return calculateIsMeOnlyPinTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyPinTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsSenderOnlyPinTextHasNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyPinTextHasNotNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyPinTextHasNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderOnlyPinTextHasNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyPinTextHasNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyPinTextHasNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyPinTextHasNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyPinTextHasNotNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSenderOnlyPinTextHasNotNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderOnlyPinTextHasNotNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSenderOnlyPinTextHasNotNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderOnlyPinTextHasNotNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsMeOnlyPinTextHasNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyPinTextHasNotNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyPinTextHasNotNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeOnlyPinTextHasNotNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyPinTextHasNotNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyPinTextHasNotNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyPinTextHasNotNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyPinTextHasNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeOnlyPinTextHasNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeOnlyPinTextHasNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyPinTextHasNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeOnlyPinTextHasNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeOnlyPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateEditAndPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    return calculateIsMeEditAndPinTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSendEditAndPinTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSendEditAndPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsSendEditAndPinTextHasNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSendEditAndPinTextHasNotNewLineSymbolMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSendEditAndPinTextHasNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSendEditAndPinTextHasNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSendEditAndPinTextHasNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSendEditAndPinTextHasNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSendEditAndPinTextHasNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSendEditAndPinTextHasNotNewLineSymbolMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsSendEditAndPinTextHasNotNewLineSymbolReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSendEditAndPinTextHasNotNewLineSymbolReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsSendEditAndPinTextHasNotNewLineSymbolReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSendEditAndPinTextHasNotNewLineSymbolReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isSendEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeEditAndPinTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (messageText.contains("\n")) {
    return calculateIsMeEditAndPinHasNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeEditAndPinHasNotNewLineSymbolTextMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeEditAndPinHasNotNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeEditAndPinHasNotNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeEditAndPinHasNotNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeEditAndPinHasNotNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeEditAndPinHasNotNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeEditAndPinHasNewLineSymbolTextMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  if (reply != null && reply.isNotEmpty) {
    return calculateIsMeEditAndPinHasNewLineSymbolTextReplyMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  } else {
    return calculateIsMeEditAndPinHasNewLineSymbolTextReplyNotMaxWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showTranslationContent: showTranslationContent,
      translationText: translationText,
      showOriginalContent: showOriginalContent,
      messageEmojiOnly: messageEmojiOnly,
      isPlayingSound: isPlayingSound,
      isWaitingRead: isWaitingRead,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      showReplyContent: showReplyContent,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeEditAndPinHasNewLineSymbolTextReplyNotMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsMeEditAndPinHasNewLineSymbolTextReplyMaxWidth({
  required Message message,
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required String? reply,
  required bool isReceiver,
  required bool showTranslationContent,
  required String translationText,
  required bool showOriginalContent,
  required bool messageEmojiOnly,
  required bool isPlayingSound,
  required bool isWaitingRead,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showReplyContent,
  required TextStyle textStyle,
}) {
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: GroupTextPlaceHolderType.isMeEditAndPin,
    textStyle: textStyle,
  );
}

NewLineBean containsEmojiBubbleWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showTranslationContent,
  required String translationText,
  required bool isReceiver,
  required String? reply,
  required bool showReplyContent,
  required bool showOriginalContent,
  required TextStyle textStyle,
}) {
  double minWidth = getContainsEmojiBubbleMinWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    showPinned: showPinned,
    emojiUserList: emojiUserList,
    showTranslationContent: showTranslationContent,
    translationText: translationText,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    showOriginalContent: showOriginalContent,
  );

  double actualWidth = maxWidth;
  double itemLineHeight = 22;
  int lineCounts = 1;

  if (showTranslationContent && translationText.isNotEmpty ||
      messageText.isNotEmpty) {
    if (showTranslationContent && translationText.isNotEmpty) {
      messageText = translationText;
    }
    NewLineBean bean = calculateAllTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );

    if (bean.actualWidth > minWidth) {
      return NewLineBean(
        GroupTextMessageReadType.none,
        maxWidth,
        minWidth: minWidth,
        actualWidth: bean.actualWidth,
        lineCounts: bean.lineCounts,
        itemLineHeight: bean.itemLineHeight,
      );
    } else {
      actualWidth = bean.actualWidth;
    }
  } else {
    /// 这里主要是为了超长文本而获取行高和item高度,其他返回参数不需要
    NewLineBean bean = baseUsePlaceholderWidthCalculateWidth(
      message: message,
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      reply: reply,
      isReceiver: isReceiver,
      showReplyContent: showReplyContent,
      minWidth: minWidth,
      type: GroupTextPlaceHolderType.isMeNone,
      textStyle: textStyle,
    );
    itemLineHeight = bean.itemLineHeight;
    lineCounts = bean.lineCounts;
  }
  return NewLineBean(
    GroupTextMessageReadType.none,
    maxWidth,
    minWidth: minWidth,
    actualWidth: actualWidth,
    lineCounts: lineCounts,
    itemLineHeight: itemLineHeight,
  );
}

double getContainsEmojiBubbleMinWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  required bool showPinned,
  required RxList<EmojiModel> emojiUserList,
  required bool showTranslationContent,
  required String translationText,
  required bool isReceiver,
  String? reply,
  required bool showReplyContent,
  required bool showOriginalContent,
}) {
  if (emojiUserList.length > 3) {
    return maxWidth + bubbleSpace;
  }

  double emojiTotalWidth = getEmojiTotalWidth(
    emojiUserList: emojiUserList,
    maxWidth: maxWidth,
  );
  bool isEdit = isEditMessage(message);

  double timeLeftPadding = placeHolderInnerPadding;
  double emojiTotalWidthMargin = emojiTotalWidth + textWithPlaceHolderPadding;
  if (!isReceiver) {
    double timeAndIconWidth =
        GroupTextPlaceHolderType.isMeNone.multilingualWidth;

    if (showPinned && isEdit) {
      return emojiTotalWidthMargin +
          (editTextWidth + pinIconWidth + placeHolderInnerPadding) +
          timeLeftPadding +
          timeAndIconWidth;
    } else if (isEdit) {
      return emojiTotalWidthMargin +
          (editTextWidth) +
          timeLeftPadding +
          timeAndIconWidth;
    } else if (showPinned) {
      return emojiTotalWidthMargin +
          (pinIconWidth) +
          timeLeftPadding +
          timeAndIconWidth;
    } else {
      return emojiTotalWidthMargin + timeAndIconWidth;
    }
  } else {
    double timeWidth = GroupTextPlaceHolderType.isSendNone.multilingualWidth;
    if (showPinned && isEdit) {
      return emojiTotalWidthMargin +
          (editTextWidth + pinIconWidth + placeHolderInnerPadding) +
          timeLeftPadding +
          timeWidth;
    } else if (isEdit) {
      return emojiTotalWidthMargin +
          (editTextWidth) +
          timeLeftPadding +
          timeWidth;
    } else if (showPinned) {
      return emojiTotalWidthMargin +
          (pinIconWidth) +
          timeLeftPadding +
          timeWidth;
    } else {
      return emojiTotalWidthMargin + timeWidth;
    }
  }
}

double getEmojiTotalWidth({
  required RxList<EmojiModel> emojiUserList,
  required double maxWidth,
}) {
  int emojisLen = emojiUserList.length;
  double emojiTotalWidth = 0;
  if (emojisLen == 1) {
    return emojiWidthUnit + emojiSpaceHorizontalUnitSpace;
  } else if (emojisLen == 2) {
    return emojiWidthUnit * 2 + emojiSpaceHorizontalUnitSpace;
  } else if (emojisLen == 3) {
    return emojiWidthUnit * 3 + emojiSpaceHorizontalUnitSpace * 2;
  } else {
    debugPrint("=========> 超过4种类型的部分");
  }
  return emojiTotalWidth;
}

NewLineBean calculateAllTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required TextStyle textStyle,
}) {
  if (showOriginalContent) {
    return calculateOnlyShowOriginalContentTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );
  } else {
    return calculateAllShowTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateOnlyShowOriginalContentTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    double minWidth = GroupTextPlaceHolderType.isMeNone.multilingualWidth;
    return calculateIsMeOnlyShowOriginalContentTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  } else {
    double minWidth = GroupTextPlaceHolderType.isSendNone.multilingualWidth;
    return calculateIsSendOnlyShowOriginalContentTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      minWidth: minWidth,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeOnlyShowOriginalContentTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required double minWidth,
  required TextStyle textStyle,
}) {
  GroupTextPlaceHolderType type = showPinned
      ? GroupTextPlaceHolderType.isMeOnlyPin
      : GroupTextPlaceHolderType.isMeNone;
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: type,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSendOnlyShowOriginalContentTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required double minWidth,
  required TextStyle textStyle,
}) {
  GroupTextPlaceHolderType type = showPinned
      ? GroupTextPlaceHolderType.isSendOnlyPin
      : GroupTextPlaceHolderType.isSendNone;
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: type,
    textStyle: textStyle,
  );
}

NewLineBean calculateAllShowTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required TextStyle textStyle,
}) {
  if (!isReceiver) {
    return calculateIsMeAllShowTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );
  } else {
    return calculateIsSenderAllShowTranslationTextWidth(
      messageText: messageText,
      maxWidth: maxWidth,
      extraWidth: extraWidth,
      message: message,
      isReceiver: isReceiver,
      reply: reply,
      showReplyContent: showReplyContent,
      showOriginalContent: showOriginalContent,
      showPinned: showPinned,
      textStyle: textStyle,
    );
  }
}

NewLineBean calculateIsMeAllShowTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required TextStyle textStyle,
}) {
  GroupTextPlaceHolderType type = showPinned
      ? GroupTextPlaceHolderType.isMeOnlyPin
      : GroupTextPlaceHolderType.isMeNone;
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: type,
    textStyle: textStyle,
  );
}

NewLineBean calculateIsSenderAllShowTranslationTextWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required bool showOriginalContent,
  required bool showPinned,
  required TextStyle textStyle,
}) {
  GroupTextPlaceHolderType type = showPinned
      ? GroupTextPlaceHolderType.isSendOnlyPin
      : GroupTextPlaceHolderType.isSendNone;
  return baseUsePlaceholderWidthCalculateWidth(
    messageText: messageText,
    maxWidth: maxWidth,
    extraWidth: extraWidth,
    message: message,
    isReceiver: isReceiver,
    reply: reply,
    showReplyContent: showReplyContent,
    type: type,
    textStyle: textStyle,
  );
}

double getMaxWidth(
  double maxWidth,
  int t2,
  TextPainter textPainter2,
  double t3,
  String originalText,
  TextStyle textStyle,
) {
  if (originalText.contains('\n')) {
    List<String> list = originalText.split('\n');
    String txt = "";
    for (String str in list) {
      int c = str.length;
      if (c > txt.length) {
        txt = str;
      }
    }
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: txt, style: textStyle),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);
    int len = textPainter.computeLineMetrics().length;
    if (len > 1) {
      return maxWidth + bubbleSpace;
    } else {
      double calculatedWidth = maxWidth;
      calculatedWidth = textPainter.computeLineMetrics().first.width;
      if (calculatedWidth > maxWidth) {
        calculatedWidth = maxWidth + bubbleSpace;
      } else {
        double c = calculatedWidth + t3 + bubbleSpace;
        if (c < maxWidth) {
          calculatedWidth = c;
        } else {
          calculatedWidth = maxWidth + bubbleSpace;
        }
      }
      return calculatedWidth;
    }
  } else {
    double calculatedWidth = maxWidth;
    if (t2 == 1) {
      calculatedWidth = textPainter2.computeLineMetrics().first.width;
      if (calculatedWidth > maxWidth) {
        calculatedWidth = maxWidth + bubbleSpace;
      } else {
        double c = calculatedWidth + t3 + bubbleSpace;
        if (c < maxWidth) {
          calculatedWidth = c;
        } else {
          calculatedWidth = maxWidth + bubbleSpace;
        }
      }
    } else {
      calculatedWidth = maxWidth + bubbleSpace;
    }
    return calculatedWidth;
  }
}

NewLineBean baseUsePlaceholderWidthCalculateWidth({
  required String messageText,
  required double maxWidth,
  required double extraWidth,
  required Message message,
  bool isReceiver = false,
  String? reply,
  bool showReplyContent = false,
  required GroupTextPlaceHolderType type,
  required TextStyle textStyle,
  double minWidth = 100.0,
}) {
  TextPainter textPainter = TextPainter(
    text: TextSpan(text: messageText, style: textStyle),
    maxLines: null,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(maxWidth: maxWidth);

  double placeHolderWidth = type.multilingualWidth;

  int len = textPainter.computeLineMetrics().length;

  double calculatedMaxWidth = getLongestTextWidth(
    maxWidth: maxWidth,
    textOriginalPainter: textPainter,
    textStyle: textStyle,
    placeHolderWidth: placeHolderWidth,
    originalText: messageText,
    minWidth: minWidth,
    reply: reply,
  );

  double w = textPainter.computeLineMetrics().last.width;
  double h = textPainter.computeLineMetrics().last.height;

  if (len == 1) {
    double b = maxWidth - placeHolderWidth;
    if (w < b) {
      return NewLineBean(
        GroupTextMessageReadType.inlineType,
        calculatedMaxWidth,
        actualWidth: w + placeHolderWidth,
        itemLineHeight: h,
        lineCounts: len,
      );
    } else {
      return NewLineBean(
        GroupTextMessageReadType.beakLineType,
        calculatedMaxWidth,
        actualWidth: w,
        itemLineHeight: h,
        lineCounts: len,
        minWidth: minWidth,
      );
    }
  } else {
    double b = maxWidth - placeHolderWidth;
    if (w < b) {
      return NewLineBean(
        GroupTextMessageReadType.inlineType,
        calculatedMaxWidth,
        actualWidth: calculatedMaxWidth,
        itemLineHeight: h,
        lineCounts: len,
        minWidth: minWidth,
      );
    } else {
      return NewLineBean(
        GroupTextMessageReadType.beakLineType,
        calculatedMaxWidth,
        actualWidth: calculatedMaxWidth,
        itemLineHeight: h,
        lineCounts: len,
        minWidth: minWidth,
      );
    }
  }
}

String handleText(String messageText) {
  List<String> charactersList = messageText.characters.toList();
  String str = "";
  for (int k = 0; k < charactersList.length; k++) {
    str += "${charactersList[k]}${"\u{200B}"}";
  }
  return str;
}

double getLongestTextWidth({
  required double maxWidth,
  required TextPainter textOriginalPainter,
  required TextStyle textStyle,
  required double placeHolderWidth,
  required String originalText,
  required double minWidth,
  required String? reply,
}) {
  if (originalText.contains('\n')) {
    List<String> list = originalText.split('\n');
    String txt = "";
    for (String str in list) {
      String s = str.trim();
      int c = s.length;
      if (c > txt.length) {
        txt = s;
      }
    }
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: txt, style: textStyle),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);

    int len = textPainter.computeLineMetrics().length;
    if (len > 1) {
      return maxWidth + bubbleSpace;
    } else {
      double calculatedWidth = maxWidth;
      calculatedWidth = textPainter.computeLineMetrics().first.width;
      if (calculatedWidth > maxWidth) {
        calculatedWidth = maxWidth + bubbleSpace;
      } else {
        double c = calculatedWidth + placeHolderWidth + bubbleSpace;
        if (c < maxWidth) {
          calculatedWidth = c;
        } else {
          calculatedWidth = maxWidth + bubbleSpace;
        }
      }

      if (minWidth > calculatedWidth) {
        return minWidth;
      }
      return calculatedWidth;
    }
  } else {
    int len = textOriginalPainter.computeLineMetrics().length;
    double calculatedWidth = maxWidth;
    if (len == 1) {
      if (calculatedWidth > maxWidth) {
        calculatedWidth = maxWidth + bubbleSpace;
      } else {
        double c = calculatedWidth + placeHolderWidth + bubbleSpace;
        if (c < maxWidth) {
          calculatedWidth = c;
        } else {
          calculatedWidth = maxWidth + bubbleSpace;
        }
      }
    } else {
      calculatedWidth = maxWidth + bubbleSpace;
    }
    if (minWidth > calculatedWidth) {
      return minWidth;
    }
    return calculatedWidth;
  }
}

double calculateNameWidth(
    {required String? name,
    required TextStyle textStyle,
    required double maxWidth}) {
  TextPainter textPainter = TextPainter(
    text: TextSpan(text: name, style: textStyle),
    maxLines: null,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(minWidth: 0, maxWidth: maxWidth);
  return textPainter.width;
}

double calculatedReplyTextWidth({
  required String reply,
  required TextStyle textStyle,
  required double maxWidth,
  required String messageText,
  required bool showPinned,
  required bool isEdit,
  required bool isReceiver,
  required RxList<EmojiModel> emojiUserList,
}) {
  if (reply.contains("\n")) {
    List<String> list = reply.split('\n');
    reply = list[0];
  }
  TextPainter textPainter = TextPainter(
    text: TextSpan(text: reply, style: textStyle),
    maxLines: null,
    textDirection: TextDirection.ltr,
  );

  double minContentWidth = 50; //最小初始寬度
  textPainter.layout(minWidth: minContentWidth, maxWidth: maxWidth);
  int len = textPainter.computeLineMetrics().length;
  double w = textPainter.width;

  bool textEmpty = false; //確認是否為非針對訊息回覆,如紅包,地址等
  if (reply.contains('"text":""')) textEmpty = true;

  if (textEmpty) {
    //如果是回覆紅包,地址等
    Map<String, dynamic> jsonData = json.decode(reply);
    String? name = jsonData['nick_name'];
    // User? user = objectMgr.userMgr.getUserById(jsonData['user_id']);
    // String? name = user?.username;
    double nameWidth = calculateNameWidth(
      name: name ?? '',
      textStyle: TextStyle(
        fontWeight: MFontWeight.bold5.value,
        fontSize: bubbleNicknameSize,
      ).useSystemChineseFont(),
      maxWidth: maxWidth,
    );
    //對回覆紅包,地址等回覆的訊息計算寬度
    TextPainter msgTextPainter = TextPainter(
      text: TextSpan(text: messageText, style: textStyle),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );
    msgTextPainter.layout(minWidth: minContentWidth, maxWidth: maxWidth);
    double msw = msgTextPainter.width; //計算後取得的紅包,地址等回覆訊息的寬度
    double timeLeftPadding = placeHolderInnerPadding;
    double emojiTotalWidth = getEmojiTotalWidth(
      emojiUserList: emojiUserList,
      maxWidth: maxWidth,
    );
    double emojiTotalWidthMargin = emojiTotalWidth + textWithPlaceHolderPadding;

    if (!isReceiver) {
      double timeAndIconWidth =
          GroupTextPlaceHolderType.isMeNone.multilingualWidth;

      if (showPinned && isEdit) {
        msw += emojiTotalWidthMargin +
            (editTextWidth + pinIconWidth + placeHolderInnerPadding) +
            timeLeftPadding +
            timeAndIconWidth +
            nameWidth;
      } else if (isEdit) {
        msw += emojiTotalWidthMargin +
            (editTextWidth) +
            timeLeftPadding +
            timeAndIconWidth +
            nameWidth;
      } else if (showPinned) {
        msw += emojiTotalWidthMargin +
            (pinIconWidth) +
            timeLeftPadding +
            timeAndIconWidth +
            nameWidth;
      } else {
        msw += emojiTotalWidthMargin + timeAndIconWidth + nameWidth;
      }
    } else {
      double timeWidth = GroupTextPlaceHolderType.isSendNone.multilingualWidth;
      if (showPinned && isEdit) {
        msw += emojiTotalWidthMargin +
            (editTextWidth + pinIconWidth + placeHolderInnerPadding) +
            timeLeftPadding +
            timeWidth +
            nameWidth;
      } else if (isEdit) {
        msw += emojiTotalWidthMargin +
            (editTextWidth) +
            timeLeftPadding +
            timeWidth +
            nameWidth;
      } else if (showPinned) {
        msw += emojiTotalWidthMargin +
            (pinIconWidth) +
            timeLeftPadding +
            timeWidth +
            nameWidth;
      } else {
        msw += emojiTotalWidthMargin + timeWidth + nameWidth;
      }
    }

    double replyTxtWidth;
    if (msw > maxWidth) {
      replyTxtWidth = maxWidth;
    } else if (msw > minContentWidth) {
      replyTxtWidth = msw;
    } else {
      replyTxtWidth = minContentWidth;
    }
    return replyTxtWidth;
  } else if (len == 1) {
    return w;
  } else {
    //這邊為非紅包,地址那些的回覆
    if (maxWidth < w) {
      return maxWidth;
    } else {
      return w;
    }
  }
}

String newConvertSpecialText(String text, Message message) {
  Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);

  Iterable<RegExpMatch> matches = Regular.extractLink(text);
  if (matches.isNotEmpty ||
      message.atUser.isNotEmpty ||
      message.data.containsKey('at_users') &&
          notBlank(message.getValue('at_users')) &&
          message.getValue('at_users') is String) {
    return parseUserNameAndLink(message, mentionMatches, text, matches);
  } else {
    return text;
  }
}

String parseUserNameAndLink(
  Message message,
  Iterable<RegExpMatch> mentionMatches,
  String text,
  Iterable<RegExpMatch> matches,
) {
  List<RegexTextModel> spanMapsList = [];

  List<RegexTextModel> firstLastSpanMapsList = [];

  List<RegexTextModel> textSpanMapsList = [];

  List<MentionModel> mentionList = <MentionModel>[];
  if (message.atUser.isNotEmpty) {
    mentionList.addAll(message.atUser);
  } else if (message.data.containsKey('at_users') &&
      notBlank(message.getValue('at_users')) &&
      message.getValue('at_users') is String) {
    final atUser = jsonDecode(message.getValue('at_users'));
    if (notBlank(atUser) && atUser is List) {
      mentionList.addAll(
        atUser.map<MentionModel>((e) => MentionModel.fromJson(e)).toList(),
      );
    }
  }

  if (mentionMatches.isNotEmpty) {
    for (var match in mentionMatches) {
      RegexTextModel spanMap = RegexTextModel(
        type: RegexTextType.mention.value,
        text: text.substring(match.start, match.end),
        start: match.start,
        end: match.end,
      );
      spanMapsList.add(spanMap);
    }
  }

  if (matches.isNotEmpty) {
    for (var match in matches) {
      RegexTextModel spanMap = RegexTextModel(
        type: RegexTextType.link.value,
        text: text.substring(match.start, match.end),
        start: match.start,
        end: match.end,
      );
      spanMapsList.add(spanMap);
    }
  }
  if (spanMapsList.isEmpty) {
    return text;
  }

  spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

  if (spanMapsList.first.start > 0) {
    RegexTextModel spanMap = RegexTextModel(
      type: RegexTextType.text.value,
      text: text.substring(0, spanMapsList.first.start),
      start: 0,
      end: spanMapsList.first.start,
    );
    firstLastSpanMapsList.add(spanMap);
  }

  if (spanMapsList.last.end < text.length) {
    RegexTextModel spanMap = RegexTextModel(
      type: RegexTextType.text.value,
      text: text.substring(spanMapsList.last.end, text.length),
      start: spanMapsList.last.end,
      end: text.length,
    );
    firstLastSpanMapsList.add(spanMap);
  }
  spanMapsList.addAll(firstLastSpanMapsList);

  spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

  for (int i = 0; i < spanMapsList.length; i++) {
    try {
      int firstEnd = spanMapsList[i].end;
      if (i + 1 == spanMapsList.length) break;
      int secondStart = spanMapsList[i + 1].start;

      if (secondStart != firstEnd) {
        RegexTextModel spanMap = RegexTextModel(
          type: RegexTextType.text.value,
          text: text.substring(firstEnd, secondStart),
          start: firstEnd,
          end: secondStart,
        );
        textSpanMapsList.add(spanMap);
      }
    } catch (e) {
      pdebug(e.toString());
    }
  }
  spanMapsList.addAll(textSpanMapsList);

  spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

  String txt = "";
  for (int i = 0; i < spanMapsList.length; i++) {
    String subText = spanMapsList[i].text;

    bool startsWithNewline = subText.startsWith('\n');

    if (startsWithNewline) {
      txt += "\n";
      subText = subText.substring(1);
    }

    if (spanMapsList[i].type == RegexTextType.mention.value) {
      String uidStr = Regular.extractDigit(subText)?.group(0) ?? '';
      int uid = int.parse(uidStr);
      final MentionModel? model =
          mentionList.firstWhereOrNull((mention) => mention.userId == uid);

      String name = '';

      if (uid == 0 && model != null && model.role == Role.all) {
        name = localized(mentionAll);
      } else {
        if (uid == 0) {
          name = localized(mentionAll);
        } else if (model != null) {
          name = model.userName;
        } else {
          name = objectMgr.userMgr
              .getUserTitle(objectMgr.userMgr.getUserById(uid));
        }
      }

      if (name.isEmpty) {
        if (model == null) {
          name = uidStr.toString();
        } else {
          name = model.userName;
        }
      }
      txt += '@$name';
    } else if (spanMapsList[i].type == RegexTextType.link.value) {
      RegExp regExp = RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
      subText = subText.replaceAll(regExp, '');

      txt += handleText(subText);
    } else {
      txt += subText;
    }
  }
  return txt;
}

double getNewLineExtraWidth({
  required bool showPinned,
  required bool isEdit,
  required bool isSender,
  List<EmojiModel>? emojiUserList,
  GroupTextMessageReadType? groupTextMessageReadType,
  bool? messageEmojiOnly = false,
  bool? showReplyContent = false,
  bool? showTranslationContent = false,
}) {
  if (isSender) {
    if (showPinned && isEdit) {
      return GroupTextPlaceHolderType.isSendEditAndPin.multilingualWidth;
    } else if (showPinned) {
      return GroupTextPlaceHolderType.isSendOnlyPin.multilingualWidth;
    } else if (isEdit) {
      return GroupTextPlaceHolderType.isSendOnlyEdit.multilingualWidth;
    } else {
      return GroupTextPlaceHolderType.isSendNone.multilingualWidth;
    }
  } else {
    if (showPinned && isEdit) {
      return GroupTextPlaceHolderType.isMeEditAndPin.multilingualWidth;
    } else if (showPinned) {
      return GroupTextPlaceHolderType.isMeOnlyPin.multilingualWidth;
    } else if (isEdit) {
      return GroupTextPlaceHolderType.isMeOnlyEdit.multilingualWidth;
    } else {
      return GroupTextPlaceHolderType.isMeNone.multilingualWidth;
    }
  }
}

class NewLineBean {
  double calculatedWidth;
  GroupTextMessageReadType type;

  double minWidth;
  double actualWidth;

  /// 总行数(仅限没有换行符的)
  int lineCounts;

  /// 单个的行高
  double itemLineHeight;

  /// 有回复 计算以下回复的高度
  double replyWidth = 0;

  NewLineBean(
    this.type,
    this.calculatedWidth, {
    this.minWidth = 0,
    this.actualWidth = 100,
    this.lineCounts = 0,
    this.itemLineHeight = 0,
  });

  double get totalHeights {
    if (lineCounts != null &&
        lineCounts != 0 &&
        itemLineHeight != null &&
        itemLineHeight != 0) {
      return lineCounts * itemLineHeight;
    }
    return 0;
  }

  @override
  toString() {
    return "minWidth = $minWidth,actualWidth =$actualWidth,actualWidth =$actualWidth";
  }
}

enum GroupTextPlaceHolderType {
  isSendNone(34),
  isSendOnlyEdit(73),
  isSendOnlyPin(51),
  isSendEditAndPin(85),
  isMeNone(51),
  isMeOnlyEdit(85),
  isMeOnlyPin(68),
  isMeEditAndPin(107),
  isTranslate(32);

  const GroupTextPlaceHolderType(this.placeHolderWidth);

  final double placeHolderWidth;

  double get multilingualWidth {
    return placeHolderWidth.w;
  }

  double get translateMultilingualWidth {
    return (placeHolderWidth + isTranslate.placeHolderWidth).w;
  }
}

bool isEditMessage(Message message) {
  return (message.edit_time > 0);
}

double lineSpacing = 12.w;

double get chatBubbleBodyVerticalPadding {
  return 4.w;
}

double get chatBubbleBodyHorizontalPadding {
  return 12.w;
}

double get textWithPlaceHolderPadding {
  return 8.w;
}

double get emojiSpaceHorizontalUnitSpace {
  return 4.w;
}

double get emojiSpaceVerticalUnitSpace {
  return 4.w;
}

double get emojiWidthUnit {
  return 44.w;
}

double get editTextWidth {
  return 38.w;
}

double get pinIconWidth {
  return 17.w;
}

double get placeHolderInnerPadding {
  return 2.w;
}

String getReplyStr(String reply) {
  if (reply.isNotEmpty) {
    ReplyModel model = ReplyModel.fromJson(
      json.decode(reply),
    );
    switch (model.typ) {
      case messageTypeReply:
      case messageTypeText:
      case messageTypeLink:
        return model.text;
      case messageTypeFile:
      case messageTypeImage:
      case messageTypeVideo:
        if (model.filePath != null) {
          String fileName = model.filePath.split("/").last;
          return fileName;
        } else {
          return "--";
        }
    }
  }
  return reply;
}

///  点赞后，需要重新计算
double getBubbleMaxWidth(
    {required double textWidth,
    required int emojiLen,
    required bool isSender,
    required double extraWidth}) {
  double maxW = textWidth;
  double tempW = 0.0;

  if (isSender) {
    double temp = emojiLen > 0 ? 50.w : 0.w;
    tempW = emojiLen * (44.w + 2) + extraWidth + temp;
  } else {
    double temp = emojiLen > 0 ? 35.w : 0.w;
    tempW = emojiLen * (44.w + 2) + extraWidth + temp;
  }

  if (maxW < tempW) {
    maxW = tempW;
  }
  return maxW;
}

double getTextWidth(String text, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();

  return textPainter.width;
}

/// 获取一个字符串长度
double getTextStrWidth(String text, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();

  return textPainter.width;
}

double fontSizeWithEmojiLength(String text) {
  final matches = EmojiParser.REGEX_EMOJI.allMatches(text);
  final length = matches.length;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  if (length == 1) {
    return isDesktop ? 96.0 : 84.0;
  } else if (length == 2) {
    return isDesktop ? 92.0 : 66.0;
  } else if (length == 3) {
    return isDesktop ? 80.0 : 48.0;
  } else if (length == 4) {
    return isDesktop ? 65.0 : 30.0;
  } else if (length == 5) {
    return isDesktop ? 52.0 : 24.0;
  } else if (length == 6) {
    return isDesktop ? 40.0 : 24.0;
  }
  return isDesktop ? 26.0 : 24.0; // Default value for unspecified lengths
}
