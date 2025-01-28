import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/chat_info/group/game_profile_header_widget.dart';
import 'package:jxim_client/im/chat_info/group/game_profile_page.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';

const Duration duration = Duration(milliseconds: 50);

const double avatarRadius = 30;
const double minAvatarRadius = 20;
const double maxAvatarRadius = 50;

const double minLeftOffset = 20;
const double maxleftOffset = 80;

const double minTopOffset = -100;
const double maxTopOffset = 50;

const double minFontSize = 17;
const double maxFontSize = 30;

const double minImageSize = 14;
const double maxImageSize = 20.12;

double minSubtitleTopGap = 0;
double maxSubtitleTopGap = 4.w;

extension NicknameExtension on NicknameText {
  NicknameText newSize(double size){
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


class GamePersistentProfileHeader extends SliverPersistentHeaderDelegate {
  GamePersistentProfileHeader({
    required this.server,
    this.img,
    required this.defaultImg,
    required this.name,
    this.toMaxImage,
    this.toMiddleImage,
    this.action,
    required this.ableEdit,
    this.activateGame = true,
    required this.onlineCount,
    required this.membersCount,
  });

  final int onlineCount;
  final int membersCount;
  final String server;
  final String? img;
  final NicknameText name;
  final Widget defaultImg;
  final VoidCallback? toMaxImage;
  final Function(GameJumpExtent)? toMiddleImage;
  final VoidCallback? action;
  final bool ableEdit;
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
            //duration: duration,
            top: //mustExpand ? 0 :
              percent > 0.8
                    ? -100
                    : (maxExtent - shrinkOffset) - 168,
            left: //mustExpand ? 0 :
              leftOffset,
            child: GestureDetector(
              onTap: () {
                // if (img != '') {
                //   toMaxImage!();
                // }
              },
              child: AnimatedContainer(
                duration: duration,
                height:
                    //mustExpand ? maxExtent - shrinkOffset :
                    100 - (percent * 3),
                width: //mustExpand ? MediaQuery.of(context).size.width :
                    100 - (percent * 3),
                child: ExtendedImage.network(
                  '$server/${img!}',
                  fit: BoxFit.fill,
                  cache: true,
                  shape: //mustExpand ? BoxShape.rectangle :
                    BoxShape.circle,
                  loadStateChanged: (ExtendedImageState state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                      case LoadState.failed:
                      case LoadState.completed:
                      return defaultImg;
                    }
                  },
                ),
              ),
            ),
          ),

          Positioned(
            //duration: duration,
            top: // mustExpand
            //     ? (maxExtent - shrinkOffset) - 60
            //     :
            percent > 0.8
                ? paddingTop + 8
                : (maxExtent - shrinkOffset) - 58,
            left: 0,
            right: //mustExpand ? null :
              0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (percent > 0.8) ? 88.w : 16.w ),
              child: Column(
                crossAxisAlignment: //mustExpand
                    // ? CrossAxisAlignment.start:
                CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          style: TextStyle(
                            color: //mustExpand ? Colors.white :
                            ImColor.black,
                            fontSize: //mustExpand ? 24 :
                            fontSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'pingfang',
                            overflow: TextOverflow.ellipsis
                          ),
                          duration: const Duration(
                            milliseconds: 200,
                          ),
                          child: name.newSize(fontSize),
                        ),
                      ),
                      ImGap.hGap(4),
                      if (activateGame)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.5),
                          child: SvgPicture.asset(
                            'assets/svgs/certificate.svg',
                            width: imageSize,
                            height: imageSize,
                            colorFilter: const ColorFilter.mode(
                                JXColors.blue, BlendMode.srcIn),
                          ),
                        ),
                    ],
                  ),
                  ImGap.vGap(subtitleTopGap),
                  AnimatedDefaultTextStyle(
                    style: const TextStyle(
                        color: //mustExpand ? Colors.white :
                          JXColors.secondaryTextBlack,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'pingfang',
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: ImText(
                      '$membersCount${localized(groupMemberCount)}，$onlineCount${localized(groupOnline)}',
                        height: ImLineHeight.lh_22,
                      color: ImColor.black48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Positioned(
          //   //duration: duration,
          //   top: mustExpand
          //       ? (maxExtent - shrinkOffset) - 60
          //       : percent > 0.8
          //           ? paddingTop + 16
          //           : (maxExtent - shrinkOffset) - 60,
          //   left: 0,
          //   right: mustExpand ? null : 0,
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(
          //         horizontal: (percent > 0.8) ? 88.w : 16.w),
          //     child: Column(
          //       crossAxisAlignment: mustExpand
          //           ? CrossAxisAlignment.start
          //           : CrossAxisAlignment.center,
          //       children: [
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             AnimatedDefaultTextStyle(
          //               style: TextStyle(
          //                 color: mustExpand ? Colors.white : ImColor.black,
          //                 fontSize: mustExpand ? 24 : fontSize,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //               duration: const Duration(
          //                 milliseconds: 200,
          //               ),
          //               child: name,
          //             ),
          //             ImGap.vGap(5),
          //             if (activateGame)
          //               SvgPicture.asset(
          //                 'assets/svgs/certificate.svg',
          //                 width: 20,
          //                 height: 20,
          //                 color: JXColors.blue,
          //               ),
          //           ],
          //         ),
          //         AnimatedDefaultTextStyle(
          //           style: TextStyle(
          //               color: mustExpand
          //                   ? Colors.white
          //                   : JXColors.secondaryTextBlack,
          //               fontWeight: FontWeight.w400,
          //               fontSize: 13),
          //           overflow: TextOverflow.ellipsis,
          //           duration: const Duration(
          //             milliseconds: 200,
          //           ),
          //           child: Text(
          //             '$membersCount位成员，$onlineCount在线',
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          GameProfileHeaderWidget(
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
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
