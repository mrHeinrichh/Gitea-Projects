import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/sticker/store/sticker_store_trending_item.dart';

class StickerStoreTrending extends StatefulWidget {
  const StickerStoreTrending({super.key});

  @override
  State<StickerStoreTrending> createState() => _StickerStoreTrendingState();
}

class _StickerStoreTrendingState extends State<StickerStoreTrending> {
  final _sticker = List.generate(
    5,
    (i) => StickerStoreTrendingItem(
      onClick: () {},
      index: i,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8).w,
          child: const ImText(
            'Trending', //commonLocalized ()
            color: ImColor.black48,
          ),
        ),
        SizedBox(
          height: 264.w,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _sticker.length,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) => _sticker[index],
          ),
        ),
      ],
    );
  }
}
