import 'package:flutter/material.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/reel_avatar.dart';
import 'package:jxim_client/utils/config.dart';

class ReelProfileAvatar extends StatefulWidget {
  final int userId;
  final String? profileSrc;
  final double size;

  const ReelProfileAvatar({
    super.key,
    required this.userId,
    this.profileSrc,
    required this.size,
  });

  @override
  State<ReelProfileAvatar> createState() => _ReelProfileAvatarState();
}

class _ReelProfileAvatarState extends State<ReelProfileAvatar> {
  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(ReelProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: notBlank(widget.profileSrc)
          ? RemoteImage(
              src: widget.profileSrc ?? "",
              mini: Config().headMin,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
            )
          : ReelAvatar(
              uid: widget.userId,
              size: widget.size,
              headMin: Config().headMin,
              fontSize: 24.0,
              shouldAnimate: false,
            ),
    );
  }
}
