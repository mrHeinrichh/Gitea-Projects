import 'package:jxim_client/main.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

import '../im/model/group/group.dart';
import '../object/chat/message.dart';

class SlowModeTask extends ScheduleTask {

  SlowModeTask() : super(1*1000, true);

  @override
  execute() {
    if (objectMgr.chatMgr.groupSlowMode.isNotEmpty) {
      objectMgr.chatMgr.groupSlowMode.forEach((groupId, groupData) {
        Group group = groupData['group'];
        Message? message = groupData['message'];
        bool isEnable = groupData['isEnable'];
        if (!isEnable) {
          if (message != null) {
            DateTime createTime = DateTime.fromMillisecondsSinceEpoch(message.create_time * 1000);
            if (DateTime.now().difference(createTime) >= Duration(seconds: group.speak_interval)) {
              isEnable = true;
            } else {
              isEnable = false;
            }
          } else {
            isEnable = true;
          }
          groupData['isEnable'] = isEnable;
        }
      });
    }
  }
}
