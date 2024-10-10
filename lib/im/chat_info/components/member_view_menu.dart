import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_menu_effect.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class MemberViewMenu extends StatefulWidget {
  const MemberViewMenu({
    super.key,
    required this.tempList,
    required this.itemIndex,
  });

  final List<ToolOptionModel> tempList;
  final int itemIndex;

  @override
  State<MemberViewMenu> createState() => _MemberViewMenuState();
}

class _MemberViewMenuState extends State<MemberViewMenu> {
  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(
        left: 10.0,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ChatPopMenuSheetMenuEffect(
        num: widget.tempList.length,
        index: groupInfoController!.touchIndex,
        isShowSeen: false,
        isShowMore: true,
        itemTouch: (index) {
          setState(() {
            groupInfoController!.touchIndex = index;
          });
        },
        itemTouchEnd: (index) {
          if (index < 0 || index >= widget.tempList.length) {
            return;
          }
          groupInfoController?.onAdminMemberOptionTap(
            widget.tempList[index].optionType,
            groupInfoController!.groupMemberListData[widget.itemIndex],
          );
          groupInfoController!.touchIndex = -1;
        },
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: widget.tempList.length,
          itemBuilder: (context, optionId) {
            if (!widget.tempList[optionId].isShow) return const SizedBox();
            return GestureDetector(
              onTap: () => groupInfoController?.onAdminMemberOptionTap(
                widget.tempList[optionId].optionType,
                groupInfoController!.groupMemberListData[widget.itemIndex],
              ),
              child: OverlayEffectMenu(
                isHighLight: optionId == groupInfoController!.touchIndex,
                child: Container(
                  height: 44.0,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorBorder,
                        width:
                            optionId == widget.tempList.length - 1 ? 0.0 : 1.0,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.tempList[optionId].title,
                    style: jxTextStyle.textStyle16(
                        color: widget.tempList[optionId].color),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
