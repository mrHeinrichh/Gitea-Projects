import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';

class EmojiView extends GetView<StickerController> {
  const EmojiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: const Center(
                child: Text(
                  "RECENTLY USED",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          } else if (index == 1) {
            return controller.recentEmojiList.isNotEmpty
                ? getGridView(controller.recentEmojiList)
                : Container();
          } else if (index == 2) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: const Center(
                child: Text(
                  "ALL EMOJI",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          } else {
            return getGridView(controller.allEmojiList);
          }
        },
      ),
    );
  }

  Widget getGridView(List<Emoji> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
      ),
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            controller.selectEmoji(index);
          },
          child: Padding(
            padding: EdgeInsets.all(5.h),
            child: Center(
              child: Text(
                '${list[index]}',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ),
        );
      },
    );
  }
}
