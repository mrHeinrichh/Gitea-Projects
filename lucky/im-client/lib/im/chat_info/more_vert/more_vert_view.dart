
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import '../../../utils/lang_util.dart';

class MoreVertView extends StatefulWidget {
  final List<ToolOptionModel> optionList;
  final VoidCallback? func;

  MoreVertView({
    required this.optionList,
    Key? key,
    this.func,
  }) : super(key: key);

  @override
  State<MoreVertView> createState() => _MoreVertViewState();
}

class _MoreVertViewState extends State<MoreVertView> {
  final MoreVertController controller = Get.find<MoreVertController>();
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<ToolOptionModel> currentList = [];

  @override
  void initState() {
    super.initState();
    controller.optionList = widget.optionList;
    controller.currentList = controller.optionList;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MoreVertController>(
      init: controller,
      builder: (context) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: ListView.builder(
            itemCount: controller.currentList.length,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return optionItem(index);
            },
          ),
        );
      },
    );
  }

  Widget optionItem(int index) {
    var currentItem = controller.currentList[index];
    if (!currentItem.isShow) return const SizedBox();
    return GestureDetector(
      onTap: () {
        controller.onTap(index);
        widget.func!();
      },
      child: OverlayEffect(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: index == controller.currentList.length - 1
                      ? BorderSide.none
                      : const BorderSide(
                    color: JXColors.borderPrimaryColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      currentItem.title,
                      style: jxTextStyle.textStyle17(
                        color: currentItem.color ?? JXColors.primaryTextBlack,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: currentItem.imageUrl != null,
                    child: SvgPicture.asset(
                      currentItem.imageUrl ?? '',
                      width: 24,
                      height: 24,
                      color: currentItem.color ?? JXColors.primaryTextBlack,
                    ),
                  ),
                ],
              ),
            ),
            if (currentItem.largeDivider != null && currentItem.largeDivider!)
              Container(
                height: 7,
                color: JXColors.black3,
              )
          ],
        ),
      ),
    );
  }
}
