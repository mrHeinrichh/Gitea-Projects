import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_cell.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class MomentMyPostsView extends GetView<MomentMyPostsController>
    with TickerProviderMixin {
  const MomentMyPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: GestureDetector(
        onTap: controller.outsideTap,
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: <Widget>[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Obx(
                  () => Container(
                    height: max(
                      0.0,
                      MediaQuery.of(context).size.height -
                          controller.overlayBgHeight.value,
                    ),
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Expanded(
                    child: CustomScrollView(
                      controller: controller.scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        /// Cover
                        SliverToBoxAdapter(child: buildCover(context)),

                        if (controller.userId == objectMgr.userMgr.mainUser.uid)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: headerWidget(context),
                            ),
                          ),

                        SliverPadding(
                          padding: EdgeInsets.only(
                            top: controller.userId ==
                                    objectMgr.userMgr.mainUser.uid
                                ? 0.0
                                : 50,
                          ),
                          sliver: Obx(
                            () => SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      /// Showing the year when the post is not in the same year as the previous post
                                      if (index != 0 &&
                                          !controller.isSameYear(
                                            controller.postList[index].post!
                                                .createdAt,
                                            controller.postList[index - 1].post!
                                                .createdAt,
                                          ))
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 0,
                                            top: 0,
                                            bottom: 10,
                                          ),
                                          child: Text(
                                            DateFormat.y(
                                              Localizations.localeOf(
                                                Get.context!,
                                              ).toString(),
                                            ).format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                controller.postList[index].post!
                                                    .createdAt!,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                      MomentMyPostsCell(
                                        key: ValueKey(
                                          controller.postList[index].hashCode,
                                        ),
                                        momentPost: controller.postList[index],
                                        index: index,
                                        isShowDate: controller.isShowingDate(
                                          controller
                                              .postList[index].post!.createdAt,
                                          index == 0
                                              ? 0
                                              : controller.postList[index - 1]
                                                  .post!.createdAt,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                childCount: controller.postList.length,
                              ),
                            ),
                          ),
                        ),

                        /// when no posts.
                        SliverToBoxAdapter(
                          child: Obx(
                            () => controller.postList.isEmpty &&
                                    !controller.isLoading.value
                                ? Container(
                                    height: MediaQuery.of(Get.context!)
                                            .size
                                            .height *
                                        0.15,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0,
                                    ),
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        controller.userId ==
                                                objectMgr.userMgr.mainUser.uid
                                            ? Text(
                                                localized(momentMyPostsEmpty),
                                                style:
                                                    jxTextStyle.textStyleBold14(
                                                  color: colorTextSecondary,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                textAlign: TextAlign.center,
                                              )
                                            : Text(
                                                localized(
                                                  momentMyFriendPostsEmpty,
                                                ),
                                                style:
                                                    jxTextStyle.textStyleBold14(
                                                  color: colorTextSecondary,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),

                        /// loading when no cache
                        SliverToBoxAdapter(
                          child: Obx(
                            () => controller.postList.isEmpty &&
                                    controller.isLoading.value
                                ? Container(
                                    height: MediaQuery.of(Get.context!)
                                            .size
                                            .height *
                                        0.2,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            backgroundColor: Colors.transparent,
                                            color: colorTextPlaceholder,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          localized(momentPostLoading),
                                          style: jxTextStyle.textStyleBold14(
                                            color: colorTextSecondary,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),

                        /// NoMoreWidget divider
                        SliverToBoxAdapter(
                          child: Obx(
                            () => !controller.hasMore.value &&
                                    controller.postList.isNotEmpty
                                ? buildNoMoreWidget(context)
                                : const SizedBox(),
                          ),
                        ),

                        /// placeholder
                        SliverToBoxAdapter(
                          child: Container(
                            height: 80,
                            color: Colors.transparent,
                            child: const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ///ActionBar
              Obx(
                () => AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  top: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: PrimaryAppBar(
                    isBackButton: true,
                    withBackTxt: false,
                    backButtonColor: controller.appBarIconInvert.value
                        ? colorTextPrimary
                        : colorWhite,
                    systemOverlayStyle: !controller.appBarIconInvert.value
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark,
                    bgColor: colorBackground
                        .withOpacity(controller.appBarOpacity.value),
                    elevation: 0.0,
                    centerTitle: true,
                    titleWidget: Opacity(
                      opacity: controller.appBarOpacity.value,
                      child: Text(
                        controller.userId == objectMgr.userMgr.mainUser.uid
                            ? localized(momentMyPosts)
                            : controller.getUserNickName(controller.userId),
                        style: jxTextStyle.textStyleBold17(color: Colors.black),
                      ),
                    ),
                    trailing: controller.userId ==
                            objectMgr.userMgr.mainUser.uid
                        ? <Widget>[
                            GestureDetector(
                              onTap: controller.onGoNotification,
                              child: OpacityEffect(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        controller.appBarIconInvert.value
                                            ? 'assets/svgs/moment_notification_outline.svg'
                                            : 'assets/svgs/chat_info_mute.svg',
                                        width: 24,
                                        height: 24,
                                        color: controller.appBarIconInvert.value
                                            ? colorTextPrimary
                                            : colorWhite,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),

              ///Loading
              Positioned(
                top: 0,
                left: 0,
                child: RepaintBoundary(
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: SlideTransition(
                        position: controller.slideAnimation(this),
                        child: RotationTransition(
                          turns: controller.loadingAnimation(this),
                          child: SvgPicture.asset(
                            'assets/svgs/moments_loader.svg',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCover(BuildContext context) {
    return Obx(() {
      return SizedBox(
        height: controller.MOMENT_COVER_HEIGHT,
        width: MediaQuery.of(context).size.width,
        child: GestureDetector(
          onTap: controller.onCoverTap,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: controller.MOMENT_COVER_HEIGHT,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                //封面
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                child: controller.coverPath.value.isEmpty
                    ? Image.asset(
                        'assets/images/moment_cover.jpeg',
                        alignment: Alignment.topCenter,
                        width: MediaQuery.of(context).size.width,
                        height: controller.MOMENT_COVER_HEIGHT,
                        fit: BoxFit.fitWidth,
                      )
                    : RemoteImage(
                        key: ValueKey(controller.coverPath.value),
                        src: controller.coverPath.value,
                        width: MediaQuery.of(context).size.width,
                        height: controller.MOMENT_COVER_HEIGHT,
                        fit: BoxFit.cover,
                        mini: Config().dynamicMin,
                      ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  height: 70.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                right: 16.0,
                child: Opacity(
                  //名稱頭像
                  opacity: controller.headOpacity.value,
                  child: Row(
                    key: const ValueKey('not_moving_cover'),
                    children: <Widget>[
                      Transform.translate(
                        key: const ValueKey('not_moving_cover'),
                        offset: const Offset(0.0, 20.0),
                        child: Row(
                          key: const ValueKey<int>(1),
                          // Provide a unique key for the Row
                          children: <Widget>[
                            NicknameText(
                              uid: controller.userId,
                              color: colorWhite,
                              fontSize: MFontSize.size16.value,
                              fontWeight: FontWeight.w600,
                              isTappable: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 10.0),
                            GestureDetector(
                              onTap: ()=>controller.routeToChat(),
                              child: ForegroundOverlayEffect(
                                  overlayColor: colorTextPrimary.withOpacity(0.3),
                                  radius: BorderRadius.circular(80.0),
                                  child:CustomAvatar.normal(
                                    controller.userId,
                                    size: 80.0,
                                    headMin: Config().headMin,
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.userId == objectMgr.userMgr.mainUser.uid)
                Align(
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      reverseDuration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.linear,
                      switchOutCurve: Curves.linear,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: controller.isClickingCover.value
                          ? GestureDetector(
                              key: const ValueKey('is_moving_cover'),
                              onTapDown: (details) =>
                                  controller.onCoverTapDown(details),
                              onTap: () =>
                                  controller.changeCoverAction(context),
                              child: ForegroundOverlayEffect(
                                onPointerUp: () =>
                                    controller.onCoverPointerUp(),
                                overlayColor: colorTextPrimary.withOpacity(0.4),
                                radius: BorderRadius.circular(60.0),
                                child: Container(
                                  width: 100.0,
                                  height: 100.0,
                                  alignment: Alignment.bottomRight,
                                  decoration: const BoxDecoration(
                                    color: Color(
                                        0x66000000), // Set the background color
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/svgs/camera_icon2.svg',
                                      width: 63.48,
                                      height: 56.96,
                                      fit: BoxFit.fill,
                                      colorFilter: const ColorFilter.mode(
                                        colorWhite,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox()),
                )
            ],
          ),
        ),
      );
    });
  }

  Widget headerWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.22,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: buildDateText(context),
            ),
            InkWell(
              onTap: controller.onCreateTab,
              child: OpacityEffect(
                child: Container(
                  width: 80,
                  height: 80,
                  color: colorBackground3,
                  child: SvgPicture.asset(
                    'assets/svgs/add.svg',
                    height: 28,
                    width: 28,
                    color: colorGrey,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ),
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: SizedBox(height: 64, child: Text("")),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget buildDateText(BuildContext context) {
    DateTime now = DateTime.now();
    List<TextSpan> ts = [];
    if (AppLocalizations(objectMgr.langMgr.currLocale).isMandarin()) {
      ts.add(
        TextSpan(
          text: localized(myChatToday),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          //   style: jxTextStyle.textStyle20()
        ),
      );
    } else {
      ts.add(
        TextSpan(
          children: [
            TextSpan(
              text: now.day.toString(),
              style: TextStyle(
                fontSize: MFontSize.size24.value,
                fontWeight: MFontWeight.bold4.value,
                color: colorTextPrimary,
              ),
            ),
            TextSpan(
              text: " ",
              style: TextStyle(
                fontSize: 8,
                fontWeight: MFontWeight.bold4.value,
                color: colorTextPrimary,
              ),
            ),
            TextSpan(
              text: controller.monthAbbreviations[now.month - 1],
              style: jxTextStyle.textStyleBold10(
                fontWeight: MFontWeight.bold5.value,
              ),
            ),
          ],
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: ts,
      ),
    );
  }

  Widget buildNoMoreWidget(BuildContext context) {
    return Container(
      height: 50.0,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      color: colorWhite,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 24.0,
            child: Divider(
              color: momentBorderColor,
              thickness: 0.5,
            ),
          ),
          Container(
            width: 4.0,
            height: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: const BoxDecoration(
              color: momentBorderColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 24.0,
            child: Divider(
              color: momentBorderColor,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

mixin TickerProviderMixin on GetView<MomentMyPostsController>
    implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

class CustomBouncingScrollPhysics extends BouncingScrollPhysics {
  const CustomBouncingScrollPhysics({super.parent});

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  /// This is done by reducing the ratio of the scroll effect output vs the
  /// scroll gesture input.
  ///
  /// This factor starts at 0.52 and progressively becomes harder to overscroll
  /// as more of the area past the edge is dragged in (represented by an increasing
  /// `overscrollFraction` which starts at 0 when there is no overscroll).
  @override
  double frictionFactor(double overscrollFraction) {
    return 0.30 * pow(1 - overscrollFraction, 2);
  }

  @override
  CustomBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart = max(
      clampDouble(position.minScrollExtent - position.pixels, 0.0, 150),
      0.0,
    );
    final double overscrollPastEnd =
        max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = max(overscrollPastStart, overscrollPastEnd);

    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension,
          )
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    if (overscrollPast == 150.0) {
      return 0.0;
    }

    if (easing && decelerationRate == ScrollDecelerationRate.fast) {
      return direction * offset.abs();
    }
    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
    double extentOutside,
    double absDelta,
    double gamma,
  ) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }
}
