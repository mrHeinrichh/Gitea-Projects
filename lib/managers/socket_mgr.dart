import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/network_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/socket.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';

/// 长连接管理器
class SocketMgr extends EventDispatcher {
  /// 连接建立
  static const String eventSocketOpen = 'eventSocketOpen';

  /// 连接关闭
  static const String eventSocketClose = 'eventSocketClose';

  /// 连接错误
  static const String eventSocketError = 'eventSocketError';

  /// 发生对象更新事件
  static const String updateBlock = 'updateBlock';

  static const String updateTaskBlock = 'updateTaskBlock';

  /// 系统行为通知
  static const String sysOprateBlock = 'sysOprateBlock';

  /// 已读对象更新事件
  static const String updateChatReadBlock = 'updateChatReadBlock';

  /// 已读对象更新事件
  static const String updateChatDeleteBlock = 'updateChatDeleteBlock';

  /// 朋友圈更新事件
  static const String updateMomentBlock = 'updateMomentBlock';

  /// 网络切换更新事件
  static const String updateNetConnectBlock = 'updateNetConnectBlock';

  /// 历史消息推送事件
  static const String updateHistoryMessageBlock = 'updateHistoryMessageBlock';

  static const String updateClientActionBlock = 'updateClientActionBlock';

  static const int heartbeatTime = 10 * 1000;
  int closeAtTime = 0;

  int updateSocketTime = 0;
  int reConnectTime = DateTime.now().millisecondsSinceEpoch;

  String socketUrl = '';

  setSocketUrl(String token) {
    socketUrl =
        "${serversUriMgr.socketUrl}?token=$_token&cipher=true&type=mode2";
  }

  bool isAlreadyPubSocketOpen = false;

  bool _isConnect = true;

  bool get isConnect => _isConnect;

  set isConnect(bool value) {
    _isConnect = value;
    event(this, updateNetConnectBlock);
  }

  Socket? socket;
  String? _token;
  List<String> contents = [];

  void init(String token) async {
    updateSocketTime = DateTime.now().millisecondsSinceEpoch;
    _token = token;
    setSocketUrl(token);

    await objectMgr.messageManager.init(objectMgr.userMgr.mainUser.id, token);
    socket?.destroy();
    socket = Socket.create(
      socketUrl,
      onSocketMessage,
      onopen: _onSocketOpen,
      onclose: _onSocketClose,
      onerror: _onSocketError,
      onpong: _onPong,
    );
    pdebug('@@@@@@@@@@@@ WebSocket connect');
    socket?.connect();
  }

  void checkReInit(String? newToken) {
    if (newToken != null) {
      _token = newToken;
      setSocketUrl(newToken);
    }

    if (_token == null || socket == null) {
      return;
    }

    if (socket!.open) {
      socket!.changeUrl(socketUrl);
      socket!.canReconnect = true;
      socket!.close();
    }
  }

