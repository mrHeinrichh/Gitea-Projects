import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:lottie/lottie.dart';

class ReelFollowWidget extends StatefulWidget {
  final ReelCreator creator;
  final bool isFollowTap;
  final Function(Duration) onCompositionLoaded;

  const ReelFollowWidget({
    super.key,
    required this.creator,
    required this.isFollowTap,
    required this.onCompositionLoaded,
  });

  @override
  State<ReelFollowWidget> createState() => _ReelFollowWidgetState();
}

class _ReelFollowWidgetState extends State<ReelFollowWidget> {
  // @override
  // bool get wantKeepAlive => true;
  late Rxn<ReelCreator> creator;

  @override
  void initState() {
    super.initState();
    creator = ReelPostMgr.instance.allCreators[widget.creator.id.value]!;
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);

    return Obx(() {
      if (widget.isFollowTap) {
        return SizedBox(
          width: 24,
          height: 24,
          // padding: const EdgeInsets.all(2),
          child: Lottie.asset(
            'assets/lottie/follow_animation.json',
            repeat: false,
            onLoaded: (composition) {
              widget.onCompositionLoaded(composition.duration);
            },
          ),
        );
      } else if (ProfileRs.canFollowWithRs(creator.value!.rs.value!)) {
        return SvgPicture.asset(
          'assets/svgs/follow_icon.svg',
          width: 24,
          height: 24,
        );
      } else {
        return const SizedBox();
      }
    });

  }
}
