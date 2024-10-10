import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_bottom_view.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_like_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_avatar.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_name.dart';
import 'package:jxim_client/reel/reel_page/reel_save_mgr.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/reel_search/reel_search_feature_item.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ResultItem extends StatefulWidget {
  final ReelPost post;
  final int index;

  const ResultItem({
    super.key,
    required this.post,
    required this.index,
  });

  @override
  State<ResultItem> createState() => _ResultItemState();
}

class _ResultItemState extends State<ResultItem>
    with AutomaticKeepAliveClientMixin {
  ReelSearchController get controller => Get.find<ReelSearchController>();

  late Rx<ReelPost> post;
  RxBool isLikedTap = false.obs;
  RxBool isFavoriteTap = false.obs;

  int currentSecond = 0;

  void onPlaybackCallback(int second) => currentSecond = second;

  final tempTag = ['歌曲', '直播间', '图片', '原创', '二次元', 'CG', '哈尔滨'];
  late StreamSubscription videoStreamSubscription;
  Rxn<TencentVideoStream> currentVideoStream = Rxn<TencentVideoStream>();
  Rx<TencentVideoState> currentVideoState = TencentVideoState.INIT.obs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    post = widget.post.obs;
    videoStreamSubscription =
        controller.videoStreamMgr.onStreamBroadcast.listen(_onVideoUpdates);
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != widget.index) return;

    if (item.state.value == TencentVideoState.DISPOSED) {
      currentVideoStream.value = null;
      currentVideoState.value = TencentVideoState.INIT;
      return;
    }

    currentVideoStream.value = item;
    currentVideoState.value = item.state.value;
  }

  @override
  void didUpdateWidget(ResultItem oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    videoStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () => VisibilityDetector(
        key: ValueKey(widget.index.toString()),
        onVisibilityChanged: (visibilityInfo) {
          visibilityInfo.visibleFraction >= 1.0
              ? controller.isInView(widget.index)
              : controller.isNotInView(widget.index);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (objectMgr.userMgr
                          .isMe(post.value.userid.value ?? 0)) {
                        Get.toNamed(
                          RouteName.reelMyProfileView,
                          preventDuplicates: false,
                          arguments: {
                            "onBack": () {
                              Navigator.of(context).pop();
                              controller.play();
                            },
                          },
                        );
                      } else {
                        Get.toNamed(
                          RouteName.reelProfileView,
                          preventDuplicates: false,
                          arguments: {
                            "userId": post.value.userid.value ?? 0,
                            "onBack": () {
                              Navigator.of(context).pop();
                              controller.play();
                            },
                          },
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: ReelProfileAvatar(
                              profileSrc:
                                  post.value.creator.value!.profilePic.value!,
                              userId: post.value.userid.value!,
                              size: 48,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReelProfileName(
                                  userId:
                                      post.value.creator.value?.id.value ?? 0,
                                  name: post.value.creator.value?.name.value ??
                                      "",
                                  fontSize: MFontSize.size17.value,
                                  color: colorTextPrimary,
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatTime.formatTimeFun(
                                      post.value.createAt.value),
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: notBlank(post.value.description.value!),
                    child: Text(
                      post.value.description.value!,
                      style: jxTextStyle.textStyle15(),
                    ),
                  ),
                  Visibility(
                    visible: notBlank(tagItem()),
                    child: Text(
                      tagItem(),
                      style: jxTextStyle.textStyle15(color: themeColor),
                    ),
                  ),
                  videoItem(context),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ReelSearchFeatureItem(
                        type: ReelIconDataType.liked,
                        count: post.value.likedCount.value ?? 0,
                        color: ((post.value.isLiked.value ?? false)
                            ? colorRed
                            : colorTextPrimary),
                        onTap: () {
                          if (!(post.value.isLiked.value ?? false)) {
                            isLikedTap.value = true;
                          }

                          ReelLikeMgr.instance.updateLike(
                            [post.value],
                            !(post.value.isLiked.value ?? false),
                          );
                        },
                      ),
                      ReelSearchFeatureItem(
                        type: ReelIconDataType.comment,
                        count: post.value.commentCount.value ?? 0,
                        color: colorTextPrimary,
                        onTap: () {
                          showBottomComment(context);
                        },
                      ),
                      ReelSearchFeatureItem(
                        type: ReelIconDataType.saved,
                        count: post.value.savedCount.value ?? 0,
                        color: ((post.value.isSaved.value ?? false)
                            ? colorOrange
                            : colorTextPrimary),
                        onTap: () {
                          if (!(post.value.isSaved.value ?? false)) {
                            isFavoriteTap.value = true;
                          }
                          ReelSaveMgr.instance.updateSave(
                            [post.value],
                            !(post.value.isSaved.value ?? false),
                            onTapSavedSuccessfullyCallback: () {
                              controller.pause();
                              Get.toNamed(
                                RouteName.reelMyProfileView,
                                preventDuplicates: false,
                                arguments: {
                                  "selectedTab": 2,
                                  "onBack": () {
                                    Navigator.of(context).pop();
                                    controller.play();
                                  },
                                },
                              );
                            },
                          );
                        },
                      ),
                      ReelSearchFeatureItem(
                        type: ReelIconDataType.share,
                        count: post.value.sharedCount.value ?? 0,
                        color: colorTextPrimary,
                        onTap: () {
                          final ReelController controller =
                              Get.find<ReelController>();
                          controller.doForward(post.value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showBottomComment(context) async {
    ReelCommentController commentController =
        reelNavigationMgr.addCommentView(controller, post.value);
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShowCommentBottomView(
          key: ValueKey(post.value.id),
          controller: commentController,
        );
      },
    ).then((value) {
      commentController.isCommentExpand.value = false;
      reelNavigationMgr.onCloseComment(commentController);
    });
  }

  Widget videoItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: <Widget>[
            Obx(() {
              return Container(
                color: Colors.black,
                height: 220,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    if (currentVideoStream.value != null)
                      TencentVideoPlayer(
                        key: ValueKey(
                          currentVideoStream.value!.url +
                              widget.index.toString(),
                        ),
                        controller: currentVideoStream.value!.controller,
                        index: widget.index,
                      ),
                    Positioned.fill(
                      child: Offstage(
                        offstage: currentVideoStream.value != null,
                        child: Container(
                          color: colorBackground,
                          child: GaussianImage(
                            src: post.value.thumbnail.value ?? "",
                            gaussianPath: post.value.gausPath.value,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            fit: BoxFit.cover,
                            mini: Config().messageMin,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  controller.onEnterReelDetail(
                    context,
                    post.value,
                    currentSecond,
                    widget.index,
                  );
                },
              ),
            ),
            Positioned(
              top: 0.0,
              right: 0.0,
              child: Obx(
                () => Visibility(
                  visible: !controller.scrollStarted.value &&
                      controller.currentIndex.value == widget.index,
                  child: GestureDetector(
                    onTap: () {
                      controller.toggleMute();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: colorBorder,
                      ),
                      child: Obx(() {
                        if (currentVideoStream.value == null) {
                          return const SizedBox();
                        }
                        return Icon(
                          controller.isMute.value
                              ? Icons.volume_off_outlined
                              : Icons.volume_up_outlined,
                          size: 22.0,
                          color: Colors.white,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              right: 0.0,
              child: Obx(() {
                return Visibility(
                  visible: !controller.scrollStarted.value &&
                      controller.currentIndex.value == widget.index,
                  child: GestureDetector(
                    onTap: () {
                      controller.togglePlay(widget.index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Obx(() {
                            if (currentVideoStream.value == null) {
                              return const SizedBox();
                            }
                            return Icon(
                              currentVideoState.value ==
                                      TencentVideoState.PLAYING
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 22.0,
                              color: Colors.white,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String tagItem() {
    String tag = "";
    if (post.value.tags.isNotEmpty) {
      for (final item in post.value.tags) {
        tag += "#$item ";
      }
    }
    return tag;
  }
}
