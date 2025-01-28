import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_component.dart';

class FavouriteUIHistory extends FavouriteUIComponent {
  const FavouriteUIHistory({
    super.key,
    required super.index,
    required super.title,
    required super.contentList,
    required super.iconPathList,
  });

  @override
  Widget buildContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(),
        const SizedBox(height: 6),
        _buildMessageList(),
      ],
    );
  }

  Widget _buildTitle() {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: title,
      ),
    );
  }

  Widget _buildMessageList() {
    final List<List<InlineSpan>> messageList = _getLimitedContentList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: messageList.map((message) {
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: message),
        );
      }).toList(),
    );
  }

  List<List<InlineSpan>> _getLimitedContentList() {
    return (contentList.length <= 2) ? contentList : contentList.sublist(0, 2);
  }
}
