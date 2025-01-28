import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/favourite_asset_view.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/favourite_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';

class FavouriteController extends GetxController {
  /// 搜索
  ScrollController scrollController = ScrollController();
  TextEditingController inputController = TextEditingController();
  FocusNode inputFocusNode = FocusNode();
  RxBool hasText = false.obs;
  int oldTextLength = 0;
  int page = 1;
  bool notLastResult = true;
  RxBool isSearching = false.obs;
  RxList<FavouriteKeywordModel> keyWordList = <FavouriteKeywordModel>[].obs;
  RxBool isCategoryExpand = false.obs;
  bool isMandarin = AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();
  RxBool isSearchMedia = false.obs;
  final debounce = Debounce(const Duration(milliseconds: 500));
  double size = (MediaQuery.of(Get.context!).size.width - 32 - 32 - 8) / 3;

  /// 多选择
  RxBool isEditing = false.obs;
  RxList<FavouriteData> selectedList = <FavouriteData>[].obs;

  /// Category
  List<FavouriteKeywordModel> categoryList = [
    FavouriteKeywordModel(
      title: localized(noteEditTitle),
      type: FavouriteNote,
      subType: FavouriteSourceNote,
    ),
    FavouriteKeywordModel(
      title: FavouriteTypType.text.subType.categoryName,
      type: FavouriteTypType.text.type,
      subType: FavouriteTypType.text.subType,
    ),
    FavouriteKeywordModel(
      title: FavouriteTypType.image.subType.categoryName,
      type: FavouriteTypType.image.type,
      subType: FavouriteTypType.image.subType,
    ),
    FavouriteKeywordModel(
      title: FavouriteTypType.audio.subType.categoryName,
      type: FavouriteTypType.audio.type,
      subType: FavouriteTypType.audio.subType,
    ),
    FavouriteKeywordModel(
      title: FavouriteTypType.document.subType.categoryName,
      type: FavouriteTypType.document.type,
      subType: FavouriteTypType.document.subType,
    ),
    FavouriteKeywordModel(
      title: FavouriteTypType.location.subType.categoryName,
      type: FavouriteTypType.location.type,
      subType: FavouriteTypType.location.subType,
    ),
  ];

  /// tag
  RxList<FavouriteKeywordModel> tagList = <FavouriteKeywordModel>[].obs;

  RxList<FavouriteData> oriFavouriteList = <FavouriteData>[].obs;
  RxList<FavouriteData> favouriteList = <FavouriteData>[].obs;

  @override
  void onInit() {
    super.onInit();
    objectMgr.favouriteMgr.on(FavouriteMgr.FAVOURITE_LIST_UPDATE, _updateList);
    objectMgr.favouriteMgr.on(FavouriteMgr.TAG_UPDATED, _updateTag);

    hasText.value = inputController.text.isNotEmpty;
    oldTextLength = inputController.text.length;
    inputController.addListener(onInputChanged);
    inputFocusNode.addListener(onInputFocusChanged);
    scrollController.addListener(onScroll);
    getTagList();

    objectMgr.favouriteMgr.syncOfflineFavouriteToServer();
    getFavouriteList();
    loadMore();
  }

  @override
  void onClose() {
    objectMgr.favouriteMgr.off(FavouriteMgr.FAVOURITE_LIST_UPDATE, _updateList);
    objectMgr.favouriteMgr.off(FavouriteMgr.TAG_UPDATED, _updateTag);
    inputController.removeListener(onInputChanged);
    inputFocusNode.removeListener(onInputFocusChanged);
    inputController.dispose();
    inputFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  loadMore() async {
    if (notLastResult) {
      notLastResult = await objectMgr.favouriteMgr.getServerFavouriteList(page);
      if (notLastResult) {
        page++;
      }
    }
  }

  void _updateList(sender, type, data) {
    if (keyWordList.isEmpty && inputController.text.trim().isEmpty) {
      getFavouriteList();
    } else {
      searchResult();
    }
  }

  void _updateTag(sender, type, data) {
    if (keyWordList.isEmpty && inputController.text.trim().isEmpty) {
      getFavouriteList();
      getTagList();
    } else {
      searchResult();
    }
  }

  Future<void> getTagList() async {
    tagList.clear();
    List<String> dataList = [];
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      final data =
          objectMgr.localStorageMgr.read(LocalStorageMgr.FAVOURITE_TAG) ?? "";
      if (data != "") {
        dataList = List<String>.from(jsonDecode(data).map((e) => e as String));
      }
    } else {
      try {
        dataList = await objectMgr.favouriteMgr.getRemoteTagList();
      } catch (e) {
        final data =
            objectMgr.localStorageMgr.read(LocalStorageMgr.FAVOURITE_TAG) ?? "";
        if (data != "") {
          dataList =
              List<String>.from(jsonDecode(data).map((e) => e as String));
        }
      }
    }

    for (String tag in dataList) {
      tagList.add(FavouriteKeywordModel(title: tag, type: FavouriteTag));
    }
  }

