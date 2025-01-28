import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/services/playback_state.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../object/reel.dart';
import '../../utils/color.dart';
import '../../utils/config.dart';
import '../../utils/format_time.dart';
import '../../views/component/custom_avatar.dart';
import '../services/reel_video.dart';

class ResultItem extends StatefulWidget {
  final ReelData reelPost;
  final int index;

  ResultItem({
    Key? key,
    required this.reelPost,
    required this.index,
  }) : super(key: key);

  @override
  State<ResultItem> createState() => _ResultItemState();
}

class _ResultItemState extends State<ResultItem> {
  ReelSearchController get controller => Get.find<ReelSearchController>();

  ReelController get reelController => Get.find<ReelController>();

  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isMute = ValueNotifier(true);
  final ValueNotifier<bool> isTransition = ValueNotifier(false);

  int currentSecond = 0;

  void onPlaybackCallback(int second) => currentSecond = second;

  @override
  void initState() {
    super.initState();
    reelController.on(ReelController.eventPlayStateChange, onPlayStateChange);
  }

  @override
  void dispose() {
    isPlaying.dispose();
    isMute.dispose();
    isTransition.dispose();

    reelController.off(ReelController.eventPlayStateChange, onPlayStateChange);
    super.dispose();
  }

  void onPlayStateChange(_, __, data) {
    if (data == null || data is! Map<String, dynamic>) return;

    if (data.containsKey('state') && data['state'] == PlaybackState.stop) {
      isPlaying.value = false;
      return;
    }

    if (data.containsKey('source') &&
        data['source'] == widget.reelPost.post!.files!.first.path) {
      if (data.containsKey('state')) {
        switch (data['state']) {
          case PlaybackState.play:
            isPlaying.value = true;
            break;
          default:
            isPlaying.value = false;
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('${widget.reelPost.post?.id}'),
      onVisibilityChanged: (VisibilityInfo info) {
        controller.checkVisibility(
          info,
          widget.reelPost.post!,
          widget.index,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                CustomAvatar(
                  uid: widget.reelPost.post!.userid!,
                  size: 48,
                  headMin: Config().headMin,
                  fontSize: 24.0,
                  shouldAnimate: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NicknameText(
                        uid: widget.reelPost.post!.userid!,
                        fontSize: MFontSize.size17.value,
                        fontWeight: MFontWeight.bold6.value,
                        overflow: TextOverflow.ellipsis,
                        isTappable: false,
                      ),
                      Text(
                        FormatTime.formatTimeFun(
                            widget.reelPost.post!.createAt),
                        style: jxTextStyle.textStyle12(
                            color: JXColors.secondaryTextBlack),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: notBlank(widget.reelPost.post!.description!),
            child: Text(
              widget.reelPost.post!.description!,
              style: jxTextStyle.textStyle15(),
            ),
          ),
          Visibility(
            visible: notBlank(tagItem()),
            child: Text(
              tagItem(),
              style: jxTextStyle.textStyle15(color: accentColor),
            ),
          ),
          VideoItem(context),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              featureItem(
                'assets/svgs/favourite_outline_icon.svg',
                widget.reelPost.post!.likedCount!,
              ),
              featureItem(
                'assets/svgs/comment_outline_icon.svg',
                0,
              ),
              featureItem(
                'assets/svgs/bookmark_outline_icon.svg',
                widget.reelPost.post!.savedCount!,
              ),
              featureItem(
                'assets/svgs/forward_icon.svg',
                widget.reelPost.post!.sharedCount!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget featureItem(String icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
                JXColors.primaryTextBlack, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: jxTextStyle.textStyle12(color: JXColors.primaryTextBlack),
          ),
        ],
      ),
    );
  }

  Widget VideoItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.black,
              height: 220,
              width: MediaQuery.of(context).size.width,
              child: ReelVideo.network(
                source: widget.reelPost.post!.files!.first.path!,
                thumbnail: widget.reelPost.post!.thumbnail!,
                index: widget.index,
                isLoop: true,
                isMute: true,
                autoPlay: false,
                onPlaybackCallback: onPlaybackCallback,
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: isTransition,
                builder: (BuildContext context, bool value, Widget? _) {
                  return Offstage(
                    offstage: !value,
                    child: Hero(
                      tag: widget.reelPost.post!.files!.first.path!,
                      child: RemoteImage(
                        src: widget.reelPost.post!.thumbnail!,
                        fit: BoxFit.contain,
                        mini: Config().dynamicMin,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  isTransition.value = true;
                  Future.delayed(const Duration(milliseconds: 300), () {
                    isTransition.value = false;
                  });

                  controller.onEnterReelDetail(
                    context,
                    widget.reelPost,
                    currentSecond,
                  );
                },
              ),
            ),
            Positioned(
              top: 0.0,
              right: 0.0,
              child: ValueListenableBuilder<bool>(
                  valueListenable: isMute,
                  builder: (_, bool value, __) {
                    return GestureDetector(
                      onTap: () {
                        isMute.value = !value;
                        controller.toggleVolume(widget.reelPost);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: JXColors.outlineColor,
                        ),
                        child: Icon(
                          value
                              ? Icons.volume_off_outlined
                              : Icons.volume_up_outlined,
                          size: 22.0,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
            ),
            Positioned(
              bottom: 0.0,
              right: 0.0,
              child: ValueListenableBuilder<bool>(
                  valueListenable: isPlaying,
                  builder: (_, bool value, __) {
                    return GestureDetector(
                      onTap: () {
                        isPlaying.value = !value;
                        controller.videoHandle(
                          isPlaying.value,
                          widget.reelPost.post!.files!.first.path,
                          isMute: isMute.value,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          value ? Icons.pause : Icons.play_arrow,
                          size: 22.0,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  String tagItem() {
    String tag = "";
    if (widget.reelPost.post!.tags!.isNotEmpty) {
      for (final item in widget.reelPost.post!.tags ?? []) {
        tag += "#$item ";
      }
    }
    return tag;
  }
}
