import 'dart:io';

import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/emoji/emoji_utils.dart';

class EmojiPanelCollection extends StatefulWidget {
  const EmojiPanelCollection({
    super.key,
    this.onEmojiClick,
  });

  final ValueChanged<String>? onEmojiClick;

  @override
  State<EmojiPanelCollection> createState() => _EmojiPanelCollectionState();
}

class _EmojiPanelCollectionState extends State<EmojiPanelCollection> {
  final List<String> collectionEmojiList = EmojiUtils.getEmojiList();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: collectionEmojiList.length,
      itemBuilder: (BuildContext ctx, index) {
        return GestureDetector(
          onTap: () {
            widget.onEmojiClick?.call(collectionEmojiList[index]);
          },
          child: Container(
            alignment: Alignment.center,
            // color: Colors.red,
            // height: 32,
            // width: 32,
            child: _getEmojiText(index),
          ),
        );
      },
    );
  }

  Widget _getEmojiText(int index) {
    final Widget emojiText;
    if (Platform.isIOS) {
      emojiText = Text(
        // textAlign: TextAlign.center,
        collectionEmojiList[index],
        style: TextStyle(
          fontSize: 30,
          // fontFamily: 'emoji',
          height: ImLineHeight.getLineHeight(fontSize: 30, lineHeight: 34),
        ),
      );
    } else {
      emojiText = Padding(
        padding: const EdgeInsets.all(3),
        child: Text(
          // textAlign: TextAlign.center,
          collectionEmojiList[index],
          style: TextStyle(
            fontSize: 26,
            // fontFamily: 'emoji',
            height: ImLineHeight.getLineHeight(fontSize: 26, lineHeight: 30),
          ),
        ),
      );
    }
    return FittedBox(
      child: emojiText,
    ) ;
  }
}
