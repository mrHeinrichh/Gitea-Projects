import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/components/emoji_panel_collection.dart';
import 'package:jxim_client/im/custom_content/components/emoji_panel_recent.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

double emojiRecentHeight = 42;
double emojiLineHeight = 1;
double emojiCollectionHeight = 258;

double emojiCollectionOriginHeight = 48.0;

double getEmojiPanelHeight() {
  double height = 0.0;

  if (!objectMgr.stickerMgr.isShowEmojiPanel.value) {
    return emojiCollectionOriginHeight;
  }

  if (objectMgr.stickerMgr.recentEmojiList.isNotEmpty) {
    height = emojiRecentHeight + emojiLineHeight + emojiCollectionHeight;
  } else {
    height = emojiCollectionHeight;
  }
  return height;
}

bool isEmojiRecentEmpty() {
  if (objectMgr.stickerMgr.recentEmojiList.isEmpty) {
    return false;
  }
  return true;
}

class EmojiPanelContainer extends StatefulWidget {
  const EmojiPanelContainer({
    super.key,
    this.onEmojiClick,
  });

  final ValueChanged<String>? onEmojiClick;

  @override
  State<EmojiPanelContainer> createState() => _EmojiPanelContainerState();
}

class _EmojiPanelContainerState extends State<EmojiPanelContainer> {
  final List<String> recentEmojiList = [];

  @override
  void initState() {
    recentEmojiList.addAll(objectMgr.stickerMgr.recentEmojiList);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final emojiContent = Column(
      children: [
        if (isEmojiRecentEmpty())
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
                height: emojiRecentHeight,
                decoration: const BoxDecoration(),
                child: EmojiPanelRecent(
                  recentEmojiList: recentEmojiList,
                  onEmojiClick: widget.onEmojiClick,
                ),
              ),
              Divider(
                height: 0.33,
                color: colorTextPrimary.withOpacity(0.2),
              ),
            ],
          ),
        Expanded(
          child: EmojiPanelCollection(
            onEmojiClick: widget.onEmojiClick,
          ),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: GestureDetector(
        onTap: () {},
        child: objectMgr.loginMgr.isDesktop ? Container(
          clipBehavior: Clip.hardEdge,
          width: 320,
          height: getEmojiPanelHeight(),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F9).withOpacity(0.75),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: colorTextPrimary.withOpacity(0.15),
              )
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: emojiContent,
          ),
        ) : Container(
          color: Colors.white,
          width: 320,
          height: getEmojiPanelHeight(),
          child: emojiContent,
        ),
      ),
    );
  }
}