  void getFavouriteList() {
    oriFavouriteList.value = objectMgr.favouriteMgr.favouriteList.toList();
    for (FavouriteData data in objectMgr.favouriteMgr.toBeDeleteList) {
      oriFavouriteList.removeWhere((element) => element.id == data.id);
    }
    favouriteList.value = oriFavouriteList.toList();
  }

  /// ================================== 搜索功能 - start ================================== ///
  void onActivateSearchBar() {
    /// 1. Activate search bar
    /// 2. reset input field

    isSearching.value = true;

    oldTextLength = 0;
    inputController.clear();

    onClickTextField();
  }

  void onClickTextField() {
    /// if keyWordList.last 的类型是 == searchCustom
    /// searchTextEditingController set to last.title
    /// keyWordList will remove the last one
    if (keyWordList.isNotEmpty && keyWordList.last.type == FavouriteCustom) {
      inputController.text = keyWordList.last.title;
      keyWordList.removeLast();
    }

    inputFocusNode.requestFocus();
  }

  void onClickCategory(FavouriteKeywordModel model) {
    /// 1. isSearching mode must = true
    /// 2. if subType == FavouriteTypeImage || FavouriteTypeVideo, show isSearchMedia view
    /// 3. add keyword
    /// 4. reset input field (if input is empty, set input == " ")
    /// 5. collapse CategoryExpand view

    isSearching.value = true;
    model.isHighlight = false;

    addKeyword(model);
    setSearchMediaMode(model);

    if (inputController.text.trim().isEmpty) {
      inputController.text = ' ';
      oldTextLength = 1;
    } else {
      oldTextLength = inputController.text.length;
    }

    isCategoryExpand.value = false;
  }

  void onInputChanged() {
    hasText.value = inputController.text.isNotEmpty &&
        inputController.text.trim().isNotEmpty;

    /// 删除判断
    final isDelete = oldTextLength - 1 == inputController.text.length &&
        !(oldTextLength > 1 && !hasText.value);

    if (isDelete) {
      if (keyWordList.isNotEmpty && keyWordList.last.isHighlight == true) {
        String inputText = ' ';
        if (keyWordList.last.type == FavouriteCustom) {
          inputText = keyWordList.last.title;
        }

        keyWordList.removeLast();

        if (keyWordList.isEmpty) {
          oldTextLength = 0;
          inputController.clear();
        } else {
          inputController.text = inputText;
          oldTextLength = inputText.length;
        }
        searchResult();
        return;
      }

      if (inputController.text.trim().isEmpty &&
          keyWordList.isNotEmpty &&
          !keyWordList.last.isHighlight!) {
        FavouriteKeywordModel model = keyWordList[keyWordList.length - 1];
        model.isHighlight = true;
        keyWordList[keyWordList.length - 1] = model;

        inputController.text = ' ';
        oldTextLength = 1;
      }
      debounce.call(() {
        searchResult();
      });

      return;
    }

    final isAdd = oldTextLength + 1 == inputController.text.length;

    if (inputController.text.isEmpty) {
      if (keyWordList.isNotEmpty) {
        inputController.text = ' ';
        oldTextLength = 1;
      }
      return;
    }

    // 增加
    int highlightIndex =
        keyWordList.indexWhere((element) => element.isHighlight == true);
    if (isAdd && keyWordList.isNotEmpty && highlightIndex != -1) {
      FavouriteKeywordModel model = keyWordList[highlightIndex];
      model.isHighlight = false;
      keyWordList[highlightIndex] = model;
    }

    oldTextLength = inputController.text.length;

    debounce.call(() {
      searchResult();
    });
  }

