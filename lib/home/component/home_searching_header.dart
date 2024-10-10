import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';

class HomeSearchingHeader<T> extends StatelessWidget {
  const HomeSearchingHeader({
    super.key,
    required this.controller,
    required this.title,
    required this.list,
    this.isShowLabel = true,
  });

  final ChatListController controller;
  final String title;
  final RxList<T> list;
  final bool isShowLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SliverAppBar(
        elevation: 0,
        pinned: true,
        toolbarHeight:
            controller.isSearching.value && list.isNotEmpty && isShowLabel
                ? 30
                : 0,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
          width: double.infinity,
          color: colorBackground,
          child: Text(
            title,
            style: jxTextStyle.textStyle14(color: colorTextSecondary),
          ),
        ),
      ),
    );
  }
}
