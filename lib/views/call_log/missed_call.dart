import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/call_log/component/call_log_empty.dart';
import 'package:jxim_client/views/component/component.dart';

class MissedCall extends StatefulWidget {
  const MissedCall({super.key});

  @override
  State<StatefulWidget> createState() => _MissedCallState();
}

class _MissedCallState extends State<MissedCall>
    with AutomaticKeepAliveClientMixin {
  CallLogController get controller => Get.find<CallLogController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => controller.missedCallList.isEmpty
          ? const Center(child: CallLogEmpty())
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  controller.missedScrollController = ScrollController(
                    initialScrollOffset: notification.metrics.pixels,
                  );
                }

                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  24 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: CustomRoundContainer(
                  child: SlidableAutoCloseBehavior(
                    child: AnimatedList(
                      shrinkWrap: true,
                      key: controller.missListKey,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      controller: controller.missedScrollController,
                      initialItemCount: controller.missedCallList.length,
                      itemBuilder: (context, index, animation) {
                        final Call callItem = controller.missedCallList[index];
                        return controller.buildItem(
                          1,
                          index,
                          callItem,
                          animation,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
