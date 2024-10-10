import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/components/reel_search_input.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/reel_search/result_item.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/no_content_view.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelSearchView extends GetView<ReelSearchController> {
  final String searchTag;
  final ReelTagBackFromEnum? fromTagPage;
  final Function()? onBack;

  const ReelSearchView({
    super.key,
    this.searchTag = '',
    this.fromTagPage,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      body: WillPopScope(
        onWillPop: () async {
          if (searchTag != '') {
            //針對由視頻點選tag跳轉近來的情境
            _fromTagBack();
            return false;
          } else {
            return controller.willPop();
          }
        },
        child: Column(
          children: [
            ReelSearchInput(
              controller: controller.searchController,
              focusNode: controller.focusNode,
              onChanged: (value) => controller.getSearchCompletion(value),
              onClick: () => controller.isSearching(true),
              hasAutoFocus: false,
              onBackClick: () {
                if (searchTag != '') {
                  //針對由視頻點選tag跳轉近來的情境
                  _fromTagBack();
                } else {
                  controller.onBackClick();
                }
              },
              onClearClick: () => controller.clearInput(),
              onSearchClick: () =>
                  controller.onSearch(controller.searchController.text),
            ),
            Expanded(
              child: Obx(
                () => controller.isSearching.value
                    ? controller.getSearchContent()
                    : resultContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultContent(BuildContext context) {
    return controller.resultList.isNotEmpty
        ? Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scroll) {
                  controller.onScroll(scroll);
                  return true;
                },
                child: VisibilityDetector(
                  key: ValueKey(controller.searchScrollerKey),
                  onVisibilityChanged: (visibilityInfo) {
                    return;
                  },
                  child: CustomScrollView(
                    controller: controller.resultController,
                    physics: const _CustomBouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: VisibilityDetector(
                          key: ValueKey(controller.tagScrollerKey),
                          onVisibilityChanged: (visibilityInfo) {
                            if (visibilityInfo.visibleFraction == 1.0) {
                              controller.resultTagRect =
                                  visibilityInfo.visibleBounds;
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: (controller.resultList.isNotEmpty &&
                                      controller.tagList.isNotEmpty)
                                  ? 12.0
                                  : 0,
                              bottom: (controller.resultList.isNotEmpty &&
                                      controller.tagList.isNotEmpty)
                                  ? 16.0
                                  : 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Visibility(
                                  visible: controller.resultList.isNotEmpty &&
                                      controller.tagList.isNotEmpty,
                                  child: SizedBox(
                                    height: 30,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: controller.tagList.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return tagItem(
                                          index,
                                          controller.tagList[index],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => SliverList.builder(
                          itemCount: controller.resultList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = controller.resultList[index];
                            return ResultItem(
                              key: ValueKey(item.id.value!),
                              post: item,
                              index: index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : controller.isLoading.value
            ? const SizedBox() //為了讓loading中不要先閃一下無資料的畫面
            : reelSearchNoContentView();
  }

  Widget reelSearchNoContentView() {
    return const Column(
      children: [
        SizedBox(
          height: 350,
          child: NoContentView(
            subtitle: '',
          ),
        ),
      ],
    );
  }

  Widget tagItem(int index, String tag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (index == 0) {
          controller.onSearch("", isSave: false);
        } else {
          controller.onSearch(tag, isSave: true);
        }
      },
      child: OpacityEffect(
        child: Container(
          margin: EdgeInsets.only(
            right: (index == controller.tagList.length - 1) ? 0 : 8,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorTextPrimary.withOpacity(0.06),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Text(
            tag,
            style: jxTextStyle.textStyleBold14(
              color: (controller.searchKeyword.value == tag)
                  ? colorTextPrimary
                  : colorTextSecondary,
              fontWeight: (controller.searchKeyword.value == tag)
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

  _fromTagBack() {
    //從視頻預覽
    if (fromTagPage == ReelTagBackFromEnum.reelPreview) {
      //從視頻預覽,但又點了搜尋的視頻的情況
      controller.onTagResultBackClick(
        tagBackFrom: fromTagPage,
      );
      if (onBack != null) onBack!();
    } else {
      //視頻主頁
      controller.onTagResultBackClick(
        tagBackFrom: fromTagPage,
      );
    }
  }
}

class _CustomBouncingScrollPhysics extends BouncingScrollPhysics {
  const _CustomBouncingScrollPhysics({super.parent});

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  /// This is done by reducing the ratio of the scroll effect output vs the
  /// scroll gesture input.
  ///
  /// This factor starts at 0.52 and progressively becomes harder to overscroll
  /// as more of the area past the edge is dragged in (represented by an increasing
  /// `overscrollFraction` which starts at 0 when there is no overscroll).
  @override
  double frictionFactor(double overscrollFraction) {
    return 0.35 * pow(1 - overscrollFraction, 2);
  }

  @override
  _CustomBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart = max(
      clampDouble(position.minScrollExtent - position.pixels, 0.0, 150),
      0.0,
    );
    final double overscrollPastEnd =
        max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = max(overscrollPastStart, overscrollPastEnd);

    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension,
          )
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    if (overscrollPast == 150.0) {
      return 0.0;
    }

    if (easing && decelerationRate == ScrollDecelerationRate.fast) {
      return direction * offset.abs();
    }
    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
    double extentOutside,
    double absDelta,
    double gamma,
  ) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }
}
