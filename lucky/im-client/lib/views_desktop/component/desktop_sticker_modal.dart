import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';
import '../../object/chat/message.dart';

class DesktopStickerModal extends StatelessWidget {
  DesktopStickerModal({
    Key? key,
    required this.messageImage,
  }) : super(key: key) {
    Get.put(StickerController());
  }

  final MessageImage messageImage;

  @override
  Widget build(BuildContext context) {
    final StickerController controller = Get.find<StickerController>();
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: constraints.maxHeight > 750
                      ? 300
                      : constraints.maxHeight * 0.4,
                  width: 475,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: RemoteImage(
                          src: messageImage.url,
                          width: 150,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   height: constraints.maxHeight * 0.5,
              //   width: 475,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 15),
              //     child: Column(
              //       children: <Widget>[
              //         Expanded(
              //           child: ListView(
              //             shrinkWrap: true,
              //             children: [
              //               Padding(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 20,
              //                   vertical: 15,
              //                 ),
              //                 child: Row(
              //                   mainAxisAlignment:
              //                       MainAxisAlignment.spaceBetween,
              //                   children: <Widget>[
              //                     Text(
              //                       controller
              //                               .selectStickerCollection(
              //                                   messageImage)
              //                               ?.collection
              //                               .name ??
              //                           localized(stickers),
              //                       style: const TextStyle(fontSize: 20),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //               GridView.builder(
              //                 shrinkWrap: true,
              //                 physics: const NeverScrollableScrollPhysics(),
              //                 itemCount: controller
              //                     .selectStickerCollection(messageImage)
              //                     ?.stickerList
              //                     .length,
              //                 gridDelegate:
              //                     const SliverGridDelegateWithFixedCrossAxisCount(
              //                   crossAxisCount: 5,
              //                 ),
              //                 itemBuilder: (BuildContext context, int index) {
              //                   return Padding(
              //                     padding: const EdgeInsets.all(10),
              //                     child: Center(
              //                       child: RemoteImage(
              //                         src: controller
              //                                 .selectStickerCollection(
              //                                     messageImage)
              //                                 ?.stickerList[index]
              //                                 .url ??
              //                             '',
              //                         fit: BoxFit.fill,
              //
              //                       ),
              //                     ),
              //                   );
              //                 },
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
    );
  }
}
