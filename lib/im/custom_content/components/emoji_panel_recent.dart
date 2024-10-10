import 'dart:io';

import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';

class EmojiPanelRecent extends StatefulWidget {
  const EmojiPanelRecent({
    super.key,
    required this.recentEmojiList,
    this.onEmojiClick,
  });

  final ValueChanged<String>? onEmojiClick;
  final List<String> recentEmojiList;

  @override
  State<EmojiPanelRecent> createState() => _EmojiPanelRecentState();
}

class _EmojiPanelRecentState extends State<EmojiPanelRecent> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 0,
          childAspectRatio: 1.0,
        ),
        itemCount: widget.recentEmojiList.length + 1,
        itemBuilder: (BuildContext ctx, index) {
          if (index == 0) {
            return Image.asset(
              'assets/images/emoji_menu_recent.png',
            );
          }
          return GestureDetector(
            onTap: () {
              widget.onEmojiClick?.call(widget.recentEmojiList[index - 1]);
            },
            child: FittedBox(
              child: Padding(
                padding: EdgeInsets.all(Platform.isAndroid ? 3 : 0),
                child: Text(
                  textAlign: TextAlign.center,
                  widget.recentEmojiList[index - 1],
                  style: TextStyle(
                    fontSize: 23,
                    // fontFamily: 'emoji',
                    height: ImLineHeight.getLineHeight(
                        fontSize: 23, lineHeight: 29),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
