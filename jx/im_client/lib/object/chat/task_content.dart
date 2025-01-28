import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/user.dart';

class TaskContent {
  int taskId = 0;
  String title = '';
  String groupName = '';
  String userName = '';
  int creatorUid = 0;
  int chatId = 0;
  int createTime = 0;
  List<SubTask> subtasks = <SubTask>[];

  int get totalCount => subtasks.length;

  int get progressCount =>
      subtasks.where((element) => element.status.value == 1).length;

  int get doneCount =>
      subtasks.where((element) => element.status.value == 2).length;

  int get cancelCount =>
      subtasks.where((element) => element.status.value == 3).length;

  bool get isProgress => progressCount == totalCount;

  bool get isDone => doneCount == totalCount;

  bool get isCancel => cancelCount == totalCount;

  /// =============================== 构造函数 ==================================

  applyJson(Map<String, dynamic> json) {
    taskId = json['id'] ?? 0;
    title = json['title'] ?? "";
    groupName = json['group_name'] ?? '';
    userName = json['username'] ?? '';
    chatId = json['chat_id'] ?? 0;
    creatorUid = json['creator_uid'] ?? 0;
    createTime = json['create_time'] ?? 0;
    if (json['tasks'] != null && json['tasks'] is List) {
      for (final data in json['tasks']) {
        final tempV = SubTask();
        tempV.applyJson(data);
        subtasks.add(tempV);
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': taskId,
      'title': title,
      'chatId': chatId,
      'tasks': jsonEncode(subtasks).toString(),
      'createTime': createTime,
      'chat_id': chatId,
      'creator_uid': creatorUid,
      'group_name': groupName,
      'username': userName,
    };
  }

  static TaskContent creator() {
    return TaskContent();
  }
}

class SubTask {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final userObv = Rxn<User>();

  int taskId = 0;
  int subTaskId = 0;
  String content = '';
  int uid = 0;
  TaskStatus status = TaskStatus.toDo;
  int updateTime = 0;

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('task_id')) {
      taskId = json['task_id'];
    }
    subTaskId = json['sub_task_id'];
    content = json['content'];
    uid = json['uid'];
    switch (json['status']) {
      case 1:
        status = TaskStatus.progress;
        break;
      case 2:
        status = TaskStatus.done;
        break;
      case 3:
        status = TaskStatus.cancel;
        break;
      default:
        status = TaskStatus.toDo;
    }

    if (json.containsKey('update_time')) {
      updateTime = json['update_time'];
    }
  }
}

enum TaskStatus {
  toDo(0),
  progress(1),
  done(2),
  cancel(3);

  final int value;

  const TaskStatus(this.value);
}
