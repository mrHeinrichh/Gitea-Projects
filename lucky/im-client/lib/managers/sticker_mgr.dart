import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/sticker.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/object/sticker_collection.dart';
import 'package:jxim_client/object/stickers_recently_data.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

class StickerMgr extends EventDispatcher implements MgrInterface {
  static const String eventStickerChange = "eventStickerChange";
  static const String eventGifChange = "eventGifChange";

  static const int recentEmojiLimit = 20;
  static const int recentStickerLimit = 12;
  static const int recentGifLimit = 9;

  ///贴纸数据
  List<StickerCollection> stickerCollectionList = [];
  List<Gifs> gifCollectionList = [];
  List<Sticker> favouriteStickersList = [];
  List<Sticker> recentStickersList = [];
  List<String> recentEmojiList = [];
  List<Gifs> recentGifList = [];

  RxBool isDownloading = false.obs;

  int get stickerCount =>
      stickerCollectionList.length +
      (favouriteStickersList.isNotEmpty ? 1 : 0) +
      (recentStickersList.isNotEmpty
          ? 1
          : 0); // +2 if add shop and add sticker tab

  @override
  Future<void> init() async {
    await getAllStickers();
    await getAllGifs();
    await getRecentEmojis();
    await getRecentStickers();
    await getRecentGifs();
    // await getRemoteRecentStickers();
    downloadToLocal().then((_) => isDownloading.value = false);
    // getFavouriteStickers();
  }

  @override
  Future<void> logout() async {
    stickerCollectionList.clear();
    favouriteStickersList.clear();
    recentStickersList.clear();
    recentEmojiList.clear();
    recentGifList.clear();
  }

  @override
  Future<void> register() async {}

