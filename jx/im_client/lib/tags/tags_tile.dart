import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/tags/tags_management_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class TagsTile extends StatefulWidget {
  final int index;
  final TagsManagementController controller;
  final Tags tag;

  const TagsTile({
    super.key,
    required this.index,
    required this.controller,
    required this.tag,
  });

  @override
  State<TagsTile> createState() => _TagsTileState();
}

class _TagsTileState extends State<TagsTile> with SingleTickerProviderStateMixin
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

  void _onDeleteTap() {
    widget.controller.onDeleteTags(
      context,
      widget.tag,
    );
  }

  ActionPane _createEndActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.2,
      children: <Widget>[
        CustomSlidableAction(
          onPressed: (BuildContext context) =>
              widget.controller.onDeleteTags(
                context,
                widget.tag,
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

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => GestureDetector(
            onTap: widget.controller.isEditing.value
                ? null
                : () => widget.controller.onTagsPress(
              context,
              tags: widget.tag,
            ),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: widget.controller.tagsList.length - 1 == widget.index
                    ? const BorderRadius.only(bottomLeft: Radius.circular(8.0), bottomRight: Radius.circular(8.0),)
                    : BorderRadius.zero,
              ),
              child: Slidable(
                controller: sliderController,
                closeOnScroll: true,
                enabled: widget.controller.isEditing.value?false:true,
                endActionPane: _createEndActionPane(context),
                child: OverlayEffect(
                  withEffect: true,
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
                            GestureDetector(
                              onTap: _onDeleteTap,
                              behavior: HitTestBehavior.opaque,
                              child: Opacity(
                                opacity: widget.controller.dragIndex.value == widget.index
                                    ? 0.0
                                    : 1.0,
                                child: AnimatedContainer(
                                  alignment: Alignment.centerRight,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOutCubic,
                                  height: 24.0,
                                  margin: EdgeInsets.only(right: widget.controller.isEditing.value
                                        ? 12.0
                                        : 0.0,
                                  ),
                                  width: widget.controller.isEditing.value
                                      ? 24.0
                                      : 0.0,
                                  child: OverlayEffect(
                                    radius: const BorderRadius.all(Radius.circular(8.0)),
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
                                      child:
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(widget.tag.tagName,
                                                style: jxTextStyle.textStyle17(),
                                              ),
                                              const SizedBox(width: 5,),
                                              Text(
                                                "(${widget.controller.allTagByGroup[widget.tag.uid]?.length ?? 0})",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: jxTextStyle.textStyle17(),
                                              ),
                                            ],
                                          ),
                                          if(widget.controller.allTagByGroup[widget.tag.uid]?.isNotEmpty??false)
                                            Text(widget.controller.allTagByGroup[widget.tag.uid]
                                                ?.map((e) => e.alias!=""?e.alias:e.nickname)
                                                .toList()
                                                .join(", ") ?? "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: jxTextStyle.textStyle13(color: colorTextSecondary,),
                                            )
                                        ],
                                      ),
                                    ),

                                    // animated switching with edit flag
                                    SvgPicture.asset(
                                      // widget.controller.isEditing.value
                                      //     ? 'assets/svgs/horizontal_line.svg'
                                      //     : 'assets/svgs/right_arrow_thick.svg',
                                      'assets/svgs/right_arrow_thick.svg',
                                      width: 16.0,
                                      height: 16.0,
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

                      if (widget.index != widget.controller.tagsList.length - 1)
                         Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Container(
                              width: double.infinity,
                              height: 0.5,
                              color: colorTextPlaceholder
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
