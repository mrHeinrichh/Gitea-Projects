import 'dart:convert';

import 'package:jxim_client/api/task.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/task_content.dart';

class MgrTask extends BaseMgr implements TemplateMgrInterface {
  static const String UPDATE_TASK = 'UPDATE_TASK';

  final Map<int, TaskContent> taskMap = <int, TaskContent>{};

  @override
  Future<void> initialize() async {
    objectMgr.socketMgr.on(SocketMgr.updateTaskBlock, onStatusUpdate);
  }

  Future<TaskContent?> send(TaskContent task) async {
    TaskContent? result = await createTask(task);
    return result;
  }

  @override
  Future<void> cleanup() async {
    objectMgr.socketMgr.off(SocketMgr.updateTaskBlock, onStatusUpdate);
  }

  @override
  Future<void> registerModel() async {}

  void onStatusUpdate(Object sender, Object type, Object? data) {
    SubTask? subTask;

    if (data is String) {
      final Map<String, dynamic> taskData = jsonDecode(data);
      int? taskId = taskData['task_id'];
      TaskContent? task = taskMap[taskId];

      if (task == null) {
        return;
      }

      final SubTask result = SubTask()..applyJson(taskData);

      subTask = task.subtasks
          .firstWhere((element) => element.subTaskId == result.subTaskId);
      subTask.taskId = result.taskId;

      if (result.status != subTask.status) {
        subTask.status = result.status;
      }
    }

    if (subTask != null) {
      event(this, UPDATE_TASK, data: subTask);
    }
  }

  void processTaskMessage(Message message) async {
    final TaskContent task = message.decodeContent(cl: TaskContent.creator);
    if (task.taskId > 0) {
      await loadTask(task.taskId);
    }
  }

  Future<void> loadTask(int taskId) async {
    final TaskContent remoteTask = await getTaskDetail(taskId);
    taskMap[taskId] = remoteTask;
  }

  void updateTask(
    int taskId,
    int chatId,
    String chatName,
    String userName,
    String groupName,
    int subTaskId,
    int subTaskUid,
    String content,
    int status,
  ) async {
    try {
      await updateTaskApi(
        taskId,
        chatId,
        objectMgr.userMgr.mainUser.nickname,
        chatName,
        subTaskId,
        subTaskUid,
        content,
        status,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
