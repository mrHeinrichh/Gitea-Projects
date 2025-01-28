import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/im/sticker/gifs_component_grid_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../object/chat/chat.dart';

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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late int _gifsViewCount;
  final List<Gifs> _recentGifList = [];

  ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();

    _itemPositionsListener.itemPositions.addListener(() {
      _selectedIndex.value =
          _itemPositionsListener.itemPositions.value.first.index;
    });

    _recentGifList.addAll(objectMgr.stickerMgr.recentGifList);

    _gifsViewCount = (_recentGifList.isNotEmpty ? 1 : 0) +
        objectMgr.stickerMgr.gifCollectionList.length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: _getGifsContentList(),
      ),
    );
  }

  // Widget _buildGifsHeader() {
  //   return Container(
  //     alignment: Alignment.centerLeft,
  //     height: kToolbarHeight,
  //     child: SizedBox(
  //       height: 32,
  //       child: ListView.builder(
  //         itemCount: _gifsViewCount,
  //         scrollDirection: Axis.horizontal,
  //         padding: EdgeInsets.zero,
  //         shrinkWrap: true,
  //         itemBuilder: (BuildContext context, int index) {
  //           return GestureDetector(
  //             onTap: () {
  //               _itemScrollController.scrollTo(
  //                 index: index,
  //                 duration: const Duration(seconds: 1),
  //                 curve: Curves.easeInOutCubic,
  //               );
  //             },
  //             child: ValueListenableBuilder(
  //               valueListenable: _selectedIndex,
  //               builder: (_, value, __) {
  //                 return Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(8),
  //                     color:
  //                         value == index ? JXColors.black8 : Colors.transparent,
  //                   ),
  //                   margin: EdgeInsets.only(
  //                     right: 4,
  //                     left: index == 0 ? 12 : 0,
  //                   ),
  //                   padding:
  //                       EdgeInsets.all(objectMgr.loginMgr.isDesktop ? 0 : 4),
  //                   child: _getGifsHeaderList()[index],
  //                 );
  //               },
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildGifsContent() {
  //   return ScrollablePositionedList.builder(
  //     itemCount: _gifsViewCount,
  //     itemBuilder: (context, index) => _getGifsContentList()[index],
  //     itemScrollController: _itemScrollController,
  //     itemPositionsListener: _itemPositionsListener,
  //   );
  // }

  // List<Widget> _getGifsHeaderList() {
  //   return [
  //     if (_recentGifList.isNotEmpty)
  //       SvgPicture.asset(
  //         'assets/svgs/recent.svg',
  //         width: 24.w,
  //         height: 24.w,
  //         colorFilter: const ColorFilter.mode(
  //           JXColors.black48,
  //           BlendMode.srcIn,
  //         ),
  //       ),
  //     ...List.generate(
  //       objectMgr.stickerMgr.gifCollectionList.length,
  //       (index) => RemoteImage(
  //         key: ValueKey(objectMgr.stickerMgr.gifCollectionList[index].path),
  //         src: objectMgr.stickerMgr.gifCollectionList[index].path,
  //         width: 24,
  //         height: 24,
  //
  //       ),
  //     ),
  //   ];
  // }

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
      )
    ];
  }
}
