import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker_controller.dart';
import 'package:get/get.dart';

class StickerCollection extends GetView<ManageStickerController> {
  const StickerCollection({Key? key}) : super(key: key);

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
              key: Key('title'),
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
                  child: Container(
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
                              // Padding(
                              //   padding: EdgeInsets.symmetric(horizontal: 5.h),
                              //   child: Container(
                              //     alignment: Alignment.bottomRight,
                              //     child: Text(
                              //       "${stickerCollection.stickerList.length} Stickers\t·\tSize",
                              //       style: TextStyle(
                              //         fontSize: 10.sp,
                              //         color: Colors.grey.shade600,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        // Expanded(
                        //   child: Padding(
                        //     padding: EdgeInsets.symmetric(vertical: 10.h),
                        //     child: Row(
                        //       children: <Widget>[
                        //         Expanded(
                        //           flex: 4,
                        //           child: ListView.builder(
                        //             scrollDirection: Axis.horizontal,
                        //             itemCount: 5,
                        //             itemBuilder:
                        //                 (BuildContext context, int listIndex) {
                        //               final sticker = stickerCollection
                        //                   .stickerList[listIndex];
                        //               return Container(
                        //                 child: Padding(
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 5.h),
                        //                   child: Image.asset(
                        //                     sticker.url,
                        //                     height: 45,
                        //                     width: 45,
                        //                   ),
                        //                 ),
                        //               );
                        //             },
                        //           ),
                        //         ),
                        //         Expanded(
                        //           child: IconButton(
                        //             onPressed: () {
                        //               Toast.showToast(stickerCollection.name);
                        //             },
                        //             icon: Icon(
                        //               Icons.delete,
                        //               color: Colors.red.shade700,
                        //               size: 23.sp,
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                index != controller.stickerCollectionList.length - 1
                    ? Divider(
                  height: 0,
                  color: Colors.grey,
                )
                    : Container()
              ],
            );
          }
        },
      ),
    );
  }
}
