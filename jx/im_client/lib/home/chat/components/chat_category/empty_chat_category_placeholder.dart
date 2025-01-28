import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class EmptyChatCategoryPlaceholder extends StatelessWidget {
  final ChatListController controller;
  final ChatCategory category;

  const EmptyChatCategoryPlaceholder({
    super.key,
    required this.controller,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'assets/images/chat_category_create_icon.png',
          width: 84.0,
          height: 84.0,
        ),
        const SizedBox(height: 24.0),
        Text(
          localized(chatCategoryNoChatTitle),
          style: jxTextStyle.textStyleBold17(),
        ),
        const SizedBox(height: 8.0),
        Text(
          localized(chatCategoryNoChatSubTitle),
          style: jxTextStyle.textStyle17(
            color: colorTextSecondary,
          ),
        ),
        const SizedBox(height: 24.0),
        GestureDetector(
          onTap: () => controller.onEditChatCategory(context, category),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32.0),
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              localized(chatCategoryEditFolder),
              style: jxTextStyle.textStyle17(
                color: colorWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
