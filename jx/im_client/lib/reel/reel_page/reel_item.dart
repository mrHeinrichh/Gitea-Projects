import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_item_widget.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_bottom_view.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_feature_item.dart';
import 'package:jxim_client/reel/reel_page/reel_follow_widget.dart';
import 'package:jxim_client/reel/reel_page/reel_like_heart.dart';
import 'package:jxim_client/reel/reel_page/reel_like_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_name.dart';
import 'package:jxim_client/reel/reel_page/reel_save_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_save_widget.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ReelItem extends StatefulWidget {
  final ReelPost post;
  final int index;
  final ReelController controller;

  const ReelItem({
    super.key,
    required this.post,
    required this.index,
    required this.controller,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with AutomaticKeepAliveClientMixin {
  // @override
  @override
  bool get wantKeepAlive => widget.controller.currentPage == widget.index;

  RxBool isLikedTap = false.obs;
  RxBool isFavoriteTap = false.obs;
  RxBool isFollowTap = false.obs;

  RxBool isExpendTxt = false.obs;
  RxBool isTxtOverflowing = false.obs;

  //點讚的動畫位置與動畫存放列表
  final animations = <AnimationPosition>[].obs;
  final tapCounter = 0.obs;
  Timer? tapTimer;
  late bool isComboTap = false;
  final int comboTime = 300;
  late bool isComboFlowEnd = false; //經歷連擊flow,且為結束的最後一擊
  final RxBool _hasStartedPlaying = false.obs;

  bool _isCommentActive = false; // 評論彈窗狀態

  String txt = "";
  double txtWidth = 260.w;
  String descTagsTxt = "";
  late TextSpan tags;
  late StreamSubscription videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  final RxDouble _bottomControllerHeight = 0.0.obs;
  final RxDouble _verticalAdjustments = 0.0.obs;
  final RxDouble _horizontalAdjustments = 0.0.obs;
  final RxDouble _commentVerticalAdjustments = 0.0.obs;
  final RxDouble _commentHorizontalAdjustments = 0.0.obs;
  final RxDouble _actualWidth = 0.0.obs;
  final RxDouble _actualHeight = 0.0.obs;
  final RxDouble _commentActualWidth = 0.0.obs;
  final RxDouble _commentActualHeight = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _bottomControllerHeight.value =
        52 + MediaQuery.of(navigatorKey.currentContext!).padding.bottom;
    videoStreamSubscription = widget.controller.videoStreamMgr.onStreamBroadcast
        .listen(_onVideoUpdates);
    txt = widget.post.description.value ?? "";
    descTagsTxt = reelUtils.getDescTagsTxtSize(
      descTxt: txt,
      tags: widget.post.tags,
    );
    reelUtils.hasTextOverflow(
      text: descTagsTxt,
      style: jxTextStyle.textStyle15(
        color: Colors.white,
      ),
      maxWidth: txtWidth,
      isTxtOverflowing: (isOverflowing) {
        isTxtOverflowing.value = isOverflowing;
      },
    );
    tags = reelUtils.tagsWidget(
      fromTagPage: ReelTagBackFromEnum.reelItem,
      tags: widget.post.tags,
      onTapTag: () {
        widget.controller.onNavigation();
      },
    );
  }

  _onVideoUpdates(TencentVideoStream item) {
    // if (item.pageIndex != currentPage) return;
    if (item.pageIndex != widget.index) return;

    if (item.state.value == TencentVideoState.DISPOSED) {
      currentVideoStream.value = null;
      currentVideoState.value = TencentVideoState.INIT;
      return;
    }

    if (currentVideoStream.value != item) {
      _calculateStreamAdjustments(item);
    }
    currentVideoStream.value = item;
    currentVideoState.value = item.state.value;
    if (widget.index == 0) {
      widget.controller.isLoading.value = false; //流接收到第一片数据的信息，才可做为下载完毕
    }

    if (item.state.value == TencentVideoState.PREPARED &&
        widget.index == widget.controller.currentPage) {
      item.controller.play();
    }
    if (item.state.value == TencentVideoState.PLAYING) {
      _hasStartedPlaying.value = true;
    }
  }

  _calculateStreamAdjustments(TencentVideoStream item) {
    final int width = item.controller.config.width;
    final int height = item.controller.config.height;
    final (
      double actualWidth,
      double actualHeight,
      double horizontalAdjustments,
      double verticalAdjustments
    ) = widget.controller.getVideoWidthAndHeight(
      width,
      height,
      _bottomControllerHeight.value,
    );
    _horizontalAdjustments.value = horizontalAdjustments;
    _verticalAdjustments.value = verticalAdjustments;
    _actualWidth.value = actualWidth;
    _actualHeight.value = actualHeight;

    final (double widthOnExpand, double heightOnExpand, double horizontal, _) =
        widget.controller.getVideoWidthAndHeight(width, height, 500);

    _commentHorizontalAdjustments.value = horizontal;
    _commentVerticalAdjustments.value = 500 - _bottomControllerHeight.value;
    _commentActualWidth.value = widthOnExpand;
    _commentActualHeight.value = heightOnExpand;
  }

  @override
  dispose() {
    tapTimer?.cancel();
    videoStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Video
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            top: (widget.controller.tempReelCommentController.value != null)
                ? 0
                : -_verticalAdjustments,
            left: (widget.controller.tempReelCommentController.value != null)
                ? _commentHorizontalAdjustments.value
                : -_horizontalAdjustments.value,
            right: (widget.controller.tempReelCommentController.value != null)
                ? _commentHorizontalAdjustments.value
                : -_horizontalAdjustments.value,
            bottom: (widget.controller.tempReelCommentController.value != null)
                ? _commentVerticalAdjustments.value
                : -_verticalAdjustments,
            child: Container(
              width: (widget.controller.tempReelCommentController.value != null)
                  ? _commentActualWidth.value
                  : _actualWidth.value,
              height:
                  (widget.controller.tempReelCommentController.value != null)
                      ? _commentActualHeight.value
                      : _actualHeight.value,
              alignment: Alignment.center,
              child: currentVideoStream.value != null
                  ? TencentVideoPlayer(
                      controller: currentVideoStream.value!.controller,
                      index: widget.index,
                      hasAspectRatio: true, //评论模式或者横屏视频都需要控制长宽比
                      overlay: Positioned.fill(
                        child: GestureDetector(
                          onTap: currentVideoStream
                              .value!.controller.togglePlayState,
                        ),
                      ),
                    )
                  : Container(),
            ),
          ),

          if (!widget.controller.isEnteringScreen.value)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  ///有特殊需求,所以onTap一律在onTapDown下面指定位置做
                  // 取得點擊的手指落下位置
                  final tapPosition = details.localPosition;

                  if (tapCounter > 0) isComboTap = true; //判定為連擊開始

                  tapCounter.value++;

                  //計時器來判定是不是連擊
                  tapTimer?.cancel();
                  tapTimer = Timer(Duration(milliseconds: comboTime), () {
                    if (isComboTap) isComboFlowEnd = true;
                    tapCounter.value = 0; //不是連擊
                  });

                  // 等待comboTime毫秒後執行其他操作
                  Future.delayed(Duration(milliseconds: comboTime), () {
                    if (isComboFlowEnd) {
                      //連擊結束的最後一下
                      isComboFlowEnd = false;
                      isComboTap = false;
                    } else if (!isComboTap) {
                      ///有特殊需求,所以onTap一律在這裡做
                      widget.controller.onVideoTap();
                    }
                  });

                  //最初點擊兩下加一個動畫,後續每增加一擊加一個動畫
                  if (tapCounter.value == 2 || tapCounter.value > 2) {
                    // 未點讚,雙擊點讚; 已經是讚的話,不需要雙擊點讚
                    if (!(widget.post.isLiked.value ?? false) &&
                        tapCounter.value == 2) {
                      isLikedTap.value = true;
                      ReelLikeMgr.instance.updateLike(
                        [widget.post],
                        !(widget.post.isLiked.value ?? false),
                      );
                    }

                    //在動畫列表加入點讚動畫
                    animations.add(
                      AnimationPosition(
                        position: tapPosition,
                        animation: reelItemWidget.buildAnimation(),
                      ),
                    );
                  }
                },
                onLongPress: widget.controller.onVideoLongPress,
                onLongPressUp: () =>
                    widget.controller.onVideoLongPressEnd(null),
                onLongPressEnd: widget.controller.onVideoLongPressEnd,
                child: Stack(
                  children: [
                    for (var animationPosition in animations)
                      Positioned(
                        left: animationPosition.position.dx - 100,
                        top: animationPosition.position.dy - 125,
                        child: animationPosition.animation,
                      ),
                  ],
                ),
              ),
            ),

          //用於影片說明展開底部要深色漸層
          if (!widget.controller.isEnteringScreen.value)
            Visibility(
              visible: isExpendTxt.value && isTxtOverflowing.value,
              child: Positioned.fill(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  //這邊是用於展開後,點擊屏幕即可觸發關閉
                  onTap: () => isExpendTxt.value = !isExpendTxt.value,
                  child: reelUtils.reelGradientBox(),
                ),
              ),
            ),

          // Details
          if (!widget.controller.isEnteringScreen.value)
            Positioned.fill(
              top: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(),
                  Opacity(
                    opacity: widget.controller.isScrolling.value ? 0.5 : 1.0,
                    child: Row(
                      children: <Widget>[
                        const Spacer(),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                widget.controller.onNavigation();

                                if (objectMgr.userMgr.isMe(
                                    widget.post.creator.value!.id.value!)) {
                                  widget.controller.onBottomTap(2);
                                } else {
                                  Get.toNamed(
                                    RouteName.reelProfileView,
                                    preventDuplicates: false,
                                    arguments: {
                                      "userId":
                                          widget.post.creator.value!.id.value!,
                                      "onBack": (toDismiss) {
                                        widget.controller.onReturnNavigation();
                                      },
                                    },
                                  );
                                }
                              },
                              child: friendIcon(),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                if (!(widget.post.isLiked.value ?? false)) {
                                  //點讚
                                  isLikedTap.value = true;

                                  // widget.controller.onLikedClick(widget.reelData,
                                  //     updateDelay: true);
                                }
                                ReelLikeMgr.instance.updateLike(
                                  [widget.post],
                                  !(widget.post.isLiked.value ?? false),
                                );
                              },
                              child: ReelLikeHeart(
                                post: widget.post,
                                isLikedTap: isLikedTap.value,
                                onCompositionLoaded: (duration) {
                                  Future.delayed(duration, () {
                                    isLikedTap.value = false;
                                  });
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!_isCommentActive) {
                                  _isCommentActive = true;
                                  showBottomComment(
                                    navigatorKey.currentContext!,
                                    widget.post,
                                  );
                                }
                              },
                              child: ReelFeatureItem(
                                type: ReelIconDataType.comment,
                                count: widget.post.commentCount.value ?? 0,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                if (!(widget.post.isSaved.value ?? false)) {
                                  //收藏
                                  isFavoriteTap.value = true;
                                }

                                ReelSaveMgr.instance.updateSave(
                                  [widget.post],
                                  !(widget.post.isSaved.value ?? false),
                                  onTapSavedSuccessfullyCallback: () {
                                    widget.controller
                                        .onBottomTap(2, nextSelected: 2);
                                  },
                                );
                              },
                              child: ReelSaveWidget(
                                post: widget.post,
                                isFavoriteTap: isFavoriteTap.value,
                                onCompositionLoaded: (duration) {
                                  Future.delayed(duration, () {
                                    isFavoriteTap.value = false;
                                  });
                                },
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  widget.controller.doForward(widget.post),
                              child: ReelFeatureItem(
                                type: ReelIconDataType.share,
                                count: widget.post.sharedCount.value ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (!widget.controller.isEnteringScreen.value)
            Positioned(
              left: 0,
              bottom: 0,
              child: Opacity(
                opacity: widget.controller.isScrolling.value ? 0.5 : 1.0,
                child: GestureDetector(
                  onTap: () => isExpendTxt.value = !isExpendTxt.value,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      right: 12.0,
                      bottom: 25.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: txtWidth,
                              child: Row(
                                children: [
                                  Text(
                                    "@",
                                    style: TextStyle(
                                      fontSize: MFontSize.size16.value,
                                      fontWeight: MFontWeight.bold6.value,
                                      overflow: TextOverflow.ellipsis,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Expanded(
                                    child: ReelProfileName(
                                      userId:
                                          widget.post.creator.value?.id.value ??
                                              0,
                                      name: widget
                                              .post.creator.value?.name.value ??
                                          "",
                                      fontSize: MFontSize.size16.value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            reelUtils.videoDescription(
                              txtWidth: txtWidth,
                              txt: txt,
                              tags: tags,
                              isExpendTxt: isExpendTxt,
                            ),
                          ],
                        ),
                        isTxtOverflowing.value
                            ? Text(
                                isExpendTxt.value
                                    ? localized(reelLess)
                                    : localized(reelMore),
                                style: jxTextStyle.textStyleBold15(
                                  color: Colors.white,
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (!widget.controller.isEnteringScreen.value)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 20,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: [
                    Offstage(
                      offstage: !widget.controller.isLoading.value,
                      child: Lottie.asset(
                        'assets/lottie/video_line_animation.json',
                        height: 10,
                      ),
                    ),
                    if (_hasStartedPlaying.value &&
                        !widget.controller.actualScrolling.value &&
                        currentVideoStream.value != null &&
                        currentVideoState.value == TencentVideoState.PAUSED)
                      TencentVideoSlider(
                        controller: currentVideoStream.value!.controller,
                        showTime: false,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget friendIcon() {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                  child: ReelProfileAvatar(
                    profileSrc: widget.post.creator.value!.profilePic.value,
                    userId: widget.post.creator.value!.id.value!,
                    size: 48,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (widget.post.creator.value!.canFollow) {
                      isFollowTap.value = true;
                      widget.post.creator.value!
                          .followUser(widget.post.creator.value!.id.value!);
                    }
                  },
                  child: followIconHandler(),
                ),
              ),
            ],
          ),
        ));
  }

  Widget followIconHandler() {
    return Obx(() {
      return ReelFollowWidget(
        creator: widget.post.creator.value!,
        isFollowTap: isFollowTap.value,
        onCompositionLoaded: (duration) {
          Future.delayed(duration, () {
            isFollowTap.value = false;
          });
        },
      );
    });
  }

  void showBottomComment(context, ReelPost post) {
    ReelCommentController commentController =
        reelNavigationMgr.addCommentView(widget.controller, post);
    // commentController.commentBtnSheetActive.value = true;
    widget.controller.tempReelCommentController.value = commentController;
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        if (widget.controller.tempReelCommentController.value == null) {
          return Container();
        }
        return ShowCommentBottomView(
          key: ValueKey(post.id),
          controller: widget.controller.tempReelCommentController.value!,
        );
      },
    ).then((value) {
      widget.controller.tempReelCommentController.value = null;
      commentController.commentBtnSheetActive.value = false;
      commentController.isCommentExpand.value = false;
      reelNavigationMgr.onCloseComment(commentController);
      _isCommentActive = false;
    });
  }
}
