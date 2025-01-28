import 'dart:io';

final NetworkMgr networkMgr = NetworkMgr();

// 网络检查管理器
class NetworkMgr {
  Future<bool> checkServerConnection(String domain, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(domain, port,
          timeout: const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Future<bool> checkNetWork() async {
    final List<Map<String, dynamic>> sites = [
      {'domain': 'apple.com', 'port': 80},
      {'domain': 'qq.com', 'port': 80},
      {'domain': 'baidu.com', 'port': 80},
      {'domain': 'amazon.com', 'port': 80},
    ];

    List<Future<bool>> checks = sites.map((site) {
      return checkServerConnection(site['domain'], site['port']);
    }).toList();

    try {
      bool hasNet = await Future.any(checks);
      if (!hasNet) {
        final results = await Future.wait(checks);
        hasNet = results.contains(true);
      }
      return hasNet;
    } catch (e) {
      return false;
    }
  }
}
