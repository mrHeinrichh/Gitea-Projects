import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class DiscoveryAppletItem extends StatelessWidget {
  final String imgPath;
  final String title;
  final String subtitle;
  final bool isCollected;
  final VoidCallback? onClickIcon;
  final VoidCallback? onClick;

  const DiscoveryAppletItem({
    super.key,
    required this.imgPath,
    required this.title,
    required this.subtitle,
    this.isCollected = false,
    this.onClickIcon,
    this.onClick,
  });

  final double _avatarSize = 48;
  final double _avatarVerticalPadding = 8;

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipOval(
        child: RemoteImage(
          src: imgPath,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      constraints: BoxConstraints(
        minHeight: _avatarSize + _avatarVerticalPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.2),
            width: 0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jxTextStyle.textStyleBold17(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: jxTextStyle.textStyle13(
                    color: colorTextPrimary.withOpacity(0.48),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClickIcon,
            child: OpacityEffect(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.star_rounded,
                  size: 24,
                  color: isCollected
                      ? themeColor
                      : colorTextPrimary.withOpacity(0.2),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClick,
            child: ForegroundOverlayEffect(
              radius: BorderRadius.circular(30),
              child: IntrinsicHeight(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16
                  ),
                  decoration: BoxDecoration(
                    color: colorTextPrimary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    localized(miniAppEnter),
                    style: jxTextStyle.textStyleBold14(color: themeColor),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        _buildAvatar(),
        const SizedBox(width: 12),
        Flexible(
          child: _buildContent(),
        )
      ],
    );
  }
}
