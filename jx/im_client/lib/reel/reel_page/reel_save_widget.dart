import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ReelSaveWidget extends StatefulWidget {
  final ReelPost post;
  final bool isFavoriteTap;
  final Function(Duration) onCompositionLoaded;

  const ReelSaveWidget({
    super.key,
    required this.post,
    required this.isFavoriteTap,
    required this.onCompositionLoaded,
  });

  @override
  State<ReelSaveWidget> createState() => _ReelSaveWidgetState();
}

class _ReelSaveWidgetState extends State<ReelSaveWidget> {
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          if (widget.isFavoriteTap)
            reelUtils.reelShadow(
              child: Lottie.asset(
                'assets/lottie/favorite_animation.json',
                width: 40,
                height: 40,
                repeat: false,
                onLoaded: (composition) {
                  widget.onCompositionLoaded(composition.duration);
                },
              ),
            ),
          if (!widget.isFavoriteTap)
            Obx(
              () => reelUtils.reelShadow(
                child: SvgPicture.asset(
                  'assets/svgs/favorite_icon.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    (widget.post.isSaved.value ?? false) ? colorOrange : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          Obx(
            () => Text(
              '${widget.post.savedCount.value ?? 0}',
              style: jxTextStyle.textStyle12(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
