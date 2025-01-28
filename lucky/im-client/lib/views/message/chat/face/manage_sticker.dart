import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/message/chat/face/sticker_collection.dart';
import 'package:jxim_client/views/message/chat/face/sticker_creation.dart';

import 'manage_sticker_controller.dart';

class ManageStickers extends GetView<ManageStickerController> {
  const ManageStickers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_sharp),
        ),
        title: Text(localized(stickers)),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: controller.tabList,
          indicatorColor: Colors.grey.shade600,
        ),
        elevation: 0,
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller.tabController,
        children: [
          const StickerCollection(),
          const StickerCreation(),
        ],
      ),
    );
  }
}
