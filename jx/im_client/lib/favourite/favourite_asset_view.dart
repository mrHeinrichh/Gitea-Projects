import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/enums/tool_extension.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/wake_lock_utils.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:photo_view/photo_view.dart';

class FavouriteAssetView extends StatefulWidget {
  final List<dynamic> assets;
  final int index;

  const FavouriteAssetView({
    super.key,
    required this.assets,
    required this.index,
  });

  @override
  State<FavouriteAssetView> createState() => _FavouriteAssetViewState();
}

class _FavouriteAssetViewState extends State<FavouriteAssetView> {
  late final PageController photoPageControllers;

  int currentPage = 0;

  Map<String, bool> loadedOriginMap = <String, bool>{};

  TencentVideoStreamMgr? videoStreamMgr;
  StreamSubscription? videoStreamSubscription;
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;
  Rxn<TencentVideoStream> videoStream = Rxn<TencentVideoStream>();

  int get videoCacheRange => 1;

  bool hasLimitedVolume = false;

  final showAppBar = true.obs;

  @override
  void initState() {
    super.initState();

    WakeLockUtils.enable();
    currentPage = widget.index;
    photoPageControllers = PageController(initialPage: widget.index);
    videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
    videoStreamSubscription =
        videoStreamMgr?.onStreamBroadcast.listen(_onVideoUpdates);
    if (widget.assets[widget.index] is FavouriteVideo) {
      hasLimitedVolume = true;
      VolumePlayerService.sharedInstance.onClose();
    }

    _preloadVideos(widget.index);
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
            autoplay: i == currentPage,
            type: ConfigType.saveMp4,
          );
          objectMgr.tencentVideoMgr.currentStreamMgr
              ?.addController(config, index: i);
        }
      }
    }
  }

  (String, String, String?, int, int) _getPreloadParams(int index) {
    if (index < 0) return ("", "", null, 0, 0);
    if (widget.assets[index] is FavouriteVideo) {
      return (
        notBlank(widget.assets[index].url)
            ? widget.assets[index].url
            : widget.assets[index].filePath,
        widget.assets[index].cover,
        widget.assets[index].gausPath,
        widget.assets[index].width,
        widget.assets[index].height
      );
    }

    return ("", "", null, 0, 0);
  }

  @override
  void dispose() {
    videoStreamSubscription?.cancel();
    if (videoStreamMgr != null) {
      objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr!);
    }

    WakeLockUtils.disable();
    super.dispose();
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != currentPage) return;
    if (videoStream.value != item) {
      videoStream.value = item;
    }

    if (currentVideoState.value != item.state.value) {
      currentVideoState.value = item.state.value;
      if (currentVideoState.value == TencentVideoState.PAUSED ||
          currentVideoState.value == TencentVideoState.LOADING) {
        showAppBar.value = true;
      } else {
        showAppBar.value = false;
      }
    }
  }

  void onPageChange(int index) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      currentPage = index;
      _onVideoPageChange(index);
      if (mounted) setState(() {});
    });
  }

  _onVideoPageChange(int index) {
    videoStreamMgr!.removeControllersOutOfRange(index, videoCacheRange);
    _preloadVideos(index);

    TencentVideoController? controller = videoStreamMgr?.getVideo(index);

    videoStreamMgr!.pausePlayingControllers(index);
    if (controller != null) {
      if (!hasLimitedVolume) {
        hasLimitedVolume = true;
        VolumePlayerService.sharedInstance.onClose();
      }
      controller.play();
    }
  }

  void onThumbnailLoadCallback(PhotoViewLoadState? state, File? f) {
    if (state == PhotoViewLoadState.completed) {
      bool isLoaded = loadedOriginMap[widget.assets[currentPage].url] ?? false;

      if (f != null && !isLoaded) {
        Future.delayed(const Duration(milliseconds: 300), onFullImageLoaded);
      }
    }
  }

  onFullImageLoaded() {
    if (!(loadedOriginMap[widget.assets[currentPage].url] ?? false)) {
      loadedOriginMap[widget.assets[currentPage].url] = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });
    }
  }

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  double imageRatio(int index) =>
      widget.assets[index].width / widget.assets[index].height;

  BoxFit get boxFit => deviceRatio > imageRatio(currentPage)
      ? BoxFit.fitHeight
      : BoxFit.fitWidth;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            PhotoViewSlidePage(
              slideAxis: SlideDirection.vertical,
              slideType: SlideArea.wholePage,
              slidePageBackgroundHandler: (Offset offset, Size pageSize) {
                return Colors.black;
              },
              child: PageView.builder(
                scrollDirection: Axis.horizontal,
                controller: photoPageControllers,
                itemCount: widget.assets.length,
                onPageChanged: onPageChange,
                itemBuilder: (BuildContext context, int index) {
                  final asset = widget.assets[index];
                  TencentVideoStream? stream =
                      videoStreamMgr?.getVideoStream(index);
                  if (asset is FavouriteVideo) {
                    return GestureDetector(
                      onTap: () {
                        videoStream.value?.controller.togglePlayState();
                      },
                      onLongPressStart: (details) {
                        _onLongPress(context, asset);
                      },
                      child: Container(
                        color: Colors.black,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewPadding.bottom,
                        ),
                        child: DismissiblePage(
                          onDismissed: Navigator.of(context).pop,
                          direction: DismissiblePageDismissDirection.down,
                          child: Hero(
                            tag: currentPage == index ? asset.url : 'null',
                            child: stream != null
                                ? TencentVideoPlayer(
                                    key: ValueKey(
                                      "favourite_${stream.url} - $index",
                                    ),
                                    controller: stream.controller,
                                    index: index,
                                    onTapWidget: () {
                                      return null;
                                    },
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                    );
                  }

                  Size screenSize = MediaQuery.of(context).size;

                  return Hero(
                    tag: currentPage == index ? asset.url : 'null',
                    transitionOnUserGestures: currentPage == index,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      onLongPressStart: (details) =>
                          _onLongPress(context, asset),
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: notBlank(asset.url)
                            ? [
                                if (!(loadedOriginMap[asset.url] ?? false))
                                  ExtendedPhotoView(
                                    key: ValueKey(
                                      'favourite_${asset.url}_${Config().sMessageMin}',
                                    ),
                                    src: asset.url,
                                    width: boxFit == BoxFit.fitWidth &&
                                            asset.width < screenSize.width
                                        ? screenSize.width
                                        : asset.width.toDouble(),
                                    height: boxFit == BoxFit.fitHeight &&
                                            asset.height < screenSize.height
                                        ? screenSize.height
                                        : null,
                                    fit: boxFit,
                                    mini: Config().sMessageMin,
                                    mode: PhotoViewMode.gesture,
                                  ),
                                ExtendedPhotoView(
                                  key: ValueKey("favourite_${asset.url}"),
                                  src: asset.url,
                                  width: boxFit == BoxFit.fitWidth &&
                                          asset.width < screenSize.width
                                      ? screenSize.width
                                      : asset.width.toDouble(),
                                  height: boxFit == BoxFit.fitHeight &&
                                          asset.height < screenSize.height
                                      ? screenSize.height
                                      : null,
                                  fit: boxFit,
                                  constraint: const BoxConstraints.expand(),
                                  onLoadStateCallback: onThumbnailLoadCallback,
                                  mode: PhotoViewMode.gesture,
                                )
                              ]
                            : [
                                PhotoView.file(
                                  File(asset.filePath),
                                  key: ValueKey('favourite_${asset.filePath}'),
                                  width: asset.width.toDouble(),
                                  height: asset.height.toDouble(),
                                  fit: boxFit,
                                  enableSlideOutPage: true,
                                  mode: PhotoViewMode.gesture,
                                  initGestureConfigHandler:
                                      initGestureConfigHandler,
                                )
                              ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.assets[currentPage] is FavouriteVideo)
              Positioned(
                left: 0.0,
                right: 0.0,
                bottom: MediaQuery.of(context).viewPadding.bottom,
                child: _buildVideoBottomToolBar(),
              ),
            if (widget.assets[currentPage] is FavouriteVideo)
              Obx(() {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: showAppBar.value ? 100 : 0,
                  child: AppBar(
                    systemOverlayStyle: SystemUiOverlayStyle.light,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBottomToolBar() {
    return Obx(() {
      return videoStream.value == null
          ? const SizedBox()
          : AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              child: Obx(() {
                return showAppBar.value
                    ? Column(
                        children: <Widget>[
                          Obx(
                            () => videoStream.value != null
                                ? TencentVideoSlider(
                                    controller: videoStream.value!.controller,
                                  )
                                : const SizedBox(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Obx(
                              () => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: videoStream
                                        .value?.controller.onRewindVideo,
                                    child: SvgPicture.asset(
                                      MessagePopupOption
                                          .backward10sec.imagePath,
                                      width: 28.0,
                                      height: 28.0,
                                      colorFilter: const ColorFilter.mode(
                                        colorWhite,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 32.0),
                                  GestureDetector(
                                    onTap: videoStream
                                        .value?.controller.togglePlayState,
                                    child: SvgPicture.asset(
                                      showAppBar.value
                                          ? MessagePopupOption.play.imagePath
                                          : MessagePopupOption.pause.imagePath,
                                      width: 28.0,
                                      height: 28.0,
                                      colorFilter: const ColorFilter.mode(
                                        colorWhite,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 32.0),
                                  GestureDetector(
                                    onTap: videoStream
                                        .value?.controller.onForwardVideo,
                                    child: SvgPicture.asset(
                                      MessagePopupOption.forward10sec.imagePath,
                                      width: 28.0,
                                      height: 28.0,
                                      colorFilter: const ColorFilter.mode(
                                        colorWhite,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox();
              }),
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

  _onLongPress(context, asset) {
    String saveTitle = localized(chatOptionsSaveImage);
    if (asset is FavouriteVideo) {
      saveTitle = localized(chatOptionsSaveVideo);
    }

    vibrate();
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(saveTitle),
          onClick: () => onSelectionSelect(context, 0, asset),
        ),
        CustomBottomAlertItem(
          text: localized(chatOptionsForward),
          onClick: () => onSelectionSelect(context, 1, asset),
        ),
      ],
    );
  }

  onSelectionSelect(context, index, asset) async {
    if (index == 0) {
      String? cachePath;
      if (asset is FavouriteVideo) {
        TencentVideoController? controller =
            videoStreamMgr?.getVideo(currentPage);
        if (controller != null) {
          String vidPath = controller.downloadVideo();
          if (vidPath.isNotEmpty) cachePath = vidPath;
        }
      } else {
        // cachePath = await downloadMgr.downloadFile(asset.url);
        DownloadResult result = await downloadMgrV2.download(asset.url, downloadType: DownloadType.largeFile);
        cachePath = result.localPath;
      }

      if (notBlank(cachePath)) {
        saveFileToGallery(cachePath!);
        return;
      }

      BotToast.removeAll(BotToast.textKey);
      showCustomBottomAlertDialog(
        context,
        title: localized(toastTryLater),
        subtitle: localized(toastSaveUnsuccessfulWaitVideoDownload),
        confirmTextColor: colorRed,
        cancelTextColor: themeColor,
        confirmText: localized(buttonConfirm),
        cancelText: localized(buttonConfirm),
        onConfirmListener: () {},
      );
      return;
    } else {
      dynamic msg;
      int messageType = messageTypeImage;
      if (asset is FavouriteVideo) {
        msg = MessageVideo();
        msg.url = asset.url;
        msg.fileName = asset.fileName;
        msg.filePath = asset.filePath;
        msg.size = asset.size;
        msg.width = asset.width;
        msg.height = asset.height;
        msg.second = asset.second;
        msg.cover = asset.cover;
        msg.coverPath = asset.coverPath;
        messageType = messageTypeVideo;
      } else {
        msg = MessageImage();
        msg.url = asset.url;
        msg.filePath = asset.filePath;
        msg.size = asset.size;
        msg.width = asset.width;
        msg.height = asset.height;
      }
      Message message = Message();
      message.content = jsonEncode(msg);
      message.typ = messageType;

      showModalBottomSheet(
        context: Get.context!,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: colorOverlay40,
        builder: (BuildContext context) {
          return ForwardContainer(
            forwardMsg: [message],
          );
        },
      );
    }
  }
}
