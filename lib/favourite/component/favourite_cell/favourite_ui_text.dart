import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';

class FavouriteUIText extends FavouriteUIComponent {
  const FavouriteUIText({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget buildContentView() {
    final bool hasMultipleContents = contentList.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: hasMultipleContents ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: title,
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(
          hasMultipleContents ? 2 : contentList.length,
          (index) => RichText(
            maxLines: hasMultipleContents ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: contentList[index],
            ),
          ),
        ),
      ],
    );
  }
}
