import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/object/chat/message.dart';

import '../../main.dart';

class ChatScrollToBottom extends StatelessWidget {
  final dynamic controller;
  final Widget? gameIcon;

  const ChatScrollToBottom({
    Key? key,
    required this.controller,
    this.gameIcon,
  }) : super(key: key);

  onJump() async {
    if (Get.isRegistered<ChatContentController>(
        tag: controller.chat.id.toString())) {
      final chatController =
          Get.find<ChatContentController>(tag: controller.chat.id.toString());
      chatController.scrollToBottomMessage();
    }
  }

  onJumpMention() async{
    Message msg = controller.mentionChatIdxList.first;
    controller.showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
    controller.mentionChatIdxList.remove(msg);
    if(objectMgr.chatMgr.mentionMessageMap[msg.chat_id] != null){
      objectMgr.chatMgr.mentionMessageMap[msg.chat_id]!.remove(msg.chat_idx);
    }
  }
      

  Widget _btnContainer({required int value, required Widget child}) {
    return Container(
      height: 38,
      width: 38,
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: value > 0 ? 13 : 5),
      decoration: BoxDecoration(
        color: JXColors.bgPrimaryColor, // <-- Button color
        shape: BoxShape.circle,
        border: Border.all(color: JXColors.black.withOpacity(0.04)),
      ),
      child: child,
    );
  }

  Widget _btnCount({required int value, required Widget child}) {
    return Positioned(
      top: objectMgr.loginMgr.isDesktop ? 0 : 3,
      child: Container(
        padding: objectMgr.loginMgr.isDesktop
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: ShapeDecoration(
          color: accentColor,
          shape: value > 99 ? const StadiumBorder() : const CircleBorder(),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Obx(
        () {
          final shouldShowMention = controller.mentionChatIdxList.length > 0;
          final shouldScrollBottom = controller.showScrollBottomBtn.value;

          return AnimatedSize(
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                if (gameIcon != null) ...[
                  gameIcon!,
                  if (shouldShowMention || shouldScrollBottom)
                    const SizedBox(height: 10),
                ],
                if (controller.mentionChatIdxList.length > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onJumpMention,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _btnContainer(
                          value: controller.mentionChatIdxList.length,
                          child: SvgPicture.asset(
                            'assets/svgs/at.svg',
                            width: 17,
                            height: 17,
                            color: JXColors.black,
                          ),
                        ),
                        _btnCount(
                          value: controller.mentionChatIdxList.length,
                          child: AnimatedFlipCounter(
                              value: controller.mentionChatIdxList.length,
                              textStyle:jxTextStyle.textStyle13(color: Colors.white)
                          ),
                        ),
                      ],
                    ),
                  ),
                if(objectMgr.loginMgr.isDesktop )const SizedBox(height: 10),
                if(controller.showScrollBottomBtn.value)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onJump,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _btnContainer(
                          value: controller.unreadCount.value,
                          child: SvgPicture.asset(
                            'assets/svgs/arrow_down_icon.svg',
                            color: JXColors.iconPrimaryColor,
                            width:  30,
                            height:  30,
                          ),
                        ),
                        if (controller.unreadCount.value > 0)
                          _btnCount(
                            value: controller.unreadCount.value,
                            child: controller.unreadCount.value > 999
                                ? const Text(
                              '999+',
                              style: TextStyle(
                                color: JXColors.white,
                                fontSize: 13,
                              ),
                            )
                                : AnimatedFlipCounter(
                              value: controller.unreadCount.value,
                              textStyle: const TextStyle(
                                color: JXColors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
