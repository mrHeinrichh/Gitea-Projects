import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class StickerDialog extends StatefulWidget {
  StickerDialog({
    super.key,
    required this.chatID,
  }) {
    Get.put(StickerController());
  }

  final int chatID;

  @override
  State<StickerDialog> createState() => _StickerDialogState();
}

class _StickerDialogState extends State<StickerDialog>
    with SingleTickerProviderStateMixin {
  List<GlobalKey> stickerCollectionKeys = [];
  CustomInputController? controller;
  AutoScrollController scrollController = AutoScrollController();
  late TabController tabController;
  int currentTabIdx = 0;

  bool isSwitchingBetweenStickerAndKeyboard = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomInputController>(tag: widget.chatID.toString());

    tabController = TabController(
      length: objectMgr.stickerMgr.stickerCount,
      vsync: this,
    );

    tabController.addListener(() {
      if (currentTabIdx != tabController.index) {
        currentTabIdx = tabController.index;
        if (mounted) setState(() {});
      }
    });
    prepareStickerKey();

    objectMgr.stickerMgr.on(StickerMgr.eventStickerChange, onStickerChange);
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.off(StickerMgr.eventStickerChange, onStickerChange);
    super.dispose();
  }

  void onStickerChange(Object sender, Object type, Object? data) {
    if (stickerCollectionKeys.length != objectMgr.stickerMgr.stickerCount &&
        stickerCollectionKeys.length < objectMgr.stickerMgr.stickerCount) {
      for (int i = stickerCollectionKeys.length;
          i < objectMgr.stickerMgr.stickerCount;
          i++) {
        stickerCollectionKeys.add(GlobalKey());
      }

      if (mounted) setState(() {});
    }
  }

  void prepareStickerKey() {
    if (objectMgr.stickerMgr.recentStickersList.isNotEmpty) {
      stickerCollectionKeys.add(GlobalKey());
    }

    if (objectMgr.stickerMgr.favouriteStickersList.isNotEmpty) {
      stickerCollectionKeys.add(GlobalKey());
    }

    for (int i = 0;
        i < objectMgr.stickerMgr.stickerCollectionList.length;
        i++) {
      stickerCollectionKeys.add(GlobalKey());
    }
  }

  void scrollToSpecificPosition(int index) async {
    if (index == 0) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    const animateDuration = Duration(milliseconds: 100);
    const curves = Curves.easeInOutCubic;

    List<int> currIdxList = scrollController.tagMap.keys.toList();
    if (currIdxList.isNotEmpty) {
      int currIdx = currIdxList.first;

      if (currIdx == index) {
        scrollController.scrollToIndex(
          currIdx,
          duration: animateDuration,
          preferPosition: AutoScrollPosition.begin,
        );
        return;
      }

      if (index > currIdx) {
        if (stickerCollectionKeys[index].currentContext != null) {
          scrollController.scrollToIndex(
            index,
            duration: animateDuration,
            preferPosition: AutoScrollPosition.begin,
          );

          return;
        } else {
          while (stickerCollectionKeys[index].currentContext == null) {
            scrollController.animateTo(
              scrollController.offset + (ObjectMgr.screenMQ!.size.height * 0.4),
              duration: const Duration(milliseconds: 20),
              curve: Curves.linear,
            );

            await Future.delayed(const Duration(milliseconds: 20));

            if (stickerCollectionKeys[index].currentContext != null ||
                scrollController.offset >=
                    scrollController.position.maxScrollExtent) {
              break;
            }
          }

          if (stickerCollectionKeys[index].currentContext != null) {
            scrollController.scrollToIndex(
              index,
              duration: animateDuration,
              preferPosition: AutoScrollPosition.begin,
            );
            return;
          }
        }
      } else {
        if (stickerCollectionKeys[index].currentContext != null) {
          scrollController.scrollToIndex(
            index,
            duration: animateDuration,
            preferPosition: AutoScrollPosition.begin,
          );
          return;
        } else {
          while (stickerCollectionKeys[index].currentContext == null) {
            scrollController.animateTo(
              scrollController.offset - (ObjectMgr.screenMQ!.size.height * 0.4),
              duration: const Duration(milliseconds: 20),
              curve: curves,
            );

            await Future.delayed(const Duration(milliseconds: 20));

            if (stickerCollectionKeys[index].currentContext != null ||
                scrollController.offset <=
                    scrollController.position.minScrollExtent) {
              break;
            }
          }

          if (stickerCollectionKeys[index].currentContext != null) {
            scrollController.scrollToIndex(
              index,
              duration: animateDuration,
              preferPosition: AutoScrollPosition.begin,
            );
            return;
          }
        }
      }
    }
  }

  void onTabChange(int index) {
    currentTabIdx = index;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 200,
          bottom: 65,
          left: 10,
          right: 10,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0, 1), // Top shadow
                  blurRadius: 1,
                ),
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(1, 0), // Right shadow
                  blurRadius: 1,
                ),
              ],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: kToolbarHeight,
                  width: 400,
                  child: TabBar(
                    controller: tabController,
                    onTap: onTabChange,
                    isScrollable: true,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    labelPadding: EdgeInsets.zero,
                    indicatorColor: Colors.transparent,
                    tabs: List<Widget>.generate(
                        objectMgr.stickerMgr.stickerCount, (index) {
                      return buildTab(index);
                    }),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: List<Widget>.generate(
                        objectMgr.stickerMgr.stickerCount, (listIdx) {
                      return buildTabView(listIdx);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTab(int index) {
    if (objectMgr.stickerMgr.recentStickersList.isNotEmpty && index == 0) {
      return buildTabItem(
        Icons.access_time_outlined,
        colorBackground6,
        colorBackground6,
        recentStickers,
      );
    } else if (objectMgr.stickerMgr.favouriteStickersList.isNotEmpty &&
        index < 2) {
      return buildTabItem(
        Icons.bookmark_border,
        colorBackground6,
        colorBackground6,
        favouriteStickers,
      );
    } else {
      int idx = index;
      if (objectMgr.stickerMgr.recentStickersList.isNotEmpty) {
        idx--;
      }

      if (objectMgr.stickerMgr.favouriteStickersList.isNotEmpty) {
        idx--;
      }

      return buildTabItemWithImage(
        objectMgr.stickerMgr.stickerCollectionList[idx].collection.thumbnail,
        colorBackground6,
        objectMgr.stickerMgr.stickerCollectionList[idx].collection.name
            .toUpperCase(),
        50,
        50,
      );
    }
  }

  Widget buildTabView(int listIdx) {
    if (objectMgr.stickerMgr.recentStickersList.isNotEmpty && listIdx == 0) {
      return buildStickerSection(
        objectMgr.stickerMgr.recentStickersList,
        recentStickers,
        listIdx,
        listIdx,
      );
    } else if (objectMgr.stickerMgr.favouriteStickersList.isNotEmpty &&
        listIdx < 2) {
      return buildStickerSection(
        objectMgr.stickerMgr.favouriteStickersList,
        favouriteStickers,
        listIdx,
        listIdx,
      );
    } else {
      int idx = listIdx;
      if (objectMgr.stickerMgr.recentStickersList.isNotEmpty) {
        idx--;
      }

      if (objectMgr.stickerMgr.favouriteStickersList.isNotEmpty) {
        idx--;
      }

      return buildStickerSection(
        objectMgr.stickerMgr.stickerCollectionList[idx].stickerList,
        objectMgr.stickerMgr.stickerCollectionList[idx].collection.name
            .toUpperCase(),
        idx,
        listIdx,
      );
    }
  }

  Widget buildTabItem(
    IconData icon,
    Color tabColor,
    Color iconColor,
    String label,
  ) {
    return Tab(
      child: Container(
        color: tabColor,
        padding: EdgeInsets.symmetric(
          vertical: objectMgr.loginMgr.isDesktop ? 10 : 8,
          horizontal: objectMgr.loginMgr.isDesktop ? 10 : 10,
        ),
        child: Icon(
          icon,
          size: 25,
          color: iconColor,
        ),
      ),
    );
  }

  Widget buildTabItemWithImage(
    String imageUrl,
    Color tabColor,
    String label,
    double width,
    double height,
  ) {
    return Tab(
      child: Container(
        color: tabColor,
        padding: EdgeInsets.symmetric(
          vertical: objectMgr.loginMgr.isDesktop ? 0 : 8,
          horizontal: objectMgr.loginMgr.isDesktop ? 10 : 10,
        ),
        child: RemoteImage(
          src: imageUrl,
          width: width,
          height: height,
        ),
      ),
    );
  }

  Widget buildStickerSection(
    List<Sticker> stickerCollection,
    String stickerTitle,
    int listIdx,
    int oriIdx,
  ) {
    return ListView(
      children: <Widget>[
        AutoScrollTag(
          key: oriIdx > stickerCollectionKeys.length
              ? GlobalKey()
              : stickerCollectionKeys[oriIdx],
          controller: scrollController,
          index: oriIdx,
          child: Container(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: MFontWeight.bold6.value,
                ),
                child: Text(
                  stickerTitle,
                ),
              ),
            ),
          ),
        ),
        GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: stickerCollection.length,
          itemBuilder: (BuildContext context, int gridIdx) {
            return GestureDetector(
              onTap: () => controller?.sendSticker(stickerCollection[gridIdx]),
              // onLongPress: () =>
              //     controller?.openStickerDialog(stickerCollection[gridIdx]),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: stickerItem(
                  stickerCollection,
                  gridIdx,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget stickerItem(List<Sticker> stickerList, int gridIdx) {
    return RemoteImage(
      src: stickerList[gridIdx].url,
    );
  }
}
