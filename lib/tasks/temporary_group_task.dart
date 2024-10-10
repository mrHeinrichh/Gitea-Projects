import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/utility.dart';

class TemporaryGroupTask extends ScheduleTask {
  TemporaryGroupTask({
    Duration delay = const Duration(milliseconds: 1000),
  }) : super(delay);
  final tempGroupMap = <int, Group>{};

  @override
  Future<void> execute() async {
    if (tempGroupMap.isNotEmpty) {
      List<int> keysToRemove = [];
      DateTime now = DateTime.now();

      for (var entry in tempGroupMap.entries) {
        int id = entry.key;
        Group group = entry.value;

        DateTime givenTime = DateTime.fromMillisecondsSinceEpoch(
          group.expireTime * 1000,
          isUtc: true,
        );
        if (givenTime.isBefore(now)) {
          keysToRemove.add(id);
          continue;
        }

        bool isExpiring = isLessThan24hrsUTC(group.expireTime);

        objectMgr.myGroupMgr.event(
          objectMgr.myGroupMgr,
          MyGroupMgr.eventTmpGroupLessThanADay,
          data: {
            'id': id,
            'isExpiring': isExpiring,
            'timestamp': group.expireTime,
          },
        );
      }

      keysToRemove.forEach(tempGroupMap.remove);
    }
  }

  addTempGroupTask(int groupID, {Group? group}) async {
    group ??= await objectMgr.myGroupMgr.loadGroupById(groupID);
    if (group != null && group.isTmpGroup) {
      tempGroupMap[groupID] = group;
    }
  }

  clear() {
    tempGroupMap.clear();
  }
}
