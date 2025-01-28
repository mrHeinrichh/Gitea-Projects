import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';

class ShortTalkComponent extends StatefulWidget {
  final Chat chat;
  final bool isFocus;
  final bool isShowShortTalk;   //是否是顯示快捷短語

  const ShortTalkComponent({
    super.key,
    required this.chat,
    required this.isFocus,
    this.isShowShortTalk = false,
  });

  @override
  State<ShortTalkComponent> createState() => _ShortTalkComponentState();
}

class _ShortTalkComponentState extends State<ShortTalkComponent>
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
  void didUpdateWidget(ShortTalkComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShowShortTalk != oldWidget.isShowShortTalk ||
        widget.isFocus != oldWidget.isFocus) {
      if (widget.isFocus &&
          !oldWidget.isFocus &&
          oldWidget.isShowShortTalk &&
          !widget.isShowShortTalk) {
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
    final bottomInsetHeight = MediaQuery.of(context).viewInsets.bottom;

    double bottomHeight = 310.0.h;
    if (widget.isFocus && bottomInsetHeight < keyboardHeight.value) {
      if (isSwitchingBetweenStickerAndKeyboard) {
        bottomHeight = keyboardHeight.value;
      } else {
        bottomHeight = bottomInsetHeight;
      }
    } else if (bottomInsetHeight > keyboardHeight.value) {
      bottomHeight = bottomInsetHeight;
    } else {
      bottomHeight = keyboardHeight.value;
    }
    if(objectMgr.loginMgr.isDesktop)return const SizedBox();

    return GetBuilder<CustomInputController>(
        id: 'short_talk_tab',
        init: controller,
        builder: (_) {
          return ClipRRect(
            child: AnimatedAlign(
              alignment: Alignment.bottomCenter,
              duration: Duration(
                milliseconds:
                widget.isShowShortTalk || widget.isFocus ? 0 : 180,
              ),
              curve: Curves.easeOut,
              heightFactor: widget.isShowShortTalk || widget.isFocus ? 1.0 : 0.0,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(
                      milliseconds: widget.isShowShortTalk
                          ? 0
                          : widget.isFocus
                          ? 30
                          : 10,
                    ),
                    curve: Curves.easeOut,
                    height: widget.isShowShortTalk && bottomHeight < 200
                        ? 280
                        : bottomHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(243, 243, 243, 1),
                    ),
                    child: !widget.isShowShortTalk
                        ? null
                        : SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          const Divider(
                            height: 0.33,
                            thickness: 0.33,
                            color: JXColors.borderPrimaryColor,
                          ),
                          Expanded(
                            child: getShortTalkWidget(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}