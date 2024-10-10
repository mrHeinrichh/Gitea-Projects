import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker_controller.dart';

class StickerCreation extends GetView<ManageStickerController> {
  const StickerCreation({super.key});

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
                      child: SizedBox(
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
                    color: themeColor,
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