  Timer? _timer;
  Timer? _batchTimer;
  int _batchAmount = 0;
  bool batchFirstComing = false;
  AppLifecycleState? _appLifecycleState;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _timer?.cancel();
      int nowTime = DateTime.now().millisecondsSinceEpoch;
      if (nowTime - updateSocketTime > 20 * 1000 ||
          (socket != null && !socket!.open)) {
        objectMgr.appInitState.value = AppInitState.connecting;
        isConnect = false;
        objectMgr.onNetworkOn();
      }
      updateSocketTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      if (!objectMgr.loginMgr.isDesktop) {
        __tryClose();
      }
    }
  }

  void __tryClose() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 90), (Timer timer) {
      if (socket != null && socket!.open) {
        socket?.close();
        objectMgr.chatMgr.event(objectMgr.chatMgr, ChatMgr.eventChatIsTyping);
      }
    });
  }

  void _runBatchTimer() {
    if (_batchTimer != null) {
      return;
    }

    _batchTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (contents.length > _batchAmount) {
        _batchAmount = contents.length;
        pdebug(
          "ExecuteBatch=================> $_batchAmount, ${contents.length}",
        );
      } else if (batchFirstComing) {
        // execute and stop
        _executeContents();
        _stopBatchTimer();
        batchFirstComing = false;
        pdebug("StopBatch=================> $_batchAmount, ${contents.length}");
      }
    });
  }

  _executeContents() async {
    final resultPort = ReceivePort();
    await Isolate.spawn(
      _batchAESDecode,
      [resultPort.sendPort, contents],
    );

    final contentResultList = await (resultPort.first) as List<String>;
    for (final content in contentResultList) {
      parseContent(content);
    }
  }

  static _batchAESDecode(List<dynamic> args) async {
    SendPort sendPort = args[0];
    List<String> contents = args[1];
    List<String> decodedContents = [];

    List<Future<String>> decodeFutures = [];

    decodedContents = await Future.wait(decodeFutures);

    pdebug(
      "_batchAESDecode============> ${contents.length}-${decodedContents.length}",
    );
    sendPort.send(decodedContents);
  }

  _stopBatchTimer() {
    if (_batchTimer != null) {
      _batchTimer!.cancel();
      _batchTimer = null;
    }
  }

  void onSocketMessage(dynamic content) async {
    updateSocketTime = DateTime.now().millisecondsSinceEpoch;
    objectMgr.messageManager.onSocketMessage(content);
    if (objectMgr.appInitState.value == AppInitState.connecting) {
      objectMgr.appInitState.value = AppInitState.done;
    }
  }

  void parseContent(String content) {
    var parser = UpdateBlockParser.created(content);

    // 系统操作更新
    for (var item in parser.updateOprateBeans) {
      event(this, sysOprateBlock, data: item);
    }

    // 已读消息更新
    // {"chat_read_msg":{"r":[{"id":1032,"other_read_idx":745}]}}
    for (var item in parser.updateChatReadBeans) {
      event(this, updateChatReadBlock, data: item);
    }

    // 删除消息更新
    for (var item in parser.updateChatDeleteBeans) {
      event(this, updateChatDeleteBlock, data: item);
    }

    // 朋友圈更新
    for (var item in parser.updateMomentBeans) {
      event(this, updateMomentBlock, data: item);
    }

    // 推历史消息结束的更新
    for (var item in parser.clientActions) {
      event(this, updateClientActionBlock, data: item);
    }

    // 历史消息推送更新
    for (var item in parser.messageHistoryBeans) {
      event(this, updateHistoryMessageBlock, data: item);
    }

    // 对象更新
    for (var item in parser.updateBlockBeans) {
      event(this, updateBlock, data: item);
    }
  }

  void sendEvent(String type, Object item) {
    event(this, type, data: item);
  }

  void _onSocketOpen() {
    pdebug('@@@@@@@@@@@@ onSocketOpen');
    isConnect = true;
    int start = updateSocketTime;
    updateSocketTime = DateTime.now().millisecondsSinceEpoch;
    _ping();
    event(this, eventSocketOpen);
    isAlreadyPubSocketOpen = true;
    logMgr.metricsMgr.addMetrics(
      Metrics(
        type: MetricsMgr.METRICS_TYPE_CONN_SOCKET,
        startTime: start,
        endTime: updateSocketTime,
      ),
    );
  }

  void _onSocketClose() {
    pdebug('@@@@@@@@@@@@ onSocketClose');
    closeAtTime = DateTime.now().millisecondsSinceEpoch;
    isConnect = false;
    contents.clear();
    event(this, eventSocketClose);
  }

  void _onSocketError() {
    pdebug('@@@@@@@@@@@@ onSocketError');
    closeAtTime = DateTime.now().millisecondsSinceEpoch;
    isConnect = false;
    contents.clear();
    event(this, eventSocketError);
  }

  Future<void> healthCheck() async {
    // 长连接建立后，检查 websocket 连通性
    int diff = DateTime.now().millisecondsSinceEpoch - updateSocketTime;
    int diffReConnect = DateTime.now().millisecondsSinceEpoch - reConnectTime;
    if (diff > (heartbeatTime + 1500) ||
        objectMgr.appInitState.value == AppInitState.no_network ||
        objectMgr.appInitState.value == AppInitState.no_connect ||
        (objectMgr.appInitState.value == AppInitState.connecting &&
            diffReConnect >= 2000)) {
      if (networkMgr.hasNetwork) {
        diffReConnect = DateTime.now().millisecondsSinceEpoch - reConnectTime;
        if (objectMgr.appInitState.value != AppInitState.connecting ||
            (objectMgr.appInitState.value == AppInitState.connecting &&
                diffReConnect >= 4000)) {
          isConnect = false;
          await objectMgr.onNetworkOn();
        }
      } else {
        objectMgr.appInitState.value = AppInitState.no_network;
      }
    }
  }

  _ping() async {
    if (socket != null && socket!.open) {
      String content = 'ping';
      socket?.send(content);
    }
  }

  send(String content, {bool isBatchExecute = false}) async {
    if (socket != null && socket!.open) {
      socket?.send(content);

      if (isBatchExecute) {
        contents.clear();
        _runBatchTimer();
      }
    }
  }

  _onPong() async {
    updateSocketTime = DateTime.now().millisecondsSinceEpoch;
    isConnect = true;
    Future.delayed(const Duration(milliseconds: heartbeatTime), () => _ping());
  }

  // 退出登录
  void logout() {
    updateSocketTime = 0;
    destroy();
  }

  // 释放
  void destroy() {
    closeAtTime = DateTime.now().millisecondsSinceEpoch;
    socket?.destroy();
    socket = null;
    super.clear();
  }

  void doRefreshToken({String? token}) {
    if (token != null) {
      checkReInit(token);
    }
  }
}

/// http请求响应回调,存着时间用于计算超时
class HttpTunnelDelegate {
  // 回调函数
  late Function resolve;
  late Function reject;

  // 回调序号
  int seq = 0;

  // 请求uri调试用
  String uri = '';

  // 请求发出去的时候
  int createTime = 0;

  // 请求的数据包
  dynamic packet;

  // 已过期
  bool timeout = false;

  //
  String messageJson = '';
}
