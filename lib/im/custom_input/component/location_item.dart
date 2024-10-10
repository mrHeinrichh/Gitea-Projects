import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';

import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class LocationItem extends StatelessWidget {
  final String title;
  final String subTitle;
  final bool showDivider;
  final int? avatarUid;
  final Widget? rightWidget;
  final String? pngPath;
  final String? svgPath;
  final Function()? onClick;
  const LocationItem({
    super.key,
    this.avatarUid,
    required this.title,
    required this.subTitle,
    this.showDivider = true,
    this.rightWidget,
    this.pngPath,
    this.onClick,
    this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = Container(
      height: 52,
      padding: const EdgeInsets.only(left: 12),
      alignment: Alignment.centerLeft,
      color: colorWhite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (pngPath == null && svgPath == null)
            avatarUid != null
                ? Center(
                    child: CustomAvatar.normal(
                      key: ValueKey(avatarUid),
                      avatarUid ?? 0,
                      size: 40,
                      shouldAnimate: false,
                    ),
                  )
                : const SizedBox(
                    width: 40,
                  ),
          if (pngPath != null)
            Image.asset(
              pngPath!,
              width: 40.0,
              height: 40.0,
            ),
          if (svgPath != null)
            SvgPicture.asset(
              svgPath!,
              width: 40.0,
              height: 40.0,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: showDivider
                    ? const Border(
                        bottom: BorderSide(
                          width: 1,
                          color: ImColor.black6,
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          style: jxTextStyle.textStyleBold16(
                            fontWeight: MFontWeight.bold6.value,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subTitle,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: colorTextSecondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ImGap.hGap12,
                  if (rightWidget != null) rightWidget!,
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onClick != null) {
      current = ImClick(
        onClick: onClick,
        child: current,
      );
    }

    return current;
  }
}
