import 'dart:core';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/utility.dart';

enum CallLogType {
  all(0),
  missedCall(1);

  const CallLogType(this.type);

  final int type;
}

class CallLogMgr extends BaseMgr {
  final String eventAddCallLog = "eventAddCallLog";
  final String eventDelCallLog = "eventDelCallLog";
  final String eventCallLogUnreadUpdate = "eventCallLogUnreadUpdate";
  final String eventCallLogInited = "eventCallLogInited";
  RtcEngine? engine;
  List<Call>? allCallLog;
  bool isReloadData = false;

  @override
  Future<void> initialize() async {
    allCallLog = await loadDBCallLog();
    event(this, eventCallLogInited);
    if (objectMgr.socketMgr.isAlreadyPubSocketOpen) {
      _onSocketOpen(null, null, null);
    }
    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
  }

  Future<void> _onSocketOpen(a, b, c) async {
    loadRemoteCallLog(isInit: true);
  }

  Future<void> reloadData() async {
    if (isReloadData == true) {
      return;
    }
    isReloadData = true;
    await Future.delayed(const Duration(seconds: 5));
    allCallLog = await loadDBCallLog();
    await Future.delayed(const Duration(seconds: 30));
    isReloadData = false;
  }

  Future<void> loadRemoteCallLog({bool isInit = false}) async {
    // app 启动后再次请求间隔必须大于24小时
    if (isInit) {
      int lastInitTime = objectMgr.localStorageMgr
              .read(LocalStorageMgr.LAST_APP_INIT_CALL_LOG) ??
          0;
      if (isLess24Hours(lastInitTime)) {
        return; // 少于24小时，直接返回
      } else {
        objectMgr.localStorageMgr.write(LocalStorageMgr.LAST_APP_INIT_CALL_LOG,
            DateTime.now().millisecondsSinceEpoch);
      }
    }

    // 本地call log 最新数据的创建时间
    int lastUpdateTime =
        objectMgr.localStorageMgr.read(LocalStorageMgr.LAST_APP_CALL_LOG) ?? 0;
    allCallLog = await loadDBCallLog();
    if (lastUpdateTime == 0) {
      lastUpdateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    // 请求后端若有数据将会进行更新
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

    objectMgr.logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        deviceId: PlatformUtils.deviceId,
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

  Future<void> logout() async {
    allCallLog = null;
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
    isReloadData = false;
    clear();
  }

  @override
  Future<void> cleanup() async {}

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
