import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupAutoDeleteInterval extends StatefulWidget {
  const GroupAutoDeleteInterval({
    super.key,
    required this.message,
    required this.messageInterval,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  final Message message;
  final MessageInterval messageInterval;
  final Chat chat;
  final int index;
  final bool isPrevious;

  @override
  State<GroupAutoDeleteInterval> createState() =>
      _GroupAutoDeleteIntervalState();
}

class _GroupAutoDeleteIntervalState extends State<GroupAutoDeleteInterval>
    with MessageWidgetMixin {
  late ChatContentController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
  }

  @override
  Widget build(BuildContext context) {
    String intervalContent = getIntervalContent();
    int? groupId;
    if (widget.chat.isGroup) {
      groupId = widget.chat.chat_id;
    }
    return Align(
      alignment: Alignment.center,
      child: Container(
          margin: jxDimension.systemMessageMargin(context),
          padding: jxDimension.systemMessagePadding(),
          decoration: const ShapeDecoration(
            color: colorTextSupporting,
            shape: StadiumBorder(),
          ),
          child: Text(
            "${objectMgr.userMgr.isMe(widget.messageInterval.owner) ? localized(you) : objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(widget.messageInterval.owner), groupId: groupId)}$intervalContent",
            style: jxTextStyle.textStyle12(color: colorWhite),
            textAlign: TextAlign.center,
          )),
    );
  }

  String getIntervalContent() {
    if (widget.messageInterval.interval == 0) {
      return ' ${localized(turnOffAutoDeleteMessage)}';
    } else if (widget.messageInterval.interval < 60) {
      bool isSingular = widget.messageInterval.interval == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? secondParam : secondsParam,
                params: ["${widget.messageInterval.interval}"]))
          ])}';
    } else if (widget.messageInterval.interval < 3600) {
      bool isSingular = widget.messageInterval.interval ~/ 60 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? minuteParam : minutesParam,
                params: ["${widget.messageInterval.interval ~/ 60}"]))
          ])}';
    } else if (widget.messageInterval.interval < 86400) {
      bool isSingular = widget.messageInterval.interval ~/ 3600 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? hourParam : hoursParam,
                params: ["${widget.messageInterval.interval ~/ 3600}"]))
          ])}';
    } else if (widget.messageInterval.interval < 2592000) {
      bool isSingular = widget.messageInterval.interval ~/ 86400 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? dayParam : daysParam,
                params: ["${widget.messageInterval.interval ~/ 86400}"]))
          ])}';
    } else {
      bool isSingular = widget.messageInterval.interval ~/ 2592000 == 1;
      return ' ${localized(turnOnAutoDeleteMessage, params: [
            (localized(isSingular ? monthParam : monthsParam,
                params: ["${widget.messageInterval.interval ~/ 2592000}"]))
          ])}';
    }
  }
}
