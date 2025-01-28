import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/reel_avatar.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelMyProfileEdit extends StatefulWidget {
  final ReelMyProfileController controller;

  const ReelMyProfileEdit({
    super.key,
    required this.controller,
  });

  @override
  State<ReelMyProfileEdit> createState() => _ReelMyProfileEditState();
}

class _ReelMyProfileEditState extends State<ReelMyProfileEdit> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.tempAvatar.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    double circleDiameter = 100.0;

    return GestureDetector(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Image.asset(
              'assets/images/reel_profile_header_background.png',
              fit: BoxFit.cover,
              width: width,
              height: height * 0.23,
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: OpacityEffect(
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.32),
                        ),
                        child: const CustomImage(
                          'assets/svgs/Back.svg',
                          color: colorWhite,
                          width: 9,
                          height: 17,
                          padding: EdgeInsets.only(right: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Second container overlap top
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * 0.8,
                width: width,
                decoration: const BoxDecoration(
                  color: colorBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(
                              () => RichText(
                                text: TextSpan(
                                  text: '${localized(reelCompleteRate)} ',
                                  style: jxTextStyle.textStyleBold14(),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: widget.controller.reelProfile.value
                                                  .profilePercentage ==
                                              ''
                                          ? "100%"
                                          : widget.controller.reelProfile.value
                                              .profilePercentage,
                                      style: TextStyle(color: themeColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(child: _buildProfileSettingsList()),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBtn(),
                  ],
                ),
              ),
            ),
            // circle avatar
            Positioned(
              top: (height / 5) -
                  (circleDiameter / 2), // To overlap in the middle
              left: (width / 2) - (circleDiameter / 2),
              child: _buildProfileAvatar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () {
          widget.controller.showPickPhotoOption(context);
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: colorWhite,
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Offstage(
                  offstage: widget.controller.tempAvatar.value == null,
                  child: widget.controller.tempAvatar.value != null
                      ? Image.file(
                          widget.controller.tempAvatar.value!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : ReelAvatar(
                          uid: widget.controller.userId.value,
                          size: 100,
                          headMin: Config().headMin,
                          fontSize: 24.0,
                          shouldAnimate: false,
                        ),
                ),
                Offstage(
                  offstage: (widget.controller.tempAvatar.value != null),
                  child: ReelProfileAvatar(
                    profileSrc:
                        widget.controller.reelProfile.value.profilePic.value,
                    userId: widget.controller.userId.value,
                    size: 100,
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withOpacity(0.5),
                    child: OpacityEffect(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CustomImage(
                            'assets/svgs/camera_icon2.svg',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localized(reelChangeAvatar),
                            style: jxTextStyle.textStyle14(color: colorWhite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSettingsList() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomRoundContainer(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              _buildListItem(
                title: localized(myEditName),
                rightTitle: widget.controller.reelProfile.value.name.value,
                onClick: () async => Get.toNamed(
                  RouteName.reelEditPage,
                  arguments: {
                    'controller': widget.controller,
                    'type': ReelEditTypeEnum.nickname,
                  },
                ),
              ),
              separateDivider(),
              _buildListItem(
                title: localized(bio),
                rightTitle:
                    notBlank(widget.controller.reelProfile.value.bio.value)
                        ? widget.controller.reelProfile.value.bio.value!
                        : localized(reelMyBioDefault),
                onClick: () async => Get.toNamed(
                  RouteName.reelEditPage,
                  arguments: {
                    'controller': widget.controller,
                    'type': ReelEditTypeEnum.bio,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    String? rightTitle,
    required Function() onClick,
  }) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: ForegroundOverlayEffect(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: jxTextStyle.textStyle16(color: colorTextPrimary),
              ),
              const SizedBox(width: 27),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    textAlign: TextAlign.justify,
                    rightTitle ?? '',
                    style: jxTextStyle.textStyle16(
                      color: colorTextPrimary.withOpacity(0.48),
                    ),
                  ),
                ),
              ),
              CustomImage(
                'assets/svgs/right_arrow_thick.svg',
                color: colorTextPrimary.withOpacity(0.48),
                padding: const EdgeInsets.only(top: 3, left: 5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBtn() {
    return SafeArea(
      top: false,
      child: Obx(
        () => widget.controller.isLoading.value
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: BallCircleLoading(
                    radius: 10,
                    ballStyle: BallStyle(
                      size: 4,
                      color: themeColor,
                      ballType: BallType.solid,
                      borderWidth: 1,
                      borderColor: themeColor,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: CustomButton(
                  text: localized(saveButton),
                  callBack: () => widget.controller.onSave(),
                ),
              ),
      ),
    );
  }
}
