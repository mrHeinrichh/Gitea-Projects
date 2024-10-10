import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';

class LiveLocationStatus extends StatelessWidget {
  const LiveLocationStatus({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.w,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: ImColor.bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/svgs/stop_sharing_pin.svg',
                  width: 24.w,
                  height: 24.w,
                  colorFilter: ColorFilter.mode(
                    themeColor,
                    BlendMode.srcIn,
                  ),
                ),
                ImGap.hGap8,
                ImText(
                  'Live Location',
                  fontSize: ImFontSize.small,
                  fontWeight: FontWeight.w500,
                ),
                Flexible(
                  child: ImText(
                    ' - ${'You,'} Mario and Crysta',
                    fontSize: ImFontSize.small,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: SvgPicture.asset(
              'assets/svgs/close_icon.svg',
              width: 24.w,
              height: 24.w,
              colorFilter: ColorFilter.mode(
                themeColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
