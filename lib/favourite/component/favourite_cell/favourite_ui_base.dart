import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

abstract class FavouriteUIBase<T> extends GetView<T> {
  final int index;
  final List<InlineSpan> title;
  final List<List<InlineSpan>> contentList;
  final List<Map<String, dynamic>> iconPathList;

  const FavouriteUIBase({
    super.key,
    required this.index,
    required this.title,
    required this.contentList,
    required this.iconPathList,
  });

  Widget buildContentView();
}
