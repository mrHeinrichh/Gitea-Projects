
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/services/reel_video.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../utils/config.dart';
import '../../views/component/custom_avatar.dart';
import '../../views/component/nickname_text.dart';

class ReelItem extends StatelessWidget {
  final ReelData reelData;
  final int index;
  final ReelController controller;

  const ReelItem({
    super.key,
    required this.reelData,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    bool like = false;
    bool save = false;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Video
        ReelVideo.file(
          source: reelData.post!.files![0].path!,
          thumbnail: reelData.post!.thumbnail!,
          index: index,
          isLoop: true,
        ),

        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: controller.onVideoTap,
            onLongPress: controller.onVideoLongPress,
            onLongPressUp: () => controller.onVideoLongPressEnd(null),
            onLongPressEnd: controller.onVideoLongPressEnd,
          ),
        ),

        // Details
        Positioned.fill(
          top: 44.0,
          bottom: 50.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),

              Row(
                children: <Widget>[
                  const Spacer(),
                  Column(
                    children: [
                      friendIcon(),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          like = !like;
                          controller.onLikedClick(reelData.post?.id, like);
                        },
                        child: featureItem('assets/svgs/favorite_icon.svg',
                            reelData.post?.likedCount ?? 0),
                      ),
                      featureItem('assets/svgs/comment_icon.svg', 0),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          save = !save;
                          controller.onSavedClick(reelData.post?.id, save);
                        },
                        child: featureItem('assets/svgs/bookmark_icon.svg',
                            reelData.post?.savedCount ?? 0),
                      ),
                      InkWell(
                        onTap: () => controller.doForward(reelData),
                        child: featureItem('assets/svgs/forward_fill_icon.svg',
                            reelData.post?.sharedCount ?? 0),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),

              // comment
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  bottom: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NicknameText(
                      uid: reelData.post?.userid ?? 0,
                      fontSize: MFontSize.size16.value,
                      fontWeight:MFontWeight.bold6.value,
                      overflow: TextOverflow.ellipsis,
                      isTappable: false,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reelData.post!.description ?? "",
                      style: jxTextStyle.textStyle16(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget friendIcon() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(100)),
              ),
              child: CustomAvatar(
                uid: reelData.post?.userid ?? 0,
                size: 48,
                headMin: Config().headMin,
                fontSize: 24.0,
                shouldAnimate: false,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Icon(
              Icons.add_circle,
              color: errorColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget featureItem(String icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            width: 40,
            height: 40,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          Text(
            '$count',
            style: jxTextStyle.textStyle12(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
