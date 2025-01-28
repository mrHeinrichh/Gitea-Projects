import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../../../views/component/check_tick_item.dart';

class ForwardContentContainer extends StatefulWidget {
  const ForwardContentContainer({
    Key? key,
    required this.chatList,
    required this.clickCallback,
    required this.slideCallback,
  }) : super(key: key);

  final List<Chat> chatList;
  final Function(List<Chat>) clickCallback;
  final Function(bool) slideCallback;

  @override
  State<ForwardContentContainer> createState() =>
      _ForwardContentContainerState();
}

class _ForwardContentContainerState extends State<ForwardContentContainer> {
  RxList<Chat> selectedChats = RxList();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.offset <=
          scrollController.position.minScrollExtent - 100) {
        widget.slideCallback(true);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 15, // Spacing between columns
          mainAxisSpacing: 6.0,
          childAspectRatio: 0.65 // Spacing between rows
          ),
      itemCount: widget.chatList.length, // Number of items in the grid
      itemBuilder: (context, index) {
        return forwardItem(index);
      },
    );
  }

  Widget forwardItem(int index) {
    final chat = widget.chatList[index];
    return GestureDetector(
      onTap: () => selectChat(chat),
      child: Obx(
        () => Column(
          children: [
            Stack(
              children: [
                chat.typ == chatTypeSaved
                    ? ForegroundOverlayEffect(
                        overlayColor:
                            JXColors.primaryTextBlack.withOpacity(0.3),
                        radius: const BorderRadius.vertical(
                          top: Radius.circular(100),
                          bottom: Radius.circular(100),
                        ),
                        child: const SavedMessageIcon(
                          size: 62,
                        ),
                      )
                    : ForegroundOverlayEffect(
                        overlayColor:
                            JXColors.primaryTextBlack.withOpacity(0.3),
                        radius: const BorderRadius.vertical(
                          top: Radius.circular(100),
                          bottom: Radius.circular(100),
                        ),
                        child: CustomAvatar(
                          key:
                              ValueKey(chat.isGroup ? chat.id : chat.friend_id),
                          uid: chat.isGroup ? chat.id : chat.friend_id,
                          isGroup: chat.isGroup,
                          size: 62,
                          headMin: Config().headMin,
                        ),
                      ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: CheckTickItem(
                      isCheck: selectedChats.contains(chat),
                      showUnCheckbox: false,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: chat.typ == chatTypeSaved
                  ? Text(
                      chat.name,
                      style: jxTextStyle.textStyle12(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    )
                  : NicknameText(
                      uid: chat.isGroup ? chat.id : chat.friend_id,
                      isGroup: chat.isGroup,
                      isTappable: false,
                      overflow: TextOverflow.ellipsis,
                      fontSize: MFontSize.size12.value,
                      maxLine: 2,
                      textAlign: TextAlign.center,
                    ),
            )
          ],
        ),
      ),
    );
  }

  void selectChat(Chat chat) {
    if (selectedChats.contains(chat)) {
      selectedChats.remove(chat);
    } else {
      selectedChats.add(chat);
    }
    widget.clickCallback(selectedChats);
  }
}
