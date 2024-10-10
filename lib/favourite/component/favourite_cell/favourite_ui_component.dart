import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_tag_item.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_base.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class FavouriteUIComponent extends FavouriteUIBase<FavouriteController> {
  const FavouriteUIComponent({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget build(BuildContext context) {
    FavouriteData favouriteData = controller.favouriteList[index];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => controller.longPressItem(favouriteData),
      onTap: () => controller.onClickItem(index),
      child: Row(
        children: [
          ClipRRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              alignment: Alignment.centerLeft,
              curve: Curves.easeInOutCubic,
              widthFactor: controller.isEditing.value ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.only(left: 16),
                child: CheckTickItem(
                  isCheck: controller.selectedList.contains(favouriteData),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: const BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              child: Slidable(
                key: UniqueKey(),
                closeOnScroll: true,
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.5,
                  children: [
                    CustomSlidableAction(
                      onPressed: (_) => controller.editTag([favouriteData]),
                      backgroundColor: colorOrange,
                      foregroundColor: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/tag_fill_icon.svg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.fill,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            localized(buttonEdit),
                            style: jxTextStyle.supportText(color: colorWhite),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    CustomSlidableAction(
                      onPressed: (_) =>
                          controller.deleteFavourite([favouriteData]),
                      backgroundColor: colorRed,
                      foregroundColor: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/delete2_icon.svg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.fill,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            localized(buttonDelete),
                            style: jxTextStyle.supportText(color: colorWhite),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                child: buildContent(favouriteData),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent(FavouriteData favouriteData) {
    return OverlayEffect(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildContentView(),
            buildInfoView(favouriteData),
            buildTagView(favouriteData),
          ],
        ),
      ),
    );
  }

  Widget buildInfoView(FavouriteData favouriteData) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Visibility(
                visible: favouriteData.isUploaded == 0,
                child: const Padding(
                  padding: EdgeInsets.only(right: 14.0),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: favouriteData.isNote,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: SvgPicture.asset(
                    'assets/svgs/note_icon.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
              Text(
                objectMgr.favouriteMgr.getFavouriteAuthorName(favouriteData),
                style: jxTextStyle.supportText(color: colorTextSecondary),
              ),
            ],
          ),
          Text(
            timeText(favouriteData),
            style: jxTextStyle.supportText(color: colorTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget buildTagView(FavouriteData favouriteData) {
    return Visibility(
      visible: favouriteData.tag.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
          direction: Axis.horizontal,
          spacing: 16,
          runSpacing: 4,
          children: List.generate(
            favouriteData.tag.length,
            (index) => FavouriteTagItem(text: favouriteData.tag[index]),
          ),
        ),
      ),
    );
  }

  String timeText(FavouriteData favouriteData) {
    String time = "";
    if (favouriteData.updatedAt != null) {
      time = FormatTime.chartTime(
        favouriteData.updatedAt ?? 0,
        true,
        todayShowTime: true,
        dateStyle: DateStyle.MMDDYYYY,
      );
    }

    return time;
  }

  @override
  Widget buildContentView() {
    return const SizedBox();
  }
}
