import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/main.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/metrics_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/api_urls.dart';
import 'package:jxim_client/network/dun_mgr.dart';
import 'package:jxim_client/object/my_app_config.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';

final ServersUriMgr serversUriMgr = ServersUriMgr();

class ServersUriMgr {
  //api
  Uri? _apiUri = null;

  String get apiUrl => _apiUri == null ? "" : _apiUri!.origin;

  Uri? _socketUri = null;

  String get socketUrl =>
      _socketUri == null ? "" : "ws://${_socketUri!.authority}/websock/open";

  // String get socketUrl =>
  //     _apiUri == null ? "" : "ws://im-user.jxtest.net/websock/open";

  Uri? _sentryUri = null;

  String get sentryUrl => _sentryUri == null
      ? Config().sentryUrl
      : _sentryUri!.origin.split("/").last;

  Uri? _uploadUri = null;

  Uri? get uploadUri => _uploadUri;

  Uri? _download2Uri = null;

  Uri? get download2Uri => _download2Uri;

  Uri? _download1Uri = null;

  Uri? get download1Uri => _download1Uri;

  String get kiwiPort => apiUrl.split(":").last;

  bool isInit = false;

  bool isKiWiConnected = false;

  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

  Future<bool> checkIsConnected() async {
    isKiWiConnected = await networkCheck();
    return isKiWiConnected;
  }

  // 交换kiwi地址
  // 'kiwi_upload_uri': 'http://127.0.0.1:12345',
  Map<String, Uri?> _cacheKiwiMap = {};

  Future<Uri?> exChangeKiwiUrl(String urlPath, Uri? defaultUrl) async {
    if (urlPath.isEmpty) return null;
    // 绝对路径且不包含kiwi关键字，认为是cdn路径
    if (urlPath.startsWith('http')) {
      if (urlPath.contains('kiwi_')) {
        // 使用Uri.parse()解析URL
        Uri uri = Uri.parse(urlPath);
        // 获取基本URL
        String kiwiKey = Uri(
                scheme: uri.scheme, // 协议，如 http 或 https
                host: uri.host, // 主机名
                port: uri.port // 端口号，如果URL中没有特定指定端口号，则会返回默认的端口号
                )
            .toString();
        if (_cacheKiwiMap.isNotEmpty) {
          Uri? localUri = _cacheKiwiMap[kiwiKey];
          if (localUri != null) {
            uri = uri.replace(
              scheme: localUri.scheme,
              host: localUri.host,
              port: localUri.port,
            );
            return uri;
          }
        }
        Uri localUri = await getLocalUri(kiwiKey);
        uri = uri.replace(
          scheme: localUri.scheme,
          host: localUri.host,
          port: localUri.port,
        );
        _cacheKiwiMap[kiwiKey] = localUri;
        return uri;
      } else {
        // cdn
        return Uri.parse(urlPath);
      }
    } else {
      if (defaultUrl == null) return null;
      Uri uri = Uri.parse(urlPath);
      // 相对路径
      String path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      return Uri.parse("${defaultUrl.origin}/${path}");
    }
  }

  initApi() async {
    int start = DateTime.now().millisecondsSinceEpoch;
    if (_apiUri != null) {
      // 已初始化过
      return;
    }

    if (isInit) {
      // 正在初始化
      return;
    }

    isInit = true;

    ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(isolateInitApi, [receivePort.sendPort]);

    _apiUri = await receivePort.first;
    await doAnotherKiwiInit();
    isKiWiConnected = true;
    pdebug("kiwi _apiUri $_apiUri");
    objectMgr.onKiwiInit();
    int end = DateTime.now().millisecondsSinceEpoch;
    logMgr.metricsMgr.addMetrics(Metrics(
        type: MetricsMgr.METRICS_TYPE_CONN_KIWI,
        startTime: start,
        endTime: end));
  }

