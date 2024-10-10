import 'package:collection/collection.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/sticker.dart';
import 'package:jxim_client/managers/object_mgr.dart';
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
  static const String keyShowEmojiPanelClick = 'keyShowEmojiPanelClick';
  static const String keyChatPopMenuAreaEvent = 'keyChatPopMenuAreaEvent';

  static const int recentEmojiLimit = 20;
  static const int recentStickerLimit = 12;
  static const int recentGifLimit = 9;

  final isShowEmojiPanel = false.obs;

  ///贴纸数据
  List<StickerCollection> stickerCollectionList = [];
  Set<StickerCollection> selectedStickerCollections = {};
  List<Gifs> gifCollectionList = [];
  List<Sticker> favouriteStickersList = [];
  List<Sticker> recentStickersList = [];
  List<String> recentEmojiList = [];
  List<Gifs> recentGifList = [];

  RxBool isDownloading = false.obs;

  int get stickerCount =>
      stickerCollectionList.length +
      (favouriteStickersList.isNotEmpty ? 1 : 0) +
      (recentStickersList.isNotEmpty ? 1 : 0);

  List<int> get stickerCollectionIds =>
      stickerCollectionList.map((e) => e.collection.collectionId).toList();

  List<int> get selectedStickerCollectionIds =>
      selectedStickerCollections.map((e) => e.collection.collectionId).toList();

  void onSelectedStickerCollectionChanged(StickerCollection collection) {
    final oldCollection = selectedStickerCollections.firstWhereOrNull(
      (element) =>
          element.collection.collectionId == collection.collection.collectionId,
    );

    if (oldCollection != null) {
      selectedStickerCollections.remove(oldCollection);
    } else {
      selectedStickerCollections.add(collection);
    }

    event(this, eventStickerChange);
  }

  @override
  Future<void> init() async {
    await getAllStickers();
    await getAllGifs();
    getRecentEmojis();
    getRecentStickers();
    getRemoteRecentStickers();
    getRecentGifs();
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
      stickerCollections = await getMyStickerCollection();
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ALL_STICKERS, stickerCollections);
    } catch (e) {
      stickerCollections =
          objectMgr.localStorageMgr.read(LocalStorageMgr.ALL_STICKERS) ?? [];
      pdebug(e);
    } finally {
      stickerCollectionList.clear();
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
      pdebug(e);
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

      pdebug(e);
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
    final List<Gifs> tempRecentList =
        recentGifList.where((element) => element.id == gif.id).toList();

    if (tempRecentList.isEmpty) {
      if (recentGifList.length == recentGifLimit) {
        recentGifList.insert(0, gif);
        recentGifList.removeLast();
      } else {
        recentGifList.insert(0, gif);
      }
    } else {
      final int recentIndex =
          recentGifList.indexWhere((element) => element.id == gif.id);
      recentGifList.removeAt(recentIndex);
      recentGifList.insert(0, gif);
    }
  }

  void saveRecentEmojiToLocalStorage() async {
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.RECENT_EMOJIS, recentEmojiList);
  }

  void saveRecentStickerToLocalStorage() async {
    objectMgr.localStorageMgr.write(
      LocalStorageMgr.RECENT_STICKERS,
      recentStickersList.map((element) => element.toJson()).toList(),
    );
  }

  void saveRecentGifToLocalStorage() async {
    objectMgr.localStorageMgr.write(
      LocalStorageMgr.RECENT_GIFS,
      recentGifList.map((element) => element.toJson()).toList(),
    );
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
      StoreData.recentStickers.key,
      stickersRecentlyDataToJson(data),
      isBroadcast: true,
    );
    if (res) {}
  }

  Future<void> addStickerCollection(StickerCollection collection) async {
    showLoading(msg: "");
    await requestAddCollection(collection.collection.collectionId)
        .then((result) {
      if (result == true) {
        stickerCollectionList.insert(0, collection);
        final json = stickerCollectionList.map((e) => e.toJson()).toList();
        objectMgr.localStorageMgr.write(LocalStorageMgr.ALL_STICKERS, json);
        event(this, eventStickerChange);
      }
    });
    dismissLoading();
  }

  Future<void> removeStickerCollection() async {
    final selectedStickerCollectionIds = selectedStickerCollections
        .map((e) => e.collection.collectionId)
        .toList();
    showLoading(msg: "");
    requestRemoveCollections(selectedStickerCollectionIds).then((result) {
      if (result == true) {
        stickerCollectionList.removeWhere(
          (element) => selectedStickerCollectionIds
              .contains(element.collection.collectionId),
        );
        final json = stickerCollectionList.map((e) => e.toJson()).toList();
        objectMgr.localStorageMgr.write(LocalStorageMgr.ALL_STICKERS, json);
        selectedStickerCollections.clear();
        event(this, eventStickerChange);
      }
    });
    dismissLoading();
  }

  void updateMyCollectionOrder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = stickerCollectionList.removeAt(oldIndex);
    stickerCollectionList.insert(newIndex, item);
    event(this, eventStickerChange);

    requestUpdateMyCollectionOrder(stickerCollectionIds);
  }

  showEmojiPanelClick() {
    event(this, keyShowEmojiPanelClick);
  }

  onChatPopMenuAreaEvent(bool isInMenuArea) {
    event(this, keyChatPopMenuAreaEvent, data: isInMenuArea);
  }

  @override
  Future<void> reloadData() {
    throw UnimplementedError();
  }
}
