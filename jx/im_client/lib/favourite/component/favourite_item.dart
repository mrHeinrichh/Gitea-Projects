import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class FavouriteItem extends StatelessWidget {
  final FavouriteKeywordModel model;
  final bool isSelected;
  final Function() callback;

  const FavouriteItem({
    super.key,
    required this.model,
    required this.isSelected,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => callback(),
      child: ForegroundOverlayEffect(
        radius: const BorderRadius.all(Radius.circular(4.0)),
        child: Container(
          alignment: Alignment.center,
          width: (MediaQuery.of(context).size.width - 20 - 32) / 3,
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? colorBorder : colorWhite,
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
          child: Text(
            model.title,
            style: jxTextStyle.normalText(
                color: isSelected ? colorTextPrimary : colorTextSecondary,
            ).copyWith(height: 1.15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
