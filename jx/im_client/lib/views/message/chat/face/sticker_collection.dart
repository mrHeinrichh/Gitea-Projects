import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker_controller.dart';
import 'package:get/get.dart';

class StickerCollection extends GetView<ManageStickerController> {
  const StickerCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReorderableListView.builder(
        onReorder: (int oldIndex, int newIndex) {
          final index = newIndex > oldIndex ? newIndex - 1 : newIndex;
          final collection =
              controller.stickerCollectionList.removeAt(oldIndex - 1);
          controller.stickerCollectionList.insert(index - 1, collection);
        },
        itemCount: controller.stickerCollectionList.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Container(
              key: const Key('title'),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Text(
                    "Hold and drag the items to re-order the list",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          } else {
            final stickerCollection =
                controller.stickerCollectionList[index - 1];
            return Column(
              key: Key(stickerCollection.collection.name),
              children: [
                Padding(
                  padding: EdgeInsets.all(10.h),
                  child: SizedBox(
                    height: 100.h,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.h),
                                child: Text(
                                  stickerCollection.collection.name
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                index != controller.stickerCollectionList.length - 1
                    ? const Divider(
                        height: 0,
                        color: Colors.grey,
                      )
                    : Container(),
              ],
            );
          }
        },
      ),
    );
  }
}
