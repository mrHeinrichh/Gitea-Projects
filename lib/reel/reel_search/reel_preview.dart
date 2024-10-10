import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
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
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class ReelPreview extends StatefulWidget {
  final ReelPost post;
  final int? userId;
  final int index;
  final int currentPage;
  final bool commentHasFocus;

  final TencentVideoStreamMgr streamMgr;
  final Function()? onReturn;
  final Function()? onReturnFromSave;
  final (RxBool, RxBool) Function() transferParams;

  const ReelPreview({
    super.key,
    required this.index,
    required this.post,
    required this.streamMgr,
    required this.currentPage,
    required this.transferParams,
    required this.commentHasFocus,
    this.userId,
    this.onReturn,
    this.onReturnFromSave,
  });

  @override
  State<ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<ReelPreview>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.currentPage == widget.index;

  RxInt currentSecond = 0.obs;
  RxBool isDisposing = false.obs;
  late Rx<ReelPost> data;
  late ReelController reelController;
  late RxBool _isScrolling;
  late RxBool _actualScrolling;

  late TencentVideoStreamMgr videoStreamMgr;
  late StreamSubscription videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;
  final RxBool _hasStartedPlaying = false.obs;

  RxBool isLikedTap = false.obs;
  RxBool isFavoriteTap = false.obs;
  RxBool isFollowTap = false.obs;
  RxBool isDoubleTapLiked = false.obs;

  RxBool isExpendTxt = false.obs;
  RxBool isTxtOverflowing = false.obs;

  final RxBool _inOverallComment = false.obs;

  //點讚的動畫位置與動畫存放列表
  final animations = <AnimationPosition>[].obs;
  final tapCounter = 0.obs;
  Timer? tapTimer;
  late bool isComboTap = false;
  final int comboTime = 300;
  late bool isComboFlowEnd = false; //經歷連擊flow,且為結束的最後一擊

  bool _isCommentActive = false; // 評論彈窗狀態

  String txt = "";
  double txtWidth = 260.w;
  String descTagsTxt = "";

  final RxDouble _verticalAdjustments = 0.0.obs;
  final RxDouble _horizontalAdjustments = 0.0.obs;
  final RxDouble _commentVerticalAdjustments = 0.0.obs;
  final RxDouble _commentHorizontalAdjustments = 0.0.obs;
  final RxDouble _actualWidth = 0.0.obs;
  final RxDouble _actualHeight = 0.0.obs;
  final RxDouble _commentActualWidth = 0.0.obs;
  final RxDouble _commentActualHeight = 0.0.obs;

  double _tempVerticalAdjustments = 0.0;
  double _tempHorizontalAdjustments = 0.0;
  double _tempActualWidth = 0.0;
  double _tempActualHeight = 0.0;

  final RxDouble _bottomControllerHeight = 0.0.obs;

  late TextSpan tags;

  final Rxn<ReelCommentController> _tempReelCommentController =
      Rxn<ReelCommentController>();

  FocusNode commentFocusNode = FocusNode();
  final commentTextEditingController = TextEditingController();

  FocusNode reelViewCommentFocusNode = FocusNode();
  final reelViewCommentTextEditingController = TextEditingController();

  bool _isControllerPlaying = false;

  @override
  void initState() {
    super.initState();

    reelController = Get.find<ReelController>();
    _inOverallComment.value = widget.commentHasFocus;
    final (pageScroll, actualScroll) = widget.transferParams();
    _isScrolling = pageScroll;
    _actualScrolling = actualScroll;
    videoStreamMgr = widget.streamMgr;
    videoStreamSubscription =
        videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);

    data = widget.post.obs;

    TencentVideoConfig config = TencentVideoConfig(
      url: data.value.file.value!.path.value!,
      width: data.value.file.value!.width.value!,
      height: data.value.file.value!.height.value!,
      thumbnail: data.value.thumbnail.value!,
      thumbnailGausPath: data.value.gausPath.value,
      hasBottomSafeArea: false,
      hasTopSafeArea: false,
      autoplay: videoStreamMgr.currentIndex.value ==
              widget.index,
      isLoop: true,
    );

    _bottomControllerHeight.value =
        52 + MediaQuery.of(navigatorKey.currentContext!).padding.bottom;
    TencentVideoStream stream =
        videoStreamMgr.addController(config, index: widget.index);

    _calculateStreamAdjustments(stream);
    currentVideoStream.value = stream;

    txt = data.value.description.value ?? "";
    descTagsTxt = reelUtils.getDescTagsTxtSize(
      descTxt: txt,
      tags: data.value.tags,
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
      fromTagPage: ReelTagBackFromEnum.reelPreview,
      tags: data.value.tags,
      onTapTag: () {
        currentVideoStream.value?.controller.pause();
      },
      onBack: () {
        currentVideoStream.value?.controller.play();
      },
    );
  }

  @override
  void dispose() {
    isDisposing.value = true;
    videoStreamSubscription.cancel();

    super.dispose();
  }


  _calculateStreamAdjustments(TencentVideoStream item) {
    final int width = item.controller.config.width;
    final int height = item.controller.config.height;
    final (
      double actualWidth,
      double actualHeight,
      double horizontalAdjustments,
      double verticalAdjustments
    ) = reelController.getVideoWidthAndHeight(
      width,
      height,
      _bottomControllerHeight.value,
    );
    _horizontalAdjustments.value = horizontalAdjustments;
    _verticalAdjustments.value = verticalAdjustments;
    _actualWidth.value = actualWidth;
    _actualHeight.value = actualHeight;

    final (
      double widthOnExpand,
      double heightOnExpand,
      double horizontal,
      double _
    ) = reelController.getVideoWidthAndHeight(width, height, 500);

    _commentHorizontalAdjustments.value = horizontal;
    _commentVerticalAdjustments.value = 500 - _bottomControllerHeight.value;
    _commentActualWidth.value = widthOnExpand;
    _commentActualHeight.value = heightOnExpand;
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != widget.index) return;
    if (currentVideoStream.value != item) {
      _calculateStreamAdjustments(item);
    }

    if (item.state.value == TencentVideoState.DISPOSED) {
      currentVideoStream.value = null;
      currentVideoState.value = TencentVideoState.INIT;
      return;
    }

    currentVideoStream.value = item;
    currentVideoState.value = item.state.value;

    if (widget.index == widget.currentPage &&
        item.state.value == TencentVideoState.PREPARED) {
      item.controller.play();
    }

    if (item.state.value == TencentVideoState.PLAYING) {
      _hasStartedPlaying.value = true;
    }
  }

  @override
  void didUpdateWidget(ReelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commentHasFocus != widget.commentHasFocus) {
      _inOverallComment.value = widget.commentHasFocus;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_inOverallComment.value) {
      //如果只是单键盘，才另外算
      final (
        double actualWidth,
        double actualHeight,
        double horizontalAdjustments,
        double _
      ) = reelController.getVideoWidthAndHeight(
        currentVideoStream.value?.controller.config.width ?? 0,
        currentVideoStream.value?.controller.config.height ?? 0,
        MediaQuery.of(context).viewInsets.bottom,
      );
      _tempActualWidth = actualWidth;
      _tempActualHeight = actualHeight;
      _tempHorizontalAdjustments = horizontalAdjustments;
      _tempVerticalAdjustments = MediaQuery.of(context).viewInsets.bottom;
    }

    super.build(context);
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          //video
          Obx(
            () => AnimatedPositioned(
              curve: _inOverallComment.value ? Curves.linear : Curves.easeInOut,
              duration: const Duration(milliseconds: 100),
              top: _inOverallComment.value
                  ? 0
                  : _tempReelCommentController.value != null
                      ? 0
                      : -_verticalAdjustments.value,
              left: _inOverallComment.value
                  ? _tempHorizontalAdjustments
                  : _tempReelCommentController.value != null
                      ? _commentHorizontalAdjustments.value
                      : -_horizontalAdjustments.value,
              right: _inOverallComment.value
                  ? _tempHorizontalAdjustments
                  : _tempReelCommentController.value != null
                      ? _commentHorizontalAdjustments.value
                      : -_horizontalAdjustments.value,
              bottom: _inOverallComment.value
                  ? _tempVerticalAdjustments
                  : _tempReelCommentController.value != null
                      ? _commentVerticalAdjustments.value
                      : -_verticalAdjustments.value,
              child: Container(
                width: _inOverallComment.value
                    ? _tempActualWidth
                    : _tempReelCommentController.value != null
                        ? _commentActualWidth.value
                        : _actualWidth.value,
                height: _inOverallComment.value
                    ? _tempActualHeight
                    : _tempReelCommentController.value != null
                        ? _commentActualHeight.value
                        : _actualHeight.value,
                alignment: Alignment.center,
                child: currentVideoStream.value != null
                    ? TencentVideoPlayer(
                        controller: currentVideoStream.value!.controller,
                        index: widget.index,
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
          ),

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
                    currentVideoStream.value?.controller.togglePlayState();
                  }
                });

                //最初點擊兩下加一個動畫,後續每增加一擊加一個動畫
                if (tapCounter.value == 2 || tapCounter.value > 2) {
                  // 未點讚,雙擊點讚; 已經是讚的話,不需要雙擊點讚
                  if (!(data.value.isLiked.value ?? false) &&
                      tapCounter.value == 2) {
                    isLikedTap.value = true;
                    ReelLikeMgr.instance.updateLike(
                      [data.value],
                      !(data.value.isLiked.value ?? false),
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
              onLongPress: () {
                currentVideoStream.value?.controller.setRate(2.0);
              },
              onLongPressUp: () {
                currentVideoStream.value?.controller.setRate(1.0);
              },
              onLongPressEnd: (details) {
                currentVideoStream.value?.controller.setRate(1.0);
              },
              child: Obx(
                () => Stack(
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
          ),

          Positioned.fill(
            child: Obx(
              () => Offstage(
                offstage: !_inOverallComment.value,
                child: const AbsorbPointer(),
              ),
            ),
          ),

          //用於影片說明展開底部要深色漸層
          Obx(
            () => Visibility(
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
          ),

          Positioned.fill(
            top: 44.0,
            bottom: 5.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Spacer(),
                Obx(
                  () => Opacity(
                    opacity: _isScrolling.value ? 0.5 : 1.0,
                    child: Row(
                      children: <Widget>[
                        const Spacer(),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                videoStreamMgr.enteringBusinessPausePhase = true;
                                _isControllerPlaying =
                                    currentVideoStream.value?.state.value ==
                                        TencentVideoState.PLAYING;
                                currentVideoStream.value?.controller.pause();
                                if (data.value.creator.value?.id.value == widget.userId) {
                                  Get.back();
                                  widget.onReturn?.call();
                                  return;
                                }

                                if (objectMgr.userMgr.isMe(
                                    data.value.creator.value?.id.value ?? 0)) {
                                  Get.toNamed(
                                    RouteName.reelMyProfileView,
                                    preventDuplicates: false,
                                    arguments: {
                                      "onBack": () {
                                        Navigator.of(context).pop();
                                        videoStreamMgr.enteringBusinessPausePhase = false;
                                        if (_isControllerPlaying) {
                                          currentVideoStream.value?.controller
                                              .play();
                                        }
                                      },
                                    },
                                  );
                                } else {
                                  Get.toNamed(
                                    RouteName.reelProfileView,
                                    preventDuplicates: false,
                                    arguments: {
                                      "userId":
                                          data.value.creator.value!.id.value!,
                                      "onBack": () {
                                        Navigator.of(context).pop();
                                        videoStreamMgr.enteringBusinessPausePhase = false;
                                        if (_isControllerPlaying) {
                                          currentVideoStream.value?.controller
                                              .play();
                                        }
                                        // _commentCounter.value = post.commentCount ?? 0;
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
                                if (!(data.value.isLiked.value ?? false)) {
                                  isLikedTap.value = true;
                                }

                                ReelLikeMgr.instance.updateLike(
                                  [data.value],
                                  !(data.value.isLiked.value ?? false),
                                );
                              },
                              child: Obx(
                                () => ReelLikeHeart(
                                  post: data.value,
                                  isLikedTap: isLikedTap.value,
                                  onCompositionLoaded: (duration) {
                                    Future.delayed(duration, () {
                                      isLikedTap.value = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!_isCommentActive) {
                                  _isCommentActive = true;
                                  showBottomComment(context, data.value);
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
                                if (!(data.value.isSaved.value ?? false)) {
                                  isFavoriteTap.value = true;
                                }
                                ReelSaveMgr.instance.updateSave(
                                  [data.value],
                                  !(data.value.isSaved.value ?? false),
                                  onTapSavedSuccessfullyCallback: () {
                                    _isControllerPlaying =
                                        currentVideoStream.value?.state.value ==
                                            TencentVideoState.PLAYING;
                                    currentVideoStream.value?.controller
                                        .pause();
                                    videoStreamMgr.enteringBusinessPausePhase = true;

                                    if (widget.onReturnFromSave != null) {
                                      widget.onReturnFromSave?.call();
                                      return;
                                    }

                                    Get.toNamed(
                                      RouteName.reelMyProfileView,
                                      preventDuplicates: false,
                                      arguments: {
                                        "selectedTab": 2,
                                        "onBack": () {
                                          Navigator.of(context).pop();
                                          videoStreamMgr.enteringBusinessPausePhase = false;
                                          if (_isControllerPlaying) {
                                            currentVideoStream.value?.controller
                                                .play();
                                          }
                                        },
                                      },
                                    );
                                  },
                                );
                              },
                              child: Obx(
                                () => ReelSaveWidget(
                                  post: data.value,
                                  isFavoriteTap: isFavoriteTap.value,
                                  onCompositionLoaded: (duration) {
                                    Future.delayed(duration, () {
                                      isFavoriteTap.value = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => reelController.doForward(data.value),
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
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Obx(() {
              return Opacity(
                opacity: _isScrolling.value ? 0.5 : 1.0,
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
                                          data.value.creator.value?.id.value ??
                                              0,
                                      name: data.value.creator.value?.name
                                              .value ??
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
              );
            }),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              return Container(
                height: 20,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: [
                    Offstage(
                      offstage:
                          currentVideoState.value != TencentVideoState.LOADING,
                      child: Lottie.asset(
                        'assets/lottie/video_line_animation.json',
                        height: 10,
                      ),
                    ),
                    if (_hasStartedPlaying.value &&
                        !_actualScrolling.value &&
                        currentVideoStream.value != null &&
                        currentVideoState.value == TencentVideoState.PAUSED)
                      TencentVideoSlider(
                        controller: currentVideoStream.value!.controller,
                        showTime: false,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget friendIcon() {
    return Obx(
      () => Padding(
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
                  userId: widget.post.creator.value!.id.value ?? 0,
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
                    widget.post.creator.value!.followUser(widget.post.creator.value!.id.value!);
                  }
                },
                child: followIconHandler(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget followIconHandler() {
    return Obx(
      () => ReelFollowWidget(
        creator: widget.post.creator.value!,
        isFollowTap: isFollowTap.value,
        onCompositionLoaded: (duration) {
          Future.delayed(duration, () {
            isFollowTap.value = false;
          });
        },
      ),
    );
  }

  void showBottomComment(context, ReelPost post) async {
    ReelCommentController commentController = reelNavigationMgr.addCommentView(
        currentVideoStream.value?.controller, post);
    // commentController.commentBtnSheetActive.value = true;
    _tempReelCommentController.value = commentController;
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShowCommentBottomView(
          key: ValueKey(post.id.value!),
          controller: commentController,
        );
      },
    ).then((value) {
      _tempReelCommentController.value = null;
      commentController.commentBtnSheetActive.value = false;
      commentController.isCommentExpand.value = false;
      reelNavigationMgr.onCloseComment(commentController);
      _isCommentActive = false;
    });
  }
}
