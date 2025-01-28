import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/services/reel_video.dart';

import '../object/reel.dart';

class ReelGroupVipDemoVideoPage extends StatelessWidget {
  const ReelGroupVipDemoVideoPage({super.key, required this.videoPath});

  final String videoPath;

  @override
  Widget build(BuildContext context) {
    ReelController controller = Get.find<ReelController>();
    return Stack(
      children: [
        ReelVideo.file(
          source: videoPath,
          thumbnail: '',
          index: 0,
          isLoop: true,
        ),
        Positioned(
            left: 30,
            top: 50,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ))
      ],
    );
  }
}

extension vipGroup on ReelController {
  void precacheVideo(String videoPath) {
    if (videoPath.isNotEmpty) {
      final String source = videoPath;
      initPlayer(source);
    }
  }
}
