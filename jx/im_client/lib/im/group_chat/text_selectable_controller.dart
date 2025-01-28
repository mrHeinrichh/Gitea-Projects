import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/regex_text_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/group/customize_selectable_text.dart';

class TextSelectableController extends GetxController {
  late String text;

  late Chat chat;
  late Message message;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    text = args["text"];
    chat = args["chat"];
    message = args['message'];
  }

  void onClick(BuildContext context) {
    ContextMenuController.removeAny();
    goBack();
    /*  Navigator.pop(
       context,
       PageRouteBuilder(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: animation,
             child: child,
           );
         },
         transitionDuration: Duration(milliseconds: 500),
       ),
     );*/
  }

  List<InlineSpan> getTextSpans() {
    return buildSpanList(
      message,
      text,
      isReply: false,
      isEmojiOnly: false,
      launchLink: null,
      textColor: colorTextPrimary,
    );
  }

  InlineSpan buildText(
    String text,
    Color color, {
    bool isMention = false,
    bool isLink = false,
    bool isPhone = false,
    bool isSender = false,
    bool isEmojiOnly = false,
    double? fontSize,
  }) {
    if (isMention) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontSize: MFontSize.size28.value,
          fontWeight: MFontWeight.bold4.value,
          color: color,
          height: 1.29,
        ),
      );
    }

    if (isLink) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontSize: MFontSize.size28.value,
          fontWeight: MFontWeight.bold4.value,
          color: color,
          height: 1.29,
        ),
      );
    }

    if (isPhone) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontSize: MFontSize.size28.value,
          fontWeight: MFontWeight.bold4.value,
          color: color,
          height: 1.29,
        ),
      );
    }
    if (isEmojiOnly && isSender) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontSize: MFontSize.size28.value,
          fontWeight: MFontWeight.bold4.value,
          color: color,
          height: 1.29,
        ),
      );
    }

    if (fontSize != null) {
//有外部传入的字体大小，优先使用外部传入的
    }
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: MFontSize.size28.value,
        fontWeight: MFontWeight.bold4.value,
        color: color,
        height: 1.29,
      ),
    );
  }

  /// 根据纯表情的数量来决定字体大小 注意每个表情占length为2
  double fontSizeWithEmojiLength(String text) {
    final matches = EmojiParser.REGEX_EMOJI.allMatches(text);
    final length = matches.length;
    if (length == 1) {
      return 84.0;
    } else if (length == 2) {
      return 66.0;
    } else if (length == 3) {
      return 48.0;
    } else if (length == 4) {
      return 30.0;
    } else if (length == 5) {
      return 24.0;
    } else if (length == 6) {
      return 24.0;
    }
    return 24.0; // Default value for unspecified lengths
  }

  List<InlineSpan> buildSpanList(
    Message message,
    String text, {
    bool isSender = false,
    bool isEmojiOnly = false,
    Function(String text)? launchLink,
    Function(int uid)? onMentionTap,
    Function(String text)? openLinkPopup,
    Function(String text)? openPhonePopup,
    Color? textColor,
    bool isReply = false, //回覆的訊息
  }) {
    // if (isMarkdown(text)) {
    //   return [
    //     WidgetSpan(
    //         child: MarkdownBody(
    //           data: text,
    //           onTapLink: (String text, String? href, String title) {
    //             if ((href ?? "").isNotEmpty) {
    //               launchLink?.call(href!);
    //             }
    //           },
    //         ))
    //   ];
    // }

    /// 匹配链接
    Iterable<RegExpMatch> matches = Regular.extractLink(text);
    Iterable<RegExpMatch> mentionMatches = Regular.extractSpecialMention(text);
    Iterable<RegExpMatch> phoneMatches = Regular.extractPhoneNumber(text);
    Iterable<RegExpMatch> emojiMatches = Regular.extractEmojis(text);
    if (isEmojiOnly) {
      //emojiMatches 只用来处理表情和其他混合的时候，如果是纯表情 不需要emojiMatches处理
      emojiMatches = [];
    }

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

    if (matches.isNotEmpty ||
        mentionMatches.isNotEmpty ||
        phoneMatches.isNotEmpty ||
        emojiMatches.isNotEmpty) {
      /// 最终文本
      List<RegexTextModel> spanMapsList = [];

      /// 开始和结尾的文本
      List<RegexTextModel> firstLastSpanMapsList = [];

      /// 普通文本
      List<RegexTextModel> textSpanMapsList = [];

      ///--------------------------处理特别文本----------------------------///

      /// 检查@文本
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

      /// 检查链接文本
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

      /// 检查电话号码文本
      if (phoneMatches.isNotEmpty) {
        for (var match in phoneMatches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.number.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 检查表情文本
      if (emojiMatches.isNotEmpty) {
        for (var match in emojiMatches) {
          RegexTextModel spanMap = RegexTextModel(
            type: RegexTextType.emoji.value,
            text: text.substring(match.start, match.end),
            start: match.start,
            end: match.end,
          );
          spanMapsList.add(spanMap);
        }
      }

      /// 排序特别文本（链接，@，电话号码）
      spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

      ///-------------------------- 处理开头和结尾文本----------------------------///
      /// 如果开头字不是特别文本，补上开头的文本
      if (spanMapsList.first.start > 0) {
        RegexTextModel spanMap = RegexTextModel(
          type: RegexTextType.text.value,
          text: text.substring(0, spanMapsList.first.start),
          start: 0,
          end: spanMapsList.first.start,
        );
        firstLastSpanMapsList.add(spanMap);
      }

      /// 如果结尾字不是特别文本，补上结尾的文本
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

      /// 排序开头结尾文本
      spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

      ///-------------------------- 处理最终文本 ----------------------------///
      for (int i = 0; i < spanMapsList.length; i++) {
        try {
          int firstEnd = spanMapsList[i].end;
          if (i + 1 == spanMapsList.length) break;
          int secondStart = spanMapsList[i + 1].start;

          /// 如果中间字不是特别文本，补上中间的文本
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
          //throw e;
          pdebug(e.toString());
        }
      }
      spanMapsList.addAll(textSpanMapsList);

      /// 排序最终文本
      spanMapsList.sort((a, b) => (a.start).compareTo(b.start));

      ///-------------------------- 处理字体样本 ----------------------------///
      List<InlineSpan> spanList = List.empty(growable: true);
      for (int i = 0; i < spanMapsList.length; i++) {
        String subText = spanMapsList[i].text;
        // Check if the text starts with a newline character
        bool startsWithNewline = subText.startsWith('\n');

        if (startsWithNewline) {
          spanList.add(
            buildText(
              '\n',
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
          subText = subText.substring(1);
        }

        if (spanMapsList[i].type == RegexTextType.mention.value) {
          /// @文本
          String uidStr = Regular.extractDigit(subText)?.group(0) ?? '';
          int uid = int.parse(uidStr);

          final MentionModel? model =
              mentionList.firstWhereOrNull((mention) => mention.userId == uid);

          String name = '';

          if (uid == 0 && model != null && model.role == Role.all) {
            name = localized(mentionAll);
          } else {
            name = objectMgr.userMgr
                .getUserTitle(objectMgr.userMgr.getUserById(uid));
          }

          if (name.isEmpty) {
            if (model == null) {
              name = uidStr.toString();
            } else {
              name = model.userName;
            }
          }
          spanList.add(
            buildText(
              '@$name',
              const Color(0xFF1D49A7),
              isMention: true,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.link.value) {
          /// 链接文本

          RegExp regExp = RegExp(r'\u214F\u2983\d+@jx\u2766\u2984');
          subText = subText.replaceAll(regExp, '');

          spanList.add(
            buildText(
              subText,
              const Color(0xFF1D49A7),
              isLink: true,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.number.value) {
          /// 电话号码
          spanList.add(
            buildText(
              subText,
              const Color(0xFF1D49A7),
              isPhone: true,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        } else if (spanMapsList[i].type == RegexTextType.emoji.value) {
          /// 表情文本
          /// make emoji with text bigger on iOS.
          double size = MFontSize.size28.value;
          if (Platform.isIOS) size = MFontSize(31).value;
          spanList.add(
            buildText(
              subText,
              isSender ? bubblePrimary : themeColor,
              isSender: isSender,
              isEmojiOnly: false,
              fontSize: size,
            ),
          );
        } else {
          /// 普通文本
          spanList.add(
            buildText(
              subText,
              textColor ?? colorTextPrimary,
              isSender: isSender,
              isEmojiOnly: isEmojiOnly,
            ),
          );
        }
      }
      return spanList;
    } else {
      /// 普通文本
      return [
        buildText(
          text,
          textColor ?? colorTextPrimary,
          isSender: isSender,
          isEmojiOnly: isEmojiOnly,
          fontSize: isReply ? MFontSize.size28.value : null,
        ),
      ];
    }
  }

  late CustomizeTextSpanEditingController customizeTextSpanEditingController;
  late TextSelection selection;
  bool isOverlayShow = false;
  SelectionChangedCause? currentCause;

  void onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
    CustomizeTextSpanEditingController editingController,
  ) {
    currentCause = cause;
    if (cause == SelectionChangedCause.longPress) {
      this.selection = selection;
      customizeTextSpanEditingController = editingController;
      updateOverlayStatus(true);
    } else if (cause == SelectionChangedCause.drag) {
      this.selection = selection;
      updateOverlayStatus(true);
    } else if (cause == SelectionChangedCause.tap) {
      if (isOverlayShow) {
        updateOverlayStatus(false);
        return;
      }
      updateOverlayStatus(false);
      goBack();
    }
  }

  updateOverlayStatus(bool status) {
    isOverlayShow = status;
  }

  void goBack() {
    if (isOverlayShow) {
      updateOverlayStatus(false);
      return;
    }
    Get.back();
  }

  String? contentTxt;

  Widget textMenuBar(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return CostumeSelectionToolbar(
      anchorAbove: editableTextState.contextMenuAnchors.primaryAnchor,
      anchorBelow: editableTextState.contextMenuAnchors.secondaryAnchor == null
          ? editableTextState.contextMenuAnchors.primaryAnchor
          : editableTextState.contextMenuAnchors.secondaryAnchor!,
      children: [
        GestureDetector(
          onTap: () async {
            try {
              customizeTextSpanEditingController.selection = TextSelection(
                baseOffset: selection.baseOffset,
                extentOffset: selection.extentOffset,
              );
              String str = customizeTextSpanEditingController.text
                  .substring(selection.baseOffset, selection.extentOffset);
              copyToClipboard(
                str,
              );
              editableTextState.copySelection(currentCause!);
              contentTxt = str;
            } catch (e) {
              pdebug(e);
            }
            ContextMenuController.removeAny();
            updateOverlayStatus(false);
          },
          child: _buildItem(
            title: localized(copy),
            url: "assets/svgs/icon_menu_copy.svg",
            radius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
        ),
        const Divider(
          color: colorBorder,
          height: 1,
        ),
        GestureDetector(
          onTap: () async {
            ContextMenuController.removeAny();
            updateOverlayStatus(false);
            contentTxt = customizeTextSpanEditingController.text
                .substring(selection.baseOffset, selection.extentOffset);
            forwardMessageText();
          },
          child: _buildItem(
            title: localized(forward),
            url: "assets/svgs/icon_menu_forward.svg",
          ),
        ),
        const Divider(
          color: colorBorder,
          height: 1,
        ),
        GestureDetector(
          onTap: () async {
            try {
              copyToClipboard(text);
              contentTxt = text;
              editableTextState.selectAll(currentCause!);
            } catch (e) {
              // showWarningToast("${e.toString()}");
              // pdebug("kkkkkkkkk =====> ${e.toString()}");
            }

            ContextMenuController.removeAny();
            updateOverlayStatus(false);
          },
          child: _buildItem(
            title: localized(selectAll),
            url: "assets/svgs/icon_menu_select.svg",
            radius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  OverlayEffect _buildItem({
    required String title,
    required String url,
    BorderRadius? radius,
  }) {
    return OverlayEffect(
      radius: radius,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: jxTextStyle.textStyle17(color: colorTextPrimary),
            ),
            SvgPicture.asset(
              url,
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> copyToClipboard(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    if (await isAndroid13()) {
      return;
    }
    showSuccessToast(localized(toastCopySuccess));
  }

  Future<bool> isAndroid13() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt == 33;
    }
    return false;
  }

  Future<void> forwardMessageText() async {
    CustomInputController controller =
        Get.find<CustomInputController>(tag: chat.id.toString());
    if (controller.chatController.canForward.value &&
        connectivityMgr.connectivityResult != ConnectivityResult.none) {
      RxMap<int, Message> chooseMessage =
          controller.chatController.chooseMessage;
      chooseMessage[message.message_id] = message;
      await controller.onForwardMessage(selectableText: contentTxt);
    }
  }
}

class CostumeSelectionToolbar extends TextSelectionToolbar {
  const CostumeSelectionToolbar({
    super.key,
    required super.anchorAbove,
    required super.anchorBelow,
    required super.children,
  });

  static const double _kToolbarScreenPadding = 8.0;
  static const double _kToolbarHeight = 275.0;

  @override
  Widget build(BuildContext context) {
    final double paddingAbove =
        MediaQuery.of(context).padding.top + _kToolbarScreenPadding;
    final double availableHeight = anchorAbove.dy - paddingAbove;
    final bool fitsAbove = _kToolbarHeight <= availableHeight;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Container(
      // color: Colors.black.withOpacity(0.25),
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: Stack(
        children: <Widget>[
          CustomSingleChildLayout(
            delegate: TextSelectionToolbarLayoutDelegate(
              anchorAbove: anchorAbove - localAdjustment,
              anchorBelow: anchorBelow - localAdjustment,
              fitsAbove: fitsAbove,
            ),
            child: Container(
              width: 195.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
