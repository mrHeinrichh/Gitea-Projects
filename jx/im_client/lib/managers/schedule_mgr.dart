import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/push_notification.dart';
import 'package:jxim_client/managers/task/download_lib/download_util.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/tasks/check_kiwi_task.dart';
import 'package:jxim_client/tasks/data_analytics_task.dart';
import 'package:jxim_client/tasks/expire_message_task.dart';
import 'package:jxim_client/tasks/heart_beat_task.dart';
import 'package:jxim_client/tasks/online_task.dart';
import 'package:jxim_client/tasks/ping_pong_task.dart';
import 'package:jxim_client/tasks/read_message_task.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/tasks/sign_chat_task.dart';
import 'package:jxim_client/tasks/temporary_group_task.dart';
import 'package:jxim_client/tasks/translate_message_task.dart';

class ScheduleMgr implements InterfaceMgr {
  ScheduleMgr() {
    // 注册需要
    addTask(queueUploadTaskMgr);
    _onTick();
  }

  final List<ScheduleTask> _tasks = [];
  final CheckKiwiTask checkKiwiTask = CheckKiwiTask();
  final ReadMessageTask readMessageTask = ReadMessageTask();
  final HeartBeatTask heartBeatTask = HeartBeatTask();
  final PingPongTask _pingPongTask = PingPongTask();
  final OnlineTask _onlineTask = OnlineTask();
  final SignChatTask signChatTask = SignChatTask();
  final TranslateMessageTask translateMessageTask = TranslateMessageTask();
  final TemporaryGroupTask temporaryGroupTask = TemporaryGroupTask();

  final ExpireMessageTask _messageTask = ExpireMessageTask();
  final ChatTypingTask _typingTask = ChatTypingTask();
  final DataAnalyticsTask _dataAnalyticsTask = DataAnalyticsTask();

  // 延迟关闭开关
  bool _isDelayCancelled = false;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _isDelayCancelled = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (_isDelayCancelled) {
          for (final task in _tasks) {
            task.resumed();
          }
        }
      });
      // 在前台关闭取消推送
      PushManager.cancelVibrate();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isDelayCancelled = false;
      // 切后台延迟1秒关闭心跳
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isDelayCancelled) {
          for (final task in _tasks) {
            task.pause();
          }
        }
      });
    }
  }

  bool _isInit = false;

  // 一帧间隔diff
  final Duration _diff = const Duration(milliseconds: 200);

  @override
  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;

    // addTask(_slowMode);
    addTask(_messageTask);
    addTask(_typingTask);

    addTask(_onlineTask);
    addTask(heartBeatTask);
    addTask(_pingPongTask);
    addTask(readMessageTask);
    addTask(translateMessageTask);
    addTask(temporaryGroupTask);
    addTask(queueDownloadTaskMgr);
    addTask(signChatTask);

    addTask(_dataAnalyticsTask);
  }

  void _onTick() {
    _tasks.removeWhere((e) => e.isFinished);

    for (final task in _tasks) {
      task.update(_diff.inMilliseconds);
    }

    Future.delayed(_diff, _onTick);
  }

  void addTask(ScheduleTask task) {
    if (!_tasks.contains(task)) {
      _tasks.add(task);
    }
  }

  @override
  Future<void> clear() async {
    _onlineTask.clear();
    readMessageTask.clear();
    temporaryGroupTask.clear();
    _tasks.removeWhere((element) => !element.always);
    queueDownloadTaskMgr.clear();
    queueUploadTaskMgr.clear();
    _isInit = false;
  }
}
