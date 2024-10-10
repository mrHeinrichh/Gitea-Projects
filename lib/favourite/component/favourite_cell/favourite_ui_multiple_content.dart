import 'package:flutter/material.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';
import 'package:jxim_client/managers/utils.dart';

class FavouriteUIMultipleContent extends FavouriteUIComponent {
  const FavouriteUIMultipleContent({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget buildContentView() {
    if (_isTitleAvailable()) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          _buildContentList(),
        ],
      );
    }

    // No title
    return _buildContentList();
  }

  bool _isTitleAvailable() {
    return title.isNotEmpty && notBlank(title.first.toPlainText());
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: title,
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        contentList.length,
        (index) => RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: contentList[index],
          ),
        ),
      ),
    );
  }
}
