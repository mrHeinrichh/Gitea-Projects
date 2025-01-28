import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/network_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/api_urls.dart';
import 'package:jxim_client/network/dun_mgr.dart';
import 'package:jxim_client/object/my_app_config.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';

final ServersUriMgr serversUriMgr = ServersUriMgr();

class ServersUriMgr {
  //api
  Uri? _apiUri;

  String get apiUrl => _apiUri == null ? Config().apiHost : _apiUri!.origin;

  Uri? _socketUri;
  Uri? get socketUri => _socketUri;

  String get socketUrl => _socketUri == null
      ? "${Config().apiHost.replaceFirst("http", "ws")}/websock/open"
      : "ws://${_socketUri!.authority}/websock/open";

  Uri? _openInstallUri;

  String get openInstallUrl =>
      _openInstallUri == null ? Config().opHost : _openInstallUri!.origin;

  Uri? _uploadUri;

  Uri? get uploadUri => _uploadUri ?? Uri.parse(Config().uploadHost);

  Uri? _download2Uri;

  Uri? get download2Uri => _download2Uri ?? Uri.parse(Config().download2Host);

  Uri? _download1Uri;

  Uri? get download1Uri => _download1Uri ?? Uri.parse(Config().download1Host);

  Uri? _speed1Uri;

  Uri? get speed1Uri => _speed1Uri ?? Uri.parse(Config().speedHost);

  String get kiwiPort => apiUrl.split(":").last;

  bool isInit = false;

  bool isKiWiConnected = false;

  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

  Future<bool> checkIsConnected() async {
    isKiWiConnected = await networkCheck();
    return isKiWiConnected;
  }

  Future<bool> networkCheck() async {
    try {
      Map<String, dynamic> dataBody = {"channel": Config().orgChannel};

      final ResponseData res = await CustomRequest.doGet(
        "/im/health/check",
        data: dataBody,
        needToken: false,
      );
      return res.success();
    } on AppException {
      return false;
    }
  }

