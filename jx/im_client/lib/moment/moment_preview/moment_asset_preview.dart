import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/component/moment_hero_widget.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/wake_lock_utils.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class MomentAssetPreview extends StatefulWidget {
  final List<MomentContentDetail> assets;
  final int index;
  final int postId;
  final int userId;
  final Function(int)? onPageChange;

  const MomentAssetPreview({
    super.key,
    required this.assets,
    required this.index,
    required this.postId,
    required this.userId,
    this.onPageChange,
  });

  @override
  State<MomentAssetPreview> createState() => _MomentAssetPreviewState();
}

class _MomentAssetPreviewState extends State<MomentAssetPreview> {
  late final PhotoViewPageController photoViewPageController;
  int currentPage = 0;
  Map<int, LoadStatus> loadedOriginMap = <int, LoadStatus>{};

  TencentVideoStreamMgr? videoStreamMgr;
  StreamSubscription? videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  GlobalKey<PhotoViewSlidePageState> slidePageKey =
      GlobalKey<PhotoViewSlidePageState>();

  bool _hasLimitedVolume = false;

  bool isCanSlide = true; //防止換頁時，圖片還未中止在當前頁面急手勢滑出問題.

  int slideResetPageMilliseconds = 100;

  @override
  void initState() {
    super.initState();

    WakeLockUtils.enable();
    currentPage = widget.index;

    photoViewPageController = PhotoViewPageController(
        initialPage: widget.index, shouldIgnorePointerWhenScrolling: true);

    photoViewPageController.addListener(_onPageScroll);

    initVideoController();
    iniLoadMap();
  }

  @override
  void dispose() {
    setStatusBarColor(Colors.transparent);
    videoStreamSubscription?.cancel();
    if (videoStreamMgr != null) {
      objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr!);
    }
    videoStreamMgr = null;

