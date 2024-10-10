import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';
import 'package:jxim_client/object/chat/message.dart';

class DesktopStickerModal extends StatelessWidget {
  DesktopStickerModal({
    super.key,
    required this.messageImage,
  }) {
    Get.put(StickerController());
  }

  final MessageImage messageImage;

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        ),
      ),
    );
  }
}
