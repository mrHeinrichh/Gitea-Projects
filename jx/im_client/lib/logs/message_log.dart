part of 'log_libs.dart';

enum MessageModule {
  kiwi,
  socket,
  chat_list_normal,
  chat_list_push,
  message_push,
  message_normal,
  message_fetch,
}

class MessageLog extends LogUtil {
  factory MessageLog() => _getInstance();

  static MessageLog get sharedInstance => _getInstance();

  static MessageLog? _instance;

  static MessageLog _getInstance() {
    _instance ??= MessageLog._internal();
    return _instance!;
  }

  MessageLog._internal() : super.module(LogModule.message);

  final Map<MessageModule, MessageDataAnalytics> _messageDataAnalytics =
      <MessageModule, MessageDataAnalytics>{};

  final Map<MessageModule, Lock> _messageReportLock = {
    MessageModule.kiwi: Lock(),
    MessageModule.socket: Lock(),
    MessageModule.chat_list_normal: Lock(),
    MessageModule.chat_list_push: Lock(),
    MessageModule.message_push: Lock(),
    MessageModule.message_normal: Lock(),
    MessageModule.message_fetch: Lock(),
  };

  static bool enableReport = true;

  void updateInfo(
    MessageModule module, {
    int? startTime,
    int? startRequestTime,
    int? endRequestTime,
    int? startReceiveTime,
    int? receiveBatchCount,
    int? endTime,
    int? messageCount,
    int? chatCount,
    bool shouldAddLog = false,
    bool shouldUpload = false,
  }) {
    MessageDataAnalytics? analytics = _messageDataAnalytics[module];
    if (analytics == null) {
      analytics = MessageDataAnalytics();
      _messageDataAnalytics[module] = analytics;
    }

    Lock? syncLock = _messageReportLock[module];
    if (syncLock == null) {
      syncLock ??= Lock();
      _messageReportLock[module] = syncLock;
    }

    // change to multiple module log
    analytics._updateInfo(
      module,
      startTime: startTime,
      startRequestTime: startRequestTime,
      endRequestTime: endRequestTime,
      startReceiveTime: startReceiveTime,
      receiveBatchCount: receiveBatchCount,
      endTime: endTime,
      messageCount: messageCount,
      chatCount: chatCount,
    );

    syncLock.synchronized(() async {
      if (shouldAddLog) {
        if (_messageDataAnalytics.isNotEmpty) {
          await _addLog(_messageDataAnalytics[module]);
        }
        _messageDataAnalytics.remove(module);
      }

      if (shouldUpload && enableReport) {
        await _report();
      }
    });
  }

  @protected
  @override
  Map<String, dynamic> processLog<T>(T message) {
    final logMsg = switch (message.runtimeType) {
      const (String) => {"message": message},
      const (MessageDataAnalytics) =>
        (message as MessageDataAnalytics).toJson(),
      _ => {},
    };

    return {
      'app_version': appVersionUtils.currentAppVersion,
      'platform': appVersionUtils.getDownloadPlatform(),
      'app_life_cycle_state': appLifeCycleState,
      'user_id': objectMgr.userMgr.mainUser.uid,
      'nick_name': objectMgr.userMgr.mainUser.username,
      'data': logMsg,
    };
  }
}

/// 使用的时候创建实例 缓存起来
/// 使用完毕把该实例直接销毁
class MessageDataAnalytics {
  int _startTime = 0;

  int _startRequestTime = 0;

  int _endRequestTime = 0;

  int _startReceiveTime = 0;

  int _receiveBatchCount = 0;

  int _endTime = 0;

  int _messageCount = 0;

  /// 获取聊天室数量
  int _chatCount = 0;

  MessageModule _module = MessageModule.message_normal;

  int get reqDuration => _endRequestTime - _startRequestTime;

  int get reqReceiveGap => _startReceiveTime - _startRequestTime;

  int get receiveLatency => _endTime - _startReceiveTime;

  int get receiveLatencyAvg => receiveLatency ~/ max(_receiveBatchCount, 1);

  int get totalLatency => _endTime - _startTime;

  bool get hasData => _startTime > 0 && _endTime > 0;

  void _updateInfo(
    MessageModule module, {
    int? startTime,
    int? startRequestTime,
    int? endRequestTime,
    int? startReceiveTime,
    int? receiveBatchCount,
    int? endTime,
    int? messageCount,
    int? chatCount,
  }) {
    _module = module;

    if (startTime != null) _startTime = startTime;

    if (startRequestTime != null) _startRequestTime = startRequestTime;

    if (endRequestTime != null) _endRequestTime = endRequestTime;

    if (startReceiveTime != null) _startReceiveTime = startReceiveTime;

    if (receiveBatchCount != null) _receiveBatchCount = receiveBatchCount;

    if (endTime != null) _endTime = endTime;

    if (messageCount != null) _messageCount += messageCount;

    if (chatCount != null) _chatCount += chatCount;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['module'] = _module.name;

    data.addAll(
      switch (_module) {
        const (MessageModule.kiwi) || const (MessageModule.socket) => {
            'start_time': _startTime,
            'end_time': _endTime,
            'total_latency': totalLatency,
          },
        const (MessageModule.chat_list_normal) => {
            'start_time': _startTime,
            'end_time': _endTime,
            'chat_count': _chatCount,
            'total_latency': totalLatency,
          },
        const (MessageModule.chat_list_push) => {
            'start_time': _startTime,
            'end_time': _endTime,
            'chat_count': _chatCount,
            'total_latency': totalLatency,
          },
        const (MessageModule.message_push) => {
            'start_time': _startTime,
            'start_request_time': _startRequestTime,
            'end_request_time': _endRequestTime,
            'req_duration': reqDuration,
            'end_time': _endTime,
            'total_latency': totalLatency,
          },
        const (MessageModule.message_normal) => {
            'start_time': _startTime,
            'end_time': _endTime,
            'total_latency': totalLatency,
          },
        const (MessageModule.message_fetch) => {
            'start_time': _startTime,
            'start_request_time': _startRequestTime,
            'req_receive_gap': reqReceiveGap,
            'start_receive_time': _startReceiveTime,
            'end_time': _endTime,
            'total_latency': totalLatency,
            'receive_batch_count': _receiveBatchCount,
            'receive_latency': receiveLatency,
            'receive_latency_avg': receiveLatencyAvg,
            'message_count': _messageCount,
          },
      },
    );

    return data;
  }

  @override
  String toString() {
    switch (_module) {
      // case MessageModule.socket:
      //   break;
      // case MessageModule.chatlist:
      //   break;
      // case MessageModule.message_push:
      //   break;
      case MessageModule.message_normal:
        return '''
\n      Request Message Info:
      Start Time: $_startTime
      Start Request Time: $_startRequestTime
      Start Receive Time: $_startReceiveTime
      End Time: $_endTime
      Total Latency: $totalLatency
      Request-Receive Gap: $reqReceiveGap
      Receive Latency: $receiveLatency
      Receive Latency Avg: $receiveLatencyAvg
      Message Count: $_messageCount
    ''';
      default:
        return '';
    }
  }
}
