import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';

import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/im/custom_input/component/chat_attachment_view.dart';

class AttachmentKeyboardComponent extends StatefulWidget {
  final Chat chat;
  final bool isFocus;
  final bool isShowSticker; //是否是顯示貼圖
  final bool isShowGameKeyboard;   //是否是顯示遊戲鍵盤
  final bool isShowShortTalk;   //是否是顯示快捷短語
  final dynamic tag;
  final List<ChatAttachmentOption> options;
  final Function()? onHideAttachmentView;
  final bool isShowAttachment;

  const AttachmentKeyboardComponent({
    super.key,
    required this.chat,
    required this.isFocus,
    required this.tag,
    required this.onHideAttachmentView,
    required this.isShowAttachment,
    this.isShowGameKeyboard = false,
    this.isShowShortTalk = false,
    this.isShowSticker = false,
    required this.options,
  });

  @override
  State<AttachmentKeyboardComponent> createState() =>
      _AttachmentKeyboardComponentState();
}

class _AttachmentKeyboardComponentState
    extends State<AttachmentKeyboardComponent>
    with SingleTickerProviderStateMixin {
  CustomInputController? controller;

  bool isSwitchingBetweenStickerAndKeyboard = false;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());
  }

  @override
  void didUpdateWidget(AttachmentKeyboardComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShowAttachment != oldWidget.isShowAttachment ||
        widget.isFocus != oldWidget.isFocus) {
      if (widget.isFocus &&
          !oldWidget.isFocus &&
          oldWidget.isShowAttachment &&
          !widget.isShowAttachment) {
        isSwitchingBetweenStickerAndKeyboard = true;
        controller?.stickerDebounce.call(() {
          isSwitchingBetweenStickerAndKeyboard = false;
        });
      } else {
        isSwitchingBetweenStickerAndKeyboard = false;
      }

      if (mounted) setState(() {});
    }

    ever(keyboardHeight, (callback) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsetHeight = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

    double bottomHeight = getPanelFixHeight;
    if (widget.isFocus && bottomInsetHeight < keyboardHeight.value) {
      if (isSwitchingBetweenStickerAndKeyboard) {
        bottomHeight = getPanelFixHeight;
      } else {
        bottomHeight = bottomInsetHeight;
      }
    } else if (bottomInsetHeight > keyboardHeight.value) {
      bottomHeight = bottomInsetHeight;
    } else {
      bottomHeight = getPanelFixHeight;
    }
    if (objectMgr.loginMgr.isDesktop) return const SizedBox();
    return Container(
      color: JXColors.bgPrimaryColor,
      height: widget.isShowAttachment
          ? bottomHeight
          : widget.isFocus
          ? getPanelFixHeight
          : 0,
      alignment: Alignment.topCenter,
      child: GetBuilder<CustomInputController>(
          id: 'attachment_keyboard_tab',
          init: controller,
          builder: (_) {
            return getBody();
          }),
    );
  }

  Widget getBody() {
    if (!widget.isShowAttachment && widget.isFocus) {
      return const SizedBox();
    }
    return Container(
      key: ValueKey("attachment_keyboard_tab${widget.tag}"),
      clipBehavior: Clip.antiAlias,
      decoration:  BoxDecoration(
        color: JXColors.bgPrimaryColor,
      ),
      child: ChatAttachmentView(
        options: widget.options,
        onHideAttachmentView: widget.onHideAttachmentView,
      ),
    );
  }
}
