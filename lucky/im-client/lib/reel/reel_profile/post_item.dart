import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../object/reel.dart';
import '../../utils/cache_image.dart';
import '../../utils/color.dart';
import '../../utils/config.dart';

class PostItem extends StatelessWidget {
  final ReelData item;

  const PostItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RemoteImage(
          src: item.post!.thumbnail!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
          mini: Config().dynamicMin,
        ),
        Positioned.fill(
          child: ColoredBox(
            color: JXColors.primaryTextBlack.withOpacity(0.05),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/favourite_outline_icon.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "${item.post!.likedCount ?? 0}",
                style: jxTextStyle.textStyle12(color: Colors.white),
              )
            ],
          ),
        )
      ],
    );
  }
}
