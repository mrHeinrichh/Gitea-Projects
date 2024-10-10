import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:collection/collection.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_post_comment_view.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/reel/reel_page/video_volume_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart' as im_bottom;
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:lottie/lottie.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MomentMyPostViewerPage extends StatefulWidget {
  final int index; //點擊的MyPost index
  const MomentMyPostViewerPage({
    super.key,
    required this.index,
  });

  @override
  State<MomentMyPostViewerPage> createState() => _MomentMyPostViewerPageState();
}

//每次進來資料都是從MyPosts過來，沒有緩存，所以更新資料時，是UpdateMoment去更新MyPosts的緩存資料。
class _MomentMyPostViewerPageState extends State<MomentMyPostViewerPage>
    with SingleTickerProviderStateMixin {
  final int POST_ACTION_UPDATE = 0;
  final int POST_ACTION_DELETE = 1;

  late final PhotoViewPageController photoPageController;

  late MomentMyPostsController momentMyPostsController;

  final List<int> _mediaStartIndices = [];

  late AnimationController likeAnimationControllers;

  int currentAssetsIndex = 0; //全部貼文媒體的Index，
  int postsIndex = 0; //目前在哪一則貼文.
  int postTotalAssetsIndex = 0; //每則貼文的assets總數
  int postAssetsCurrentIndex = 1; //目前Preview的assets index

  bool hideActionBar = false;
  bool _hasLimitedVolume = false;

  //字体
  String appFontFamily = 'pingfang';

  Map<int, LoadStatus> loadedOriginMap = <int, LoadStatus>{};

  List<MomentPosts> postList = <MomentPosts>[];

  final List<MomentContentDetail> _allAssets = [];

  int get videoCacheRange => 1;
  TencentVideoStreamMgr? videoStreamMgr;
  StreamSubscription? videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();

  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  OverlayEntry? moreActionOE;

  GlobalKey moreActionKey = GlobalKey();

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  bool isSliding = false;

  bool _isControllerPlaying = false;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();
    objectMgr.momentMgr.on(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
    objectMgr.momentMgr.on(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);

    momentMyPostsController = Get.find<MomentMyPostsController>();
    postList.assignAll(momentMyPostsController.postList);

    int removedCount = 0;
    //remove posts.content.assets is null
    postList.removeWhere(
      (element) => (element.post!.content!.assets == null ||
          element.post!.content!.assets!.isEmpty),
    );

    for (int i = 0; i < widget.index; i++) {
      if (momentMyPostsController.postList[i].post!.content!.assets == null ||
          momentMyPostsController.postList[i].post!.content!.assets!.isEmpty) {
        removedCount++;
      }
    }

    postsIndex = widget.index - removedCount;

    configPost();

    photoPageController = PhotoViewPageController(
      initialPage: currentAssetsIndex,
      shouldIgnorePointerWhenScrolling: true,
    );

    postTotalAssetsIndex = postList[postsIndex].post!.content!.assets!.length;

    initVideoController();
    iniLoadMap();

    likeAnimationControllers = AnimationController(
      value: postList[postsIndex]
                  .likes!
                  .list
                  ?.contains(objectMgr.userMgr.mainUser.uid) ??
              false
          ? 1.0
          : 0.0,
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void iniLoadMap() {
    for (int i = 0; i < _allAssets.length; i++) {
      loadedOriginMap[i] = LoadStatus();
    }
  }

  @override
  void deactivate() {
    _closeMoreActionOE();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeMoreActionOE();
    releaseVideController();
    //postList 離開要對應回去更新資料momentMyPostsController.postList
    likeAnimationControllers.dispose();
    objectMgr.momentMgr.off(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
    objectMgr.momentMgr.off(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);

    WakelockPlus.disable();
    super.dispose();
  }

  void _closeMoreActionOE() {
    if (moreActionOE != null) {
      moreActionOE?.remove();
      moreActionOE?.dispose();
      moreActionOE = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => isHideAction(!hideActionBar),
            child: Stack(
              children: <Widget>[
                PhotoViewSlidePage(
                  slideAxis: SlideDirection.vertical,
                  slideType: SlideArea.wholePage,
                  slidePageBackgroundHandler: (Offset offset, Size pageSize) {
                    return isSliding ? Colors.transparent : Colors.black;
                  },
                  onSlidingPage:
                      (PhotoViewSlidePageState photoViewSlidePageState) {
                    pageSlidingStatus(photoViewSlidePageState.isSliding);
                  },
                  child: Stack(
                    children: [
                      PhotoViewGesturePageView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: photoPageController,
                        itemCount: _allAssets.length,
                        onPageChanged: onPageChange,
                        itemBuilder: (BuildContext context, int index) {
                          final asset = _allAssets[index];

                          /// Video area
                          if (asset.type.contains('video')) {
                            TencentVideoStream? s =
                                videoStreamMgr?.getVideoStream(index);
                            return DismissiblePage(
                                onDismissed: Navigator.of(context).pop,
                                direction: DismissiblePageDismissDirection.down,
                                child: Container(
                                  color: isSliding
                                      ? Colors.transparent
                                      : Colors.black,
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewPadding
                                        .bottom,
                                  ),
                                  child: Stack(
                                    children: <Widget>[
                                      s != null
                                          ? TencentVideoPlayer(
                                              key: ValueKey(asset.uniqueId),
                                              controller: s.controller,
                                              index: index,
                                              overlay: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: GestureDetector(
                                                      onTap:
                                                          Navigator.of(context)
                                                              .pop,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox(),
                                      Positioned.fill(
                                        child: GestureDetector(
                                            onTap: () =>
                                                isHideAction(!hideActionBar)
                                            // onTap: videoController[index]!.onVideoTap,
                                            ),
                                      ),
                                    ],
                                  ),
                                ));
                          }

                          /// Picture area
                          Size screenSize = MediaQuery.of(context).size;
                          return GestureDetector(
                            child: Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                ExtendedPhotoView(
                                  key: ValueKey(asset.url),
                                  src: asset.url,
                                  width: getAssetBoxFit(index) ==
                                              BoxFit.fitWidth &&
                                          asset.width < screenSize.width
                                      ? screenSize.width
                                      : asset.width.toDouble(),
                                  height: getAssetBoxFit(index) ==
                                              BoxFit.fitHeight &&
                                          asset.height < screenSize.height
                                      ? screenSize.height
                                      : asset.height.toDouble(),
                                  fit: getAssetBoxFit(index),
                                  constraint: const BoxConstraints.expand(),
                                  onLoadStateCallback: onThumbnailLoadCallback,
                                  mode: PhotoViewMode.gesture,
                                  noSimmerEffect: true,
                                ),
                                Obx(
                                  () => !(loadedOriginMap[index]!
                                          .isLoaded
                                          .value)
                                      ? ExtendedPhotoView(
                                          key: ValueKey(
                                            '${asset.url}_${Config().sMessageMin}',
                                          ),
                                          src: asset.url,
                                          width: getAssetBoxFit(index) ==
                                                      BoxFit.fitWidth &&
                                                  asset.width < screenSize.width
                                              ? screenSize.width
                                              : asset.width.toDouble(),
                                          height: getAssetBoxFit(index) ==
                                                      BoxFit.fitHeight &&
                                                  asset.height <
                                                      screenSize.height
                                              ? screenSize.height
                                              : asset.height.toDouble(),
                                          fit: getAssetBoxFit(index),
                                          mini: Config().sMessageMin,
                                          mode: PhotoViewMode.gesture,
                                          noSimmerEffect: true,
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///Top layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  top: hideActionBar || isSliding
                      ? -(MediaQuery.of(context).size.height / 20) * 1.6
                      : 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      color: isSliding
                          ? Colors.transparent
                          : const Color(0x99000000),
                      width: MediaQuery.of(context).size.width,
                      height: (MediaQuery.of(context).size.height / 20) * 1.6,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  ///當使用者從MyPosted->刪除貼文後，返回MyPosted頁面，需要通知MyPosted頁面刷新
                                  Navigator.of(context).pop();
                                },
                                child: OpacityEffect(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back_ios_new_outlined,
                                        color: colorWhite,
                                      ),
                                      Center(
                                        child: Text(
                                          localized(buttonBack),
                                          style: jxTextStyle.textStyle17(
                                            color: colorWhite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    FormatTime.getTime(
                                        postList[postsIndex].post!.createdAt! ~/
                                            1000),
                                    style: jxTextStyle.textStyle17(
                                      color: colorWhite,
                                    ),
                                  ),
                                  if (postTotalAssetsIndex > 1)
                                    Text(
                                      //picture number
                                      "$postAssetsCurrentIndex/$postTotalAssetsIndex",
                                      style: jxTextStyle.textStyle13(
                                        color: const Color(0x99FFFFFF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _moreActionPopup();
                                    },
                                    child: OpacityEffect(
                                      child: SvgPicture.asset(
                                        key: moreActionKey,
                                        'assets/svgs/moment_preview_more_action.svg',
                                        width: 24,
                                        height: 24,
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
                  ),
                ),

                ///The description of the post on the bottom.
                if (!isSliding &&
                    postList[postsIndex].post!.content!.text!.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final textSpan = TextSpan(
                          text: postList[postsIndex].post!.content!.text!,
                          style: jxTextStyle.textStyle15(color: colorWhite),
                        );

                        final textPainter = TextPainter(
                          text: textSpan,
                          maxLines: 6,
                          textDirection: TextDirection.ltr,
                        );

                        textPainter.layout(
                            maxWidth:
                                constraints.maxWidth - 36); // 減去左右 padding

                        final textHeight = textPainter.size.height;

                        return IgnorePointer(
                          child: Container(
                            height: textHeight + 65,
                            width: MediaQuery.of(context).size.width,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/moments/gradient_black_down_to_up.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                            margin: EdgeInsets.only(
                                bottom: hideActionBar
                                    ? 0
                                    : _allAssets[currentAssetsIndex]
                                            .type
                                            .contains('video')
                                        ? ObjectMgr.screenMQ!.size.height * 0.05
                                        : ObjectMgr.screenMQ!.size.height *
                                            0.04),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 18, right: 18, bottom: 8),
                                child: Text(
                                  postList[postsIndex].post!.content!.text!,
                                  style: jxTextStyle.textStyle15(
                                      color: colorWhite),
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ///Bottom layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  bottom: hideActionBar || isSliding
                      ? _allAssets[currentAssetsIndex].type.contains('video')
                          ? -ObjectMgr.screenMQ!.size.height * 0.05
                          : -ObjectMgr.screenMQ!.size.height * 0.042
                      : 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        /// Video tool
                        if (_allAssets[currentAssetsIndex]
                            .type
                            .contains('video'))
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              color: Colors.transparent,
                              child: _buildVideoBottomToolBar(),
                            ),
                          ),
                        Container(
                          color: const Color(0x99000000),
                          width: MediaQuery.of(context).size.width,
                          height: ObjectMgr.screenMQ!.size.height * 0.042,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      GestureDetector(
                                        onTap: onLikePost,
                                        child: OpacityEffect(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Lottie.asset(
                                                'assets/lottie/like-animation2_gray.json',
                                                controller:
                                                    likeAnimationControllers,
                                                width: 24.0,
                                                height: 24.0,
                                                animate: false,
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    left: postList[postsIndex]
                                                            .likes!
                                                            .list!
                                                            .isNotEmpty
                                                        ? 2
                                                        : 8),
                                                child: Center(
                                                  child: Text(
                                                    postList[postsIndex]
                                                            .likes!
                                                            .list!
                                                            .isNotEmpty
                                                        ? postList[postsIndex]
                                                            .likes!
                                                            .list!
                                                            .length
                                                            .toString()
                                                        : localized(momentLike),
                                                    style:
                                                        jxTextStyle.textStyle15(
                                                      color: const Color(
                                                          0x99FFFFFF),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _isControllerPlaying =
                                              currentVideoStream
                                                      .value?.state.value ==
                                                  TencentVideoState.PLAYING;
                                          currentVideoStream.value?.controller
                                              .pause();
                                          Get.to(
                                            () => MomentMyPostCommentView(
                                                post: postList[postsIndex]),
                                          )?.then((value) {
                                            if (_isControllerPlaying) {
                                              currentVideoStream
                                                  .value?.controller
                                                  .play();
                                            }
                                          });
                                        },
                                        child: OpacityEffect(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/svgs/comment_outlined.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Color(0x99FFFFFF),
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    left: postList[postsIndex]
                                                            .commentDetail!
                                                            .comments!
                                                            .isNotEmpty
                                                        ? 2
                                                        : 8),
                                                child: Center(
                                                  child: Text(
                                                    postList[postsIndex]
                                                            .commentDetail!
                                                            .comments!
                                                            .isNotEmpty
                                                        ? postList[postsIndex]
                                                            .commentDetail!
                                                            .comments!
                                                            .length
                                                            .toString()
                                                        : localized(
                                                            momentComment),
                                                    style:
                                                        jxTextStyle.textStyle15(
                                                      color: const Color(
                                                          0x99FFFFFF),
                                                    ),
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
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: goToDetailPage,
                                  child: OpacityEffect(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Center(
                                          child: Text(
                                            localized(momentDetail),
                                            style: jxTextStyle.textStyle15(
                                              color: const Color(0x99FFFFFF),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, right: 16),
                                          child: SvgPicture.asset(
                                            'assets/svgs/arrow_right.svg',
                                            width: 24.0,
                                            height: 24.0,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0x99FFFFFF),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
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

  void configPost({bool isDeleted = false}) {
    _allAssets.clear();
    _mediaStartIndices.clear();

    int currentIndex = 0;
    for (int i = 0; i < postList.length; i++) {
      var post = postList[i];
      _allAssets.addAll(post.post!.content!.assets!);
      if (postsIndex == i) {
        currentAssetsIndex = currentIndex;
        if (isDeleted) {
          currentAssetsIndex = _allAssets.length - 1;
        }
      }
      currentIndex += post.post!.content!.assets!.length;
      _mediaStartIndices.add(currentIndex);
    }
  }

  void initVideoController() {
    int postAssetsIndex = 0;
    int postIndex = 0;
    MomentPosts? temp;

    _allAssets.forEachIndexed((i, post) {
      temp ??= postList[postIndex];

      final asset = temp!.post!.content!.assets![postAssetsIndex];
      if (asset.type.contains('video')) {
        if (videoStreamMgr == null) {
          videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
          videoStreamSubscription =
              videoStreamMgr?.onStreamBroadcast.listen(_onVideoUpdates);
        }

        TencentVideoConfig config = TencentVideoConfig(
          url: asset.url,
          width: asset.width,
          height: asset.height,
          thumbnail: asset.cover,
          thumbnailGausPath: asset.gausPath,
          autoplay: i == currentAssetsIndex,
          hasBottomSafeArea: false,
          hasTopSafeArea: false,
          isLoop: true,
          type: ConfigType.saveMp4,
        );

        videoStreamMgr!.addController(config, index: i);

        if (i == currentAssetsIndex) {
          _preloadVideos(i);
        }
      }

      postAssetsIndex++;
      if (postAssetsIndex > temp!.post!.content!.assets!.length - 1) {
        postAssetsIndex = 0;
        postIndex++;
        temp = null;
      }
    });

    if (videoStreamMgr?.hasStream() ?? false) {
      _hasLimitedVolume = true;
      VolumePlayerService.sharedInstance.onClose();
      VideoVolumeManager.instance.limitVideoVolume();
    }
  }

  void releaseVideController() {
    videoStreamSubscription?.cancel();
    if (videoStreamMgr != null) {
      objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr!);
    }
    videoStreamMgr = null;
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != currentAssetsIndex) {
      return;
    }

    if (item.state.value == TencentVideoState.DISPOSED) {
      currentVideoStream.value = null;
      currentVideoState.value = TencentVideoState.INIT;
      return;
    }

    currentVideoStream.value = item;
    currentVideoState.value = item.state.value;
  }

  void isHideAction(bool isHide) {
    setState(() {
      hideActionBar = isHide;
    });
  }

  void pageSlidingStatus(bool aIsSliding) {
    if (isSliding != aIsSliding) {
      setState(() {
        isSliding = aIsSliding;
      });
    }
  }

  void goToDetailPage() {
    _isControllerPlaying =
        currentVideoStream.value?.state.value == TencentVideoState.PLAYING;
    currentVideoStream.value?.controller.pause();

    Get.toNamed(
      RouteName.momentDetail,
      arguments: {
        'detail': postList[postsIndex],
      },
    )?.then((value) {
      if (_isControllerPlaying) {
        currentVideoStream.value?.controller.play();
      }

      Map<String, dynamic> jsonResult = value ?? {};
      if (jsonResult['isDeleted'] ?? false) {
        int removeLength = postList[postsIndex].post!.content!.assets!.length;
        bool isVideo = postList[postsIndex]
            .post!
            .content!
            .assets![postAssetsCurrentIndex - 1]
            .type
            .contains('video');
        var post = postList.removeAt(postsIndex);
        updateMyPosts(POST_ACTION_DELETE, post);
        postsIndex = postsIndex - 1 < 0 ? 0 : postsIndex - 1;

        if (isVideo) {
          videoStreamMgr!.removeController(currentAssetsIndex);
        }
        videoStreamMgr!
            .realignIndex(currentAssetsIndex, reducingOffset: removeLength);

        configPost(isDeleted: true);

        postTotalAssetsIndex =
            postList[postsIndex].post!.content!.assets!.length;
        postAssetsCurrentIndex = postTotalAssetsIndex;

        videoStreamMgr?.currentIndex.value = currentAssetsIndex;
        _onVideoPageChange(currentAssetsIndex);
        photoPageController.jumpToPage(currentAssetsIndex);
        if (mounted) {
          setState(() {});
        }
      }
      checkLikeStatus();
    });
  }

  void onPageChange(int index) {
    if (currentAssetsIndex == index) return;

    iniLoadMap();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      currentAssetsIndex = index;
      videoStreamMgr?.currentIndex.value = currentAssetsIndex;
      _onVideoPageChange(index);

      if (mounted) setState(() {});
    });

    int previous = postsIndex;
    postsIndex =
        _mediaStartIndices.indexWhere((startIndex) => index < startIndex);

    if (previous != postsIndex) {
      postTotalAssetsIndex = postList[postsIndex].post!.content!.assets!.length;
      postAssetsCurrentIndex = previous > postsIndex ? postTotalAssetsIndex : 1;
      likeAnimationControllers.duration = const Duration(milliseconds: 10);
      postList[postsIndex]
                  .likes!
                  .list
                  ?.contains(objectMgr.userMgr.mainUser.uid) ??
              false
          ? likeAnimationControllers.forward()
          : likeAnimationControllers.reverse();
      likeAnimationControllers.duration = const Duration(milliseconds: 500);
    } else {
      currentAssetsIndex > index
          ? postAssetsCurrentIndex--
          : postAssetsCurrentIndex++;
    }
  }

  _onVideoPageChange(int index) {
    videoStreamMgr?.removeControllersOutOfRange(index, videoCacheRange);
    _preloadVideos(index);

    TencentVideoController? controller = videoStreamMgr?.getVideo(index);

    videoStreamMgr?.pausePlayingControllers(index);
    if (controller != null) {
      if (!_hasLimitedVolume) {
        _hasLimitedVolume = true;
        VolumePlayerService.sharedInstance.onClose();
        VideoVolumeManager.instance.limitVideoVolume();
      }
      controller.play();
    }
  }

  void _preloadVideos(int index) async {
    for (int i = index - videoCacheRange; i <= index + videoCacheRange; i++) {
      final (
        String url,
        String cover,
        String? gausPath,
        int width,
        int height
      ) = _getPreloadParams(i);
      if (url.isNotEmpty) {
        if (objectMgr.tencentVideoMgr.currentStreamMgr?.getVideoStream(i) ==
            null) {
          TencentVideoConfig config = TencentVideoConfig(
            url: url,
            thumbnail: cover,
            thumbnailGausPath: gausPath,
            width: width,
            height: height,
            isLoop: true,
            autoplay: i == currentAssetsIndex,
          );
          objectMgr.tencentVideoMgr.currentStreamMgr
              ?.addController(config, index: i);
        }
      }
    }
  }

  (String, String, String?, int, int) _getPreloadParams(int index) {
    if (index < 0) return ("", "", null, 0, 0);

    final asset = _allAssets[index];

    if (asset.type.contains('video')) {
      return (
        asset.url,
        asset.cover ?? "",
        asset.gausPath,
        asset.width,
        asset.height
      );
    }

    return ("", "", null, 0, 0);
  }

  void onThumbnailLoadCallback(PhotoViewLoadState? state, File? f) {
    String cachePath = f?.path.split("/").last ?? "";
    String originalUrl = _allAssets[currentAssetsIndex].url.split("/").last;
    if (state == PhotoViewLoadState.completed && cachePath == originalUrl) {
      bool isLoaded = loadedOriginMap[currentAssetsIndex]!.isLoaded.value;
      if (f != null && !isLoaded) {
        if (!loadedOriginMap[currentAssetsIndex]!.isShow) {
          loadedOriginMap[currentAssetsIndex]!.isShow = true;
          onFullImageLoaded(currentAssetsIndex);
        }
      }
    }
  }

  void onFullImageLoaded(int index) {
    Future.delayed(const Duration(milliseconds: 250), () {
      loadedOriginMap[index]!.isLoaded.value = true;
    });
  }

  void handleVibration() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate();
    }
  }

  void onLikePost() async {
    handleVibration();
    bool isLiked = postList[postsIndex]
        .likes!
        .list!
        .contains(objectMgr.userMgr.mainUser.uid);

    if (isLiked) {
      likeAnimationControllers.reverse();
    } else {
      likeAnimationControllers.forward();
    }

    objectMgr.momentMgr.onLikePost(postList[postsIndex].post!.id!, !isLiked);

    // 点赞成功
    isLiked = postList[postsIndex]
            .likes!
            .list
            ?.contains((objectMgr.userMgr.mainUser.uid)) ??
        false;

    if (isLiked) {
      postList[postsIndex].likes!.list!.remove(objectMgr.userMgr.mainUser.uid);
      postList[postsIndex].likes!.count =
          postList[postsIndex].likes!.count! - 1;
      objectMgr.momentMgr.updateMoment(postList[postsIndex]);
      return;
    }

    if (!isLiked) {
      postList[postsIndex].likes!.list!.add(objectMgr.userMgr.mainUser.uid);
      postList[postsIndex].likes!.count =
          postList[postsIndex].likes!.count! + 1;
      objectMgr.momentMgr.updateMoment(postList[postsIndex]);
      return;
    }
  }

  Widget photoLoadStateChanged(
    PhotoViewState state, {
    bool isTransition = false,
  }) {
    return switch (state.extendedImageLoadState) {
      PhotoViewLoadState.completed => isTransition
          ? FadeImageBuilder(child: state.completedWidget)
          : state.completedWidget,
      PhotoViewLoadState.failed => const SizedBox(),
      PhotoViewLoadState.loading =>
        const Center(child: CircularProgressIndicator()),
    };
  }

  Future<void> onForwardMessage(
      {bool fromChatInfo = false,
      bool fromMediaDetail = false,
      String? selectableText,
      MomentContentDetail? assetsMedia,
      int? media}) async {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ForwardContainer(
          showSaveButton: false,
          selectableText: selectableText,
          forwardMsg: [_onForwardMedia(assetsMedia!, media ?? 0)],
        );
      },
    ).whenComplete(() {});
  }

  Message _onForwardMedia(MomentContentDetail assetsMedia, int media) {
    final Message msg = Message();
    //media: 0->image,1->video
    if (media == 0) {
      msg.typ = messageTypeImage;
      MessageImage messageImage = MessageImage();
      messageImage.url = assetsMedia.url;
      messageImage.height = assetsMedia.height;
      messageImage.width = assetsMedia.width;
      messageImage.forward_user_id = objectMgr.userMgr.mainUser.uid;
      messageImage.forward_user_name = objectMgr.userMgr.mainUser.nickname;
      messageImage.gausPath = assetsMedia.gausPath ?? '';
      msg.content = jsonEncode(messageImage);
      msg.decodeContent(
        cl: msg.getMessageModel(msg.typ),
        v: jsonEncode(messageImage),
      );
    } else {
      msg.typ = messageTypeVideo;
      MessageVideo messageVideo = MessageVideo();
      messageVideo.url = assetsMedia.url;
      messageVideo.cover = assetsMedia.cover!;
      final duration =
          currentVideoStream.value?.controller.videoDuration.value ?? 0;
      messageVideo.second = (duration / 1000).round();
      messageVideo.height = assetsMedia.height;
      messageVideo.width = assetsMedia.width;
      messageVideo.forward_user_id = objectMgr.userMgr.mainUser.uid;
      messageVideo.forward_user_name = objectMgr.userMgr.mainUser.nickname;
      messageVideo.gausPath = assetsMedia.gausPath ?? '';
      msg.content = jsonEncode(messageVideo);
      msg.decodeContent(
        cl: msg.getMessageModel(msg.typ),
        v: jsonEncode(messageVideo),
      );
    }

    return msg;
  }

  Future<void> saveMessageMedia(
    BuildContext context,
    Message message, {
    bool isFromChatRoom = false,
  }) async {
    final (List<File?> cacheFileList, String? albumError) = await objectMgr
        .shareMgr
        .getShareFile(message, isFromChatRoom: isFromChatRoom);
    List<XFile> fileList = [];
    for (File? cacheFile in cacheFileList) {
      if (cacheFile != null && cacheFile.existsSync()) {
        fileList.add(XFile(cacheFile.path));
      }
    }
    if (fileList.isEmpty) {
      Toast.showToast(albumError ?? localized(toastSaveUnsuccessful));
    } else {
      final fileObj = fileList.first;
      saveMedia(fileObj.path);
    }
  }

  void saveMedia(String path, {bool isReturnPathOfIOS = false}) async {
    final result = await ImageGallerySaver.saveFile(
      path,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );

    if (result != null && result["isSuccess"]) {
      im_bottom.imBottomToast(
        Get.context!,
        title: localized(toastSaveSuccess),
        icon: im_bottom.ImBottomNotifType.saving,
        duration: 3,
      );
    } else {
      _onSaveFailToast();
    }
  }

  void _onSaveFailToast() {
    BotToast.removeAll(BotToast.textKey);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(toastTryLater),
          subTitle: localized(toastSaveUnsuccessfulWaitVideoDownload),
          confirmButtonColor: colorRed,
          cancelButtonColor: themeColor,
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonConfirm),
          cancelCallback: Navigator.of(context).pop,
          confirmCallback: () {},
        );
      },
    );
  }

  void _moreActionPopup() {
    final box = moreActionKey.currentContext!.findRenderObject() as RenderBox;
    void closeEntry() {
      moreActionOE?.remove();
      moreActionOE?.dispose();
      moreActionOE = null;
    }

    moreActionOE = createOverlayEntry(
      context,
      fakeTarget(moreActionKey), //targetWidget
      GestureDetector(
        //followWidget
        onTap: () {
          closeEntry();
        },
        child: Container(
          width: 220,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: colorWhite,
            border: Border(
              bottom: BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  closeEntry();
                  onForwardMessage(
                      assetsMedia: postList[postsIndex]
                          .post!
                          .content!
                          .assets![postAssetsCurrentIndex - 1],
                      media: postList[postsIndex]
                              .post!
                              .content!
                              .assets![postAssetsCurrentIndex - 1]
                              .type
                              .contains('video')
                          ? 1
                          : 0);
                },
                child: ForegroundOverlayEffect(
                  radius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0)),
                  overlayColor: const Color(0x33121212),
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 11,
                            bottom: 11,
                          ),
                          child: Text(
                            localized(forward),
                            style: jxTextStyle.textStyle17(color: Colors.black),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 16,
                            top: 11,
                            bottom: 11,
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/menu_forward.svg',
                            width: 24.0,
                            height: 24.0,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                color: momentBorderColor,
                height: 0.5,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  closeEntry();
                  saveMessageMedia(
                      context,
                      _onForwardMedia(
                        postList[postsIndex]
                            .post!
                            .content!
                            .assets![postAssetsCurrentIndex - 1],
                        postList[postsIndex]
                                .post!
                                .content!
                                .assets![postAssetsCurrentIndex - 1]
                                .type
                                .contains('video')
                            ? 1
                            : 0,
                      ));
                },
                child: ForegroundOverlayEffect(
                  radius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0)),
                  overlayColor: const Color(0x33121212),
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 11,
                            bottom: 11,
                          ),
                          child: postList[postsIndex]
                                  .post!
                                  .content!
                                  .assets![postAssetsCurrentIndex - 1]
                                  .type
                                  .contains('video')
                              ? Text(localized(chatOptionsSaveVideo),
                                  style: jxTextStyle.textStyle17(
                                      color: Colors.black))
                              : Text(
                                  localized(chatOptionsSaveImage),
                                  style: jxTextStyle.textStyle17(
                                      color: Colors.black),
                                ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 16,
                            top: 11,
                            bottom: 11,
                          ),
                          child: SvgPicture.asset(
                            "assets/svgs/menu_save.svg",
                            width: 24.0,
                            height: 24.0,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
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
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.bottomLeft,
      left: box.localToGlobal(Offset.zero).dx - 220,
      top: box.localToGlobal(Offset.zero).dy +
          (MediaQuery.of(context).size.height / 20) * 1.6 +
          44,
      shouldBlurBackground: false,
      dismissibleCallback: () {
        moreActionOE?.remove();
        moreActionOE?.dispose();
        moreActionOE = null;
      },
      LayerLink(),
    );
  }

  Widget fakeTarget(GlobalKey gKey) {
    final box = gKey.currentContext!.findRenderObject() as RenderBox;
    return SizedBox(width: box.paintBounds.right, child: const Text(""));
  }

  //本機端互傳
  void onPostUpdate(_, __, Object? updatedPost) {
    int index = postList.indexWhere((element) =>
        updatedPost is MomentPosts && updatedPost.post?.id == element.post!.id);

    postList[index] = updatedPost as MomentPosts;
    //MyPostsCell也有監聽onPostUpdate，不需要更新history.
    if (mounted) setState(() {});
  }

  void checkLikeStatus() {
    postList[postsIndex].likes!.list!.contains(objectMgr.userMgr.mainUser.uid)
        ? likeAnimationControllers.forward()
        : likeAnimationControllers.reverse();
  }

  void onMyPostUpdate(_, __, Object? detail) {
    int index = postList.indexWhere((element) =>
        detail is MomentDetailUpdate && detail.postId == element.post!.id);

    var post = postList[index];

    if (detail is! MomentDetailUpdate || detail.postId != post.post?.id) return;

    switch (detail.typ) {
      case MomentNotificationType.likeNotificationType: //強提醒
        post.likes!.list!.add(detail.content!.userId!);
        post.likes!.count =
            post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
        break;
      case MomentNotificationType.commentNotificationType:
        if (post.commentDetail!.comments == null) {
          post.commentDetail!.comments = [];
        }

        post.commentDetail!.comments!.add(
          MomentComment(
            id: detail.typId,
            userId: detail.content!.userId,
            postId: detail.content?.postId,
            replyUserId: detail.content?.replyUserId,
            content: detail.content?.msg,
            createdAt: detail.createdAt,
          ),
        );
        post.commentDetail!.count = post.commentDetail?.comments?.length ??
            (post.commentDetail!.count ?? 0 + 1);
        post.commentDetail!.totalCount = (post.commentDetail?.totalCount ??
                post.commentDetail!.totalCount ??
                0) +
            1;
        break;
      case MomentNotificationType.deleteCommentNotificationType:
        post.commentDetail!.comments!.removeWhere(
          (element) => element.id == detail.typId,
        );
        post.commentDetail!.count = post.commentDetail?.comments?.length ??
            (post.commentDetail!.count ?? 1 - 1);
        post.commentDetail!.totalCount = (post.commentDetail?.totalCount ??
                post.commentDetail!.totalCount ??
                1) -
            1;
        break;
      case MomentNotificationType.deletePostNotificationType:
        break;
      case MomentNotificationType.deleteLikeNotificationType: //取消點讚
        post.likes!.list!.removeWhere(
          (element) => element == detail.content!.userId!,
        );
        post.likes!.count = post.likes!.list?.length;
        break;
      case MomentNotificationType.reLikeLikeNotificationType: //重新點贊
        post.likes!.list!.add(detail.content!.userId!);
        post.likes!.count =
            post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
        break;
      default:
        break;
    }

    updateMyPosts(POST_ACTION_UPDATE, post);

    //Update my posts local cache.
    objectMgr.momentMgr.updateLocalHistoryPost(post.post!.userId!, post);

    if (mounted) setState(() {});
  }

  void updateMyPosts(int aAction, var post) {
    if (aAction == POST_ACTION_UPDATE) {
      for (int i = 0; i < momentMyPostsController.postList.length; i++) {
        if (momentMyPostsController.postList[i].post!.id == post.post?.id) {
          momentMyPostsController.postList[i] = post;
          break;
        }
      }
    } else if (aAction == POST_ACTION_DELETE) {
      for (int i = 0; i < momentMyPostsController.postList.length; i++) {
        if (momentMyPostsController.postList[i].post!.id == post.post?.id) {
          momentMyPostsController.postList.removeAt(i);
          break;
        }
      }
    }
  }

  Widget _buildVideoBottomToolBar() {
    return Obx(() {
      if (currentVideoStream.value?.controller == null) return const SizedBox();

      return TencentVideoSlider(
        controller: currentVideoStream.value!.controller,
        height: ObjectMgr.screenMQ!.size.height * 0.008,
        sliderType: SliderType.myMoment,
        timeStyle: TextStyle(
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
          fontFamily: appFontFamily,
        ),
        sliderColors: FijkSliderColors(
          playedColor: Colors.white,
          cursorColor: Colors.white,
          bufferedColor: Colors.white.withOpacity(0.5),
          baselineColor: Colors.white.withOpacity(0.3),
        ),
      );
    });
  }

  BoxFit getAssetBoxFit(int index) {
    double imageRatio = _allAssets[index].width / _allAssets[index].height;
    return deviceRatio > imageRatio ? BoxFit.fitHeight : BoxFit.fitWidth;
  }
}

class LoadStatus {
  Rx<bool> isLoaded = false.obs;
  bool isShow = false;

  LoadStatus();

  LoadStatus.preview() {
    isLoaded = true.obs;
    isShow = true;
  }
}
