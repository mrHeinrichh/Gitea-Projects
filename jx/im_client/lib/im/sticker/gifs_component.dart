import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/sticker/gifs_component_grid_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:jxim_client/object/chat/chat.dart';

class GifsComponent extends StatefulWidget {
  const GifsComponent({
    super.key,
    required this.chat,
  });

  final Chat chat;

  @override
  State<GifsComponent> createState() => _GifsComponentState();
}

class _GifsComponentState extends State<GifsComponent> {
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final List<Gifs> _recentGifList = [];

  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();

    objectMgr.stickerMgr.fetch();

    _itemPositionsListener.itemPositions.addListener(() {
      _selectedIndex.value =
          _itemPositionsListener.itemPositions.value.first.index;
    });

    _recentGifList.addAll(objectMgr.stickerMgr.recentGifList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(objectMgr.loginMgr.isDesktop)
          const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: (objectMgr.loginMgr.isDesktop) ?
              const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 10
              ) : EdgeInsets.zero,
              child: Column(
                children: _getGifsContentList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _getGifsContentList() {
    return [
      if (_recentGifList.isNotEmpty) ...[
        GifsComponentGridView(
          title: localized(recentStickers),
          data: _recentGifList,
          chatId: widget.chat.id.toString(),
        ),
        SizedBox(height: 8.w),
      ],
      GifsComponentGridView(
        title: 'GIF',
        data: objectMgr.stickerMgr.gifCollectionList,
        chatId: widget.chat.id.toString(),
      ),
    ];
  }
}
