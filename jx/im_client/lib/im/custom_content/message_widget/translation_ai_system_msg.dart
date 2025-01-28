import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TranslationAISystemMsg extends StatefulWidget {
  const TranslationAISystemMsg({
    super.key,
    required this.chat,
    required this.message,
  });

  final Message message;
  final Chat chat;

  @override
  State<TranslationAISystemMsg> createState() => _TranslationAISystemMsgState();
}

class _TranslationAISystemMsgState extends State<TranslationAISystemMsg> {
  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    super.dispose();
  }

  void _onChatReplace(Object sender, Object type, Object? data) {
    if (data is Chat && widget.chat.chat_id == data.chat_id) {
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.isSendOk) return const SizedBox();
    return Visibility(
      visible: widget.chat.outgoing_idx == widget.message.chat_idx ||
          widget.chat.incoming_idx == widget.message.chat_idx,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          margin: jxDimension.systemMessageMargin(context),
          padding: jxDimension.systemMessagePadding(),
          decoration: const ShapeDecoration(
            shape: StadiumBorder(),
            color: colorTextSupporting,
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: localized(enableRealTimeTranslation),
              style: jxTextStyle.textStyle12(
                color: colorWhite,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: " ${localized(enableText)}",
                  style: jxTextStyle.textStyle12(
                    color: themeSecondaryColor,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      int indicator = 1; // for incoming
                      if (widget.chat.outgoing_idx == widget.message.chat_idx) {
                        indicator = 2; // for outgoing
                      }

                      Get.toNamed(
                        RouteName.translateSettingView,
                        arguments: [widget.chat, indicator],
                        id: objectMgr.loginMgr.isDesktop ? 1 : null,
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
