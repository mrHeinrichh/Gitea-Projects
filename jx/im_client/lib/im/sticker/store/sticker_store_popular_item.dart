import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/object/sticker_collection.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/home/component/custom_divider.dart';

enum StickerStorePopularItemBgType {
  first,
  middle,
  last,
}

class StickerStorePopularItem extends StatefulWidget {
  final StickerCollection collection;
  final StickerStorePopularItemBgType bgType;

  const StickerStorePopularItem(this.collection, this.bgType, {super.key});

  @override
  State<StatefulWidget> createState() => _StickerStorePopularItemState();
}

class _StickerStorePopularItemState extends State<StickerStorePopularItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    objectMgr.stickerMgr.on(StickerMgr.eventStickerChange, onStickerChange);
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.off(StickerMgr.eventStickerChange, onStickerChange);
    super.dispose();
  }

  void onStickerChange(Object sender, Object type, Object? data) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // if not  super build, wantKeepAlive not work
    super.build(context);
    final collection = widget.collection;

    final collectionId = collection.collection.collectionId;

    final isAdded =
        objectMgr.stickerMgr.stickerCollectionIds.contains(collectionId);

    final stickerList = collection.stickerList;

    final borderRadius = switch (widget.bgType) {
      StickerStorePopularItemBgType.first => const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      StickerStorePopularItemBgType.last => const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      _ => BorderRadius.zero,
    };

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(collection, isAdded),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  itemCount: stickerList.length,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: RemoteImage(
                          key: ValueKey("sticker_${stickerList[index].url}"),
                          src: stickerList[index].url,
                          height: 48,
                          width: 48,
                          shouldAnimate: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (widget.bgType != StickerStorePopularItemBgType.last)
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 16, 0),
            child: CustomDivider(),
          ),
      ],
    );
  }

  Widget buildHeader(StickerCollection collection, bool isAdded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          collection.collection.name,
          style: jxTextStyle.textStyle16(),
        ),
        GestureDetector(
          onTap: () async {
            if (!isAdded) {
              await objectMgr.stickerMgr.addStickerCollection(collection);
            }
          },
          child: ForegroundOverlayEffect(
            withEffect: !isAdded,
            radius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorTextPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAdded ? localized(addedStickerBtn) : localized(addStickerBtn),
                style: jxTextStyle.textStyleBold14(
                  color: isAdded ? colorTextSupporting : themeColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
