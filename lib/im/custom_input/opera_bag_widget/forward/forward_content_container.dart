import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

import 'package:jxim_client/views/component/check_tick_item.dart';

class ForwardContentContainer extends StatefulWidget {
  const ForwardContentContainer({
    super.key,
    required this.chatList,
    required this.clickCallback,
    required this.scrollController,
  });

  final List<Chat> chatList;
  final Function(List<Chat>) clickCallback;
  final ScrollController scrollController;

  @override
  State<ForwardContentContainer> createState() =>
      _ForwardContentContainerState();
}

class _ForwardContentContainerState extends State<ForwardContentContainer> {
  RxList<Chat> selectedChats = RxList();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      controller: widget.scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15, // Spacing between columns
        mainAxisSpacing: 0.0,
        // childAspectRatio: 0.65, // Spacing between rows
        mainAxisExtent: Platform.isAndroid ? 100 : 105,
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
                        overlayColor: colorTextPrimary.withOpacity(0.3),
                        radius: const BorderRadius.vertical(
                          top: Radius.circular(100),
                          bottom: Radius.circular(100),
                        ),
                        child: const SavedMessageIcon(
                          size: 60,
                        ),
                      )
                    : ForegroundOverlayEffect(
                        overlayColor: colorTextPrimary.withOpacity(0.3),
                        radius: const BorderRadius.vertical(
                          top: Radius.circular(100),
                          bottom: Radius.circular(100),
                        ),
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selectedChats.contains(chat)
                                ? Border.all(
                                    width: 2,
                                    color: themeColor,
                                  )
                                : null,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            child: CustomAvatar.chat(
                              key: ValueKey(
                                chat.isGroup ? chat.id : chat.friend_id,
                              ),
                              chat,
                              size: 60,
                              headMin: Config().headMin,
                            ),
                          ),
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
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: chat.typ == chatTypeSaved
                  ? Text(
                      localized(homeSavedMessage),
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
            ),
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
