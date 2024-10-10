import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_name.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class ReelCommentTile extends StatelessWidget {
  final void Function()? onProfileTap;
  final ReelComment comment;

  const ReelCommentTile({required this.comment, this.onProfileTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OpacityEffect(
              child: GestureDetector(
                onTap: onProfileTap,
                child: ReelProfileAvatar(
                  profileSrc: comment.profilePic.value,
                  userId: comment.userId.value ?? 0,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: onProfileTap,
                      child: ReelProfileName(
                        userId: comment.id.value ?? 0,
                        name: comment.name.value ?? "",
                        fontSize: MFontSize.size16.value,
                        color: colorTextSecondary,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      comment.comment.value ?? "",
                      style: jxTextStyle.textStyle15(),
                    ),
                  ),
                  Text(
                    FormatTime.chartTime(
                      comment.updatedAt.value ?? 0,
                      true,
                      todayShowTime: true,
                      dateStyle: DateStyle.MMDDYYYY,
                    ),
                    style: jxTextStyle.textStyle12(color: colorTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
