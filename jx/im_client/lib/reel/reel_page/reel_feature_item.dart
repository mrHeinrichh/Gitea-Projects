import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class ReelFeatureItem extends StatefulWidget {
  const ReelFeatureItem({
    super.key,
    required this.count,
    required this.type,
    this.color = Colors.white,
  });

  final Color color;
  final int count;
  final ReelIconDataType type;

  @override
  State<ReelFeatureItem> createState() => _ReelFeatureItemState();
}

class _ReelFeatureItemState extends State<ReelFeatureItem>
{
  late String svgIcon;

  @override
  void initState() {
    super.initState();

    switch (widget.type) {
      case ReelIconDataType.comment:
        svgIcon = 'assets/svgs/comment_icon.svg';
        break;
      case ReelIconDataType.share:
      default:
        svgIcon = 'assets/svgs/forward_fill_icon.svg';
        break;
    }
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
          reelUtils.reelShadow(
            child: SvgPicture.asset(
              svgIcon,
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
            ),
          ),
          Text(
            '${widget.count}',
            style: jxTextStyle.textStyle12(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
