import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

enum EmojiMargin {
  ///to avoid hitting the time.
  sender,
  me,
}

class EmojiListItem extends StatelessWidget {
  final List<EmojiModel> emojiModelList;
  final Message message;
  final ChatContentController controller;
  final bool? specialBgColor;
  final bool isSender;
  final EmojiMargin? eMargin;

  const EmojiListItem({
    Key? key,
    required this.emojiModelList,
    required this.message,
    required this.controller,
    this.specialBgColor = false,
    this.isSender = false,
    this.eMargin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 26,
      constraints: BoxConstraints(
        maxWidth: isSender ? jxDimension.groupTextSenderMaxWidth() - 75
            : jxDimension.groupTextMeMaxWidth()
      ),
      margin: EdgeInsets.only(
        top: 6,
        right: eMargin == EmojiMargin.me
            ? objectMgr.loginMgr.isDesktop
                ? 70
                : 60
            : eMargin == EmojiMargin.sender
                ? objectMgr.loginMgr.isDesktop
                    ? 40
                    : 30
                : 0.0,
        bottom: 4
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(emojiModelList.length ?? 0, (index){
          final emoji =
              MessageReactEmoji.emojiNameOldToNew(emojiModelList[index].emoji);
          final count = emojiModelList[index].uidList.length;
          final isReactByMe = emojiModelList[index]
              .uidList
              .contains(objectMgr.userMgr.mainUser.uid);
          return Container(
            // margin: const EdgeInsets.only(right: 4),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: getBgColor(isReactByMe, specialBgColor, isSender),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/lottie/react_emoji01/$emoji',
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 2),
                Text(
                  '$count',
                  style: jxTextStyle.textStyle12(
                      color: getTxtColor(isReactByMe, specialBgColor, isSender),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      // child: ListView.builder(
      //   scrollDirection: Axis.horizontal,
      //   itemCount: emojiModelList.length ?? 0,
      //   physics: const NeverScrollableScrollPhysics(),
      //   shrinkWrap: true,
      //   itemBuilder: (BuildContext context, int index) {
      //     final emoji =
      //         MessageReactEmoji.emojiNameOldToNew(emojiModelList![index].emoji);
      //     final count = emojiModelList[index].uidList.length;
      //     final isReactByMe = emojiModelList[index]
      //         .uidList
      //         .contains(objectMgr.userMgr.mainUser.uid);
      //     return Container(
      //       // margin: const EdgeInsets.only(right: 4),
      //       decoration: ShapeDecoration(
      //         shape: const StadiumBorder(),
      //         color: getBgColor(isReactByMe, specialBgColor, isSender),
      //       ),
      //       padding: const EdgeInsets.symmetric(horizontal: 8),
      //       child: Row(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Image.asset(
      //             'assets/images/lottie/react_emoji01/$emoji',
      //             width: 20,
      //             height: 20,
      //             alignment: Alignment.center,
      //             fit: BoxFit.cover,
      //           ),
      //           const SizedBox(width: 2),
      //           Text(
      //             '$count',
      //             style: jxTextStyle.textStyle12(
      //                 color: getTxtColor(isReactByMe, specialBgColor, isSender),
      //               // color: isReactByMe == true
      //               //     ? isSender
      //               //         ? JXColors.secondaryTextBlack
      //               //         : JXColors.secondaryTextWhite
      //               //     : JXColors.secondaryTextBlack,
      //             ),
      //           ),
      //         ],
      //       ),
      //     );
      //   },
      // ),
    );
  }

  Color getBgColor(bool? isReactByMe, bool? specialBgColor, bool isSender) {
    if (specialBgColor == true) {
      /// image,video
      if (isReactByMe == true) {
        return Colors.white.withOpacity(0.6);
      } else {
        return JXColors.primaryTextBlack.withOpacity(0.32);
      }
    } else {
      if (isSender) {
        return JXColors.chatBubbleMeReactBg
            .withOpacity(isReactByMe == true ? 1 : 0.12);
      } else {
        return JXColors.chatBubbleSenderReactBg
            .withOpacity(isReactByMe == true ? 1 : 0.12);
      }
    }
  }

  Color getTxtColor(bool? isReactByMe, bool? specialBgColor, bool isSender) {
    if (specialBgColor == true) {
      /// image,video
      if (isReactByMe == true) {
        return JXColors.secondaryTextBlack;
      } else {
        return JXColors.secondaryTextWhite;
      }
    } else {
      if (isSender){
        if (isReactByMe == true) {
          return JXColors.bubbleMeReactText;
        } else {
          return JXColors.bubbleMeNoReactText;
        }
      } else {
        if (isReactByMe == true) {
          return JXColors.bubbleSenderReactText;
        } else {
          return JXColors.bubbleSenderNoReactText;
        }
      }
    }
  }
}
