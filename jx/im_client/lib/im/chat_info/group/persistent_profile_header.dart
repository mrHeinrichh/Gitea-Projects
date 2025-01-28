import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/chat_info_nickname_text.dart';
import 'package:jxim_client/im/chat_info/group/profile_header_widget.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

// const double maxHeaderExtent = 220.0;
// double minHeaderExtent = 90.0;

const double avatarRadius = 30;
const double minAvatarRadius = 20;
const double maxAvatarRadius = 50;

const double minLeftOffset = 20;
const double maxleftOffset = 80;

const double minTopOffset = -100;
const double maxTopOffset = 50;

///title
const double minFontSize = 17;
const double maxFontSize = 30;

///description
const double minFontDescriptionSize = 13;
const double maxFontDescriptionSize = 16;

double minSubtitleTopGap = 0;
double maxSubtitleTopGap = 4.w;

extension ChatInfoNicknameTextExtension on ChatInfoNicknameText {
  ChatInfoNicknameText newSize(double size) {
    return ChatInfoNicknameText(
      uid: uid,
      chatType: chatType,
      size: size,
      showIcon: showIcon,
      showEncrypted: showEncrypted,
    );
  }
}

class PersistentProfileHeader extends SliverPersistentHeaderDelegate {
  PersistentProfileHeader({
    required this.server,
    this.img,
    required this.defaultImg,
    required this.name,
    required this.description,
    this.toMaxImage,
    this.toMiddleImage,
    this.action,
    required this.ableEdit,
    this.onClickProfile,
    this.isModalBottomSheet = false,
  });

  final String server;
  final String? img;
  final ChatInfoNicknameText name;
  final String description;
  final Widget defaultImg;
  final VoidCallback? toMaxImage;
  final Function(JumpExtent)? toMiddleImage;
  final VoidCallback? action;
  final bool ableEdit;
  final Function()? onClickProfile;
  final bool isModalBottomSheet;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingTop = MediaQuery.of(context).padding.top;
    double percent = (shrinkOffset) / (maxExtent - paddingTop - 60);

    double radius = avatarRadius * (1.3 - percent);
    radius = radius.clamp(minAvatarRadius, maxAvatarRadius);

    double leftOffset = (screenWidth / 2) - 50;
    leftOffset = leftOffset.clamp(minLeftOffset, screenWidth);

    double topOffset = maxTopOffset / (percent);
    topOffset = topOffset.clamp(minTopOffset, maxTopOffset);

    double fontSize = maxFontSize * 3 * (1 - percent);
    fontSize = fontSize.clamp(minFontSize, maxFontSize);

    double fontDescriptionSize = maxFontDescriptionSize * 3 * (1 - percent);
    fontDescriptionSize = fontDescriptionSize.clamp(
        minFontDescriptionSize, maxFontDescriptionSize);

    double subtitleTopGap = maxSubtitleTopGap * (1 - percent);
    subtitleTopGap = subtitleTopGap.clamp(minSubtitleTopGap, maxSubtitleTopGap);

    return Container(
      color: ImColor.systemBg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: percent > 0.8 ? -100 : (0 - shrinkOffset) + 24,
            left: leftOffset,
            child: AnimatedContainer(
              duration: duration,
              child: GestureDetector(
                onTap: () =>
                    (onClickProfile != null) ? onClickProfile!() : null,
                child: ClipOval(
                  child: img != null
                      ? defaultImg
                      : RemoteImage(
                          width: 100.0,
                          height: 100.0,
                          src: img ?? "",
                          fit: BoxFit.cover,
                          mini: Config().headMin,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: percent > 0.8 ? paddingTop : (0 - shrinkOffset) + 132,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: percent > 0.8 ? 75 : 50),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                        color: ImColor.black,
                        fontSize: fontSize,
                        fontWeight: MFontWeight.bold6.value,
                        overflow: TextOverflow.ellipsis),
                    child: name.newSize(fontSize),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  style: TextStyle(
                      color: colorTextSecondary,
                      fontWeight: MFontWeight.bold4.value,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: fontDescriptionSize,
                      fontFamily: appFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProfileHeaderWidget(
            paddingTop: paddingTop,
            editCallBack: action,
            ableEdit: ableEdit,
            isModalBottomSheet: isModalBottomSheet,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 190;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
