import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_controller.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_popular.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

Widget stickerStore() {
  Get.put(StickerStoreController());
  return const StickerStoreFrame();
}

class StickerStoreFrame extends GetView<StickerStoreController> {
  const StickerStoreFrame({super.key});

  void _getStickerCollections(String word) =>
      controller.getStickerCollections(keyword: word);

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = 12 + MediaQuery.of(context).viewPadding.bottom;

    return Obx(
      () => CustomBottomSheetContent(
        showHeader: !controller.isSearching,
        title: localized(stickerShop),
        leading: const CustomLeadingIcon(needPadding: false),
        useBottomSafeArea: false,
        topChild: CustomSearchBar(
          controller: controller.textController,
          onClick: () => controller.setIsSearching(true),
          onChanged: _getStickerCollections,
          onSubmitted: _getStickerCollections,
          onClearClick: controller.getStickerCollections,
          onCancelClick: () {
            controller.setIsSearching(false);
            controller.getStickerCollections();
          },
        ),
        showDivider: true,
        middleChild: Column(
          children: [
            if (controller.isLoading) ...[
              const SizedBox(height: 64),
              Center(child: CircularProgressIndicator(color: themeColor)),
            ],
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  if (!controller.isLoading) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: CustomRoundContainer(
                          title: localized(popular),
                          titleColor: colorTextSecondary,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const StickerStorePopular(),
                  ],
                  SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
