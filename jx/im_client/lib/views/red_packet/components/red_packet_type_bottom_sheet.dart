import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';

class RedPacketTypeBottomSheet extends GetView<RedPacketController> {
  final List redPacketItemList;
  const RedPacketTypeBottomSheet({
    super.key,
    required this.redPacketItemList,
  });

  @override
  Widget build(BuildContext context) {
    ///初始化被選取項
    return CustomBottomSheetContent(
      title: localized(redPocketType),
      showCancelButton: true,
      middleChild: CustomRoundContainer(
        margin: const EdgeInsets.all(16),
        title: localized(redPacketSelectRedPacketType),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            redPacketItemList.length,
                (index) => Obx(
                  () => CustomSelectCheck(
                text: redPacketItemList[index]['text'],
                isSelected: index == controller.selectedIndex.value,
                showDivider:
                index != (redPacketItemList.length - 1),
                onClick: () {
                  controller.selectedIndexHandler(index);
                  redPacketItemList[index]['onClick']();
                  Get.back();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
