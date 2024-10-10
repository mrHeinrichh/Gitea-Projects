// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
// import 'dart:typed_data';
// import 'package:mime_type/mime_type.dart';

import 'package:flutter/material.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/utils/config.dart';

VideoHttpServer videoHttpServer = VideoHttpServer();

class VideoHttpServer extends LocalHttpServer {}

enum LocalHttpServerStatus {
  //没状态,啥都还没干
  none,
  //http服务开始初始化
  init,
  //资源服过盾中
  tryDun,
  //资源服过盾完成
  tryDunOk,
  //下载描述文件中
  downloadTxt,
  //描述文件下载完成
  downloadTxtOk,
  //下载资源中
  downOther,
  //http服务启动成功
  ok,
  //http服务启动失败
  fail
}

abstract class LocalHttpServer {
  Timer? _updateTimer;
  //当前状态
  LocalHttpServerStatus _status = LocalHttpServerStatus.none;
  LocalHttpServerStatus get status => _status;
  bool get ok => _status == LocalHttpServerStatus.ok;
  bool get fail => _status == LocalHttpServerStatus.fail;
  int? get port => _httpServer == null ? null : _httpServer!.port;
  //http服务
  HttpServer? _httpServer;
  final video_http_server_port = Config().video_http_server_port;

  initServerUrl() {
    if (video_http_server_port == 0) {
      return;
    }
    _initHttp();
    setStatus(LocalHttpServerStatus.init);
    _update();
  }

  setStatus(LocalHttpServerStatus status, [String msg = '']) {
    _status = status;
  }

  @protected
  downOk() {
    return true;
  }

  @protected
  downFail() {
    return false;
  }

  @protected
  changeServer() {}

  _update() {
    if (_updateTimer != null) return;
    _updateTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      switch (_status) {
        case LocalHttpServerStatus.none:
          break;
        case LocalHttpServerStatus.init:
          setStatus(LocalHttpServerStatus.tryDun);
          break;
        case LocalHttpServerStatus.tryDun:
          break;
        case LocalHttpServerStatus.tryDunOk:
          setStatus(LocalHttpServerStatus.downloadTxt);
          break;
        case LocalHttpServerStatus.downloadTxt:
          break;
        case LocalHttpServerStatus.downloadTxtOk:
          setStatus(LocalHttpServerStatus.downOther);
          break;
        case LocalHttpServerStatus.downOther:
          if (downOk()) {
            setStatus(downFail()
                ? LocalHttpServerStatus.fail
                : LocalHttpServerStatus.ok);
          }
          break;
        case LocalHttpServerStatus.ok:
          _updateTimer!.cancel();
          _updateTimer = null;
          break;
        case LocalHttpServerStatus.fail:
          _updateTimer!.cancel();
          _updateTimer = null;
          break;
      }
    });
  }

  _initHttp() async {
    print('LocalHttpServer=====创建http服务');
    int oldPort = video_http_server_port;
    if (_httpServer != null) {
      HttpClient httpClient = HttpClient();
      try {
        HttpClientRequest request = await httpClient
            .postUrl(Uri.parse('http://127.0.0.1:${_httpServer!.port}'));
        HttpClientResponse rep = await request.close();
        if (rep.statusCode == HttpStatus.ok) {
          print('LocalHttpServer=====旧的服务测试成功');
          return true;
        }
      } catch (_) {
      } finally {
        httpClient.close();
      }
      print('LocalHttpServer=====旧的服务测试失败');
      try {
        oldPort = _httpServer!.port;
        await _httpServer!.close(force: true);
      } catch (_) {}
      _httpServer = null;
      changeServer();
    }

    int newProt = oldPort;
    int tryCount = 0;

    while (_httpServer == null && tryCount <= 5) {
      // if (!networkMgr.hasNetwork) continue;
      _httpServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, newProt);
      if (_httpServer == null) {
        print("http服务启动失败$oldPort");
        return false;
      }

      print('LocalHttpServer=====启动成功 http://127.0.0.1:${_httpServer!.port}');
      await for (HttpRequest request in _httpServer!) {
        try {
          _httpListen(request);
        } catch (_) {
          _httpServer = null;
        }
      }

      if (_httpServer == null) {
        newProt = 0;
        tryCount++;
      }
    }

    return true;
  }

  //http监听
  _httpListen(HttpRequest request) async {
    //普通的资源
    if (await _handleGet(request)) return;

    //其他的暂时没有支持
    assert(false);
  }

  // String? _getMimeType(String name) {
  //   String? mimeType = mime(name);
  //   if (mimeType == null) {
  //     final int lastDot = name.lastIndexOf('.', name.length - 1);
  //     if (lastDot != -1) {
  //       final String extension = name.substring(lastDot + 1);
  //       switch (extension) {
  //         case "atlas":
  //           mimeType = 'text/plain; charset=utf-8';
  //           break;
  //       }
  //     }
  //   }
  //   return mimeType;
  // }

  // void _addUint8ListToRes(Uint8List ul, HttpRequest request) {
  //   request.response.statusCode = HttpStatus.ok;
  //   String? mimeType = _getMimeType(request.uri.path);
  //   if (mimeType != null) {
  //     request.response.headers.set("Content-Type", mimeType);
  //   }

  //   request.response.headers.contentType = ContentType.binary;
  //   request.response.headers
  //       .set('Content-Disposition', 'attachment; filename="file.txt"');

  //   request.response.headers.set("Content-Length", ul.length);
  //   request.response.add(ul);
  // }

  Future<bool> _handleGet(HttpRequest request) async {
    if (request.method != 'GET') return false;
    if (request.uri.path.lastIndexOf('.') < 0) {
      print("_handleGet 404, ${request.uri}");
      request.response
        ..statusCode = HttpStatus.notFound
        ..write("Not found");
    } else {
      final targetUrl = await serversUriMgr.exChangeKiwiUrl(
          request.uri.toString(), serversUriMgr.download1Uri);

      // 发送请求到远程 HLS 服务器
      var clientRequest = http.Request('GET', targetUrl!);

      var clientResponse = await clientRequest.send();

      // 透传远程服务器的响应
      request.response.statusCode = clientResponse.statusCode;
      clientResponse.headers.forEach((name, values) {
        request.response.headers.set(name, values);
      });

      // 透传响应体
      await clientResponse.stream.pipe(request.response);
    }
    await request.response.close();
    return true;
  }
}
