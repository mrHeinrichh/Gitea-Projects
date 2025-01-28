import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/task/queue_task_mgr.dart';
import 'package:jxim_client/tasks/chat_message_task.dart';
import 'package:jxim_client/tasks/check_kiwi_task.dart';
import 'package:jxim_client/tasks/check_login_task.dart';
import 'package:jxim_client/tasks/expire_message_task.dart';
import 'package:jxim_client/tasks/heartbeat_task.dart';
import 'package:jxim_client/tasks/online_task.dart';
import 'package:jxim_client/tasks/readmessage_task.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/tasks/slow_mode_task.dart';

import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/utils/net/dio/check_file_task.dart';

class ScheduleMgr with WidgetsBindingObserver implements MgrInterface {
  final Duration _duration = const Duration(milliseconds: 100);
  bool _stop = false;

  List<ScheduleTask> tasks = [];
  CheckLoginTask checkLoginTask = CheckLoginTask();
  ChatMessageTask chatMessageTask = ChatMessageTask();
  ScheduleTask checkKiwiTask = CheckKiwiTask();
  ReadMessageTask readMessageTask = ReadMessageTask();
  OnlineTask onlineTask = OnlineTask();
  ScheduleTask heartBeat = HeartBeatTask();
  // DownloadTask downloadTask = DownloadTask();
  CheckFileTask checkFileTask = CheckFileTask();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _stop = false;
      startTimer();
      PushManager.cancelVibrate();
    } else {
      _stop = true;
    }
  }

  @override
  Future<void> register() async {
    addTask(checkLoginTask);
    WidgetsBinding.instance.addObserver(this);
    _stop = false;
    startTimer();
  }

  @override
  Future<void> init() async {
    removeTask(checkLoginTask);
    ScheduleTask slowMode = SlowModeTask();
    ExpireMessageTask messageTask = ExpireMessageTask();
    ChatTypingTask typingTask = ChatTypingTask();

    addTask(slowMode);
    addTask(messageTask);
    addTask(typingTask);
    addTask(heartBeat);
    addTask(onlineTask);
    addTask(chatMessageTask);
    addTask(readMessageTask);
    addTask(queueUploadTaskMgr);
    addTask(queueDownloadTaskMgr);
    addTask(checkFileTask);

    // 初始化后立即执行
    chatMessageTask.execute();
  }

  void addTask(ScheduleTask task) {
    if (!tasks.contains(task)) {
      tasks.add(task);
    }
  }

  void removeTask(ScheduleTask task) {
    tasks.remove(task);
  }

  startTimer() {
    if (_stop) return;

    List<ScheduleTask> delTasks = [];
    for (final task in tasks) {
      if (!task.finished) {
        task.countdown();
      } else {
        delTasks.add(task);
      }
    }

    tasks.removeWhere((e) => delTasks.contains(e));

    Future.delayed(_duration, () => startTimer());
  }

  @override
  Future<void> logout() async {
    _stop = true;
    readMessageTask.clear();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<void> reloadData() {
    throw UnimplementedError();
  }
}