  // 初始化其他key
  doAnotherKiwiInit() async {
    // 获取配置
    const ConfKey = 'getMyConfig';
    try {
      // 先读取本地配置
      Map<String, dynamic>? map =
          objectMgr.localStorageMgr.read<Map<String, dynamic>>(ConfKey);
      // 存在直接过盾
      if (map != null && map.isNotEmpty) {
        await _formatJson(MyAppConfig.fromJson(map));
      }

      getMyConfig().then((MyAppConfig myAppConfig) async {
        if (notBlank(myAppConfig)) {
          _formatJson(myAppConfig);
          // 拿到配置进缓存
          objectMgr.localStorageMgr
              .write<Map<String, dynamic>>(ConfKey, myAppConfig.toJson());
        } else {
          // 任何失败清理缓存
          objectMgr.localStorageMgr.remove<Map<String, dynamic>>(ConfKey);
        }
      }).catchError((e) {
        // 任何失败清理缓存
        objectMgr.localStorageMgr.remove<Map<String, dynamic>>(ConfKey);
      });
    } catch (e) {
      // 任何失败清理缓存
      objectMgr.localStorageMgr.remove<Map<String, dynamic>>(ConfKey);
    }

    // 以下兜底固定=====
    Config config = Config();
    _socketUri = _socketUri ?? await getLocalUri(config.kiwiSocketHost);
    _uploadUri = _uploadUri ?? await getLocalUri(config.kiwiUpload);
    _download1Uri = _download1Uri ?? await getLocalUri(config.kiwiDownload1);
    _download2Uri = _download2Uri ?? await getLocalUri(config.kiwiDownload2);
    _sentryUri = await getLocalUri(config.kiwiSentry);
    pdebug("doAnotherKiwiInit apiUri:=========> ${_apiUri}");
    pdebug("doAnotherKiwiInit socketUri:=========> ${_socketUri}");
    pdebug("doAnotherKiwiInit sentryUri:=========> ${_sentryUri}");
    pdebug("doAnotherKiwiInit uploadUri:=========> ${_uploadUri}");
    pdebug("doAnotherKiwiInit downloadUri:=========> ${_download2Uri}");
    pdebug("doAnotherKiwiInit downloadStaticUri:=========> ${_download1Uri}");
    CommonConstants.baseGameUrl = "http://127.0.0.1:${serversUriMgr.kiwiPort}";
    // =====
  }

  // 解析配置
  Future _formatJson(MyAppConfig? myAppConfig) async {
    if (myAppConfig == null || !notBlank(myAppConfig)) {
      return;
    }
    if (myAppConfig.kiwi_download_1.isNotEmpty) {
      if (myAppConfig.kiwi_download_1.contains('kiwi_')) {
        _download1Uri ??= await getLocalUri(myAppConfig.kiwi_download_1);
      } else {
        _download1Uri = Uri.parse(myAppConfig.kiwi_download_1);
      }
    }
    if (myAppConfig.kiwi_download_2.isNotEmpty) {
      if (myAppConfig.kiwi_download_2.contains('kiwi_')) {
        _download2Uri ??= await getLocalUri(myAppConfig.kiwi_download_2);
      } else {
        _download2Uri = Uri.parse(myAppConfig.kiwi_download_2);
      }
    }
    if (myAppConfig.kiwi_upload.isNotEmpty) {
      if (myAppConfig.kiwi_upload.contains('kiwi_')) {
        _uploadUri ??= await getLocalUri(myAppConfig.kiwi_upload);
      } else {
        _uploadUri = Uri.parse(myAppConfig.kiwi_upload);
      }
    }
    if (myAppConfig.kiwi_websocket.isNotEmpty) {
      if (myAppConfig.kiwi_websocket.contains('kiwi_')) {
        _socketUri ??= await getLocalUri(myAppConfig.kiwi_websocket);
      } else {
        _socketUri = Uri.parse(myAppConfig.kiwi_websocket);
      }
    }
  }

  // 初始化api
  isolateInitApi(List<dynamic> args) async {
    SendPort sendPort = args[0];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    Config config = Config();
    await apiUrls.init(config.kiwiHost, config.kiwiKey, config.kiwiHead);

    Uri? dun_uri;

    // bypass 直连后端
    if (config.kiwiBypassHost != "") {
      dun_uri = Uri.tryParse(config.kiwiBypassHost);
      if (dun_uri != null) {
        sendPort.send(dun_uri);
        return;
      }
    }

    // 取得错误码
    final getCode = () async {
      int code = await dunMgr.initAsync(apiUrls.dunKey);
      bool done = await dunMgr.isInitDone();
      while (!done) {
        Future.delayed(const Duration(milliseconds: 20));
        done = await dunMgr.isInitDone();
      }

      if (code == 0) {
        Uri? u = Uri.tryParse(apiUrls.dunUrl);
        dun_uri = await dunMgr.serverToLocal(u!);
        if (dun_uri == null) {
          code = -1;
        }
      }

      return code;
    };

    const int max_retry_interval = 10;
    int retry_interval = 1;
    int code = await getCode();
    while (code != 0) {
      pdebug("Kiwi init return $code, try again");
      await Future.delayed(Duration(seconds: retry_interval));
      retry_interval += 1;
      if (retry_interval > max_retry_interval) {
        retry_interval = max_retry_interval;
      }
      code = await getCode();
    }

    sendPort.send(dun_uri);
  }

  getLocalUri(String dunUrl) async {
    Uri? u = Uri.tryParse(dunUrl);
    return await dunMgr.serverToLocal(u!);
  }

  restartApi() async {
    if (apiUrls.dunKey.isNotEmpty) {
      await dunMgr.restart();
    }
  }

  onNetworkOn() async {
    await dunMgr.onNetworkOn();
  }
}
