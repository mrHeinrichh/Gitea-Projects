import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';

import 'package:jxim_client/object/chat/message.dart';

class StickerModalSheet extends StatelessWidget {
  final MessageImage messageImage;

  const StickerModalSheet({Key? key, required this.messageImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification overscroll) {
        overscroll.disallowIndicator();
        return true;
      },
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          color: Colors.grey.withOpacity(0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.h)),
                    color: Colors.white,
                  ),
                  width: double.maxFinite,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: RemoteImage(
                          src: messageImage.url,
                          width: 200,
                          height: 200,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.h),
                      topRight: Radius.circular(15.h),
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Container(
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(
                      //         vertical: 15.h, horizontal: 25.h),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Text(
                      //           controller
                      //                   .selectStickerCollection(messageImage)
                      //                   ?.collection
                      //                   .name ??
                      //               localized(stickers),
                      //           style: TextStyle(fontSize: 20.sp),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      // Expanded(
                      //   child: GridView.builder(
                      //     itemCount: controller
                      //         .selectStickerCollection(messageImage)
                      //         ?.stickerList
                      //         .length,
                      //     gridDelegate:
                      //         const SliverGridDelegateWithFixedCrossAxisCount(
                      //       crossAxisCount: 4,
                      //     ),
                      //     itemBuilder: (BuildContext context, int index) {
                      //       return Padding(
                      //         padding: EdgeInsets.all(10.h),
                      //         child: Center(
                      //           child: RemoteImage(
                      //             src: controller
                      //                     .selectStickerCollection(messageImage)
                      //                     ?.stickerList[index]
                      //                     .url ??
                      //                 '',
                      //             fit: BoxFit.fill,
                      //
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
