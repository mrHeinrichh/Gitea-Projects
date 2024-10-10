import 'dart:io';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/utils/debug_info.dart';

final NetworkMgr networkMgr = NetworkMgr();

// 网络检查管理器
class NetworkMgr extends ScheduleTask {
  NetworkMgr({Duration delay = const Duration(milliseconds: 2000)})
      : _timeout = Duration(
            milliseconds: (delay.inMilliseconds >= 200
                ? delay.inMilliseconds - 10
                : delay.inMilliseconds)),
        super(delay);

  final Duration _timeout;

  bool get hasNetwork => _hasNetworkStatus == 1;
  int _hasNetworkStatus = -1;

  bool _isDelayCancelled = false;

  @override
  Future<void> execute() async {
    final tempNetwork = await _checkNetWork()
        .timeout(_timeout, onTimeout: () => false)
        .then((value) => value)
        .catchError((onError) => false);
    final tempNetworkStatus = tempNetwork ? 1 : 0;
    _isDelayCancelled =
        _hasNetworkStatus != -1 && tempNetworkStatus == _hasNetworkStatus;
    _hasNetworkStatus = tempNetworkStatus;
    Future.delayed(const Duration(seconds: 10), () {
      if (_isDelayCancelled) {
        pause();
      }
    });
  }

  final headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
  };
  Future<bool> _checkNetWork() async {
    final urls = [
      'https://www.baidu.com',
      'https://www.google.com',
      'https://www.qq.com',
      'https://aws.amazon.com',
    ];

    // https://jtalk.s3.ap-southeast-1.amazonaws.com/Image/10/6c/106cdd57464dd82f36c468bd8f5b594f/106cdd57464dd82f36c468bd8f5b594f_64.jpeg
    // "http://127.0.0.1:39999/Image/10/6c/106c23b85d7cd25861600b10927a2004/106c23b85d7cd25861600b10927a2004_384.jpeg"
    // 创建所有请求的 Future 列表，并处理所有异常情况

    final futures = urls.map((url) {
      return http.get(Uri.parse(url), headers: headers).then((response) {
        final result = response.statusCode == HttpStatus.ok;
        return result;
      }).catchError((error) {
        pdebug('fetching Error $url: $error');
        return false; // 返回 false 表示请求失败
      }).timeout(_timeout, onTimeout: () {
        pdebug('fetching Timeout $url');
        return false; // 超时时返回 false
      });
    }).toList();
    // 等待所有请求完成
    final results = await Future.wait(futures);
    pdebug('fetching results: ${results.toString()}');
    // 检查是否有任何一个请求返回 true
    return results.contains(true);
  }
}
