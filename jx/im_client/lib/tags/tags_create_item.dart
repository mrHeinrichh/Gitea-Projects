import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class TagsCreateItem extends StatefulWidget {
  final User user;
  final bool isLast;
  final void Function(User user)? onDeleteTap;

  const TagsCreateItem({
    super.key,
    required this.user,
    required this.isLast,
    this.onDeleteTap,
  });

  @override
  State<TagsCreateItem> createState() => _TagsCreateItemState();
}

class _TagsCreateItemState extends State<TagsCreateItem> with SingleTickerProviderStateMixin
{
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

  ActionPane _createEndActionPane(BuildContext context)
  {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.2,
      children: <Widget>[
        CustomSlidableAction(
          onPressed: (_) => widget.onDeleteTap?.call(widget.user),
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

  @override
  Widget build(BuildContext context)
  {
    Widget avatar = const SizedBox(width: 40.0, height: 40.0);
    Widget name = const SizedBox();

    avatar = CustomAvatar.user(
      widget.user,
      size: 40,
      headMin: Config().headMin,
    );
    name = NicknameText(
      uid: widget.user.uid,
      displayName: widget.user.nickname,
      fontSize: MFontSize.size17.value,
      fontWeight: MFontWeight.bold5.value,
      color: colorTextPrimary,
      isTappable: false,
      isGroup: false,
      overflow: TextOverflow.ellipsis,
      fontSpace: 0,
    );

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
}
