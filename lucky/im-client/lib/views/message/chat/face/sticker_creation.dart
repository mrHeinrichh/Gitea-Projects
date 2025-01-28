import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../routes.dart';
import '../../../../utils/color.dart';
import 'manage_sticker_controller.dart';

class StickerCreation extends GetView<ManageStickerController> {
  const StickerCreation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: controller.stickerCollectionList.length,
              itemBuilder: (BuildContext context, int index) {
                final stickerCollection =
                    controller.stickerCollectionList[index];
                return Column(
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5.h),
                                    child: Text(
                                      stickerCollection.collection.name
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5.h),
                                    child: Container(
                                      alignment: Alignment.bottomRight,
                                      // child: Text(
                                      //   "${stickerCollection.stickerList.length} Stickers\t·\tSize",
                                      //   style: TextStyle(
                                      //     fontSize: 10.sp,
                                      //     color: Colors.grey.shade600,
                                      //   ),
                                      // ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Expanded(
                            //   child: Padding(
                            //     padding: EdgeInsets.symmetric(vertical: 10.h),
                            //     child: Row(
                            //       children: <Widget>[
                            //         Expanded(
                            //           flex: 6,
                            //           child: ListView.builder(
                            //             scrollDirection: Axis.horizontal,
                            //             itemCount: 5,
                            //             itemBuilder: (BuildContext context,
                            //                 int listIndex) {
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
                            //           flex: 2,
                            //           child: Row(
                            //             children: [
                            //               Expanded(
                            //                 child: IconButton(
                            //                   onPressed: () {
                            //                     Toast.showToast(
                            //                         stickerCollection.name);
                            //                   },
                            //                   icon: Icon(
                            //                     Icons.delete,
                            //                     color: Colors.red.shade700,
                            //                     size: 25.sp,
                            //                   ),
                            //                 ),
                            //               ),
                            //               Expanded(
                            //                 child: IconButton(
                            //                   onPressed: () {
                            //                     Get.toNamed(
                            //                         RouteName.editSticker);
                            //                   },
                            //                   icon: Icon(
                            //                     Icons.edit,
                            //                     color: Colors.orange.shade600,
                            //                     size: 25.sp,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ],
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
                        ? const Divider(
                            height: 0,
                            color: Colors.grey,
                          )
                        : Container()
                  ],
                );
              },
            ),
          ),
          Container(
            color: Colors.grey.shade50,
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.h, 10.h, 15.h, 15.h),
              child: GestureDetector(
                onTap: () {
                  Get.toNamed(RouteName.editSticker);
                },
                child: Container(
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.h),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Create you own stickers",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
