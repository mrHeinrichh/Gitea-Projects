import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/sticker/store/sticker_store.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/object/sticker_collection.dart';

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

  final ScrollController headerScrollController = ScrollController();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final List<Sticker> recentStickerList = [];

  final List<Sticker> favouriteStickerList = [];

  final List<StickerCollection> stickerCollectionList = [];

  int stickerCount = 0;

  ValueNotifier<int> selectedIndex = ValueNotifier(0);
  ValueNotifier<bool> isManualScroll = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    itemPositionsListener.itemPositions.addListener(() async {
      if (isManualScroll.value) {
        selectedIndex.value =
            itemPositionsListener.itemPositions.value.first.index;

        headerScrollController.animateTo(
          selectedIndex.value * 35,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }
    });

    controller =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());

    _initData();

    objectMgr.stickerMgr.on(StickerMgr.eventStickerChange, onStickerChange);
  }

  void _initData() {
    recentStickerList
      ..clear()
      ..addAll(objectMgr.stickerMgr.recentStickersList);

    favouriteStickerList
      ..clear()
      ..addAll(objectMgr.stickerMgr.favouriteStickersList);

    stickerCollectionList
      ..clear()
      ..addAll(objectMgr.stickerMgr.stickerCollectionList);

    stickerCount = objectMgr.stickerMgr.stickerCount;
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
    }

    objectMgr.chatMgr.event(
      objectMgr.chatMgr,
      ChatMgr.eventScrolling,
      data: isScrolling,
    );
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.off(StickerMgr.eventStickerChange, onStickerChange);
    selectedIndex.dispose();
    isManualScroll.dispose();
    super.dispose();
  }

  void onStickerChange(Object sender, Object type, Object? data) {
    _initData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.transparent,
          child: stickerHeader(),
        ),
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: stickerContent(),
          ),
        ),
      ],
    );
  }

  Widget tabIcon(String name) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SvgPicture.asset(
        'assets/svgs/$name.svg',
        colorFilter: const ColorFilter.mode(
          colorTextSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget stickerHeader() {
    var stickers = stickerCollectionList;
    List<Widget> stickerList = [
      if (recentStickerList.isNotEmpty) tabIcon('recent'),
      // tabIcon('add'),
      if (favouriteStickerList.isNotEmpty) tabIcon('heart_outlined'),
      ...List.generate(
        stickers.length,
        (index) => RemoteImage(
          key: ValueKey(stickers[index].collection.thumbnail),
          src: stickers[index].collection.thumbnail,
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      height: 32,
      child: ListView(
        controller: headerScrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          OpacityEffect(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (context) => stickerStore(),
                ).then((value) => Get.delete<StickerStoreController>());
              },
              child: tabIcon('shop'),
            ),
          ),
          const SizedBox(width: 2),
          ...List.generate(
            stickerCount,
            (index) {
              return GestureDetector(
                onTap: () async {
                  isManualScroll.value = false;
                  selectedIndex.value = index;

                  itemScrollController.scrollTo(
                    index: index,
                    duration: const Duration(milliseconds: 200),
                  );
                },
                child: ValueListenableBuilder(
                  valueListenable: selectedIndex,
                  builder: (_, value, __) {
                    return Container(
                      height: 32,
                      width: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: value == index
                            ? Colors.black.withOpacity(0.08)
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: stickerList[index],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget stickerContent() {
    List<Widget> stickerContentList = [
      if (recentStickerList.isNotEmpty)
        stickerSection(
          recentStickerList,
          localized(recentStickers),
        ),
      // const ImCustomSticker(),
      if (favouriteStickerList.isNotEmpty)
        stickerSection(
          favouriteStickerList,
          localized(favouriteStickers),
        ),
      ...List.generate(
        stickerCollectionList.length,
        (index) => stickerSection(
          stickerCollectionList[index].stickerList,
          stickerCollectionList[index].collection.name.capitalize!,
        ),
      ),
    ];

    return Listener(
      onPointerUp: (_) => isManualScroll.value = true,
      onPointerDown: (_) => isManualScroll.value = true,
      child: NotificationListener(
        onNotification: (notification) {
          if (notification is ScrollNotification) {
            onScroll(notification);
          }
          return false;
        },
        child: ScrollablePositionedList.builder(
          itemCount: stickerCount,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemBuilder: (context, index) => stickerContentList[index],
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        ),
      ),
    );
  }

  Widget stickerSection(List<Sticker> stickerCollection, String stickerTitle) {
    return Column(
      children: <Widget>[
        Text(
          stickerTitle,
          style: jxTextStyle.textStyleBold12(color: colorTextSecondary),
          textAlign: TextAlign.center,
        ),
        GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            crossAxisCount: (objectMgr.loginMgr.isDesktop) ? 5 : 4,
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
              },
              child: RemoteImage(
                key: ValueKey(stickerCollection[index].url),
                src: stickerCollection[index].url,
                shouldAnimate: false,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
