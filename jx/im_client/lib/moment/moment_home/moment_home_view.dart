import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/sticker/emoji_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/component/custom_indicator.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_home/moment_cell.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MomentHomeView extends GetView<MomentHomeController>
    with TickerProviderMixin {
  const MomentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item = AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.light,
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
                CustomIndicator(
                  edgeOffset: -50.0,
                  displacement: 100.0,
                  onRefresh: () async {
                    await controller.getPost();
                  },
                  backgroundColor: Colors.transparent,
                  indicatorBuilder: (context, controller) {
                    return FadeTransition(
                      opacity: controller,
                      child: RotationTransition(
                        turns: controller,
                        child: SvgPicture.asset(
                          'assets/svgs/moments_loader.svg',
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: CustomScrollView(
                          controller: controller.scrollController,
                          physics: const _CustomBouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          slivers: [
                            /// cover
                            SliverToBoxAdapter(child: buildCover(context)),

                            ///notification
                            SliverToBoxAdapter(
                              child: Obx(() {
                                if (controller.isSkeletonLoading.value &&
                                    !controller
                                        .isSkeletonAnimationFinish.value) {
                                  return const SizedBox();
                                } else {
                                  return controller
                                              .notificationStrongCount.value >
                                          0
                                      ? buildMomentNotification(context)
                                      : Container(
                                          color: colorWhite,
                                          height: 44.0,
                                        );
                                }
                              }),
                            ),

                            ///moment cell
                            Obx(() {
                              return SliverList.builder(
                                itemCount: (controller.isSkeletonLoading.value && !controller.isSkeletonAnimationFinish.value)
                                        ? (MediaQuery.of(context).size.height / (controller.skeletonHeight + (MediaQuery.of(context).size.width * 0.4))).ceil()
                                        : controller.postList.length,
                                itemBuilder: (BuildContext context, int index)
                                {
                                  Widget item = const SizedBox();
                                  if (!(controller.isSkeletonLoading.value &&
                                      !controller
                                          .isSkeletonAnimationFinish.value)) {
                                    item = Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        MomentCell(
                                          key: ValueKey(
                                            controller.postList[index].hashCode,
                                          ),
                                          index: index,
                                          momentPost:
                                          controller.postList[index],
                                        ),
                                        if (index !=
                                            (controller.postList.length - 1))
                                          const CustomDivider(
                                            thickness: 0.5,
                                            color: momentBorderColor,
                                          ),
                                      ],
                                    );
                                  }

                                  item = AnimatedSwitcher(
                                    duration:
                                    const Duration(milliseconds: 300),
                                    reverseDuration:
                                    const Duration(milliseconds: 300),
                                    child: (controller
                                        .isSkeletonLoading.value &&
                                        !controller
                                            .isSkeletonAnimationFinish
                                            .value)
                                        ? Skeletonizer(
                                      effect: const ShimmerEffect(
                                        baseColor: colorBackground,
                                        highlightColor: colorWhite,
                                        begin: Alignment.centerLeft,
                                        // Start from the left
                                        end: Alignment.centerRight,
                                        // End at the right
                                        duration: Duration(seconds: 2),
                                      ),
                                      child: index == 0
                                          ? Column(
                                        children: <Widget>[
                                          Container(
                                            height: 44,
                                          ),
                                          buildSkeleton(context),
                                        ],
                                      )
                                          : buildSkeleton(context),
                                    )
                                        : item,
                                  );
                                  return item;
                                },
                              );
                            }),

                            ///no more
                            SliverToBoxAdapter(
                              child: Obx(
                                () => controller.postList.isEmpty &&
                                        !((controller.isSkeletonLoading.value &&
                                            !controller
                                                .isSkeletonAnimationFinish
                                                .value))
                                    ? Container(
                                        height: MediaQuery.of(Get.context!)
                                                .size
                                                .height *
                                            0.7,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32.0,
                                        ),
                                        color: Colors.white,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              localized(momentNoMomentTitle),
                                              style:
                                                  jxTextStyle.textStyleBold17(
                                                color: colorTextPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              localized(momentNoMomentDesc),
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
                            SliverToBoxAdapter(
                              child: Obx(
                                () => !controller.hasMore.value &&
                                        controller.postList.isNotEmpty
                                    ? buildNoMoreWidget(context)
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ///input frame
                      Obx(
                        () => ClipRect(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 233),
                            alignment: Alignment.bottomCenter,
                            curve: Curves.easeOut,
                            heightFactor: !controller.isCommentInputExpand.value
                                ? 0.0
                                : 1.0,
                            child: assetInput(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ///appBar
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: PrimaryAppBar(
                      withBackTxt: false,
                      onPressedBackBtn: () {
                        Get.back();
                      },
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
                      titleWidget: Text(
                        localized(moment),
                        style: jxTextStyle.textStyleBold17(
                          color: Colors.black.withOpacity(
                            controller.appBarOpacity.value,
                          ),
                        ),
                      ),
                      trailing: <Widget>[
                        GestureDetector(
                          onTap: controller.onCreateTab,
                          child: OpacityEffect(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: SvgPicture.asset(
                                'assets/svgs/add.svg',
                                width: 24.0,
                                height: 24.0,
                                colorFilter: ColorFilter.mode(
                                  controller.appBarIconInvert.value
                                      ? colorTextPrimary
                                      : colorWhite,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                ///fixed loader
                Positioned(
                  top: 0,
                  left: 0,
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
              ],
            ),
          ),
        ));
    if (Platform.isAndroid) {
      item = WillPopScope(
        onWillPop: () async {
          return true; // Return true to allow the pop action
        },
        child: item,
      );
    }
    return item;
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
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.linear,
                child: controller.coverPath.value.isEmpty
                    ? Image.asset(
                        'assets/images/moment_cover.jpeg',
                        alignment: Alignment.topCenter,
                        width: MediaQuery.of(context).size.width,
                        height: controller.MOMENT_COVER_HEIGHT,
                        fit: BoxFit.cover,
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
                  opacity: controller.headOpacity.value,
                  child: Row(
                    key: const ValueKey('not_moving_cover'),
                    children: <Widget>[
                      Transform.translate(
                        key: const ValueKey('not_moving_cover'),
                        offset: const Offset(0.0, 20.0),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          alignment: Alignment.centerRight,
                          child: Row(
                            key: const ValueKey<int>(1),
                            // Provide a unique key for the Row
                            children: <Widget>[
                              Expanded(
                                child: NicknameText(
                                  uid: objectMgr.userMgr.mainUser.uid,
                                  color: colorWhite,
                                  fontSize: MFontSize.size16.value,
                                  fontWeight: FontWeight.w600,
                                  isTappable: false,
                                  maxLine: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () => controller.onMyPostsTap(
                                  objectMgr.userMgr.mainUser.uid,
                                ),
                                child: ForegroundOverlayEffect(
                                  overlayColor:
                                      colorTextPrimary.withOpacity(0.3),
                                  radius: BorderRadius.circular(80.0),
                                  child: CustomAvatar.user(
                                    objectMgr.userMgr.mainUser,
                                    size: 80.0,
                                    headMin: Config().headMin,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    reverseDuration: const Duration(milliseconds: 100),
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
                            onTap: () => controller.changeCoverAction(context),
                            child: ForegroundOverlayEffect(
                              onPointerUp: () => controller.onCoverPointerUp(),
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

  Widget buildMomentNotification(BuildContext context) {
    if (controller.notificationDetailList.isEmpty) return const SizedBox();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        top: 44.0,
      ),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: controller.onNotificationTap,
        child: OpacityEffect(
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: momentNotificationBg,
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomAvatar.normal(
                  controller.notificationDetailList.first.content?.userId ?? 0,
                  size: 30.0,
                  borderRadius: 100.0,
                  headMin: Config().headMin,
                ),
                const SizedBox(width: 12.0),
                Text(
                  localized(
                    momentNotificationNewMessage,
                    params: [
                      controller.notificationStrongCount.value.toString(),
                    ],
                  ),
                  style: jxTextStyle.textStyle14(
                    color: colorWhite,
                  ),
                ),
                const SizedBox(width: 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget assetInput(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeOut,
          width: double.infinity,
          color: colorBackground,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Stack(
                    children: <Widget>[
                      GetBuilder(
                        init: controller,
                        id: 'input_text_field',
                        builder: (_) {
                          return TextField(
                            contextMenuBuilder: textMenuBar,
                            autocorrect: false,
                            enableSuggestions: false,
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.left,
                            maxLines: 10,
                            minLines: 1,
                            focusNode: controller.inputFocusNode,
                            controller: controller.inputController,
                            keyboardType: TextInputType.multiline,
                            scrollPhysics: const ClampingScrollPhysics(),
                            maxLength: 4096,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4096),
                            ],
                            cursorColor: momentThemeColor,
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 16.0,
                              color: Colors.black,
                              height: 1.25,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: (controller.commentRepliedUserId !=
                                          null &&
                                      controller.commentRepliedUserId != 0)
                                  ? "${localized(chatOptionsReply)} ${objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(controller.commentRepliedUserId!))}"
                                  : localized(chatInputting),
                              hintStyle: const TextStyle(
                                fontSize: 16.0,
                                color: colorTextSupporting,
                                fontFamily: appFontfamily,
                              ),
                              isDense: true,
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: const BorderSide(
                                  style: BorderStyle.none,
                                  width: 0,
                                ),
                              ),
                              isCollapsed: true,
                              counterText: '',
                              contentPadding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                                right: 8 + 24.0,
                                left: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8.0,
                        bottom: 6.0,
                        child: buildEmojiWidget(context),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    controller.hasText.value ? controller.onCommentPost : null,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 6.0,
                    right: 6.0,
                    top: 6.0,
                    bottom: 8.0,
                  ),
                  child: Obx(
                    () => OpacityEffect(
                      child: Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: controller.hasText.value &&
                                  !controller.isSendingPost.value
                              ? momentThemeColor
                              : colorTextPlaceholder,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: SvgPicture.asset(
                          'assets/svgs/send_arrow.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        buildEmojiPanel(context),
      ],
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

  Widget buildEmojiWidget(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.onEmojiClick,
      child: OpacityEffect(
        child: Container(
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svgs/${controller.showFaceView.value ? 'input_keyboard' : 'emoji'}.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  Widget buildEmojiPanel(BuildContext context) {
    return AnimatedContainer(
      color: colorBackground,
      duration: const Duration(milliseconds: 233),
      curve: Curves.easeOut,
      height:
          controller.showFaceView.value || controller.inputFocusNode.hasFocus
              ? controller.getKeyboardHeight
              : 0,
      child: Column(
        children: <Widget>[
          Expanded(
            child: controller.showFaceView.value
                ? EmojiComponent(
                    onEmojiClick: (String emoji) {
                      controller.addEmoji(emoji);
                    },
                  )
                : const SizedBox(),
          ),
          Container(
            color: colorSurface,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(
              top: 12.0,
              bottom: 12.0 + MediaQuery.of(context).viewPadding.bottom,
              right: 16.0,
              left: 16.0,
            ),
            child: GestureDetector(
              onTap: controller.onTextDeleteTap,
              onLongPress: controller.onTextDeleteLongPress,
              onLongPressEnd: controller.onTextDeleteLongPressEnd,
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/svgs/delete_input.svg',
                  fit: BoxFit.fill,
                  colorFilter: const ColorFilter.mode(
                    colorTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Bone.circle(
                size: 40,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 3.0),
                      child: Bone.button(
                        width: (MediaQuery.of(context).size.width * 0.3) * 0.3,
                        height: 8.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
                      child: Row(
                        children: [
                          Bone.button(
                            width:
                                (MediaQuery.of(context).size.width * 0.3) * 0.6,
                            height: 8.0,
                          ),
                          const SizedBox(width: 10.0),
                          Bone.button(
                            width:
                                (MediaQuery.of(context).size.width * 0.3) * 0.3,
                            height: 8.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Bone.button(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.width * 0.4,
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 3.0,
                        bottom: 3.0,
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Bone.button(
                              width: (MediaQuery.of(context).size.width * 0.3) *
                                  0.35,
                              height: 8.0,
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Bone.button(
                              width: 32,
                              height: 8.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ],
          ),
          const CustomDivider(
            thickness: 0.5,
            color: momentBorderColor,
          )
        ],
      ),
    );
  }
}

class _CustomBouncingScrollPhysics extends BouncingScrollPhysics {
  const _CustomBouncingScrollPhysics({super.parent});

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
    return 0.35 * pow(1 - overscrollFraction, 2);
  }

  @override
  _CustomBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomBouncingScrollPhysics(parent: buildParent(ancestor));
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

mixin TickerProviderMixin on GetView<MomentHomeController>
    implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
