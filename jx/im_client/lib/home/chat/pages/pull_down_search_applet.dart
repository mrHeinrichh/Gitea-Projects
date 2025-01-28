import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/item_views/discovery_applet_item.dart';
import 'package:jxim_client/home/chat/pages/pull_down_search_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class PullDownSearchApplet extends GetView<PullDownSearchController> {
  const PullDownSearchApplet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            Expanded(
              child: Listener(
                onPointerMove: (_) {
                  controller.focusNode.unfocus();
                },
                child: Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: !controller.isTyping.value
                        ? _buildViewBeforeSearch(context)
                        : _buildViewAfterSearch(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(border: customBorder),
      child: CustomSearchBar(
        autofocus: true,
        focusNode: controller.focusNode,
        controller: controller.searchInputController,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        onCancelClick: controller.onCancelClick,
        onClearClick: controller.onClearClick,
        onChanged: (_) => controller.onSearch(),
      ),
    );
  }

  Widget _buildSearchTile(String keyword) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => controller.onShortcutSearch(keyword),
              child: OpacityEffect(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/svgs/reel_resent_search_icon.svg",
                      width: 24,
                      height: 24,
                      clipBehavior: Clip.none,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        keyword,
                        style: jxTextStyle.textStyleBold17(
                            fontWeight: MFontWeight.bold4.value),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBeforeSearch(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ///search history
        Obx(
          () => Visibility(
            visible: controller.searchRecord.isNotEmpty,
            child: Container(
              decoration: BoxDecoration(border: customBorder),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "最近搜索",
                          style: jxTextStyle.textStyle13(
                              color: colorTextLevelTwo),
                        ),
                        CustomImage(
                          'assets/svgs/delete_icon_new.svg',
                          size: 24,
                          color: colorTextSecondary,
                          onClick: controller.deleteAllSearchRecord,
                        ),
                      ],
                    ),
                  ),
                  for (int index = 0;
                      index < controller.searchRecord.length;
                      index++)
                    _buildSearchTile(controller.searchRecord[index]),
                ],
              ),
            ),
          ),
        ),

        Obx(
          () => Visibility(
            visible: controller.exploreApps.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                11,
                16,
                8,
              ),
              child: Text(
                localized(discoverMiniApp),
                style: jxTextStyle.textStyle13(
                  color: colorTextLevelTwo,
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => Visibility(
            visible: controller.exploreApps.isNotEmpty,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.exploreApps.length,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = controller.exploreApps[index];
                return DiscoveryAppletItem(
                  imgPath: item.icon ?? '',
                  title: item.name ?? '',
                  subtitle: item.description ?? '',
                  isCollected: item.favoriteAt != 0,
                  onClickIcon: () {
                    controller.toggleFavorite(item, controller.exploreApps);
                  },
                  onClick: () {
                    controller.joinMiniApp(item, context);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewAfterSearch(BuildContext context) {
    return Obx(
      () {
        if (controller.isSearching.value) {
          return const SizedBox.shrink();
        }

        if (controller.searchApps.isEmpty) {
          return Center(
            child: SearchEmptyState(
              emptyMessage: localized(noRelevantContent),
              fixCenter: true,
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.searchApps.length,
          padding: EdgeInsets.only(
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = controller.searchApps[index];
            return DiscoveryAppletItem(
              imgPath: item.icon ?? '',
              title: item.name ?? '',
              subtitle: item.description ?? '',
              isCollected: item.favoriteAt != 0,
              onClickIcon: () {
                controller.toggleFavorite(item, controller.searchApps);
              },
              onClick: () {
                controller.joinMiniApp(item, context);
              },
            );
          },
        );
      },
    );
  }
}
