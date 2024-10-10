import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class ChatAttachmentOption {
  final String icon;
  final String title;
  final Function()? onTap;

  const ChatAttachmentOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class ChatAttachmentView extends StatelessWidget {
  final List<ChatAttachmentOption> options;
  final Function()? onHideAttachmentView;

  const ChatAttachmentView({
    required this.options,
    required this.onHideAttachmentView,
    super.key,
  });

  Widget renderOption(ChatAttachmentOption option) {
    return GestureDetector(
      onTap: () {
        option.onTap?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onHideAttachmentView?.call();
        });
      },
      child: OpacityEffect(
        child: Column(
          children: [
            Container(
              height: 64.w,
              width: 64.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                height: 29.w,
                color: Colors.black,
                // width: 29,
                option.icon,
                // fit: BoxFit.fill,
                // clipBehavior: Clip.none,
                // colorFilter: const ColorFilter.mode(
                //   ImColor.black,
                //   BlendMode.srcIn,
                // ),
              ),
            ),
            SizedBox(height: 8.w),
            ImText(
              option.title,
              fontSize: 12,
              color: ImColor.black48,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeBottom: true,
      context: context,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20).w,
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ImColor.borderColor,
              width: 0.3,
            ),
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const PageScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 6.w,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) => renderOption(options[index]),
        ),
      ),
    );
  }
}
