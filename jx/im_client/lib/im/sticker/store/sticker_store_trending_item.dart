import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';

class StickerStoreTrendingItem extends StatelessWidget {
  final int index;
  final Function() onClick;
  final String? imageUrl;
  final String? title;
  final String? subTitle;

  const StickerStoreTrendingItem({
    super.key,
    required this.index,
    required this.onClick,
    this.imageUrl,
    this.title,
    this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 200.w,
        margin: EdgeInsets.only(left: index == 0 ? 16 : 0, right: 12).w,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: ImBorderRadius.borderRadius12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                imageUrl ?? 'https://picsum.photos/200/200?random=$index',
                fit: BoxFit.fill,
              ),
            ),
            Container(
              height: 64.w,
              color: ImColor.white,
              padding: const EdgeInsets.symmetric(horizontal: 16).w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImText(
                    title ?? 'No Title',
                    fontWeight: FontWeight.w500,
                    fontSize: ImFontSize.large,
                  ),
                  ImText(
                    subTitle ?? 'No Subtitle',
                    color: ImColor.black60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
