import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/reel/components/search_tile.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/reel_search/result_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';

import '../../utils/color.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../views/component/click_effect_button.dart';
import '../../views/component/new_appbar.dart';

class ReelSearchView extends GetView<ReelSearchController> {
  const ReelSearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        leadingWidth: 0,
        isBackButton: false,
        titleWidget: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => controller.onBackClick(),
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SvgPicture.asset(
                  'assets/svgs/Back.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                ),
              ),
            ),
            SearchInput(),
            GestureDetector(
              onTap: () =>
                  controller.onSearch(controller.searchController.text),
              child: OpacityEffect(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    localized(search),
                    style: jxTextStyle.textStyle17(
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 12.0,
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: !controller.isSearching.value &&
                    controller.tagList.length > 0,
                child: SizedBox(
                  height: 30,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.tagList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return tagItem(index, controller.tagList[index]);
                    },
                  ),
                ),
              ),
              controller.isSearching.value ? SearchContent() : ResultContent()
            ],
          ),
        ),
      ),
    );
  }

  Widget SearchInput() {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: JXColors.bgSearchBarTextField,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          contextMenuBuilder: textMenuBar,
          controller: controller.searchController,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onTap: () => controller.isSearching(true),
          autofocus: true,
          cursorColor: accentColor,
          maxLines: 1,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.text,
          style: jxTextStyle.textStyle16(),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isCollapsed: true,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36, // Set minimum width
            ),
            prefixIcon: SvgPicture.asset(
              'assets/svgs/Search_thin.svg',
              width: 25,
              height: 25,
              colorFilter: const ColorFilter.mode(
                  JXColors.primaryTextBlack, BlendMode.srcIn),
            ),
            hintText: localized(hintSearch),
            hintStyle: jxTextStyle.textStyle16(
              color: JXColors.supportingTextBlack,
            ),
            suffixIcon: GestureDetector(
              onTap: () => controller.clearInput(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SvgPicture.asset(
                  'assets/svgs/close_round_icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                      JXColors.iconSecondaryColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget SearchContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Visibility(
            visible: controller.historyList.length > 0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.5, color: JXColors.outlineColor),
                ),
              ),
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                      controller.historyList.length,
                      (index) {
                        String title = controller.historyList[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => controller.onSearch(title),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SearchTile(
                              title: title,
                              onClose: () => controller.clearHistory(title),
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "全部搜索记录",
                        style: jxTextStyle.textStyle17(
                            color: JXColors.secondaryTextBlack),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      "猜你想搜索",
                      style: jxTextStyle.textStyleBold17(
                          fontWeight: MFontWeight.bold6.value),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: SvgPicture.asset(
                            'assets/svgs/refresh_icon.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              JXColors.secondaryTextBlack,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => controller.getSuggestSearch(),
                          child: Text(
                            "换一换",
                            style: jxTextStyle.textStyleBold17(
                                color: JXColors.secondaryTextBlack),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  mainAxisExtent: 20,
                ),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: controller.suggestSearchList.length,
                itemBuilder: (context, index) {
                  final item = controller.suggestSearchList[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => controller.onSearch(item),
                    child: Text(
                      item,
                      style: jxTextStyle.textStyle17(),
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget ResultContent() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: controller.resultController,
          itemCount: controller.resultList.length,
          itemBuilder: (BuildContext context, int index) {
            final item = controller.resultList[index];
            return AutoScrollTag(
              key: ValueKey(item.post!.id!),
              index: index,
              controller: controller.resultController,
              child: ResultItem(
                key: controller.getResultItemKey(item.post!.id!),
                reelPost: item,
                index: index,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget tagItem(int index, String tag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (index == 0) {
          controller.onSearch("", isSave: false);
        } else {
          controller.onSearch(tag, isSave: false);
        }
      },
      child: OpacityEffect(
        child: Container(
          margin: EdgeInsets.only(
              right: (index == controller.tagList.length - 1) ? 0 : 8),
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JXColors.primaryTextBlack.withOpacity(0.06),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Text(
            tag,
            style: jxTextStyle.textStyleBold14(
              color: (controller.searchKeyword == tag)
                  ? JXColors.primaryTextBlack
                  : JXColors.secondaryTextBlack,
              fontWeight: (controller.searchKeyword == tag)
                  ? MFontWeight.bold6.value
                  : MFontWeight.bold4.value,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
