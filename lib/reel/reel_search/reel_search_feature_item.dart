import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/utils/theme/color/color_code.dart';

class ReelSearchFeatureItem extends StatefulWidget {
  const ReelSearchFeatureItem({
    super.key,
    required this.type,
    // required this.svgIcon,
    required this.color,
    required this.count,
    this.onTap,
  });

  final Color color;
  final int count;
  final ReelIconDataType type;
  final void Function()? onTap;

  @override
  State<ReelSearchFeatureItem> createState() => _ReelSearchFeatureItemState();
}

class _ReelSearchFeatureItemState extends State<ReelSearchFeatureItem>
    with
        AutomaticKeepAliveClientMixin {
  late String svgIcon;
  late Rxn<int> count;
  late Rx<Color> color;

  @override
  void initState() {
    super.initState();

    switch (widget.type) {
      case ReelIconDataType.liked:
        svgIcon = 'assets/svgs/favourite_outline_icon.svg';

        break;
      case ReelIconDataType.comment:
        svgIcon = 'assets/svgs/comment_outline_icon.svg';
        break;
      case ReelIconDataType.saved:
        svgIcon = 'assets/svgs/bookmark_outline_icon.svg';
        break;
      case ReelIconDataType.share:
        svgIcon = 'assets/svgs/forward_icon.svg';
        break;
    }
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          children: [
            SvgPicture.asset(
              svgIcon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.count}',
              style: jxTextStyle.textStyle12(color: colorTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
