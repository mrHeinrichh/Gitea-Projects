import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ReelLikeHeart extends StatefulWidget {
  final ReelPost post;
  final bool isLikedTap;
  final Function(Duration) onCompositionLoaded;

  const ReelLikeHeart({
    super.key,
    required this.post,
    required this.isLikedTap,
    required this.onCompositionLoaded,
  });

  @override
  State<ReelLikeHeart> createState() => _ReelLikeHeartState();
}

class _ReelLikeHeartState extends State<ReelLikeHeart>{
  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          if (widget.isLikedTap)
            reelUtils.reelShadow(
              child: Lottie.asset(
                'assets/lottie/like_animation.json',
                width: 40,
                height: 40,
                repeat: false,
                onLoaded: (composition) {
                  widget.onCompositionLoaded(composition.duration);
                },
              ),
            ),
          if (!widget.isLikedTap)
            Obx(
              () => reelUtils.reelShadow(
                child: Image.asset(
                  //svg圖在ios出現模糊,故改png圖
                  'assets/images/reel/like_icon.png',
                  width: 40,
                  height: 40,
                  color: (widget.post.isLiked.value ?? false) ? colorRed : Colors.white,
                ),
              ),
            ),
          Obx(
            () => Text(
              '${widget.post.likedCount.value ?? 0}',
              style: jxTextStyle.textStyle12(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
