import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_profile/post_item.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelMultiManageView extends StatefulWidget {
  final ReelPostType type;
  final ReelMyProfileController profileController;

  const ReelMultiManageView({
    super.key,
    required this.type,
    required this.profileController,
  });

  @override
  State<ReelMultiManageView> createState() => _ReelMultiManageViewState();
}

class _ReelMultiManageViewState extends State<ReelMultiManageView> {
  ReelController reelController = Get.find<ReelController>();
  RxBool isAllSelect = false.obs;

  // 批量管理被選取的id
  final RxInt selectedCount = 0.obs;
  RxList<Rx<ReelPost>> posts = RxList<Rx<ReelPost>>();

  void toggleSelect(RxList<ReelPost> posts, int index) {
    ReelPost data = posts[index];
    posts[index].isSelected = !posts[index].isSelected;
    countSelectedItems(posts);
    reelController.update([data.id.value!.toString()]);
  }

  // 全选或取消全选
  void postSelectAll(RxList<ReelPost> posts, bool isSelected) {
    List<String> strings = [];
    for (var post in posts) {
      post.isSelected = isSelected;
      strings.add(post.id.value!.toString());
    }
    // widget.profileController.update([strings]);
    if (mounted) setState(() {});
    countSelectedItems(posts);
  }

  void countSelectedItems(RxList<ReelPost> posts) {
    List<ReelPost> data = posts.where((p0) => p0.isSelected == true).toList();
    selectedCount.value = data.length;
  }

  @override
  void dispose() {
    RxList<ReelPost> posts =
        widget.profileController.getPostForManaging(widget.type);
    for (var element in posts) {
      element.isSelected = false;
    }
    selectedCount.value = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RxList<ReelPost> posts =
        widget.profileController.getPostForManaging(widget.type);
    final bool isDraft = (widget.type == ReelPostType.draft ||
        widget.type == ReelPostType.draftRepost);

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: isDraft ? localized(reelDraft) : localized(reelBatchMng),
        trailing: [
          Obx(
            () => OpacityEffect(
              child: GestureDetector(
                onTap: () {
                  if (selectedCount > 0) {
                    // 只要底下有選取,點擊便清空選取
                    postSelectAll(posts, false);
                    isAllSelect.value = false;
                  } else if (isAllSelect.value == false) {
                    //全選
                    postSelectAll(posts, true);
                    isAllSelect.value = true;
                  } else {
                    //清空全選
                    postSelectAll(posts, false);
                    isAllSelect.value = false;
                  }
                  countSelectedItems(posts);
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      isAllSelect.value
                          ? localized(cancel)
                          : selectedCount > 0
                              ? localized(cancel)
                              : localized(selectAll),
                      style: jxTextStyle.textStyle17(color: themeColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Visibility(
            visible: !isDraft,
            child: Container(
              color: colorTextPrimary.withOpacity(0.24),
              height: 0.33,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Visibility(
            visible: isDraft,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorTextPrimary.withOpacity(0.24),
                    width: 0.33,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  localized(reelDraftDescTxt),
                  style: jxTextStyle.textStyle12(
                    color: colorTextPrimary.withOpacity(0.48),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => GridView.builder(
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  ReelPost data = posts[index];
                  return OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        //非草稿區塊,整個item點選都是勾選熱點
                        if (widget.type != ReelPostType.draft) {
                          toggleSelect(posts, index);
                        }
                      },
                      child: GetBuilder(
                        init: reelController,
                        id: data.id.value!.toString(),
                        builder: (_) {
                          return PostItem(
                            type: widget.type,
                            item: data,
                            showSelect: true,
                            onSelectTap: () {
                              toggleSelect(posts, index);
                            },
                            isSelectCheck: data.isSelected,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.only(top: 13, bottom: 13, left: 16, right: 16),
            child: SafeArea(
              top: false,
              child: Obx(
                () => _buildBottomSection(widget.type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildBottomSection(ReelPostType type) {
    switch (type) {
      case ReelPostType.post: //貼文
        return _postBottomBox();
      case ReelPostType.draftRepost: //已發貼文存草稿
        return _draftRepostBottomBox();
      case ReelPostType.draft: //草稿
      case ReelPostType.save: //收藏
      case ReelPostType.liked: //點讚
        return _generalBottomBox();
      default:
        return _postBottomBox();
    }
  }

  _postBottomBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ///移到草稿先隱藏
        const SizedBox(),
        // _buildEffectBtn(
        //   onTap: () async {
        //     if (selectedCount > 0)
        //       CustomBottomAlertDialog(
        //         context,
        //         title: localized(reelMoveConfirm),
        //         subtitle: localized(reelAskMoveToDraft),
        //         onConfirmListener: () {
        //           Get.back();
        //         },
        //       );
        //   },
        //   child: Text(
        //     localized(reelMoveToDraft),
        //     style: jxTextStyle.textStyle17(
        //         color: selectedCount == 0
        //             ? colorTextPrimary.withOpacity(0.24)
        //             : themeColor),
        //   ),
        // ),
        _buildDeleteBtn(() async {
          if (selectedCount > 0) {
            showCustomBottomAlertDialog(
              context,
              title: localized(reelDeleteConfirm),
              subtitle: localized(reelDeleteCannotRecovered),
              onConfirmListener: () async {
                widget.profileController.deletePosts(widget.type);
                selectedCount.value = 0;
              },
            );
          }
        }),
      ],
    );
  }

  _draftRepostBottomBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildEffectBtn(
          onTap: () async {
            if (selectedCount > 0) {
              showCustomBottomAlertDialog(
                context,
                title: localized(reelPublicConfirm),
                subtitle: localized(reelAskPublicWork),
                onConfirmListener: () {
                  Toast.showToast(localized(homeToBeContinue));
                },
              );
            }
          },
          child: Text(
            localized(reelPublicWork),
            style: jxTextStyle.textStyle17(
              color: selectedCount.value == 0
                  ? colorTextPrimary.withOpacity(0.24)
                  : themeColor,
            ),
          ),
        ),
        _buildDeleteBtn(() async {
          if (selectedCount > 0) {
            showCustomBottomAlertDialog(
              context,
              title: localized(reelDeleteConfirm),
              subtitle: localized(reelDeleteCannotRecovered),
              onConfirmListener: () {
                widget.profileController.deletePosts(widget.type);
                selectedCount.value = 0;
              },
            );
          }
        }),
      ],
    );
  }

  _generalBottomBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localized(reelSelectedCount, params: ['$selectedCount']),
          style: jxTextStyle.textStyle17(
            color: selectedCount.value == 0
                ? colorTextPrimary.withOpacity(0.24)
                : themeColor,
          ),
        ),
        _buildDeleteBtn(() async {
          if (selectedCount > 0) {
            showCustomBottomAlertDialog(
              context,
              title: localized(reelDeleteConfirm),
              subtitle: localized(reelDeleteCannotRecovered),
              onConfirmListener: () {
                widget.profileController.deletePosts(widget.type);
                selectedCount.value = 0;
              },
            );
          }
        }),
      ],
    );
  }

  _buildDeleteBtn(onTap) {
    return _buildEffectBtn(
      onTap: onTap,
      child: Text(
        localized(delete),
        style: jxTextStyle.textStyle17(
          color: selectedCount.value == 0
              ? colorTextPrimary.withOpacity(0.24)
              : colorRed,
        ),
      ),
    );
  }

  _buildEffectBtn({required Widget child, required Function()? onTap}) {
    return OpacityEffect(
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
