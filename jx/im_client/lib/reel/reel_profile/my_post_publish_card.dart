import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class MyPostPublishCard extends StatelessWidget {
  final VoidCallback onPressed;

  const MyPostPublishCard({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.fromLTRB(16, 6, 0, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: colorBackground6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colorTextPrimary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CustomImage(
                'assets/svgs/reel_camera_outlined.svg',
                color: colorTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发布作品，留下记忆',
                  style: jxTextStyle.textStyle14(),
                ),
                Text(
                  '记录美好',
                  style: jxTextStyle.textStyle12(color: colorTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCustomButton(),
        ],
      ),
    );
  }

  Widget _buildCustomButton() {
    final borderRadius = BorderRadius.circular(4);

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ForegroundOverlayEffect(
          radius: borderRadius,
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE1EC),
              borderRadius: borderRadius,
            ),
            child: Text(
              '去发布',
              style: jxTextStyle.textStyle14(color: const Color(0xFFEC2964)),
            ),
          ),
        ),
      ),
    );
  }
}
