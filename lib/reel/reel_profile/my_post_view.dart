import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_profile/my_post_publish_card.dart';
import 'package:jxim_client/reel/components/reel_bottom_sheet.dart';
import 'package:jxim_client/reel/reel_profile/post_item.dart';
import 'package:jxim_client/reel/reel_search/reel_media_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/views/component/component.dart';

class MyPostView extends StatefulWidget {
  final bool isOwner;
  final dynamic controller;

  const MyPostView({
    super.key,
    this.isOwner = false,
    required this.controller,
  });

  @override
  State<MyPostView> createState() => _MyPostViewState();
}

class _MyPostViewState extends State<MyPostView> {
  final RxBool _isLoading = false.obs;
  late ReelController reelController;

  @override
  void initState() {
    super.initState();
    reelController = Get.find<ReelController>();
  }

  void _scrollListener(ScrollNotification notification) {
    if (widget.controller.posts.length ==
        (widget.controller.reelProfile.value.totalPostCount ?? 0)) return;
    if (_isLoading.value) return;

    int currentPostLength = widget.controller.posts.length;
    double numberOfRows = currentPostLength / 3;
    double currentHeightPerRow =
        notification.metrics.maxScrollExtent / numberOfRows;
    double updatedPositionToCheck = numberOfRows * 3 / 5 * currentHeightPerRow;

    // Check if scrolled to the almost end of the list
    if (notification.metrics.pixels >= updatedPositionToCheck) {
      // pdebug(
      //     "### ${_scrollController.position.pixels.toString()} - ${updatedPositionToCheck.toString()}");
      _loadMoreData();
      _isLoading.value = true;
    }
  }

  _loadMoreData() async {
    if (_isLoading.value) return;

    ReelPost data = widget.controller.posts.last;
    int? postId = data.id.value!;
    await widget.controller
        .getPosts(widget.controller.userId.value, lastId: postId);

    //等待UI更新让scrollview再度识别
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _isLoading.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => widget.controller.posts.isNotEmpty
          ? NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _scrollListener(notification);
                }

                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  SliverGrid.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 1.0,
                    crossAxisSpacing: 1.0,
                    children: List.generate(
                      widget.controller.posts.length,
                      (index) {
                        final item = widget.controller.posts[index];
                        return OpacityEffect(
                          child: GestureDetector(
                            onLongPress: () async {
                              if (!widget.isOwner) return;
                              reelBtmSheet.showReelLongPressBottomSheet(
                                context: context,
                                reelItem: item,
                                onTapMng: () {
                                  Get.toNamed(
                                    RouteName.reelMultiManage,
                                    preventDuplicates: false,
                                    arguments: {
                                      'controller': widget.controller,
                                      'type': ReelPostType.post,
                                    },
                                  );
                                },
                              );
                            },
                            onTap: () async {
                              Navigator.of(context).push(
                                TransparentRoute(
                                  builder: (BuildContext context) {
                                    return ReelMediaView(
                                      assetList: widget.controller.posts.value,
                                      startingIndex: index,
                                      onPageChange: _onPageChanged,
                                      onReturnFromSave: widget.isOwner
                                          ? widget.controller.onReturnFromSave
                                          : null,
                                      userId: widget.controller.userId.value,
                                    );
                                  },
                                  settings: const RouteSettings(
                                    name: RouteName.reelPreview,
                                  ),
                                ),
                              );
                            },
                            child: PostItem(item: item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : widget.isOwner
              ? CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: MyPostPublishCard(
                        onPressed: () {
                          reelController.onBottomTap(1);
                        },
                      ),
                    ),
                  ],
                )
              : const NoContentView(),
    );
  }

  Future<List<ReelPost>> _onPageChanged(int index) async {
    List<ReelPost> newData = [];
    if (index + 5 < widget.controller.posts.length) {
      return newData;
    }

    ReelPost data = widget.controller.posts.last;
    int? postId = data.id.value;
    List<ReelPost> items = await widget.controller
        .getPosts(widget.controller.userId.value, lastId: postId);
    return items;
  }
}
