import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';

class FavouriteSelectedItem extends StatelessWidget {
  final FavouriteKeywordModel model;
  final Function() callback;

  const FavouriteSelectedItem({
    super.key,
    required this.model,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => callback(),
      child: Container(
        padding: EdgeInsets.only(
          top: 2.0,
          bottom: 2.0,
          left: (model.type == FavouriteCustom) ? 8.0 : 4.0,
          right: 4,
        ),
        decoration: BoxDecoration(
          color:
              model.isHighlight == true ? themeColor : colorTextSecondarySolid,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: model.type != FavouriteCustom,
              child: Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: SvgPicture.asset(
                  model.type == FavouriteType || model.type == FavouriteNote
                      ? 'assets/svgs/favourite_category_icon.svg'
                      : 'assets/svgs/favourite_tag_icon.svg',
                  color: colorWhite,
                ),
              ),
            ),
            Flexible(
              child: Text(
                model.title,
                style: jxTextStyle.normalText(color: colorWhite),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.close,
              color: colorWhite,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
