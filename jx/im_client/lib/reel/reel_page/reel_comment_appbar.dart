import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class ReelCommentAppBar extends StatelessWidget {
  const ReelCommentAppBar({
    super.key,
    required this.controller,
    required this.title,
  });

  final ReelCommentController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            child: Text(
              title,
              style: jxTextStyle.textStyleBold17(color: Colors.black),
            ),
          ),
          Positioned(
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Obx(
                      () => GestureDetector(
                        onTap: () {
                          controller.isCommentExpand.value =
                              !controller.isCommentExpand.value;
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/video_comment_${!controller.isCommentExpand.value ? 'expand_icon' : 'minimize_icon'}.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        controller.commentTextEditingController.clear();
                      },
                      child: SvgPicture.asset(
                        'assets/svgs/video_comment_close_icon.svg',
                        width: 30,
                        height: 30,
                      ),
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
