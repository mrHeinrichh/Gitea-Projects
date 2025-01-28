import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_controller.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_popular_item.dart';
import 'package:jxim_client/views/component/component.dart';

class StickerStorePopular extends GetView<StickerStoreController> {
  const StickerStorePopular({super.key});

  @override
  Widget build(BuildContext context) {
    final collections = controller.stickerCollections;

    return Obx(
      () => collections.isEmpty
          ? const SliverToBoxAdapter(
              child: SearchEmptyState(),
            )
          : SliverList.builder(
              itemCount: collections.length,
              itemBuilder: (_, index) {
                final collection = collections[index];
                final bgType = collection == collections.first
                    ? StickerStorePopularItemBgType.first
                    : collection == collections.last
                        ? StickerStorePopularItemBgType.last
                        : StickerStorePopularItemBgType.middle;

                final key = ValueKey(collection.collection.collectionId);

                return StickerStorePopularItem(
                  collection,
                  bgType,
                  key: key,
                );
              },
            ),
    );
  }
}
