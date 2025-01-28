import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';

import 'package:jxim_client/api/sticker.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/sticker_collection.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class StickerController extends GetxController {
  RxString searchParam = "".obs;
  RxBool inFav = true.obs;
  List<Sticker> updatedStickerList = [];
  RxList<Sticker> favouriteStickersList = <Sticker>[].obs;
  RxList<Sticker> recentStickersList = <Sticker>[].obs;
  Chat? chat;
  RxList<Emoji> allEmojiList = <Emoji>[].obs;
  RxList<Emoji> recentEmojiList = <Emoji>[].obs;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  ///Controller变量
  final AutoScrollController scrollController = AutoScrollController();
  final TextEditingController searchController = TextEditingController();
  TextEditingController inputController = TextEditingController();

  ///Widget变量
  RxList<Widget> sliverList = RxList();
  RxList<Widget> iconList = <Widget>[
    // Icon(Icons.add_circle_outline),
  ].obs;

  void searchStickers(String param) {
    // updatedStickerList =
    //     stickerList.where((element) => element.contains(param)).toList();
    // update();
  }

  ///引导至指定的位置
  Future<void> goToPosition(int index) async {
    // if (index == 0) {
    //   Get.toNamed(RouteName.manageSticker);
    // }
    final tagValue = (iconList[index].key as ValueKey).value;
    int? scrollIndex;
    if (tagValue == 'recSticker') {
      scrollIndex = -1;
    } else if (tagValue == 'favSticker') {
      scrollIndex = -2;
    } else {
      try {
        // scrollIndex = intValue;
      } catch (_) {
        pdebug("Error parsing string");
      }
    }
    if (scrollIndex != null) {
      await scrollController.scrollToIndex(
        scrollIndex,
        preferPosition: AutoScrollPosition.begin,
      );
    } else {
      pdebug('Error getting scrolling index');
    }
  }

  ///保存最近使用贴纸
  void saveRecentSticker(Sticker sticker) {
    ///会把相同的id的贴纸过滤出来
    final List<Sticker> tempRecentList = recentStickersList
        .where((element) => element.id == sticker.id)
        .toList();

    if (tempRecentList.isEmpty) {
      if (recentStickersList.length == 12) {
        recentStickersList.insert(0, sticker);
        recentStickersList.removeLast();
      } else {
        recentStickersList.insert(0, sticker);
      }
    } else {
      final int recentIndex =
          recentStickersList.indexWhere((element) => element.id == sticker.id);
      recentStickersList.removeAt(recentIndex);
      recentStickersList.insert(0, sticker);
    }
    objectMgr.localStorageMgr.write(
      LocalStorageMgr.RECENT_STICKERS,
      recentStickersList.map((element) => element.toJson()).toList(),
    );
    recentStickersList.refresh();
    iconListReassign();
  }

  ///保存最爱贴纸
  void saveFavSticker(Sticker? sticker) async {
    if (sticker == null) return;
    final res = await addFavSticker(sticker.id);
    if (res) {
      if (!favouriteStickersList.contains(sticker)) {
        if (favouriteStickersList.length == 12) {
          favouriteStickersList.insert(0, sticker);
          favouriteStickersList.removeLast();
        } else {
          favouriteStickersList.insert(0, sticker);
        }
      }
      favouriteStickersList.refresh();
      iconListReassign();
      Toast.showToast(localized(addStickerFavouritesSuccessfully));
    } else {
      Toast.showToast(localized(addStickerFavouritesUnsuccessfully));
    }
    // checkFavAvailability(sticker);
  }

  ///选择贴纸集合
  StickerCollection? selectStickerCollection(MessageImage messageImage) {
    final int collectionId = int.parse(messageImage.url.split("/")[5]);
    return objectMgr.stickerMgr.stickerCollectionList.firstWhereOrNull(
      (element) => element.collection.collectionId == collectionId,
    );
  }

  ///选择贴纸
  Sticker? selectSticker(MessageImage messageImage) {
    final int collectionId = int.parse(messageImage.url.split("/")[5]);
    final StickerCollection? collection =
        objectMgr.stickerMgr.stickerCollectionList.firstWhereOrNull(
      (element) => element.collection.collectionId == collectionId,
    );
    if (collection != null) {
      return collection.stickerList
          .firstWhereOrNull((element) => element.url == messageImage.url);
    }
    return null;
  }

  ///更新header列表
  void iconListReassign() {
    iconList.clear();

    iconList.value = [
      if (recentStickersList.isNotEmpty)
        CustomHeaderIcon(
          key: const ValueKey("recSticker"),
          viewIcon: Icon(
            Icons.access_time_outlined,
            size: 25,
            color: themeColor,
          ),
        ),
      if (favouriteStickersList.isNotEmpty)
        CustomHeaderIcon(
          key: const ValueKey("favSticker"),
          viewIcon: Icon(
            Icons.bookmark_border,
            size: 25,
            color: themeColor,
          ),
        ),
    ];
    for (var element in objectMgr.stickerMgr.stickerCollectionList) {
      final String keyValue = element.collection.collectionId.toString();
      iconList.add(
        CustomHeaderIcon(
          key: ValueKey(keyValue),
          viewIcon: RemoteImage(
            src: element.collection.thumbnail,
          ),
        ),
      );
    }
    iconList.refresh();
  }

  void favFunction(MessageImage messageImage) {
    if (inFav.value) {
      saveFavSticker(selectSticker(messageImage));
    } else {
      // removeFavSticker(selectSticker(messageImage));
    }
  }

  ///Emoji部分===============================================================
  ///选择emoji
  void selectEmoji(int index) {
    final Emoji selectedEmoji = allEmojiList[index];
    inputController.text += selectedEmoji.char;
    updateRecentEmoji(selectedEmoji);
  }

  ///选择最近使用emoji
  void selectRecentEmoji(int index) {
    final Emoji selectedEmoji = recentEmojiList[index];
    inputController.text += selectedEmoji.char;
    updateRecentEmoji(selectedEmoji);
  }

  ///更新最近使用emoji
  void updateRecentEmoji(Emoji emoji) {
    if (recentEmojiList.contains(emoji)) {
      if (recentEmojiList.length >= 15) {
        recentEmojiList.removeLast();
        recentEmojiList.insert(0, emoji);
      } else {
        recentEmojiList.insert(0, emoji);
      }
    } else {
      final int index =
          recentEmojiList.indexWhere((element) => element == emoji);
      recentEmojiList.removeAt(index);
      recentEmojiList.insert(index, emoji);
    }
  }
}

///贴纸标题图标
class CustomHeaderIcon extends StatelessWidget {
  final Widget viewIcon;

  const CustomHeaderIcon({
    super.key, // Initialize the key parameter in the constructor
    required this.viewIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 0 : 8,
        horizontal: isDesktop ? 0 : 10,
      ),
      child: viewIcon,
    );
  }
}
