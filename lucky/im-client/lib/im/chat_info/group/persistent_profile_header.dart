import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/im/chat_info/group/profile_header_widget.dart';


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

const double minImageSize = 14;
const double maxImageSize = 20.12;
///description
const double minFontDescriptionSize = 13;
const double maxFontDescriptionSize = 16;

double minSubtitleTopGap = 0;
double maxSubtitleTopGap = 4.w;

extension NicknameExtension on NicknameText {
  NicknameText newSize(double size) {
    return NicknameText(
      uid: this.uid,
      isGroup: this.isGroup,
      displayName: this.displayName,
      fontSize: size,
      overflow: this.overflow,
      fontWeight: this.fontWeight,
      isTappable: this.isTappable,
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
    this.activateGame = false,
  });

  final String server;
  final String? img;
  final NicknameText name;
  final RxString description;
  final Widget defaultImg;
  final VoidCallback? toMaxImage;
  final Function(JumpExtent)? toMiddleImage;
  final VoidCallback? action;
  final bool ableEdit;
  final Function()? onClickProfile;
  final bool activateGame;

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

    double imageSize = maxImageSize * (1 - percent);
    imageSize = imageSize.clamp(minImageSize, maxImageSize);

    double subtitleTopGap = maxSubtitleTopGap * (1 - percent);
    subtitleTopGap = subtitleTopGap.clamp(minSubtitleTopGap, maxSubtitleTopGap);

    // bool mustExpand =
    //     shrinkOffset < initialScrllOffset * scrollDesiredPercent && img != '';
    bool mustExpand = false;

    return Container(
      color: ImColor.systemBg,
      child: Stack(
        children: [
          Positioned(
            top: mustExpand
                ? 0
                : percent > 0.8
                    ? -100
                    : (0 - shrinkOffset) + 24,
            left: mustExpand ? 0 : leftOffset,
            child: AnimatedContainer(
              duration: duration,
              child: GestureDetector(
                onTap: () =>
                    (onClickProfile != null) ? onClickProfile!() : null,
                child: Hero(
                  tag: 'avatarHero',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10000000),
                    child: img!.isEmpty
                        ? defaultImg
                        : RemoteImage(
                            width: 100.0,
                            height: 100.0,
                            src: img!,
                            fit: BoxFit.fitWidth,
                          ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: percent > 0.8 ? paddingTop : (0 - shrinkOffset) + 132,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: (percent > 0.8) ? 88.w : 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                        color: mustExpand ? Colors.white : ImColor.black,
                        fontSize: mustExpand ? 24 : fontSize,
                        fontWeight: MFontWeight.bold6.value,
                        overflow: TextOverflow.ellipsis),
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: name.newSize(fontSize),
                  ),
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                        color: mustExpand
                            ? Colors.white
                            : JXColors.secondaryTextBlack,
                        fontWeight: MFontWeight.bold4.value,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: Obx(() => Text(
                          description.value,
                          style: TextStyle(
                            fontSize: fontDescriptionSize,
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
          ProfileHeaderWidget(
              paddingTop: paddingTop,
              isCollapse: mustExpand,
              editCallBack: action,
              ableEdit: ableEdit),
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
