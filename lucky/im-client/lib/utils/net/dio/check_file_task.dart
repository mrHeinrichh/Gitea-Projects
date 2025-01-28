import 'dart:io';

import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class CheckFileTask extends ScheduleTask {
  CheckFileTask({int delay = 3 * 100, bool isPeriodic = true})
      : super(delay, isPeriodic);

  final Map<String, String> _fileMap = {};
  Map<String, String> get fileMap => _fileMap;
  @override
  execute() async {
    _update();
  }

  Future<void> _update() async {
    _fileMap.removeWhere((fileLength, filePath) {
      File file = File(filePath);
      if (file.existsSync()) {
        final fileSize = file.lengthSync().toString();
        if (fileSize != fileLength) {
          logMgr.logDownloadMgr.addMetrics(LogDownloadMsg(
              msg:
                  '检查文件: $filePath 目标文件不一致: 原始大小($fileLength) 实际保存大小($fileSize)'));
          file.deleteSync();
        }
      }
      return true;
    });
  }
}