    WakeLockUtils.disable();
    photoViewPageController.removeListener(_onPageScroll);
    super.dispose();
  }

  void _onPageScroll() {
    if (photoViewPageController.page ==
        photoViewPageController.page!.roundToDouble()) {
      Future.delayed(const Duration(milliseconds: 200), () {
        isCanSlide = true;
      });
    }
  }

  void iniLoadMap() {
    for (int i = 0; i < widget.assets.length; i++) {
      loadedOriginMap[i] = LoadStatus();
    }
  }

  void initVideoController() {
    if (widget.assets.length == 1 &&
        widget.assets.first.type.contains('video')) {
      videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
      videoStreamSubscription =
          videoStreamMgr?.onStreamBroadcast.listen(_onVideoUpdates);

      TencentVideoConfig config = TencentVideoConfig(
        url: widget.assets.first.url,
        width: widget.assets.first.width,
        height: widget.assets.first.height,
        thumbnail: widget.assets.first.cover,
        thumbnailGausPath: widget.assets.first.gausPath,
        autoplay: true,
        hasBottomSafeArea: false,
        hasTopSafeArea: false,
        isLoop: true,
        type: ConfigType.saveMp4,
      );

      currentVideoStream.value =
          videoStreamMgr?.addController(config, index: 0);

      if (videoStreamMgr?.hasStream() ?? false) {
        _hasLimitedVolume = true;
        VolumePlayerService.sharedInstance.onClose();
      }
    }
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != currentPage) return;

    if (item.state.value == TencentVideoState.DISPOSED) {
      currentVideoStream.value = null;
      currentVideoState.value = TencentVideoState.INIT;
      return;
    }

    currentVideoStream.value = item;
    currentVideoState.value = item.state.value;
  }

  void onPageChange(int index) {
    isCanSlide = false;
    iniLoadMap();
    if (widget.assets.length == 1 &&
        widget.assets.first.type.contains('video')) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        currentPage = index;
        if (videoStreamMgr?.getVideoStream(index) == null) {
          currentVideoStream.value = null;
        } else if (!_hasLimitedVolume) {
          _hasLimitedVolume = true;
          VolumePlayerService.sharedInstance.onClose();
        }
        if (mounted) setState(() {});
      });
    } else {
      currentPage = index;
      if (mounted) setState(() {});
      widget.onPageChange?.call(index);
    }
  }

  void onThumbnailLoadCallback(PhotoViewLoadState? state, File? f) {
    String cachePath = f?.path.split("/").last ?? "";
    String originalUrl = widget.assets[currentPage].url.split("/").last;

    if (state == PhotoViewLoadState.completed && cachePath == originalUrl) {
      bool isLoaded = loadedOriginMap[currentPage]!.isLoaded.value;
      if (f != null && !isLoaded) {
        if (!loadedOriginMap[currentPage]!.isShow) {
          loadedOriginMap[currentPage]!.isShow = true;
          onFullImageLoaded(currentPage);
        }
      }
    }
  }

  onFullImageLoaded(int index) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!loadedOriginMap[currentPage]!.isSliding) {
        loadedOriginMap[index]!.isLoaded.value = true;
      } else {
        loadedOriginMap[index]!.delayShow = true;
      }
    });
  }

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: null,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Stack(
            children: <Widget>[
              PhotoViewSlidePage(
                key: slidePageKey,
                slideAxis: SlideDirection.vertical,
                slideType: SlideArea.onlyImage,
                resetPageDuration:
                    Duration(milliseconds: slideResetPageMilliseconds),
                slidePageBackgroundHandler: (Offset offset, Size pageSize) {
                  return defaultSlidePageBackgroundHandler(
                      offset: offset,
                      color: Colors.black,
                      pageSize: pageSize,
                      pageGestureAxis: SlideDirection.vertical);
                },
                slideOffsetHandler: (Offset offset,
                    {PhotoViewSlidePageState? state}) {
                  if (!loadedOriginMap[currentPage]!.isSliding) {
                    loadedOriginMap[currentPage]!.isSliding = true;
                  }
                  return isCanSlide ? null : Offset.zero;
                },
                slideEndHandler: (Offset offset,
                    {ScaleEndDetails? details,
                    PhotoViewSlidePageState? state}) {
                  bool isPop = defaultSlideEndHandler(
                    offset: offset,
                    pageSize: MediaQuery.of(context).size,
                    pageGestureAxis: SlideDirection.vertical,
                  );

                  if (!isPop) {
                    // PageViewSlidePage圖片動畫Tween時間為500ms，確保滑動手勢結束後，並且圖片動畫結束後再顯示原圖，
                    // 不然在Tween動畫未結束前就切換高清，會導致動畫終止，畫面卡在中間。
                    Future.delayed(
                        Duration(
                            milliseconds: slideResetPageMilliseconds + 150),
                        () {
                      if (loadedOriginMap[currentPage]!.delayShow) {
                        loadedOriginMap[currentPage]!.isLoaded.value = true;
                      }
                      loadedOriginMap[currentPage]!.isSliding = false;
                    });
                  }

                  return isPop;
                },
                child: PhotoViewGesturePageView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: photoViewPageController,
                  itemCount: widget.assets.length,
                  onPageChanged: onPageChange,
                  physics: const FastPageScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final asset = widget.assets[index];
                    if (asset.type.contains('video')) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
                          onMediaLongPress(context,
                              assetsUrl: asset.url, media: 1);
                        },
                        child: Container(
                          color: Colors.black,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewPadding.bottom,
                          ),
                          child: DismissiblePage(
                            onDismissed: Navigator.of(context).pop,
                            direction: DismissiblePageDismissDirection.down,
                            child: Obx(() {
                              return currentVideoStream.value != null
                                  ? TencentVideoPlayer(
                                      controller:
                                          currentVideoStream.value!.controller,
                                      index: widget.index,
                                      overlay: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onTap: Navigator.of(context).pop,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container();
                            }),
                          ),
                        ),
                      );
                    }

                    Size screenSize = MediaQuery.of(context).size;
                    return MomentHeroWidget(
                        slidePageKey: slidePageKey,
                        tag: asset.uniqueId,
                        child: Container(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).viewPadding.top,
                            bottom: widget.assets.length == 1
                                ? 0
                                : MediaQuery.of(context).viewPadding.bottom +
                                    MediaQuery.of(context).size.height / 20,
                          ),
                          child: GestureDetector(
                              onLongPress: () {
                                onMediaLongPress(context,
                                    assetsUrl: asset.url,
                                    media:
                                        asset.type.contains('video') ? 1 : 0);
                              },
                              child: Stack(
                                children: [
                                  Obx(() {
                                    return Offstage(
                                      offstage: !loadedOriginMap[index]!
                                          .isLoaded
                                          .value,
                                      child: ExtendedPhotoView(
                                        key: ValueKey(asset.url),
                                        src: asset.url,
                                        width: getAssetBoxFit(index) ==
                                                    BoxFit.fitWidth &&
                                                asset.width < screenSize.width
                                            ? screenSize.width
                                            : asset.width.toDouble(),
                                        height: (getAssetBoxFit(index) ==
                                                    BoxFit.fitHeight &&
                                                asset.height < screenSize.height
                                            ? screenSize.height
                                            : asset.height.toDouble()),
                                        fit: getAssetBoxFit(index),
                                        constraint:
                                            const BoxConstraints.expand(),
                                        onLoadStateCallback:
                                            onThumbnailLoadCallback,
                                        mode: PhotoViewMode.gesture,
                                        shouldAnimate: true,
                                        noSimmerEffect: true,
                                      ),
                                    );
                                  }),
                                  Obx(
                                    () =>
                                        !loadedOriginMap[index]!.isLoaded.value
                                            ? ExtendedPhotoView(
                                                key: ValueKey(
                                                  '${asset.url}_${Config().sMessageMin}',
                                                ),
                                                src: asset.url,
                                                width: screenSize.width,
                                                height: screenSize.height,
                                                fit: getAssetBoxFit(index),
                                                mini: Config().sMessageMin,
                                                mode: PhotoViewMode.gesture,
                                                shouldAnimate: true,
                                                noSimmerEffect: true,
                                              )
                                            : const SizedBox(),
                                  )
                                ],
                              )),
                        ));
                  },
                ),
              ),

              // Image indicator - 图片指示器
              if (widget.assets.length > 1)
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: MediaQuery.of(context).viewPadding.bottom +
                      MediaQuery.of(context).size.height / 40,
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.assets.length,
                        (index) => Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == currentPage
                                ? colorWhite
                                : colorWhite.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (widget.assets.length == 1 &&
                  widget.assets.first.type.contains('video'))
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                  child: _buildVideoBottomToolBar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBottomToolBar() {
    return Obx(() {
      if (currentVideoStream.value?.controller == null) return const SizedBox();

      return TencentVideoSlider(
        controller: currentVideoStream.value!.controller,
        height: ObjectMgr.screenMQ!.size.height * 0.09,
        sliderType: SliderType.moment,
        timeStyle: const TextStyle(
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
          fontFamily: appFontfamily,
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

  BoxFit getAssetBoxFit(int index) {
    double imageRatio =
        widget.assets[index].width / widget.assets[index].height;
    return deviceRatio > imageRatio ? BoxFit.fitHeight : BoxFit.fitWidth;
  }

  void onMediaLongPress(
    BuildContext context, {
    required String assetsUrl,
    required int media,
  }) async {
    // 彈窗動作
    onMediaAction(
      context,
      url: assetsUrl,
      media: media,
    );
  }

  Future<void> onMediaAction(
    BuildContext context, {
    required String url,
    required int media,
  }) async {
    FocusScope.of(context).unfocus();
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(
            media == 0
                ? localized(chatOptionsSaveImage)
                : localized(chatOptionsSaveVideo),
          ),
          textColor: themeColor,
          onClick: () {
            //Save
            saveMessageMedia(context, _onForwardMedia(media));
          },
        ),
        CustomBottomAlertItem(
          text: localized(forward),
          onClick: () {
            //forward
            onForwardMessage(assetsMedia: url, media: media);
          },
        ),
      ],
    );
  }

  Future<void> onForwardMessage(
      {bool fromChatInfo = false,
      bool fromMediaDetail = false,
      String? selectableText,
      String? assetsMedia,
      int? media}) async {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colorOverlay40,
      builder: (BuildContext context) {
        return ForwardContainer(
          showSaveButton: false,
          selectableText: selectableText,
          forwardMsg: [_onForwardMedia(media ?? 0)],
        );
      },
    ).whenComplete(() {});
  }

  Message _onForwardMedia(int media) {
    final Message msg = Message();
    //media: 0->image,1->video
    if (media == 0) {
      msg.typ = messageTypeImage;
      MessageImage messageImage = MessageImage();
      messageImage.url = widget.assets[currentPage].url;
      messageImage.height = widget.assets[currentPage].height;
      messageImage.width = widget.assets[currentPage].width;
      messageImage.forward_user_id = objectMgr.userMgr.mainUser.uid;
      messageImage.forward_user_name = objectMgr.userMgr.mainUser.nickname;
      messageImage.gausPath = widget.assets[currentPage].gausPath ?? '';
      msg.content = jsonEncode(messageImage);
      msg.decodeContent(
        cl: msg.getMessageModel(msg.typ),
        v: jsonEncode(messageImage),
      );
    } else {
      msg.typ = messageTypeVideo;
      MessageVideo messageVideo = MessageVideo();
      messageVideo.url = widget.assets[currentPage].url;
      messageVideo.cover = widget.assets[currentPage].cover!;
      messageVideo.second =
          currentVideoStream.value!.controller.videoDuration.value ~/ 1000;
      messageVideo.height = widget.assets[currentPage].height;
      messageVideo.width = widget.assets[currentPage].width;
      messageVideo.forward_user_id = objectMgr.userMgr.mainUser.uid;
      messageVideo.forward_user_name = objectMgr.userMgr.mainUser.nickname;
      messageVideo.gausPath = widget.assets[currentPage].gausPath ?? '';
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
      saveFileToGallery(fileObj.path);
    }
  }

  bool previewSlideEndHandler({
    Offset offset = Offset.zero,
    Size pageSize = const Size(100, 100),
    SlideDirection pageGestureAxis = SlideDirection.both,
  }) {
    const int parameter = 6;
    if (pageGestureAxis == SlideDirection.both) {
      return offset.distance.greaterThan(
          Offset(pageSize.width, pageSize.height).distance / parameter);
    } else if (pageGestureAxis == SlideDirection.horizontal) {
      return offset.dx.abs().greaterThan(pageSize.width / parameter);
    } else if (pageGestureAxis == SlideDirection.vertical) {
      return offset.dy.abs().greaterThan(pageSize.height / parameter);
    }
    return true;
  }

  Color slidePageBackgroundHandler({
    Offset offset = Offset.zero,
    Size pageSize = const Size(100, 100),
    required Color color,
    SlideDirection pageGestureAxis = SlideDirection.both,
  }) {
    double opacity = 0.0;
    if (pageGestureAxis == SlideDirection.both) {
      opacity = offset.distance /
          (Offset(pageSize.width, pageSize.height).distance / 2.0);
    } else if (pageGestureAxis == SlideDirection.horizontal) {
      opacity = offset.dx.abs() / (pageSize.width / 2.0);
    } else if (pageGestureAxis == SlideDirection.vertical) {
      opacity = offset.dy.abs() / (pageSize.height / 2.0);
    }
    return color.withOpacity(min(1.0, max(1.0 - opacity, 0.0)));
  }

  void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: color,
      ),
    );
  }
}

/// Fixed the problem of multiple pictures triggering hero animation at the same time
class FastPageScrollPhysics extends PageScrollPhysics {
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 13, // 質量，影響彈簧的慣性，質量越大，彈簧的運動越慢。
        stiffness: 70, // 剛度，影響彈簧的硬度，剛度越大，彈簧的運動越快。
        damping: 8, // 阻尼，影響彈簧的減震效果，阻尼越大，彈簧的運動越快停止。
      );

  @override
  double get minFlingDistance => 0.05;

  @override
  double get minFlingVelocity => 1;
}

class LoadStatus {
  Rx<bool> isLoaded = false.obs;
  bool delayShow = false;
  bool isShow = false;
  bool isSliding = false;

  LoadStatus();

  LoadStatus.preview() {
    isLoaded = true.obs;
    isShow = true;
  }
}
