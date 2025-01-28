import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as path;

abstract class _LocalHttpServerAbstract {
  int get port => _httpServer == null ? 0 : _httpServer!.port;

  String get host => '127.0.0.1';

  String get scheme => 'http';

  //http服务
  HttpServer? _httpServer;

  Completer<bool>? _completer;

  // 默认本地端口
  int defaultLocalPort = 0;

  Future<bool> initServerUrl() async {
    defaultLocalPort = Config().video_http_server_port;
    if (defaultLocalPort == 0) return false;

    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }
    _completer = Completer<bool>();
    // 如果不为空，检查下端口是不是通的
    if (_httpServer != null) {
      try {
        // 尝试建立 TCP 连接，使用超时时间
        final socket = await Socket.connect(host, _httpServer!.port,
            timeout: const Duration(seconds: 1));
        socket.destroy(); // 如果连接成功，立即关闭连接
        _completer!.complete(true);
        return _completer!.future; // 端口是通的
      } catch (e) {
        _httpServer!.close(force: true);
        _httpServer = null;
      }
    }

    //重启启动http
    if (_httpServer == null) {
      _completer!.complete(await _initHttp());
      return _completer!.future;
    }
    _completer!.complete(false);
    return _completer!.future;
  }

  close() {
    if (_httpServer != null) {
      _httpServer!.close(force: true);
      _httpServer = null;
      pdebug('LocalHttpServer=====close');
    }
  }

  Future<bool> _initHttp() async {
    pdebug('LocalHttpServer=====创建http服务');

    // 初始值默认端口 ,动态端口 【36610->36610+10】
    int localPort = defaultLocalPort;

    int retries = 0;
    // 步长固定10别动
    const maxRetries = 10;

    while (_httpServer == null && retries < maxRetries) {
      try {
        // 尝试使用随机端口启动 HttpServer（端口0表示系统随机分配）
        _httpServer =
            await HttpServer.bind(InternetAddress.loopbackIPv4, localPort);
        if (_httpServer == null) {
          pdebug("LocalHttpServer http服务启动失败");
          continue;
        }
        pdebug(
            'LocalHttpServer HTTP server started on port http://127.0.0.1:${_httpServer!.port}');

        // 处理 HTTP 请求
        _httpServer!.listen((HttpRequest request) {
          _httpListen(request);
        });
      } catch (e) {
        // 端口被占用，重新尝试绑定
        localPort++;
        retries++;
        pdebug(
            'LocalHttpServer Port allocation failed. Retrying... (Attempt $retries)');
      }
    }

    if (_httpServer == null) {
      pdebug(
          'LocalHttpServer Failed to start the server after $maxRetries attempts.');
      return false;
    }

    return true;
  }

  //http监听
  _httpListen(HttpRequest request) async {
    pdebug(
        'LocalHttpServer _httpListen method:${request.method} url:${request.uri.toString()}');
    //普通的资源
    if (await _handleGet(request)) {
      return;
    }
    //其他的暂时没有支持
    pdebug('LocalHttpServer _httpListen Not found');
    request.response
      ..statusCode = HttpStatus.notFound
      ..write("Not found");
    request.response.close();
  }

  Future<bool> _handleGet(HttpRequest request) async {
    if (request.method != 'GET') return false;
    if (request.uri == null) return false;
    if (request.uri.path.lastIndexOf('.') < 0) {
      return false;
    } else {
      bool hasSavedFile = await _hasSavedFile(request);
      if (hasSavedFile) {
        return hasSavedFile; //有写文件了就直接使用，否则继续往下走
      }
      return await _parseData(request);
    }
  }

  Future<bool> _parseData(HttpRequest request) async {
    final Uri? targetUri = await serversUriMgr.exChangeKiwiUrl(
        request.uri.toString(), serversUriMgr.download1Uri);
    if (targetUri == null) return false;
    HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3); // 设置连接超时时间
    try {
      final clientRequest = await client.getUrl(targetUri);
      // 设置请求超时 10 秒
      final clientResponse =
          await clientRequest.close().timeout(const Duration(seconds: 10));

      // 透传 statusCode
      request.response.statusCode = clientResponse.statusCode;
      // 透传 headers
      clientResponse.headers.forEach((name, values) {
        request.response.headers.set(name, values);
      });

      // 获取响应体
      Uint8List bytes =
          await _consolidateHttpClientResponseBytes(request, clientResponse)
              .timeout(const Duration(seconds: 10));

      request.response.add(bytes);
    } catch (e) {
      pdebug('LocalHttpServer error e: $e');
    } finally {
      client.close();
      await request.response.close();
    }

    return true;
  }

  // 解析respone
  Future<Uint8List> _consolidateHttpClientResponseBytes(
      HttpRequest request, HttpClientResponse response) async {
    String decodeStr = _getDecodeStr(request);

    final contents = BytesBuilder();
    await for (var data in response) {
      contents.add(data); //不能针对部分返回参数进行解密，需要针对整体返回进行解密，否则大文件有概率不全（因使用流获取）
    }

    var bytes = contents.takeBytes();
    if (decodeStr.isNotEmpty) {
      bytes = xorDecode(bytes, decodeStr);
    }

    if (_isNeedSave(request)) {
      final savePath = downloadMgr.getSavePath(request.uri.path);
      final file = File(savePath);
      try {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
      } catch (e) {
        File(savePath).delete().catchError((_) => file);
        pdebug('Failed to save file: $e');
      }
    }

    return bytes;
  }

  String _getDecodeStr(HttpRequest request) {
    if (!_isNeedDecode(request)) return '';
    return request.response.statusCode == HttpStatus.ok
        ? getDecodeKey(request.uri.path)
        : '';
  }

  bool _isNeedDecode(HttpRequest request) {
    final ext = path.extension(request.uri.path).toLowerCase();
    return ext != '.ts';
  }

  bool _isNeedSave(HttpRequest request) {
    final ext = path.extension(request.uri.path).toLowerCase();
    if (!objectMgr.loginMgr.isDesktop && (ext == ".ts" || ext == ".m3u8")) {
      return false;
    }

    return true;
  }

  Future<bool> _hasSavedFile(HttpRequest request) async {
    if (!_isNeedSave(request)) return false;
    var s3Path = request.uri.toString();
    var path = downloadMgrV2.getLocalPath(s3Path);
    if (path != null && notBlank(path)) {
      var file = File(path); //解过了
      if (file.existsSync()) {
        Uint8List bytes = file.readAsBytesSync();
        if (bytes.isNotEmpty) {
          request.response.add(bytes);
          await request.response.close();
          return true;
        }
      }
    }

    return false;
  }
}

LocalHttpServer localHttpServer = LocalHttpServer();

class LocalHttpServer extends _LocalHttpServerAbstract {
  // 获取代理地址
  static Future<Uri?> getLocalproxy(Uri? uri) async {
    if (uri != null && uri.path.contains('secret/')) {
      if (localHttpServer.port == 0) {
        await localHttpServer.initServerUrl();
      }
      if (localHttpServer.port > 0) {
        uri = uri.replace(
            scheme: localHttpServer.scheme,
            host: localHttpServer.host,
            port: localHttpServer.port);
      }
    }
    return uri;
  }
}
