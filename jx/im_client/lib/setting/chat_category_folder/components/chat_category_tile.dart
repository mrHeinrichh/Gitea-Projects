import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/setting/chat_category_folder/chat_category_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class ChatCategoryTile extends StatefulWidget {
  final int index;
  final ChatCategoryController controller;
  final ChatCategory category;

  const ChatCategoryTile({
    super.key,
    required this.index,
    required this.controller,
    required this.category,
  });

  @override
  State<ChatCategoryTile> createState() => _ChatCategoryTileState();
}

class _ChatCategoryTileState extends State<ChatCategoryTile>
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

  void _onDeleteTap() {
    sliderController.openEndActionPane(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: widget.controller.isEditing.value
            ? null
            : () => widget.controller.onChatCategoryPress(
                  context,
                  category: widget.category,
                ),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius:
                widget.controller.categoryList.length - 1 == widget.index
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      )
                    : BorderRadius.zero,
          ),
          child: Slidable(
            controller: sliderController,
            closeOnScroll: true,
            enabled: !widget.category.isAllChatRoom,
            endActionPane: _createEndActionPane(context),
            child: OverlayEffect(
              withEffect: !widget.category.isAllChatRoom,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      top: 11.0,
                      bottom: 11.0,
                      right: 16.0,
                    ),
                    child: Row(
                      children: <Widget>[
                        // delete icon
                        if (!widget.category.isAllChatRoom)
                          GestureDetector(
                            onTap: _onDeleteTap,
                            behavior: HitTestBehavior.opaque,
                            child: Opacity(
                              opacity: widget.controller.dragIndex.value ==
                                      widget.index
                                  ? 0.0
                                  : 1.0,
                              child: AnimatedContainer(
                                alignment: Alignment.centerRight,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOutCubic,
                                height: 24.0,
                                margin: EdgeInsets.only(
                                  right: widget.controller.isEditing.value
                                      ? 12.0
                                      : 0.0,
                                ),
                                width: widget.controller.isEditing.value
                                    ? 24.0
                                    : 0.0,
                                child: OverlayEffect(
                                  child: SvgPicture.asset(
                                    'assets/svgs/remove_circle.svg',
                                    width: 24.0,
                                    height: 24.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        Expanded(
                          child: _MyReorderableDragStartListener(
                            index: widget.index + 1,
                            enabled: widget.controller.isEditing.value,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    widget.category.isAllChatRoom
                                        ? localized(chatCategoryAllChatRoom)
                                        : widget.category.name,
                                    style: jxTextStyle.textStyle17(),
                                  ),
                                ),

                                // animated switching with edit flag
                                if (!widget.category.isAllChatRoom)
                                  SvgPicture.asset(
                                    widget.controller.isEditing.value
                                        ? 'assets/svgs/horizontal_line.svg'
                                        : 'assets/svgs/right_arrow_thick.svg',
                                    width: widget.controller.isEditing.value
                                        ? 24.0
                                        : 16.0,
                                    height: widget.controller.isEditing.value
                                        ? 24.0
                                        : 16.0,
                                    colorFilter: ColorFilter.mode(
                                      widget.controller.isEditing.value
                                          ? colorTextPlaceholder
                                          : colorTextSupporting,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.index != widget.controller.categoryList.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: CustomDivider(),
                    ),
                ],
              ),
            ),
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
          onPressed: (BuildContext context) =>
              widget.controller.onDeleteChatCategory(
            context,
            widget.category,
          ),
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

class _MyReorderableDragStartListener extends ReorderableDragStartListener {
  const _MyReorderableDragStartListener({
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      debugOwner: this,
      delay: Duration.zero,
    );
  }
}
