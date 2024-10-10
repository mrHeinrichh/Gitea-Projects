import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/components/emoji_animation.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/managers/object_mgr.dart';
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
  final bool showPinned;

  final double? maxWidth;
  final bool messageEmojiOnly;

  const EmojiListItem({
    super.key,
    required this.emojiModelList,
    required this.message,
    required this.controller,
    this.specialBgColor = false,
    this.isSender = false,
    this.eMargin,
    this.showPinned = false,
    this.maxWidth,
    this.messageEmojiOnly=false,
  });

  @override
  Widget build(BuildContext context) {
    double maxW = getMaxEmojiWidth(maxWidth);
    return emojiModelList.length >= 4
        ? Container(
            constraints: BoxConstraints(
              maxWidth: maxW,
            ),
            margin: EdgeInsets.only(
              top: 6,
              bottom: eMargin == EmojiMargin.me
                  ? getMoreThan4Bottom(emojiModelList.length)
                  : getMoreThan4Bottom(emojiModelList.length),
            ),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: emojiModelList.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: emojiSpaceHorizontalUnitSpace,
                mainAxisSpacing: emojiSpaceVerticalUnitSpace,
                childAspectRatio: 2,
              ),
              itemBuilder: (_, index) {
                final emoji = emojiModelList[index].emoji;
                final count = emojiModelList[index].uidList.length;
                final isReactByMe = emojiModelList[index]
                    .uidList
                    .contains(objectMgr.userMgr.mainUser.uid);
                return Container(
                  // margin: const EdgeInsets.only(right: 4),
                  width: 44.w,
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: getBgColor(isReactByMe, specialBgColor, isSender),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      EmojiAnimation(imagePath: emoji),
                      const SizedBox(width: 2),
                      Text(
                        '$count',
                        style: jxTextStyle.textStyle12(
                          color: getTxtColor(
                            isReactByMe,
                            specialBgColor,
                            isSender,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        : Container(
            constraints: BoxConstraints(
              maxWidth: isSender
                  ? jxDimension.groupTextSenderMaxWidth() - 75.w
                  : jxDimension.groupTextMeMaxWidth(),
            ),
            height: 30,
            margin: EdgeInsets.only(
              top: 3, //figma是4，中文下行高会占用一部分空间
              right: getRight(),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: emojiModelList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                final emoji = emojiModelList[index].emoji;
                final count = emojiModelList[index].uidList.length;
                final isReactByMe = emojiModelList[index]
                    .uidList
                    .contains(objectMgr.userMgr.mainUser.uid);
                return Container(
                  // width: 44.w,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: getBgColor(isReactByMe, specialBgColor, isSender),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      EmojiAnimation(imagePath: emoji),
                      // Image.asset(
                      //   'assets/images/lottie/react_emoji01/$emoji',
                      //   width: 20,
                      //   height: 20,
                      //   alignment: Alignment.center,
                      //   fit: BoxFit.cover,
                      // ),
                      const SizedBox(width: 2),
                      Text(
                        '$count',
                        style: jxTextStyle.textStyle12(
                          color: getTxtColor(
                            isReactByMe,
                            specialBgColor,
                            isSender,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  double getRight() {
    /// 如果点赞在外面
    switch (message.typ) {
      case messageTypeVideo:
      case messageTypeReel:
      case messageTypeNewAlbum:
      case messageTypeGif:
      case messageTypeLocation:
      case messageTypeImage:
        return 0;
    }
    if(messageEmojiOnly){
      return 0;
    }

    /// 点赞在气泡里面
    if (eMargin == EmojiMargin.me) {
      if (objectMgr.loginMgr.isDesktop) {
        return 70;
      } else {
        if (showPinned && isEditMessage(message)) {
          return GroupTextPlaceHolderType.isMeEditAndPin.multilingualWidth;
        } else if (isEditMessage(message)) {
          return GroupTextPlaceHolderType.isMeOnlyEdit.multilingualWidth;
        } else if (showPinned) {
          return GroupTextPlaceHolderType.isMeOnlyPin.multilingualWidth;
        }
        return GroupTextPlaceHolderType.isMeNone.multilingualWidth;
      }
    } else {
      if (objectMgr.loginMgr.isDesktop) {
        return 40;
      } else {
        if (showPinned && isEditMessage(message)) {
          return GroupTextPlaceHolderType.isSendEditAndPin.multilingualWidth;
        } else if (isEditMessage(message)) {
          return GroupTextPlaceHolderType.isSendOnlyEdit.multilingualWidth;
        } else if (showPinned) {
          return GroupTextPlaceHolderType.isSendOnlyPin.multilingualWidth;
        }
        return GroupTextPlaceHolderType.isSendNone.multilingualWidth;
      }
    }
  }

  Color getBgColor(bool? isReactByMe, bool? specialBgColor, bool isSender) {
    if (specialBgColor == true) {
      /// image,video
      if (isReactByMe == true) {
        return colorWhite;
      } else {
        return colorWhite.withOpacity(0.32);
      }
    } else {
      if (isSender) {
        return bubblePrimary.withOpacity(isReactByMe == true ? 1 : 0.08);
      } else {
        return themeColor.withOpacity(isReactByMe == true ? 1 : 0.08);
      }
    }
  }

  Color getTxtColor(bool? isReactByMe, bool? specialBgColor, bool isSender) {
    if (specialBgColor == true) {
      /// image,video
      return colorTextSecondary;
    } else {
      if (isReactByMe == true) {
        return colorWhite;
      } else {
        return colorTextSecondary;
      }
    }
  }

  ///两种情况
  ///1.如果是4的倍数，则需要bottom 15，为了不遮挡时间戳
  ///2.如果不是 则返回0，为了避免不必要的换行逻辑
  getMoreThan4Bottom(int length) {
    if (length % 4 == 0) {
      return 15.0.w;
    }
    return 0.0.w;
  }

  double getMaxEmojiWidth(double? maxWidth) {
    if (maxWidth != null) {
      return maxWidth;
    }
    return isSender
        ? jxDimension.groupTextSenderMaxWidth() - 75.w
        : jxDimension.groupTextMeMaxWidth();
  }
}
