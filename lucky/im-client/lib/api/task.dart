import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<TaskContent?> createTask(TaskContent task) async {
  List<Map<String, dynamic>> subTaskData = [];
  for (final subTask in task.subtasks) {
    if (notBlank(subTask.content)) {
      subTaskData.add({"uid": subTask.uid, "content": subTask.content});
    }
  }

  final Map<String, dynamic> dataBody = {
    'chat_id': task.chatId,
    'title': task.title,
    'group_name': task.groupName,
    'username': task.userName,
    'tasks': subTaskData
  };

  try {
    final ResponseData res = await Request.doPost(
      '/im-saturn/task/create',
      data: dataBody,
    );

    if (res.success()) {
      TaskContent task = TaskContent.creator();
      task.applyJson(res.data);
      return task;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<void> updateTaskApi(
  int taskId,
  int chatId,
  String userName,
  String groupName,
  int subTaskId,
  int subTaskUid,
  String content,
  int status,
) async {
  Map<String, dynamic> data = {};
  data['task_id'] = taskId;
  data['chat_id'] = chatId;
  data['username'] = userName;
  data['group_name'] = groupName;
  data['sub_task_id'] = subTaskId;
  data['uid'] = subTaskUid;
  data['content'] = content;
  data['status'] = status;

  try {
    final ResponseData res = await Request.doPost(
      '/im-saturn/task/update',
      data: data,
    );

    if (res.success()) {
      return;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<TaskContent> getTaskDetail(int taskId) async {
  Map<String, dynamic> data = {
    'task_id': taskId,
  };

  try {
    final ResponseData res = await Request.doPost(
      '/im-saturn/task/detail',
      data: data,
    );

    if (res.success()) {
      return TaskContent()..applyJson(res.data);
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    pdebug('AppException: ${e.toString()}');
    // Toast.showToast(e.getMessage());
    rethrow;
  }
}
