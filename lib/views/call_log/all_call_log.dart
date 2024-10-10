import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/call_log/component/call_log_empty.dart';
import 'package:jxim_client/views/component/component.dart';

class AllCallLog extends StatefulWidget {
  const AllCallLog({super.key});

  @override
  State<StatefulWidget> createState() => _AllCallLogState();
}

class _AllCallLogState extends State<AllCallLog>
    with AutomaticKeepAliveClientMixin {
  CallLogController get controller => Get.find<CallLogController>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => controller.recentCallList.isEmpty
          ? const Center(child: CallLogEmpty())
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  controller.recentScrollController = ScrollController(
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
                      key: controller.recentListKey,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      controller: controller.recentScrollController,
                      initialItemCount: controller.recentCallList.length,
                      itemBuilder: (context, index, animation) {
                        final Call callItem = controller.recentCallList[index];
                        return controller.buildItem(
                          0,
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
