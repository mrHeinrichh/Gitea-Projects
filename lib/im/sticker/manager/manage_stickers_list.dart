import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/im/sticker/manager/manage_stickers_list_item.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

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

    return CustomRoundContainer(
      title: localized(stickers),
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              proxyDecorator: (Widget child, _, __) {
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: colorWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorTextPrimary.withOpacity(0.30),
                        blurRadius: 16,
                        spreadRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
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
          ),
        ],
      ),
    );
  }
}
