import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

class ChatCategoryCreateItem extends StatefulWidget {
  final Chat chat;
  final bool isLast;
  final void Function(Chat chat)? onDeleteTap;

  const ChatCategoryCreateItem({
    super.key,
    required this.chat,
    required this.isLast,
    this.onDeleteTap,
  });

  @override
  State<ChatCategoryCreateItem> createState() => _ChatCategoryCreateItemState();
}

class _ChatCategoryCreateItemState extends State<ChatCategoryCreateItem>
    with SingleTickerProviderStateMixin {
  late final SlidableController sliderController;

  @override
  void initState() {
    super.initState();
    sliderController = SlidableController(this);
  }

  @override
  void dispose() {
    sliderController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = const SizedBox(width: 40.0, height: 40.0);
    Widget name = const SizedBox();
    if (widget.chat.isSystem) {
      avatar = const SystemMessageIcon(size: 40);
      name = Text(
        localized(chatSystem),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (widget.chat.isSaveMsg) {
      avatar = const SavedMessageIcon(size: 40);
      name = Text(
        localized(homeSavedMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else if (widget.chat.isSecretary) {
      avatar = const SecretaryMessageIcon(size: 40);
      name = Text(
        localized(chatSecretary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: MFontWeight.bold5.value,
          fontSize: MFontSize.size16.value,
          color: colorTextPrimary.withOpacity(1),
          decoration: TextDecoration.none,
          letterSpacing: 0,
          overflow: TextOverflow.ellipsis,
          height: 1.2,
        ),
      );
    } else {
      avatar = CustomAvatar.chat(
        widget.chat,
        size: 40,
        headMin: Config().headMin,
      );
      name = NicknameText(
        uid: widget.chat.isSingle ? widget.chat.friend_id : widget.chat.id,
        displayName: widget.chat.name,
        fontSize: MFontSize.size17.value,
        fontWeight: MFontWeight.bold5.value,
        color: colorTextPrimary,
        isTappable: false,
        isGroup: widget.chat.isGroup || widget.chat.isChatTypeMiniApp,
        overflow: TextOverflow.ellipsis,
        fontSpace: 0,
      );
    }

    return Container(
      height: 48.0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: widget.isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              )
            : BorderRadius.zero,
      ),
      child: Slidable(
        controller: sliderController,
        closeOnScroll: true,
        enabled: true,
        endActionPane: _createEndActionPane(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: <Widget>[
              avatar,
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: name,
                      ),
                    ),
                    if (!widget.isLast) const CustomDivider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ActionPane _createEndActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.2,
      children: <Widget>[
        CustomSlidableAction(
          onPressed: (_) => widget.onDeleteTap?.call(widget.chat),
          backgroundColor: colorRed,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          child: Text(
            localized(chatDelete),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jxTextStyle.slidableTextStyle(),
          ),
        ),
      ],
    );
  }
}
