import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/sticker.dart';
import 'package:jxim_client/object/sticker_collection.dart';

class StickerStoreController extends GetxController {
  final _stickerCollections = <StickerCollection>[].obs;

  List<StickerCollection> get stickerCollections => _stickerCollections;

  final textController = TextEditingController();

  final _isLoading = true.obs;

  bool get isLoading => _isLoading.value;

  final _isSearching = false.obs;

  bool get isSearching => _isSearching.value;

  @override
  void onInit() {
    super.onInit();
    getStickerCollections();
  }

  void setIsSearching(bool isSearching) {
    _isSearching.value = isSearching;
  }

  void getStickerCollections({String? keyword}) async {
    _isLoading.value = true;

    try {
      final resp = await requestGetStickerCollections(keyword: keyword);

      final result = resp.map((e) => StickerCollection.fromJson(e)).toList();

      _stickerCollections.clear();
      _stickerCollections.addAll(result);
    } catch (e) {
      showToast(e.toString());
    }

    _isLoading.value = false;
  }
}