  ///获取所有原本的贴纸
  Future<void> getAllStickers() async {
    List stickerCollections = [];
    try {
      stickerCollections = await getPresetStickers();
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ALL_STICKERS, stickerCollections);
    } catch (e) {
      stickerCollections =
          objectMgr.localStorageMgr.read(LocalStorageMgr.ALL_STICKERS) ?? [];
      mypdebug(e);
    } finally {
      stickerCollectionList = stickerCollections
          .map((collection) => StickerCollection.fromJson(collection))
          .toList();

      event(this, eventStickerChange);
    }
  }

  ///获取所有原本的贴纸
  Future<void> getAllGifs() async {
    List gifCollections = [];
    try {
      gifCollections = await getStickerGif();
      objectMgr.localStorageMgr.write(LocalStorageMgr.ALL_GIFS, gifCollections);
    } catch (e) {
      gifCollections =
          objectMgr.localStorageMgr.read(LocalStorageMgr.ALL_GIFS) ?? [];
      mypdebug(e);
    } finally {
      gifCollectionList = gifCollections
          .map((collection) => Gifs.fromJson(collection))
          .toList();

      event(this, eventGifChange);
    }
  }

  ///获取最近使用的贴纸
  List<Sticker> getRecentStickers() {
    final List localStickerList =
        objectMgr.localStorageMgr.read(LocalStorageMgr.RECENT_STICKERS) ?? [];
    recentStickersList = localStickerList
        .map<Sticker>((element) => Sticker.fromJson(element))
        .toList();
    return recentStickersList;
  }

  ///获取最近使用的emoji
  List<String> getRecentEmojis() {
    final localEmojiList = objectMgr.localStorageMgr
            .read<List<String>>(LocalStorageMgr.RECENT_EMOJIS) ??
        <String>[];
    recentEmojiList = localEmojiList;
    return recentEmojiList;
  }

  ///获取喜爱的贴纸
  Future<List<Sticker>> getFavouriteStickers() async {
    List favStickers = [];
    try {
      favStickers = await getMyFavStickers();
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.FAV_STICKERS, favStickers);
    } catch (e) {
      favStickers =
          objectMgr.localStorageMgr.read(LocalStorageMgr.FAV_STICKERS) ?? [];

      mypdebug(e);
    } finally {
      favouriteStickersList =
          favStickers.map((item) => Sticker.fromJson(item["sticker"])).toList();
    }
    return favouriteStickersList;
  }

  ///获取最近使用的gif
  List<Gifs> getRecentGifs() {
    final localGifList =
        objectMgr.localStorageMgr.read(LocalStorageMgr.RECENT_GIFS) ?? [];
    recentGifList =
        localGifList.map<Gifs>((e) => stickerGifEntityFromJson(e)).toList();
    return recentGifList;
  }

  ///下载贴纸到本地
  Future<void> downloadToLocal() async {
    if (isDownloading.value ||
            stickerCollectionList
                .isEmpty /*||
        connectivityMgr.connectivityResult == ConnectivityResult.none*/
        ) return;
    int initAmount = 20;
    isDownloading.value = true;

    ///下载贴纸合集
    for (StickerCollection stickerCollection in stickerCollectionList) {
      Uri stickerUri = Uri.parse(stickerCollection.collection.thumbnail);
      String path = Uri.decodeComponent(stickerUri.path);
      cacheMediaMgr.downloadMedia(path);

      ///下载贴纸合集里的所有贴纸
      for (Sticker sticker in stickerCollection.stickerList) {
        if (initAmount < 0) break;

        stickerUri = Uri.parse(sticker.url);
        path = Uri.decodeComponent(stickerUri.path);
        cacheMediaMgr.downloadMedia(path);
        initAmount--;
      }
    }
  }

  void updateRecentSticker(Sticker sticker) {
    ///会把相同的id的贴纸过滤出来
    final List<Sticker> tempRecentList = recentStickersList
        .where((element) => element.id == sticker.id)
        .toList();

    if (tempRecentList.isEmpty) {
      if (recentStickersList.length == recentStickerLimit) {
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
  }

  void updateRecentEmoji(String emoji) {
    if (recentEmojiList.contains(emoji)) {
      recentEmojiList.remove(emoji);
    }
    recentEmojiList.insert(0, emoji);
    if (recentEmojiList.length > recentEmojiLimit) {
      recentEmojiList.removeLast();
    }
  }

  void updateRecentGif(Gifs gif) {
    if (recentGifList.contains(gif)) {
      recentGifList.remove(gif);
    }
    recentGifList.insert(0, gif);
    if (recentGifList.length > recentGifLimit) {
      recentGifList.removeLast();
    }
  }

  void saveRecentEmojiToLocalStorage() async {
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.RECENT_EMOJIS, recentEmojiList);
  }

  void saveRecentStickerToLocalStorage() async {
    objectMgr.localStorageMgr.write(LocalStorageMgr.RECENT_STICKERS,
        recentStickersList.map((element) => element.toJson()).toList());
  }

  void saveRecentGifToLocalStorage() async {
    objectMgr.localStorageMgr.write(LocalStorageMgr.RECENT_GIFS,
        recentGifList.map((element) => element.toJson()).toList());
  }

  void saveAllRecentToLocalStorage() {
    saveRecentEmojiToLocalStorage();
    saveRecentStickerToLocalStorage();
    saveRecentGifToLocalStorage();
  }

  Future<void> updateFavSticker(Sticker sticker) async {
    final res = await addFavSticker(sticker.id);
    if (res) {
      if (!favouriteStickersList.contains(sticker)) {
        if (favouriteStickersList.length == recentStickerLimit) {
          favouriteStickersList.insert(0, sticker);
          favouriteStickersList.removeLast();
        } else {
          favouriteStickersList.insert(0, sticker);
        }
      }
      Toast.showToast(localized(addStickerFavouritesSuccessfully));
    } else {
      Toast.showToast(localized(addStickerFavouritesUnsuccessfully));
    }
  }

  Future<void> removeFavSticker(Sticker sticker) async {
    final res = await deleteFavSticker(sticker.id);
    if (res) {
      favouriteStickersList.remove(sticker);
      Toast.showToast(localized(removeStickerFavouritesSuccessfully));
    } else {
      Toast.showToast(localized(removeStickerFavouritesUnsuccessfully));
    }
  }

  Future<void> getRemoteRecentStickers() async {
    final GetStoreData res = await getStore(StoreData.recentStickers.key);
    if (notBlank(res.value)) {
      final data = stickersRecentlyDataFromJson(res.value);
      recentEmojiList = data.recentEmojiList;
      recentStickersList = data.recentStickersList;
      recentGifList = data.recentGifList;

      saveAllRecentToLocalStorage();
    }
  }

  void updateRemoteRecentStickers() async {
    saveAllRecentToLocalStorage();

    final data = StickersRecentlyData(
      recentEmojiList: recentEmojiList,
      recentStickersList: recentStickersList,
      recentGifList: recentGifList,
    );

    final bool res = await updateStore(
        StoreData.recentStickers.key, stickersRecentlyDataToJson(data),
        isBroadcast: true);
    if (res) {}
  }

  @override
  Future<void> reloadData() {
    throw UnimplementedError();
  }
}