  void onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      loadMore();
    }
  }

  void onInputFocusChanged() {
    if (!inputFocusNode.hasFocus) {
      onTextSubmitted(
        inputController.text,
        requestFocus: false,
      );
    }
  }

  void onTextSubmitted(
    String text, {
    bool requestFocus = true,
  }) {
    if (text.trim().isEmpty) {
      if (keyWordList.isEmpty) {
        inputController.clear();
        oldTextLength = 0;
        isSearching.value = false;
      }
      searchResult();
      return;
    }

    FavouriteKeywordModel model = FavouriteKeywordModel(
      title:
          inputController.text.substring(0, inputController.text.length).trim(),
      type: FavouriteCustom,
    );

    addKeyword(model);

    inputController.text = ' ';
    oldTextLength = 1;

    if (requestFocus) {
      inputFocusNode.requestFocus();
    }

    isCategoryExpand.value = false;
    return;
  }

  void addKeyword(FavouriteKeywordModel model) {
    if (model.type == FavouriteNote || model.type == FavouriteType) {
      int index = keyWordList.indexWhere((element) =>
          element.type == FavouriteNote || element.type == FavouriteType);
      if (index == -1) {
        keyWordList.insert(0, model);
      } else {
        keyWordList[index] = model;
      }
    } else if (model.type == FavouriteTag) {
      if (!keyWordList.contains(model)) {
        if (keyWordList.isNotEmpty &&
            keyWordList.last.type == FavouriteCustom) {
          keyWordList.insert(keyWordList.length - 1, model);
        } else {
          keyWordList.add(model);
        }
      }
    } else if (model.type == FavouriteCustom) {
      int index =
          keyWordList.indexWhere((element) => element.type == FavouriteCustom);
      if (index == -1) {
        keyWordList.add(model);
      } else {
        keyWordList[index] = model;
      }
    }
    searchResult();
  }

  void removeKeyword(FavouriteKeywordModel model) {
    if (keyWordList.contains(model)) {
      keyWordList.remove(model);
    }

    int index = keyWordList.indexWhere((element) =>
        element.subType == FavouriteTypeImage ||
        element.subType == FavouriteTypeVideo);
    if (index == -1) {
      isSearchMedia.value = false;
    } else {
      isSearchMedia.value = true;
    }

    if (keyWordList.isEmpty) {
      oldTextLength = 0;
      inputController.clear();
      isSearching.value = false;
    }

    searchResult();
  }

  void onClickExpandCategory() {
    isCategoryExpand.value = !isCategoryExpand.value;
    inputFocusNode.unfocus();
    if (keyWordList.isEmpty) {
      isSearching.value = false;
    } else {
      isSearching.value = true;
    }
  }

  Future<void> searchResult() async {
    String? searchText;
    int index =
        keyWordList.indexWhere((element) => element.type == FavouriteCustom);
    if (index == -1) {
      if (inputController.text.trim().isNotEmpty) {
        searchText = inputController.text.trim();
      }
    }

    if (keyWordList.isEmpty && searchText == null) {
      isSearchMedia.value = false;
      getFavouriteList();
    } else {
      List<FavouriteData> data = await objectMgr.favouriteMgr
          .getFavouriteDetail(keyWordList, searchText: searchText);
      favouriteList.value = data;
    }
  }

  /// ==================================搜索功能 - end ================================== ///

  void setSearchMediaMode(FavouriteKeywordModel model) {
    if (model.subType == FavouriteTypeImage ||
        model.subType == FavouriteTypeVideo) {
      isSearchMedia.value = true;
    } else {
      isSearchMedia.value = false;
    }
  }

  Future<void> deleteFavourite(
    List<FavouriteData> deleteDataList, {
    bool isMore = false,
  }) async {
    if (deleteDataList.isEmpty) return;

    await showCustomBottomAlertDialog(
      Get.context!,
      subtitle: localized(confirmToDelete),
      confirmText: (!isMore)
          ? localized(buttonDelete)
          : localized(
              deleteParamFavourite,
              params: [deleteDataList.length.toString()],
            ),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () =>
          confirmDeleteFavourite(deleteDataList, isMore: isMore),
    );
  }

  Future<void> confirmDeleteFavourite(
    List<FavouriteData> deleteDataList, {
    bool isMore = false,
  }) async {
    List<FavouriteData> dataList = [];
    List<FavouriteData> unableDeleteList = [];
    int errorCount = 0;
    List<String?> idList =
        deleteDataList.map((e) => e.parentId).toSet().toList();
    for (String? item in idList) {
      if (item != null) {
        final data = oriFavouriteList
            .firstWhereOrNull((element) => element.parentId == item);
        if (data != null) {
          dataList.add(data);
          if (data.content.length > 1) {
            errorCount += 1;
            unableDeleteList.add(data);
          }
        }
      }
    }

    int index =
        keyWordList.indexWhere((element) => element.type == FavouriteType);

    if (errorCount > 0 && index != -1) {
      if (dataList.length > 1) {
        await showCustomBottomAlertDialog(
          Get.context!,
          subtitle: localized(someOfSelectedItemCannotBeDeleted),
          confirmText: localized(reelDeleteConfirm),
          confirmTextColor: colorRed,
          cancelTextColor: themeColor,
          onConfirmListener: () {
            dataList
                .removeWhere((element) => unableDeleteList.contains(element));
            if (dataList.isNotEmpty) {
              handleDeleteFavourite(dataList);
            } else {
              Toast.showToast(
                  localized(theFavouriteYouSelectedCannotBeDeleted));
            }
          },
        );
      } else if (dataList.length == 1) {
        await showCustomBottomAlertDialog(
          Get.context!,
          subtitle: localized(jumpToOriginalFavourite),
          confirmText: localized(findInFavouriteContent),
          confirmTextColor: themeColor,
          cancelTextColor: themeColor,
          onConfirmListener: () {
            if (dataList.first.source == FavouriteSourceNote) {
              Get.toNamed(RouteName.editNotePage, arguments: [dataList.first]);
            } else {
              Get.toNamed(RouteName.favouriteDetailPage, arguments: {
                "favouriteData": dataList.first,
              });
            }
          },
        );
      }
    } else {
      handleDeleteFavourite(dataList);
    }
  }

  Future<void> handleDeleteFavourite(List<FavouriteData> deleteDataList) async {
    objectMgr.favouriteMgr.preDeleteFavourite(deleteDataList);
    for (FavouriteData data in deleteDataList) {
      favouriteList.removeWhere((element) => element.parentId == data.parentId);
    }
    deactivateSelectItem();
  }

  void editTag(List<FavouriteData> list, {bool isMore = false}) {
    if (isMore && selectedList.isEmpty) return;
    List<String> tagDataList = [];

    if (list.length == 1) {
      tagDataList = list.first.tag;
    }
    Get.toNamed(
      RouteName.favouriteEditTag,
      preventDuplicates: false,
      arguments: {
        'tagDataList': tagDataList,
      },
    )?.then((result) async {
      isEditing.value = false;
      if (notBlank(result)) {
        if (result!.containsKey('tag')) {
          List<String> tag = result['tag'];
          for (FavouriteData item in list) {
            final data = oriFavouriteList.firstWhereOrNull(
                (element) => element.parentId == item.parentId);
            if (data != null) {
              if (list.length == 1) {
                data.tag = tag;
              } else {
                List<String> combineTag =
                    {...item.tag, ...tag}.toSet().toList();
                data.tag = combineTag;
              }
              await objectMgr.favouriteMgr
                  .updateFavourite(data, ignoreUpdate: true);
            }
          }
        }
      }
      selectedList.clear();
    });
  }

  Future<void> onClickItem(int index) async {
    FavouriteData favouriteData = favouriteList[index];
    if (isEditing.value) {
      if (selectedList.contains(favouriteData)) {
        selectedList.remove(favouriteData);
      } else {
        selectedList.add(favouriteData);
      }
    } else {
      if (favouriteData.isNote) {
        var res = await objectMgr.localDB.getDataByID(favouriteData.id!);
        List<FavouriteData> dataList =
            res.map((e) => FavouriteData.fromJson(e)).toList();
        Get.toNamed(RouteName.editNotePage, arguments: [dataList.first]);
      } else {
        Get.toNamed(RouteName.favouriteDetailPage, arguments: {
          'favouriteData': favouriteList[index],
        });
      }
    }
  }

  void activateSelectItem(FavouriteData data) {
    isEditing.value = true;
    selectedList.add(data);
  }

  void deactivateSelectItem() {
    isEditing.value = false;
    selectedList.clear();
  }

  Future<void> longPressItem(FavouriteData data) async {
    if (isEditing.value) return;

    vibrate();
    showCustomBottomAlertDialog(
      Get.context!,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(sendToChat),
          onClick: () => objectMgr.favouriteMgr.forwardFavouriteList([data]),
        ),
        CustomBottomAlertItem(
          text: localized(editTags),
          onClick: () {
            editTag([data], isMore: false);
          },
        ),
        CustomBottomAlertItem(
          text: localized(selectMore),
          onClick: () {
            if (!isEditing.value) {
              activateSelectItem(data);
            }
          },
        ),
        CustomBottomAlertItem(
          text: localized(buttonDelete),
          textColor: colorRed,
          onClick: () => deleteFavourite([data]),
        ),
      ],
    );
  }

  void onTapMedia(BuildContext context, List dataList, int index) {
    Navigator.of(context).push(
      TransparentRoute(
        builder: (BuildContext context) => FavouriteAssetView(
          assets: dataList,
          index: index,
        ),
        settings: const RouteSettings(name: RouteName.favouriteAssetPreview),
      ),
    );
  }
}
