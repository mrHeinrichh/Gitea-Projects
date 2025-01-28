import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class StickerComponent extends StatefulWidget {
  final Chat chat;

  const StickerComponent({
    super.key,
    required this.chat,
  });

  @override
  State<StickerComponent> createState() => _StickerComponentState();
}

class _StickerComponentState extends State<StickerComponent> {
  CustomInputController? controller;
  final ItemScrollController itemScrollController = ItemScrollController();

  // final ItemScrollController titleScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  ValueNotifier<int> selectedIndex = ValueNotifier(0);

  final List<Sticker> recentStickerList = [];

  final List<Sticker> favouriteStickersList = [];

  @override
  void initState() {
    super.initState();

    itemPositionsListener.itemPositions.addListener(() {
      selectedIndex.value =
          itemPositionsListener.itemPositions.value.first.index;
    });

    controller =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());

    recentStickerList.addAll(objectMgr.stickerMgr.recentStickersList);

    favouriteStickersList.addAll(objectMgr.stickerMgr.favouriteStickersList);
  }

  void onScroll(ScrollNotification notification) async {
    final bool isScrolling;

    /// 是否应该滑动到最底部
    if (notification is UserScrollNotification) {
      isScrolling = notification.direction != ScrollDirection.idle;
    } else if (notification is ScrollEndNotification) {
      /// 滑动停止同步已读
      isScrolling = false;
    } else {
      isScrolling = true;
      // titleScrollController.scrollTo(
      //   index: selectedIndex.value,
      //   alignment: 0.1,
      //   duration: const Duration(
      //     milliseconds: 100,
      //   ),
      // );
    }

    objectMgr.chatMgr.event(
      objectMgr.chatMgr,
      ChatMgr.eventScrolling,
      data: isScrolling,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(color: Colors.transparent, child: stickerHeader()),
        ImGap.vGap8,
        Expanded(
          child: Container(
              color: Colors.transparent,
              child: stickerContent()), // Add color for debugging
        ),
      ],
    );
  }

  List<Widget> getStickerHeaderList() {
    Widget tabIcon(String name) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: SvgPicture.asset(
          'assets/svgs/$name.svg',
          colorFilter: const ColorFilter.mode(
            JXColors.black48,
            BlendMode.srcIn,
          ),
        ),
      );
    }

    var stickers = objectMgr.stickerMgr.stickerCollectionList;
    return [
      // tabIcon('shop'),
      if (recentStickerList.isNotEmpty) tabIcon('recent'),
      // tabIcon('add'),
      if (favouriteStickersList.isNotEmpty) tabIcon('heart_outlined'),
      ...List.generate(
        stickers.length,
        (index) => RemoteImage(
          key: ValueKey(stickers[index].collection.thumbnail),
          src: stickers[index].collection.thumbnail,
        ),
      ),
    ];
  }

  Widget stickerHeader() {
    print('check sticker count: ${objectMgr.stickerMgr.stickerCount}');
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4).w,
      alignment: Alignment.center,
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12).w,
        itemCount: objectMgr.stickerMgr.stickerCount,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () async {
              itemScrollController.scrollTo(
                index: index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
            child: ValueListenableBuilder(
              valueListenable: selectedIndex,
              builder: (_, value, __) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          value == index ? JXColors.black8 : Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: getStickerHeaderList()[index],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Widget> getStickerContentList() {
    return [
      // const SizedBox(), // Shop
      if (recentStickerList.isNotEmpty)
        stickerSection(
          recentStickerList,
          localized(recentStickers),
        ),
      // const ImCustomSticker(),
      if (favouriteStickersList.isNotEmpty)
        stickerSection(
          objectMgr.stickerMgr.favouriteStickersList,
          localized(favouriteStickers),
        ),
      ...List.generate(
        objectMgr.stickerMgr.stickerCollectionList.length,
        (index) => stickerSection(
          objectMgr.stickerMgr.stickerCollectionList[index].stickerList,
          objectMgr.stickerMgr.stickerCollectionList[index].collection.name
              .capitalize!,
        ),
      ),
    ];
  }

  Widget stickerContent() {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          onScroll(notification);
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: objectMgr.stickerMgr.stickerCount,
        itemBuilder: (context, index) => getStickerContentList()[index],
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        // padding: const EdgeInsets.only(bottom: 50), temp fix last index not selecting
      ),
    );
  }

  Widget stickerSection(List<Sticker> stickerCollection, String stickerTitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16).w,
      child: Column(
        children: <Widget>[
          Text(
            stickerTitle,
            style:
                jxTextStyle.textStyleBold12(color: JXColors.secondaryTextBlack),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.w),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              crossAxisCount: 4,
            ),
            itemCount: stickerCollection.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () async {
                  controller?.onSend(
                    null,
                    isSendSticker: true,
                    sticker: stickerCollection[index],
                  );
                  objectMgr.stickerMgr
                      .updateRecentSticker(stickerCollection[index]);
                  recentStickerList
                      .assignAll(objectMgr.stickerMgr.recentStickersList);
                  if (mounted) setState(() {});
                },
                child: RemoteImage(
                  key: ValueKey(stickerCollection[index].url),
                  src: stickerCollection[index].url,
                  shouldAnimate: false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
