import 'dart:async';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/reel/components/reel_search_input.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_chat_field.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_mgr.dart';
import 'package:jxim_client/reel/reel_search/reel_preview.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/services/preload_page_view.dart';

class ReelMediaView extends StatefulWidget {
  final List<ReelPost> assetList;
  final int startingIndex;
  final TencentVideoStream? startingStream;
  final Future<List<ReelPost>> Function(int index) onPageChange;
  final Function()? onReturn;
  final Function()? onReturnFromSave;
  final ReelSearchController? searchController;
  final int? userId;

  const ReelMediaView({
    super.key,
    required this.assetList,
    required this.startingIndex,
    required this.onPageChange,
    this.onReturn,
    this.onReturnFromSave,
    this.startingStream,
    this.userId,
    this.searchController,
  });

  @override
  State<ReelMediaView> createState() => _ReelMediaViewState();
}

class _ReelMediaViewState extends State<ReelMediaView>
    with WidgetsBindingObserver {
  RxList<ReelPost> computedAssets = RxList<ReelPost>();

  late TencentVideoStreamMgr videoStreamMgr;
  late StreamSubscription videoStreamSubscription;
  late PreloadPageController pageController;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  RxInt currentPage = 0.obs;

  int get videoCacheRange => 2;
  RxBool isScrolling = false.obs;
  RxBool actualScrolling = false.obs;

  final isLandscape = false.obs;
  bool _startUnmute = false;
  bool _isControllerPlaying = false;

  FocusNode commentFocusNode = FocusNode();
  final commentTextEditingController = TextEditingController();
  RxBool isSearchMode = false.obs;
  final searchTextEditingController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  RxBool isCommentTextFieldFocus = false.obs;

  @override
  void initState() {
    super.initState();

    commentFocusNode.addListener(() {
      isCommentTextFieldFocus.value = commentFocusNode.hasFocus;
    });

    if (widget.searchController != null) {
      searchTextEditingController.text =
          widget.searchController!.searchController.text;
    }

    videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
    videoStreamMgr.currentIndex.value = widget.startingIndex;
    videoStreamSubscription =
        videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);

    if (widget.startingStream != null) {
      widget.startingStream?.stopRemoval = true;
      videoStreamMgr.updateStream(widget.startingStream!);
      widget.startingStream?.controller.play();
      if (widget.startingStream!.controller.muted.value) {
        _startUnmute = true;
        widget.startingStream!.controller.unMute();
      }
    }

    computedAssets.assignAll(widget.assetList);
    currentPage.value = widget.startingIndex;
    pageController = PreloadPageController(initialPage: widget.startingIndex);

    _preloadVideos(widget.startingIndex);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    isLandscape.value = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.aspectRatio >
        1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    videoStreamSubscription.cancel();
    if (widget.startingStream != null) {
      if (_startUnmute) {
        widget.startingStream!.controller.mute();
      }

      widget.startingStream?.stopRemoval = false;
      videoStreamMgr.clearStartingStream(widget.startingStream!);
    }
    objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr);

    commentFocusNode.dispose();
    commentTextEditingController.dispose();

    super.dispose();
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != currentPage.value) return;
    currentVideoStream.value = item;
  }

  void onPageChange(int index) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _populateData(index);
    });

    _onVideoPageChange(index);
    isScrolling.value = false;
    currentPage.value = index;
  }

  _populateData(int index) async {
    List<ReelPost> newData = await widget.onPageChange(index);
    if (newData.isNotEmpty) {
      computedAssets.addAll(newData);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      isScrolling.value = true;
      actualScrolling.value = true;
    } else if (notification is ScrollEndNotification) {
      isScrolling.value = false;
      actualScrolling.value = false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isSearchMode.value
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.black,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          extendBodyBehindAppBar: true,
          body: WillPopScope(
            onWillPop: () async {
              return true;
            },
            child: SafeArea(
              top: false,
              bottom: false,
              child: DismissiblePage(
                onDismissed: () {
                  Get.back();
                  widget.onReturn?.call();
                },
                direction: isSearchMode.value
                    ? DismissiblePageDismissDirection.none
                    : currentPage.value == 0
                        ? DismissiblePageDismissDirection.down // 第一页，下滑关闭
                        : currentPage.value == computedAssets.length - 1
                            ? DismissiblePageDismissDirection.up // 最后一页 上滑关闭
                            : DismissiblePageDismissDirection
                                .startToEnd, // 其余页面，右滑关闭
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 52 + MediaQuery.of(context).padding.bottom,
                      child: PreloadPageView.builder(
                        controller: pageController,
                        scrollDirection: Axis.vertical,
                        onPageChanged: onPageChange,
                        onScrollNotification: _onScrollNotification,
                        preloadPagesCount: 2,
                        itemCount: computedAssets.length,
                        itemBuilder: (context, index) {
                          ReelPost data = computedAssets[index];
                          return ReelPreview(
                            streamMgr: videoStreamMgr,
                            post: data,
                            userId: widget.userId,
                            index: index,
                            currentPage: currentPage.value,
                            onReturn: widget.onReturn,
                            onReturnFromSave: widget.onReturnFromSave,
                            commentHasFocus: isCommentTextFieldFocus.value ||
                                isSearchMode.value,
                            transferParams: () {
                              return (isScrolling, actualScrolling);
                            },
                          );
                        },
                      ),
                    ),
                    Stack(
                      children: [
                        Positioned.fill(
                            top: isSearchMode.value
                                ? 0
                                : MediaQuery.of(context).viewPadding.top,
                            child: Column(
                              children: <Widget>[
                                if (widget.searchController == null)
                                  Row(
                                    children: <Widget>[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Get.back();
                                          widget.onReturn?.call();
                                        },
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                if (widget.searchController != null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ReelSearchInput(
                                          isDarkMode: !isSearchMode.value,
                                          hasAutoFocus: false,
                                          controller:
                                              searchTextEditingController,
                                          focusNode: searchFocusNode,
                                          onChanged: (value) {
                                            widget.searchController!
                                                .getSearchCompletion(value);
                                          },
                                          onClick: () {
                                            _enterSearchMode();
                                          },
                                          onBackClick: () {
                                            if (isSearchMode.value) {
                                              _exitSearchMode();
                                            } else {
                                              Get.back();
                                              widget.onReturn?.call();
                                            }
                                          },
                                          onClearClick: () {
                                            searchTextEditingController.clear();
                                            if (!isSearchMode.value) {
                                              _enterSearchMode();
                                            }
                                          },
                                          onSearchClick: () {
                                            _onSearch(searchTextEditingController.text);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                if (!isSearchMode.value) const Spacer(),
                                if (isSearchMode.value)
                                  Expanded(
                                    child: widget.searchController!
                                        .getSearchContent(
                                      background: colorBackground,
                                      onTapTile: _onSearch,
                                    ),
                                  ),
                              ],
                            )),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: MediaQuery.of(context).padding.bottom,
                          child: Obx(() {
                            if (isSearchMode.value) {
                              return Container();
                            }
                            return ReelCommentChatField(
                              controller: commentTextEditingController,
                              isDarkMode: !isCommentTextFieldFocus.value,
                              focusNode: commentFocusNode,
                              onTapOutside: (PointerDownEvent event) {
                                commentFocusNode.unfocus();
                              },
                              onTap: () async {
                                var text = commentTextEditingController.text;

                                if (text.trim().isEmpty) {
                                  return;
                                }

                                commentFocusNode.unfocus();

                                _onSendComment(
                                  computedAssets[currentPage.value],
                                  commentTextEditingController,
                                );
                                commentTextEditingController.clear();
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  _onSearch(String text) {
    if (widget.searchController!
        .searchController.text !=
        text) {
      Get.back();
      widget.onReturn?.call();
      widget.searchController!.onSearch(text);
    } else {
      _exitSearchMode();
    }
  }

  _enterSearchMode() {
    searchFocusNode.requestFocus();
    if (isSearchMode.value) return;
    isSearchMode.value = true;
    if (currentVideoStream.value != null) {
      _isControllerPlaying =
          currentVideoStream.value?.state.value == TencentVideoState.PLAYING;
      currentVideoStream.value?.controller.pause();
    }
  }

  _exitSearchMode() {
    isSearchMode.value = false;
    searchFocusNode.unfocus();
    if (currentVideoStream.value != null) {
      if (_isControllerPlaying) {
        currentVideoStream.value?.controller.play();
      }
    }
  }

  void _preloadVideos(int index) async {
    for (int i = index - videoCacheRange; i <= index + videoCacheRange; i++) {
      final data = _getPreloadParams(i);
      if (data != null) {
        if (objectMgr.tencentVideoMgr.currentStreamMgr?.getVideoStream(i) ==
            null) {
          TencentVideoConfig config = TencentVideoConfig(
            url: data.file.value!.path.value!,
            width: data.file.value!.width.value!,
            height: data.file.value!.height.value!,
            thumbnail: data.thumbnail.value!,
            thumbnailGausPath: data.gausPath.value,
            hasBottomSafeArea: false,
            hasTopSafeArea: false,
            autoplay: i == currentPage.value,
            isLoop: true,
          );

          objectMgr.tencentVideoMgr.currentStreamMgr
              ?.addController(config, index: i);
        }
      }
    }
  }

  void _onVideoPageChange(int index) async {
    videoStreamMgr.currentIndex.value = index;
    videoStreamMgr.removeControllersOutOfRange(index, videoCacheRange);
    _preloadVideos(index);

    TencentVideoController? controller = _getVideo(index);

    await videoStreamMgr.pausePlayingControllers(index);
    if (controller != null) {
      await controller.play();
    }
  }

  TencentVideoController? _getVideo(int index) {
    return videoStreamMgr.getVideo(index);
  }

  ReelPost? _getPreloadParams(int index) {
    if (!(index >= 0 && index < computedAssets.length)) return null;
    ReelPost data = computedAssets[index];
    return data;
  }

  Future<void> _onSendComment(ReelPost p, TextEditingController c) async {
    await ReelCommentMgr.instance.addComment(p, c);
  }
}
