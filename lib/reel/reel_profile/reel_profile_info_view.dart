import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_bottom_sheet.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_info_item.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_button.dart';

class ReelProfileInfoView extends StatefulWidget {
  final bool isMe;
  final ReelProfile profile;
  final int userId;
  final ReelMyProfileController? controller;

  const ReelProfileInfoView({
    super.key,
    this.isMe = false,
    required this.profile,
    required this.userId,
    this.controller,
  });

  @override
  State<ReelProfileInfoView> createState() => _ReelProfileInfoViewState();
}

class _ReelProfileInfoViewState extends State<ReelProfileInfoView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> showCustomBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '狼性仔',
                    style: jxTextStyle.textStyleBold16(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    localized(reelGetCountLiked, params: ['${888}']),
                    style: jxTextStyle.textStyle14(color: colorTextSecondary),
                  ),
                ),
                CustomButton(
                  text: localized(reelConfirm),
                  callBack: () {
                    navigator?.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return Container(
          color: colorBackground,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReelProfileInfoItem(
                      count: widget.profile.totalLikesReceived.value ?? 0,
                      label: localized(paramLike),
                    ),
                    const SizedBox(width: 16),
                    ReelProfileInfoItem(
                      count: widget.profile.totalFolloweeCount.value ?? 0,
                      label: localized(paramFollowee),
                    ),
                    const SizedBox(width: 16),
                    ReelProfileInfoItem(
                      count: widget.profile.totalFollowerCount.value ?? 0,
                      label: localized(paramFollower),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                widget.profile.relationship != ProfileRelationship.stranger
                    ? Text(
                  notBlank(widget.profile.bio.value)
                      ? widget.profile.bio.value!
                      : widget.isMe
                      ? localized(reelMyBioDefault)
                      : localized(reelDefaultBio),
                  style: jxTextStyle.textStyle14(
                    color: widget.isMe &&
                        !notBlank(
                          widget.profile.bio.value,
                        )
                        ? colorTextSecondary
                        : colorTextPrimary,
                  ),
                )
                    : const SizedBox(),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    switch (widget.profile.relationship) {
                      case ProfileRelationship.friend:
                      case ProfileRelationship.followee:
                        reelBtmSheet.showReelBottomFollowSheet(
                          ctx: context,
                          unFollowTap: () {
                            widget.profile.unfollowUser(widget.userId);
                            Get.back();
                          },
                        );
                        break;
                      case ProfileRelationship.follower:
                      case ProfileRelationship.stranger:
                        widget.profile.followUser(widget.userId);
                        break;
                      case ProfileRelationship.self:
                        Get.toNamed(
                          RouteName.reelMyProfileEdit,
                          arguments: {"controller": widget.controller},
                        );
                        break;
                      default:
                        break;
                    }
                  },
                  child: ForegroundOverlayEffect(
                    radius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ProfileRs.canFollowWithRs(widget.profile.rs
                            .value ?? 0)
                            ? themeColor
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      width: double.infinity,
                      child:
                      widget.profile.relationship == ProfileRelationship.self
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localized(myEditButton),
                            style: jxTextStyle.textStyleBold17(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.profile.profilePercentage,
                            style: jxTextStyle.textStyleBold17(
                              color: colorTextSecondary,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ProfileRs.canFollowWithRs(
                              widget.profile.rs.value ?? 0)) ...{
                            Text(
                              localized(subscribeButton),
                              style: jxTextStyle.textStyleBold17(
                                color: colorWhite,
                              ),
                            ),
                          } else
                            ...{
                              Text(
                                localized(subscribedButton),
                                style: jxTextStyle.textStyleBold17(
                                  color: colorTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/svgs/arrow_drop_down_rounded.svg',
                                width: 20,
                                height: 20,
                                fit: BoxFit.fill,
                              ),
                            },
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      });
  }
}
