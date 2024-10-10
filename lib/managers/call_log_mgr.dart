import 'dart:core';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

enum CallLogType {
  all(0),
  missedCall(1);

  const CallLogType(this.type);
  final int type;
}

class CallLogMgr
    with EventDispatcher
    implements MgrInterface, SqfliteMgrInterface {
  final String eventAddCallLog = "eventAddCallLog";
  final String eventDelCallLog = "eventDelCallLog";
  final String eventCallLogUnreadUpdate = "eventCallLogUnreadUpdate";
  final String eventCallLogInited = "eventCallLogInited";
  RtcEngine? engine;
  late DBInterface _localDB;
  List<Call>? allCallLog;

  @override
  Future<void> register() async {
    _localDB = objectMgr.localDB;
    registerSqflite();
  }

  @override
  Future<void> init() async {
    allCallLog = await loadDBCallLog();
    event(this, eventCallLogInited);
    if (objectMgr.socketMgr.isAlreadyPubSocketOpen) {
      _onSocketOpen(null, null, null);
    }
    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
  }

  Future<void> _onSocketOpen(a, b, c) async {
    loadRemoteCallLog();
  }

  @override
  Future<void> reloadData() async {
    allCallLog = await loadDBCallLog();
  }

  @override
  Future<void> registerSqflite() async {
    _localDB.registerTable('''
        CREATE TABLE IF NOT EXISTS call_log (
        id TEXT PRIMARY KEY,
        caller_id INTEGER,
        receiver_id INTEGER,
        chat_id INTEGER,
        duration INTEGER,
        video_call INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        ended_at INTEGER,
        status INTEGER,
        is_deleted INTEGER,
        deleted_at INTEGER,
        is_read INTEGER
        );
      ''');
  }

  void loadRemoteCallLog() async {
    int lastUpdateTime = 0;
    allCallLog = await loadDBCallLog();
    lastUpdateTime =
        objectMgr.localStorageMgr.read(LocalStorageMgr.LAST_APP_CALL_LOG) ?? 0;
    if (lastUpdateTime == 0) {
      lastUpdateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    final callLogs = await getCallLog(lastUpdateTime);
    if (callLogs != null) {
      for (var element in callLogs) {
        if (isMissCallLog(element) &&
            !allCallLog!.any((call) => call.channelId == element.channelId)) {
          await saveCallLog("_loadRemoteCallLog", [element]);
        }
      }
    }
  }

  bool isMissCallLog(Call callLog) {
    if (!objectMgr.userMgr.isMe(callLog.callerId) &&
        (callLog.status == CallEvent.CallOptBusy.event ||
            callLog.status == CallEvent.CallBusy.event ||
            callLog.status == CallEvent.CallOptCancel.event ||
            callLog.status == CallEvent.CallTimeOut.event)) {
      return true;
    }
    return false;
  }

  Future<List<Call>> loadDBCallLog() async {
    final callLogs = await objectMgr.localDB.loadCallLogs();
    return callLogs.map((e) => Call.fromJson(e, fromLocalDB: true)).toList();
  }

  Future<List<Call>> loadCallLog(CallLogType type) async {
    allCallLog ??= await loadDBCallLog();
    if (type == CallLogType.missedCall) {
      return allCallLog!.where((element) => isMissCallLog(element)).toList();
    }
    return allCallLog!;
  }

  Future<int> getUnreadCallCount() async {
    var callLogList = await loadCallLog(CallLogType.missedCall);
    int unreadCount = 0;
    for (var element in callLogList) {
      if (element.isRead == 0) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  void updateCallLogRead() async {
    await objectMgr.localDB.updateCallRead();
    allCallLog?.forEach((element) {
      if (element.isRead == 0) {
        element.isRead = 1;
      }
    });
    event(this, eventCallLogUnreadUpdate, data: 0);
  }

  Future<int> saveCallLog(String sender, List<Call> callList) async {
    int count = 0;
    for (final call in callList) {
      count += await saveOneCallLog(sender, call);
    }

    event(this, eventAddCallLog, data: callList);
    event(this, eventCallLogUnreadUpdate, data: 0);
    return count;
  }

  Future<int> saveOneCallLog(String sender, Call call) async {
    if (call.channelId == "") {
      if (objectMgr.userMgr.isMe(call.callerId)) {
        call.channelId =
            "${call.chatId}-${call.callerId}-${DateTime.now().millisecondsSinceEpoch}";
      } else {
        //非法的通话记录不保存
        return 0;
      }
    }
    if (isMissCallLog(call)) {
      int lastUpdateTime = 0;
      lastUpdateTime =
          objectMgr.localStorageMgr.read(LocalStorageMgr.LAST_APP_CALL_LOG) ??
              0;
      if (lastUpdateTime == 0) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      if (call.updatedAt > lastUpdateTime) {
        lastUpdateTime = call.updatedAt + 1;
      }
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.LAST_APP_CALL_LOG, lastUpdateTime);
    }
    if (allCallLog!.any((element) => call.channelId == element.channelId)) {
      return 0;
    }
    allCallLog!.add(call);
    allCallLog!.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    var count = await objectMgr.localDB.saveCallLog(call);

    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: objectMgr.loginMgr.deviceId,
        type: MetricsMgr.METRICS_TYPE_CALL,
        msg: CallLogInfo(
          channelId: objectMgr.callMgr.rtcChannelId,
          method: "saveOneCallLog",
          opt: "Sender: $sender, Call: ${call.toJson()}",
        ).toString(),
        mediaType: objectMgr.callMgr.getLogCallInfoStr(),
      ),
    );

    return count;
  }

  Future<void> removeCallLog(List<Call> callList) async {
    for (var element in callList) {
      await objectMgr.localDB.removeCallLog(element.channelId);
      allCallLog?.remove(element);
    }
    event(this, eventDelCallLog, data: callList);
  }

  @override
  Future<void> logout() async {
    allCallLog = null;
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
  }
}
