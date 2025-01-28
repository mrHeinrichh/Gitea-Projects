import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_bottom_sheet.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_profile/post_item.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/reel_search/reel_media_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/no_content_view.dart';

class SavePostView extends StatefulWidget {
  final ReelMyProfileController controller;
  const SavePostView({super.key, required this.controller});

  @override
  State<SavePostView> createState() => _SavePostViewState();
}

class _SavePostViewState extends State<SavePostView> {
  final RxBool _isLoading = false.obs;
  late ReelController reelController;

  @override
  void initState() {
    super.initState();
    reelController = Get.find<ReelController>();
    widget.controller.getSavedPosts();
  }

  bool _endOfScroll = false;
  void _scrollListener(ScrollNotification notification) {
    if (_endOfScroll) return;
    if (_isLoading.value) return;

    int currentPostLength = widget.controller.filterSavedPosts.length;
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

    List<ReelPost> updated = await widget.controller
        .getSavedPosts(lastId: widget.controller.savedPosts.length);
    _endOfScroll =
        updated.isEmpty || widget.controller.savedPosts.length % 30 != 0;

    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => widget.controller.filterSavedPosts.isNotEmpty
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
                      widget.controller.filterSavedPosts.length,
                      (index) {
                        final item = widget.controller.filterSavedPosts[index];
                        return OpacityEffect(
                          child: GestureDetector(
                            onLongPress: () async =>
                                reelBtmSheet.showReelLongPressBottomSheet(
                              context: context,
                              reelItem: item,
                              onTapMng: () {
                                Get.toNamed(
                                  RouteName.reelMultiManage,
                                  arguments: {
                                    'type': ReelPostType.save,
                                    'controller': widget.controller,
                                  },
                                );
                              },
                            ),
                            onTap: () {
                              //
                              Navigator.of(context).push(
                                TransparentRoute(
                                  builder: (BuildContext context) {
                                    return ReelMediaView(
                                      assetList: widget.controller.filterSavedPosts,
                                      startingIndex: index,
                                      onPageChange: _onPageChanged,
                                      onReturnFromSave:
                                          widget.controller.onReturnFromSave,
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
          : const NoContentView(),
    );
  }

  Future<List<ReelPost>> _onPageChanged(int index) async {
    List<ReelPost> newData = [];
    if (index + 5 < widget.controller.savedPosts.length) {
      return newData;
    }

    List<ReelPost> updated = await widget.controller
        .getSavedPosts(lastId: widget.controller.savedPosts.length);
    _endOfScroll =
        updated.isEmpty || widget.controller.savedPosts.length % 30 != 0;
    return updated;
  }
}
