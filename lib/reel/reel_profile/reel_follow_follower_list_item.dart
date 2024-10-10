import 'package:flutter/material.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ReelFollowFollowerListItem extends StatefulWidget {
  const ReelFollowFollowerListItem({
    super.key,
    required this.isFollow,
    required this.type,
    required this.name,
    required this.avatarID,
    this.profileSrc,
    required this.followerCount,
    required this.onTap,
  });

  final String? profileSrc;
  final bool isFollow;
  final int type;
  final String name;
  final int avatarID;
  final int followerCount;
  final Function() onTap;

  @override
  State<ReelFollowFollowerListItem> createState() =>
      _ReelFollowFollowerListItemState();
}

class _ReelFollowFollowerListItemState
    extends State<ReelFollowFollowerListItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 66,
          child: Row(
            children: [
              ReelProfileAvatar(
                profileSrc: widget.profileSrc,
                userId: widget.avatarID,
                size: 50,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: jxTextStyle.textStyleBold14(
                          color: colorTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          localized(
                            reelWorkCount,
                            params: ['${widget.followerCount}'],
                          ),
                          style: jxTextStyle.textStyle12(
                            color: colorTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                // onTap: () {
                //   setState(() => _isFollow = !_isFollow);
                //   widget.onTap(_isFollow);
                // },
                onTap: widget.onTap,
                child: GestureDetector(
                  child: Container(
                    width: 80,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _btnColor(widget.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _btnTxt(widget.type),
                      style: jxTextStyle.textStyleBold12(
                        color: _btnTxtColor(widget.type),
                      ),
                    ),
                    // child: SvgPicture.asset(
                    //     'assets/svgs/reel_follow_${_isFollow ? 'added' : 'add'}.svg',
                    //     width: 20,
                    //     height: 20,
                    //     colorFilter: ColorFilter.mode(
                    //         _isFollow ? colorTextPrimary : colorWhite,
                    //         BlendMode.srcIn)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // String _followButtonType(bool value) {
  //   return switch (widget.type) {
  //     FollowType.follow =>
  //       value ? localized(subscribedButton) : localized(subscribeButton),
  //     FollowType.follower =>
  //       value ? localized(reelMutualFollow) : localized(reelFollowBack),
  //   };
  // }

  String _btnTxt(int type) {
    switch (type) {
      case 0:
        return localized(reelFollow); //follow
      case 1:
        return localized(reelFollowBack); //follow
      case 2:
        return localized(reelFollowing); //following
      case 3:
        return localized(reelMutualFollow); //friends
      default:
        return "";
    }
  }

  _btnColor(int type) {
    switch (type) {
      case 0: //关注
      case 1: //回关
        return colorRed; //follow
      case 2: //已关注
      case 3: //相互关注
        return colorBorder; //friends
      default:
        return colorBorder;
    }
  }

  _btnTxtColor(int type) {
    switch (type) {
      case 0: //关注
      case 1: //回关
        return colorWhite; //follow
      case 2: //已关注
      case 3: //相互关注
        return colorTextSecondary; //friends
      default:
        return colorTextSecondary;
    }
  }
}
