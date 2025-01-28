import 'package:flutter/material.dart';
import 'package:jxim_client/im/sticker/manager/manage_stickers_list_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';

class ManageStickersList extends StatefulWidget {
  const ManageStickersList({super.key});

  @override
  State<ManageStickersList> createState() => _ManageStickersListState();
}

class _ManageStickersListState extends State<ManageStickersList> {
  @override
  void initState() {
    super.initState();
    objectMgr.stickerMgr.selectedStickerCollections.clear();
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
    final collections = objectMgr.stickerMgr.stickerCollectionList;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        proxyDecorator: (Widget child, _, __) {
          return Container(
            decoration: BoxDecoration(
              color: colorWhite,
              boxShadow: [
                BoxShadow(
                  color: colorTextPrimary.withOpacity(0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: child,
          );
        },
        onReorderStart: (_) => vibrate(),
        onReorderEnd: (_) => vibrate(),
        onReorder: objectMgr.stickerMgr.updateMyCollectionOrder,
        children: List.generate(
          collections.length,
          (index) {
            final collection = collections[index];
            return ManageStickersListItem(
              collection,
              key: Key('${collection.collection.collectionId}'),
              index: index,
              withDragIcon: true,
              showDivider: index != (collections.length - 1),
            );
          },
        ),
      ),
    );
  }
}