  // 交换kiwi地址
  // 'kiwi_upload_uri': 'http://127.0.0.1:12345',
  final Map<String, Uri?> _cacheKiwiMap = {};

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
          port: uri.port, // 端口号，如果URL中没有特定指定端口号，则会返回默认的端口号
        ).toString();
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
      String uriString = uri.toString();
      // 相对路径
      String path =
          uriString.startsWith('/') ? uriString.substring(1) : uriString;
      return Uri.parse("${defaultUrl.origin}/$path");
    }
  }

  waitNetPermission() async {
    try {
      var currentVersion = await PlatformUtils.getAppVersion();
      var latestVersion = objectMgr.localStorageMgr
              .globalRead(LocalStorageMgr.LAST_APP_VERSION_FOR_DUN) ??
          "0.0.0";
      if (currentVersion != latestVersion) {
        while (true) {
          if (await networkMgr.checkNetWork()) {
            break;
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        await objectMgr.localStorageMgr.globalWrite(
          LocalStorageMgr.LAST_APP_VERSION_FOR_DUN,
          currentVersion,
        );
      }
    } catch (e) {
      pdebug("Dun Init Api Exception:$e");
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
    Timer? timer = Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      objectMgr.onKiwiInit();
    });

    if (!Platform.isMacOS) {
      await waitNetPermission();
    }

    ReceivePort receivePort = ReceivePort();
    await Isolate.spawn<SendPort>(isolateInitApi, receivePort.sendPort);

    _apiUri = await receivePort.first;
    timer.cancel();
    await doAnotherKiwiInit();
    isKiWiConnected = true;
    pdebug("kiwi _apiUri $_apiUri");
    objectMgr.onKiwiInit();
    int end = DateTime.now().millisecondsSinceEpoch;
    objectMgr.logMgr.metricsMgr.addMetrics(
      Metrics(
        type: MetricsMgr.METRICS_TYPE_CONN_KIWI,
        startTime: start,
        endTime: end,
      ),
    );
  }

  // 初始化其他key
  doAnotherKiwiInit() async {
    // 获取配置
    try {
      // 先读取本地配置
      Map<String, dynamic>? map = objectMgr.localStorageMgr
          .read<Map<String, dynamic>>(LocalStorageMgr.SERVER_URI_CONFIG_KEY);
      // 存在直接过盾
      if (map != null && map.isNotEmpty) {
        await _formatJson(MyAppConfig.fromJson(map));
      }

      getMyConfig().then((MyAppConfig myAppConfig) async {
        if (notBlank(myAppConfig)) {
          await _formatJson(myAppConfig);
          // 拿到配置进缓存
          objectMgr.localStorageMgr.write<Map<String, dynamic>>(
              LocalStorageMgr.SERVER_URI_CONFIG_KEY, myAppConfig.toJson());
        } else {
          // 任何失败清理缓存
          objectMgr.localStorageMgr
              .remove(LocalStorageMgr.SERVER_URI_CONFIG_KEY);
        }
      }).catchError((e) {
        // 任何失败清理缓存
        objectMgr.localStorageMgr.remove(LocalStorageMgr.SERVER_URI_CONFIG_KEY);
      });
    } catch (e) {
      // 任何失败清理缓存
      objectMgr.localStorageMgr.remove(LocalStorageMgr.SERVER_URI_CONFIG_KEY);
    }

    // 以下兜底固定=====
    Config config = Config();
    _socketUri = _socketUri ?? await getLocalUri(config.kiwiSocketHost);
    _uploadUri = _uploadUri ?? await getLocalUri(config.kiwiUpload);
    _openInstallUri = _openInstallUri ?? await getLocalUri(config.kiwiOp);
    _download1Uri = _download1Uri ?? await getLocalUri(config.kiwiDownload1);
    _download2Uri = _download2Uri ?? await getLocalUri(config.kiwiDownload2);
    _speed1Uri = _speed1Uri ?? await getLocalUri(config.kiwiTest);
    pdebug("doAnotherKiwiInit apiUri:=========> $_apiUri");
    pdebug("doAnotherKiwiInit socketUri:=========> $_socketUri");
    pdebug("doAnotherKiwiInit socketUri:=========> ${_socketUri.toString()}");
    pdebug("doAnotherKiwiInit openInstallUri:=========> $_openInstallUri");
    pdebug("doAnotherKiwiInit uploadUri:=========> $_uploadUri");
    pdebug("doAnotherKiwiInit downloadUri:=========> $_download2Uri");
    pdebug("doAnotherKiwiInit downloadStaticUri:=========> $_download1Uri");
    CommonConstants.baseGameUrl = "http://127.0.0.1:${serversUriMgr.kiwiPort}";
    pdebug("doAnotherKiwiInit CommonConstants.baseGameUrl:=========> ${CommonConstants.baseGameUrl}");

    // =====

    objectMgr.loginMgr.checkNeedLoginOut();
  }

  // 解析配置
  Future _formatJson(MyAppConfig? myAppConfig) async {
    if (myAppConfig == null || !notBlank(myAppConfig)) {
      return;
    }
    if (myAppConfig.kiwiDownload1.isNotEmpty) {
      if (myAppConfig.kiwiDownload1.contains('kiwi_')) {
        final temp = await getLocalUri(myAppConfig.kiwiDownload1);
        _download1Uri = temp ?? Uri.parse(myAppConfig.kiwiDownload1);
      } else {
        _download1Uri = Uri.parse(myAppConfig.kiwiDownload1);
      }
    }
    if (myAppConfig.kiwiDownload2.isNotEmpty) {
      if (myAppConfig.kiwiDownload2.contains('kiwi_')) {
        final temp = await getLocalUri(myAppConfig.kiwiDownload2);
        _download2Uri = temp ?? Uri.parse(myAppConfig.kiwiDownload2);
      } else {
        _download2Uri = Uri.parse(myAppConfig.kiwiDownload2);
      }
    }
    if (myAppConfig.kiwiUpload.isNotEmpty) {
      if (myAppConfig.kiwiUpload.contains('kiwi_')) {
        final temp = await getLocalUri(myAppConfig.kiwiUpload);
        _uploadUri = temp ?? Uri.parse(myAppConfig.kiwiUpload);
      } else {
        _uploadUri = Uri.parse(myAppConfig.kiwiUpload);
      }
    }
    if (myAppConfig.kiwiWebsocket.isNotEmpty) {
      if (myAppConfig.kiwiWebsocket.contains('kiwi_')) {
        final temp = await getLocalUri(myAppConfig.kiwiWebsocket);
        _socketUri = temp ?? Uri.parse(myAppConfig.kiwiWebsocket);
      } else {
        _socketUri = Uri.parse(myAppConfig.kiwiWebsocket);
      }
    }

    if (myAppConfig.enableMessageLog != null) {
      MessageLog.enableReport = myAppConfig.enableMessageLog ?? true;
    }
  }

  // 初始化api
  isolateInitApi(SendPort sendPort) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    Config config = Config();
    await apiUrls.init(config.kiwiHost, config.kiwiKey, config.kiwiHead);

    Uri? dunUri;

    // bypass 直连后端
    if (config.kiwiBypassHost != "") {
      dunUri = Uri.tryParse(config.kiwiBypassHost);
      if (dunUri != null) {
        sendPort.send(dunUri);
        return;
      }
    }

    // 取得错误码
    getCode() async {
      int code = await dunMgr.initAsync(apiUrls.dunKey);
      bool done = await dunMgr.isInitDone();
      while (!done) {
        await Future.delayed(const Duration(milliseconds: 20));
        done = await dunMgr.isInitDone();
      }

      if (code == 0) {
        Uri? u = Uri.tryParse(apiUrls.dunUrl);
        dunUri = await dunMgr.serverToLocal(u!);
        if (dunUri == null) {
          code = -1;
        }
      }

      return code;
    }

    const int maxRetryInterval = 10;
    int retryInterval = 1;
    int code = await getCode();
    while (code != 0) {
      pdebug("Kiwi init return $code, try again");
      await Future.delayed(Duration(seconds: retryInterval));
      retryInterval += 1;
      if (retryInterval > maxRetryInterval) {
        retryInterval = maxRetryInterval;
      }
      code = await getCode();
    }

    sendPort.send(dunUri);
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
