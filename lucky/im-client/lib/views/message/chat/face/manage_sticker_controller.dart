import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import '../../../../object/sticker_collection.dart';

class ManageStickerController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TabController? tabController;

  final List<Tab> tabList = <Tab>[
    Tab(
      text: localized(allStickers),
    ),
    Tab(
      text: localized(myCollection),
    ),
    Tab(
      text:localized(myStickers),
    ),
  ];
  late List<StickerCollection> stickerCollectionList;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    stickerCollectionList = <StickerCollection>[];
  }

  @override
  void onClose() {
    super.onClose();
    tabController?.dispose();
  }
}
