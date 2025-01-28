import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_cell_view.dart';
import 'package:jxim_client/favourite/component/favourite_item.dart';
import 'package:jxim_client/favourite/component/favourite_search_bar.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/search_overlay.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteView extends GetView<FavouriteController> {
  const FavouriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(favouriteTitle),
        trailing: [
          OpacityEffect(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Obx(
                () => !controller.isEditing.value
                    ? GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          Get.toNamed(RouteName.editNotePage);
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/add.svg',
                          width: 20,
                          height: 20,
                          color: themeColor,
                          fit: BoxFit.fitWidth,
                        ),
                      )
                    : CustomTextButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        localized(buttonDone),
                        onClick: () => controller.deactivateSelectItem(),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => controller.oriFavouriteList.isNotEmpty
            ? _buildView(context)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildView(buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: !controller.isEditing.value,
          child: const FavouriteSearchBar(),
        ),
        _buildBody(buildContext),
        _buildBottom(buildContext),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localized(nothingHere),
            style: jxTextStyle.headerText(fontWeight: MFontWeight.bold6.value),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            localized(youCanLongPressAChatMessage),
            style: jxTextStyle.normalSmallText(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(buildContext) {
    return Expanded(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: colorBackground,
              child: favouriteListView(),
            ),
          ),

          /// search overlay
          Obx(() {
            return Positioned.fill(
              child: SearchOverlay(
                isVisible:
                    controller.isSearching.value && !controller.hasText.value,
                onTapCallback: () {
                  controller.isSearching.value = false;
                },
              ),
            );
          }),
          Positioned.fill(
            child: Obx(
              () => AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: controller.isCategoryExpand.value ? 1 : 0,
                child: Visibility(
                  visible: controller.isCategoryExpand.value,
                  child: GestureDetector(
                    onTap: () => controller.onClickExpandCategory(),
                    child: Container(
                      color: colorTextPrimary.withOpacity(0.54),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(
              () => Visibility(
                visible: !controller.isEditing.value,
                child: AnimatedCrossFade(
                  firstChild: categoryBar(),
                  secondChild: categoryExpandView(buildContext),
                  crossFadeState: controller.isCategoryExpand.value
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: controller.isEditing.value
          ? 52 + (MediaQuery.of(context).viewPadding.bottom)
          : 0.0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: colorBackground,
            border: Border(
              top: BorderSide(
                color: colorBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async => controller
                    .deleteFavourite(controller.selectedList, isMore: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SvgPicture.asset(
                    'assets/svgs/muti_selected_del.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      controller.selectedList.isNotEmpty
                          ? themeColor
                          : colorTextPlaceholder,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () =>
                    controller.editTag(controller.selectedList, isMore: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SvgPicture.asset(
                    'assets/svgs/muti_selected_tag.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      controller.selectedList.isNotEmpty
                          ? themeColor
                          : colorTextPlaceholder,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => objectMgr.favouriteMgr
                    .forwardFavouriteList(controller.selectedList),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SvgPicture.asset(
                    'assets/svgs/muti_selected_forward.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      controller.selectedList.isNotEmpty
                          ? themeColor
                          : colorTextPlaceholder,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 40,
      color: colorBackground,
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  !controller.isMandarin
                      ? controller.categoryList.length - 1
                      : controller.categoryList.length, (index) {
                FavouriteKeywordModel model = controller.categoryList[index];
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => controller.onClickCategory(model),
                  child: OpacityEffect(
                    child: Text(
                      model.title,
                      style: jxTextStyle.normalText(color: colorTextSecondary),
                    ),
                  ),
                );
              }),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.onClickExpandCategory(),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OpacityEffect(
                child: ClipOval(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    color: colorBorder,
                    child: SvgPicture.asset(
                      'assets/svgs/arrow_down_icon.svg',
                      color: colorTextSupporting,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryExpandView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/favourite_category_icon.svg',
                      width: 16,
                      height: 16,
                      color: colorTextSecondarySolid,
                      fit: BoxFit.fitWidth,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localized(favouriteType),
                      style: jxTextStyle.normalText(color: colorTextSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => controller.onClickExpandCategory(),
                child: OpacityEffect(
                  child: ClipOval(
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      color: colorBorder,
                      child: SvgPicture.asset(
                        'assets/svgs/arrow_up_icon.svg',
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...List.generate(
                  controller.categoryList.length,
                  (index) => FavouriteItem(
                    model: controller.categoryList[index],
                    isSelected: controller.keyWordList
                        .contains(controller.categoryList[index]),
                    callback: () {
                      controller
                          .onClickCategory(controller.categoryList[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return Visibility(
              visible: controller.tagList.isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svgs/favourite_tag_icon.svg',
                          width: 16,
                          height: 16,
                          color: colorTextSecondarySolid,
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          localized(favouriteTag),
                          style:
                              jxTextStyle.normalText(color: colorTextSecondary),
                        ),
                      ],
                    ),
                    Obx(() {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...List.generate(
                              controller.tagList.length,
                              (index) => FavouriteItem(
                                model: controller.tagList[index],
                                isSelected: controller.keyWordList
                                    .contains(controller.tagList[index]),
                                callback: () {
                                  controller.onClickCategory(
                                      controller.tagList[index]);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget favouriteListView() {
    if (controller.favouriteList.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: controller.isEditing.value ? 0 : 40),
        child: controller.isSearchMedia.value
            ? _mediaListView()
            : _defaultListView(),
      );
    } else {
      return Center(
        child: Text(
          localized(noResults),
          style: jxTextStyle.normalSmallText(color: colorTextSecondary),
        ),
      );
    }
  }

  Widget _defaultListView() {
    return SlidableAutoCloseBehavior(
      child: Obx(() {
        return ListView.builder(
          controller: controller.scrollController,
          padding: EdgeInsets.only(
              bottom: 12 + MediaQuery.of(Get.context!).viewPadding.bottom),
          itemCount: controller.favouriteList.length,
          itemBuilder: (context, index) {
            return FavouriteCellView(
              favouriteData: controller.favouriteList[index],
              index: index,
            );
          },
        );
      }),
    );
  }

  Widget _mediaListView() {
    double size = (MediaQuery.of(Get.context!).size.width) / 3;
    List<dynamic> dataList = [];

    return Padding(
      padding: EdgeInsets.only(
          bottom: 12 + MediaQuery.of(Get.context!).viewPadding.bottom),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        itemCount: controller.favouriteList.length,
        itemBuilder: (context, index) {
          FavouriteDetailData data =
              controller.favouriteList[index].content.first;
          dynamic item;

          if (data.typ == FavouriteTypeImage) {
            item = FavouriteImage.fromJson(jsonDecode(data.content!));
          } else if (data.typ == FavouriteTypeVideo) {
            item = FavouriteVideo.fromJson(jsonDecode(data.content!));
          } else {
            return const SizedBox();
          }

          dataList.add(item);

          return GestureDetector(
              onTap: () => controller.onTapMedia(context, dataList, index),
              child: data.typ == FavouriteTypeVideo
                  ? _buildVideo(item, size)
                  : _buildImage(item, size));
        },
      ),
    );
  }

  Widget _buildImage(FavouriteImage data, double size) {
    if (notBlank(data.url)) {
      return RemoteGaussianImage(
        key: ValueKey(data),
        src: data.url,
        gaussianPath: data.gausPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        mini: Config().headMin,
      );
    } else {
      return Image.file(
        File(data.filePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildVideo(FavouriteVideo data, double size) {
    return Stack(
      children: [
        data.cover.isNotEmpty
            ? RemoteImage(
                key: ValueKey(data),
                src: data.cover,
                width: size,
                height: size,
                fit: BoxFit.cover,
                mini: Config().headMin,
              )
            : Image.file(
                File(data.coverPath),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
        Center(
          child: SvgPicture.asset(
            'assets/svgs/video_play_icon.svg',
            width: 40,
            height: 40,
          ),
        ),
      ],
    );
  }
}
