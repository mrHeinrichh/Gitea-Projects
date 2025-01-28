import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/services/reel_video.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReelPreview extends StatefulWidget {
  final String source;
  final String thumbnail;
  final int? currentSecond;

  const ReelPreview({
    super.key,
    required this.source,
    required this.thumbnail,
    this.currentSecond,
  });

  @override
  State<ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<ReelPreview> {
  RxInt currentSecond = 0.obs;
  RxBool isDisposing = false.obs;

  @override
  void dispose() {
    isDisposing.value = true;
    WakelockPlus.disable();
    super.dispose();
  }

  void onPlaybackCallback(int second) => currentSecond.value = second;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ReelVideo.preview(
              source: widget.source,
              thumbnail: widget.thumbnail,
              index: 0,
              isLoop: true,
              onPlaybackCallback: onPlaybackCallback,
            ),
            Positioned.fill(
              child: Obx(
                () => Offstage(
                  offstage: !isDisposing.value,
                  child: Hero(
                    tag: widget.source,
                    child: RemoteImage(
                      src: widget.thumbnail,
                      fit: BoxFit.contain,
                      mini: Config().dynamicMin,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).viewPadding.top,
              child: Column(
                children: <Widget>[
                  // appBar
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
