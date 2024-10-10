import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

class TempGroupSystemItem extends StatefulWidget {
  const TempGroupSystemItem({
    super.key,
    required this.message,
    required this.messageTemp,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });
  final Message message;
  final MessageTempGroupSystem messageTemp;
  final Chat chat;
  final int index;
  final bool isPrevious;

  @override
  State<TempGroupSystemItem> createState() => _TempGroupSystemItemState();
}

class _TempGroupSystemItemState extends State<TempGroupSystemItem>
    with MessageWidgetMixin {
  late ChatContentController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Align(
              alignment: Alignment.center,
              child: Container(
                margin: jxDimension.systemMessageMargin(context),
                padding: jxDimension.systemMessagePadding(),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: colorTextSupporting,
                ),
                child: Text(
                  _getText(),
                  style: jxTextStyle.textStyle12(
                    color: colorWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  String _getText() {
    String expireDateTime = formatToLocalTime(widget.messageTemp.expire_time);
    if (widget.message.typ == messageTypeExpiredSoon) {
      return localized(thisGroupWillBeAutoDisbanded, params: [expireDateTime]);
    } else {
      bool isMe = objectMgr.userMgr.isMe(widget.messageTemp.uid);

      if (isMe) {
        return localized(youHaveChangedTheGroupExpiryDate,
            params: [localized(you), expireDateTime]);
      } else {
        int? groupId;
        if (widget.chat.isGroup) {
          groupId = widget.chat.chat_id;
        }
        String name = objectMgr.userMgr.getUserTitle(
            objectMgr.userMgr.getUserById(widget.messageTemp.uid),
            groupId: groupId);
        return localized(youHaveChangedTheGroupExpiryDate,
            params: [name, expireDateTime]);
      }
    }
  }
}
