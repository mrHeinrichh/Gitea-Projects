import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/call_log/component/call_log_empty.dart';
import '../../object/call.dart';
import 'component/call_log_tile.dart';

class MissedCall extends StatelessWidget {
  const MissedCall({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallLogController controller = Get.find<CallLogController>();
    return Column(
      children: [
        Flexible(
          child: Obx(
            () => controller.missedCallList.isEmpty
                ? const Center(
                    child: CallLogEmpty(),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification)
                        controller.missedScrollController = ScrollController(
                            initialScrollOffset: notification.metrics.pixels);
                      return false;
                    },
                    child: SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        controller: controller.missedScrollController,
                        itemCount: controller.missedCallList.length,
                        itemBuilder: (context, index) {
                          final Call callItem =
                              controller.missedCallList[index];
                          return CallLogTile(
                            key: ValueKey(callItem.channelId),
                            callItem: callItem,
                            isLastIndex:
                                index == controller.missedCallList.length - 1,
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
