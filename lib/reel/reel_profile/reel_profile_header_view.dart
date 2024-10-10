import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelProfileHeaderView extends SliverPersistentHeaderDelegate {
  final BuildContext context;
  final ReelProfile? profile;
  final int userId;
  final Function()? onBack;
  final bool showBack;

  ReelProfileHeaderView(
    this.context, {
    this.profile,
    this.onBack,
    this.showBack = true,
    required this.userId,
  });

  @override
  double get minExtent => 44 + MediaQuery.of(context).padding.top;

  @override
  double get maxExtent => MediaQuery.of(context).size.height * 0.23;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    double percent = (shrinkOffset / maxExtent) * 100;
    bool isExpand = percent > 55 ? false : true;

    return Obx(
      () => SizedBox(
        height: maxExtent,
        child: Stack(
          children: [
            /// 背景图片
            Positioned.fill(
              child: Image.asset(
                'assets/images/reel_profile_header_background.png',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: maxExtent,
              ),
            ),

            /// Overlay
            Positioned.fill(
              child: ColoredBox(
                color: colorBackground.withOpacity(percent / 100),
              ),
            ),

            /// Header
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedCrossFade(
                duration: kThemeAnimationDuration,
                crossFadeState: isExpand
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: showBack,
                        child: GestureDetector(
                          onTap: () {
                            if (onBack != null) onBack!();
                          },
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
                                width: 8,
                                height: 16,
                                padding: EdgeInsets.only(right: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AnimatedOpacity(
                            duration: kThemeAnimationDuration,
                            opacity: 1 - percent / 100,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: colorWhite,
                                shape: BoxShape.circle,
                              ),
                              child: ReelProfileAvatar(
                                profileSrc: profile?.profilePic.value,
                                userId: userId,
                                size: 100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReelAuthorName(name: profile?.name.value,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                secondChild: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 35),
                        child: Text(
                          profile?.name.value ?? "",
                          style: jxTextStyle.textStyleBold17(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Visibility(
                        visible: showBack,
                        child: Positioned(
                          left: 0,
                          child: CustomLeadingIcon(
                            withBackTxt: false,
                            buttonOnPressed: () {
                              if (onBack != null) onBack!();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                firstCurve: Curves.easeInOutCubic,
                secondCurve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(ReelProfileHeaderView oldDelegate) => true;
}

class ReelAuthorName extends StatefulWidget {
  const ReelAuthorName({
    super.key,
    this.name,
  });

  final String? name;

  @override
  State<ReelAuthorName> createState() => _ReelAuthorNameState();
}

class _ReelAuthorNameState extends State<ReelAuthorName>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context1) {
    super.build(context);
    return Text(
      widget.name ?? "",
      style: TextStyle(
        fontSize: 20,
        color: colorWhite,
        fontWeight: MFontWeight.bold6.value,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(2, 2),
            blurRadius: 8,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
