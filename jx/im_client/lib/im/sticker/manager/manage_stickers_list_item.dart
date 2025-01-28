import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sticker_collection.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

typedef OnCheckChanged = void Function(StickerCollection collection);

class ManageStickersListItem extends StatefulWidget {
  final StickerCollection collection;
  final int index;
  final bool isCustom;
  final bool withDragIcon;
  final bool showDivider;

  const ManageStickersListItem(
    this.collection, {
    super.key,
    required this.index,
    this.isCustom = false,
    this.withDragIcon = false,
    this.showDivider = true,
  });

  @override
  State<StatefulWidget> createState() => _ManageStickersListItemState();
}

class _ManageStickersListItemState extends State<ManageStickersListItem> {
  @override
  Widget build(BuildContext context) {
    final stickerMgr = objectMgr.stickerMgr;
    final isSelected = stickerMgr.selectedStickerCollectionIds
        .contains(widget.collection.collection.collectionId);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: !widget.showDivider
                ? const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  )
                : BorderRadius.zero,
          ),
          key: widget.key,
          height: 96,
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      stickerMgr.onSelectedStickerCollectionChanged(
                        widget.collection,
                      );
                    });
                  },
                  child: Row(
                    children: [
                      CheckTickItem(isCheck: isSelected),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(),
                            const SizedBox(height: 4),
                            _buildStickers(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Opacity(
                opacity: widget.withDragIcon ? 1 : 0,
                child: ReorderableDragStartListener(
                  key: widget.key,
                  index: widget.index,
                  enabled: widget.withDragIcon,
                  child: Container(
                    height: 96,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const CustomImage(
                      'assets/svgs/drag_menu.svg',
                      size: 24,
                      color: colorTextSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showDivider)
          Row(
            children: [
              Container(
                width: 56,
                height: 0.33, // Same as the indent value
                color: colorWhite, // Color for the indent
              ),
              const CustomDivider(indent: 0),
            ],
          ),
      ],
    );
  }

  Widget _buildLabel() {
    final label = widget.collection.collection.name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: jxTextStyle.headerText(),
        ),
        const SizedBox(width: 4),
        if (widget.isCustom)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: ShapeDecoration(
              color: colorTextPrimary.withOpacity(0.04),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Custom',
              style: jxTextStyle.textStyle12(
                color: colorTextPrimary.withOpacity(0.54),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickers() {
    final data = widget.collection.stickerList;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        padding: EdgeInsets.zero,
        itemBuilder: (BuildContext context, int index) {
          bool isLastIndex = index == (data.length - 1);
          final url = data[index].url;
          return Container(
            margin: EdgeInsets.only(right: isLastIndex ? 0 : 12),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: RemoteImage(
              key: ValueKey(url),
              src: url,
              width: 48,
              height: 48,
              shouldAnimate: false,
            ),
          );
        },
      ),
    );
  }
}
