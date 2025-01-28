part of 'log_libs.dart';

class MetricsMgr extends LoadMgrBase<Metrics> {
  static String? loadID;

  static int? loadStartTime;

  static int? lastReqHistoryTime;

  static const String METRICS_TYPE_CONN_KIWI = "CONN_KIWI";

  static const String METRICS_TYPE_CHAT_LIST = "CHAT_LIST";

  static const String METRICS_TYPE_REQ_HISTORY = "REQ_HISTORY";

  static const String METRICS_TYPE_RCV_MSG = "RCV_MSG";

  static const String METRICS_TYPE_SAVE_MSG = "SAVE_MSG";

  static const String METRICS_TYPE_END_MSG = "END_MSG";

  static const String METRICS_TYPE_LOAD_FINISH = "LOAD_FINISH";

  static const String METRICS_TYPE_CALL = "CALL";

  @override
  Future<void> doSomeThing(Metrics metrics) async {
    pdebug(
        "metrics_log, type: ${metrics.type}, startTime: ${metrics.startTime}, "
        "endTime: ${metrics.endTime}, latency: ${metrics.latency}, reqID: ${metrics.reqID}, loadID: ${metrics.loadID}");
    metrics.loadID = loadID;
    if (metrics.type == METRICS_TYPE_LOAD_FINISH) {
      if (loadStartTime != null) {
        metrics.startTime = loadStartTime;
        metrics.latency = metrics.endTime! - metrics.startTime!;
      }
      metricsList.add(metrics);
      uploadMetrics(metricsList);
      metricsList = [];
    } else if (metrics.type == METRICS_TYPE_CHAT_LIST) {
      loadStartTime = metrics.startTime;
      if (metricsList.isNotEmpty) {
        uploadMetrics(metricsList);
        metricsList = [];
      }
      loadID = DateTime.now().millisecondsSinceEpoch.toString();
      metrics.loadID = loadID;
      metricsList.add(metrics);
    } else if (metrics.type == METRICS_TYPE_REQ_HISTORY) {
      lastReqHistoryTime = metrics.endTime;
      metricsList.add(metrics);
    } else if (metrics.type == METRICS_TYPE_RCV_MSG) {
      if (lastReqHistoryTime != null) {
        metrics.startTime = lastReqHistoryTime;
        metrics.latency = metrics.endTime! - metrics.startTime!;
      }
      metricsList.add(metrics);
    } else {
      metricsList.add(metrics);
    }
  }
}

class Metrics extends LogMsgBase {
  int? timestamp;
  int? startTime;
  int? endTime;
  int? latency;
  String? reqID;
  String? loadID;
  int? msgCnt;
  List<Chat>? chats;

  Metrics({
    super.type,
    super.msg,
    this.startTime,
    this.endTime,
    this.reqID,
    this.msgCnt,
    this.chats,
  }) {
    if (startTime != 0 && endTime != 0) {
      latency = endTime! - startTime!;
    }
    timestamp = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['log_time'] = timestamp;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['latency'] = latency;
    data['req_id'] = reqID;
    data['load_id'] = loadID;
    data['msg_cnt'] = msgCnt;

    if (chats != null) {
      List<List<Object>> chatList = [];
      for (var chat in chats!) {
        List<Object> chatInfos = [
          chat.chat_id,
          chat.msg_idx,
          chat.last_pos,
          chat.hide_chat_msg_idx,
          chat.read_chat_msg_idx,
        ];
        chatList.add(chatInfos);
      }
      data["chat"] = jsonEncode(chatList);
    }
    return data;
  }
}

class LogData {
  List<Metrics>? log;
  String? appVersion;
}
