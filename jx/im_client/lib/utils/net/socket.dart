import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';

const _updateFrequency = 100; // 心跳频率
const _reconnectFrequency = 2000; // 重连频率
const _reconnectFrequencyAdd = 2000; // 重连频率递增

class Socket {
  String _url = '';

  changeUrl(String url) {
    _url = url;
  }

  WebSocket? _webSocket;

  Timer? _timer;
  int _reConnectCooldown = 0; // 重连冷却
  int _reConnectCount = 0;
  bool _canReconnect = false; // 能否重连
  bool get canReconnect => _canReconnect;

  set canReconnect(bool v) {
    _canReconnect = v;
    _reConnectCooldown = _reconnectFrequency +
        min(_reConnectCount * _reconnectFrequencyAdd, 16000);
  }

  // 回调
  void Function()? _onopen;

  void Function(dynamic content)? _onmessage;
  void Function()? _onclose;
  void Function()? _onerror;

  Socket.create(
    String url,
    void Function(dynamic content)? onmessage, {
    void Function()? onopen,
    void Function()? onclose,
    void Function()? onerror,
    void Function()? onpong,
  }) {
    _url = url;
    pdebug("socket url: $url");
    _onmessage = (content) {
      if (content == "pong") {
        if (onpong != null) {
          onpong();
        }
        return;
      }

      onmessage!(content);
    };
    _onopen = onopen;
    _onclose = onclose;
    _onerror = onerror;
    _timer =
        Timer.periodic(const Duration(milliseconds: _updateFrequency), _update);
  }

  HttpClient? _webSockethttpClient;

  // 连接
  void connect({String? url}) async {
    if (url != null) {
      _url = url;
    }
    // pdebug(_webSocket?.readyState);
    assert(_webSocket == null || _webSocket?.readyState == WebSocket.closed);
    pdebug('WebSocket connect:$_url');
    canReconnect = false;
    _webSockethttpClient = getHttpClient();
    try {
      _webSocket = await WebSocket.connect(
        _url,
        compression: CompressionOptions.compressionDefault,
        customClient: _webSockethttpClient,
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('WebSocket.connect timeout'));
    } on WebSocketException catch (e) {
      pdebug('WebSocket connect failed: $e');
      close();
    } on TimeoutException catch (e) {
      pdebug('WebSocket connect timeout: $e');
      close();
    } catch (e) {
      pdebug('WebSocket connect failed: $e');
      close();
    }
    canReconnect = true;

    _webSocket?.pingInterval = const Duration(milliseconds: 5000);

    // 监听事件
    _webSocket?.listen(_onmessage, onDone: __onclose, onError: __onerror);
    if (_webSocket != null) {
      _onopen?.call();
      _reConnectCount = 0;
    }
  }

  // 关闭了
  void __onclose() {
    // 记录最后在线时间
    final int curTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    objectMgr.localStorageMgr.write(LocalStorageMgr.LAST_ACTIVE_TIME, curTime);

    pdebug('WebSocket __onclose:$_url');
    _onclose?.call();
    ___onclose();
  }

  //  出错了
  void __onerror(dynamic error) {
    pdebug('WebSocket onerror:$_url');
    _onerror?.call();
    ___onclose();
  }

  // 重连
  void reConnect() {
    _reConnectCount = 0;
    canReconnect = true;
    _reConnectCooldown = 100;
  }

  // 发送
  void send(dynamic data) {
    if (_webSocket == null) {
      pdebug('WebSocket ws_send but ws_socket is null');
      return;
    }

    _webSocket?.add(data);
  }

  // 关闭
  void close() {
    canReconnect = false;
    ___onclose();
  }

  // 关闭时
  void ___onclose() {
    pdebug('WebSocket ___onclose:$_url');
    _webSockethttpClient?.close();
    _webSockethttpClient = null;
    _webSocket?.close();
    _webSocket = null;
  }

  void _update(Timer timer) {
    if (_canReconnect && _webSocket == null) {
      if (_reConnectCooldown <= 0) {
        connect();
        _reConnectCount++;
      } else {
        _reConnectCooldown -= _updateFrequency;
      }
    }
  }

  // 连接状态
  int get readyState {
    return _webSocket?.readyState ?? WebSocket.closed;
  }

  // 连接是否打开
  bool get open => readyState == WebSocket.open;

  void destroy() {
    _onopen = null;
    _onmessage = null;
    _onclose = null;
    _onerror = null;
    _timer?.cancel();
    close();
  }
}
