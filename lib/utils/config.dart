import 'dart:io';

import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';

class Config {
  static final Config _instance = Config._internal();

  factory Config() {
    return _instance;
  }

  Config._internal() {
    minType = [headMin, dynamicMin, messageMin];
  }

  /// 是否清理本地缓存
  final bool cleanLocalStorage = false;

  /// 是否清理sqflite缓存
  final bool cleanSqflite = false;

  final String scanAppUrl = "https://google.com?userId=";

  /// 设备类型
  final String deviceType = '1';

  /// 图片最小缩略图
  final int xsMessageMin = 64;

  ///头像压缩大小
  final int headMin = 128;

  final int sMessageMin = 384;

  ///消息图片压缩
  final int messageMin = 384;

  ///动态缩略图大小
  final int dynamicMin = 1024;

  final int maxOriImageMin = 1600;

  List minType = [];

  bool get isDebug =>
      debugInfo.fourceDebug ||
      const bool.fromEnvironment("IS_DEBUG", defaultValue: true);

  String get appName =>
      const String.fromEnvironment("APP_NAME", defaultValue: "");

  String get host => serversUriMgr.apiUrl;

  //游戏盾默认节点组(当阶段朱设置空的时候，一定不过盾)
  String get kiwiHead => "kiwi_";

  //非空则不经过kiwi直连后端
  //String get kiwiBypassHost => const String.fromEnvironment("KIWI_BYPASS_HOST", defaultValue: "http://im-user.jxtest.net:80");
  String get kiwiBypassHost =>
      const String.fromEnvironment("KIWI_BYPASS_HOST", defaultValue: "");

  //取api备用线路的网络地址
  String get kiwiBackupHost => "";

  String get kiwiHost =>
      const String.fromEnvironment("KIWI_API", defaultValue: "");

  // socket
  String get kiwiSocketHost =>
      const String.fromEnvironment("KIWI_SOCKET", defaultValue: "");

  // sentry相关
  String get sentryKey =>
      const String.fromEnvironment("SENTRY_KEY", defaultValue: "");

  String get sentryCdn =>
      "http://$sentryKey@${serversUriMgr.sentryUrl}/$sentryChannel";

  String get sentryChannel =>
      const String.fromEnvironment("SENTRY_CHANNEL", defaultValue: "");

  String get kiwiSentry =>
      const String.fromEnvironment("KIWI_SENTRY", defaultValue: "");

  String get sentryUrl =>
      const String.fromEnvironment("SENTRY_URL", defaultValue: "")
          .split("/")
          .last;

  String get kiwiDownload1Url =>
      const String.fromEnvironment("KIWI_DOWNLOAD_1_URL", defaultValue: "");

  String get aesKey =>
      const String.fromEnvironment("AES_SECRET", defaultValue: "");

  String get kiwiKey =>
      const String.fromEnvironment("KIWI_KEY", defaultValue: "");

  // 上传相关配置
  String get kiwiUpload =>
      const String.fromEnvironment("KIWI_UPLOAD", defaultValue: "");

  // KIWI openInstall
  String get kiwiOp =>
      const String.fromEnvironment("KIWI_OP", defaultValue: "");

  // 下载相关配置
  String get kiwiDownload2 =>
      const String.fromEnvironment("KIWI_DOWNLOAD_2", defaultValue: "");

  String get kiwiDownload1 =>
      const String.fromEnvironment("KIWI_DOWNLOAD_1", defaultValue: "");

  int get kiwiVersion =>
      const int.fromEnvironment("KIWI_VER", defaultValue: 21040101);

  String get xorSecret => "jxim";

  String get agoraAppID =>
      const String.fromEnvironment("AGORA_APP_ID", defaultValue: "");

  bool get enableWallet =>
      const bool.fromEnvironment("ENABLE_WALLET", defaultValue: false);

  bool get enableRedPacket =>
      const bool.fromEnvironment("ENABLE_PACKET", defaultValue: false);

  bool get enableReel =>
      const bool.fromEnvironment("ENABLE_REEL", defaultValue: false);

  bool get enableDeviceLink =>
      const bool.fromEnvironment("ENABLE_DEVICE_LINK", defaultValue: false);

  bool get enablePushCipher =>
      const bool.fromEnvironment("ENABLE_PUSH_CIPHER", defaultValue: false);

  bool get enableVersionUpdate =>
      const bool.fromEnvironment("ENABLE_VERSION_UPDATE", defaultValue: false);

  bool get enablePushKit =>
      const bool.fromEnvironment("ENABLE_PUSHKIT", defaultValue: true);

  bool get enableInAppInstall =>
      const bool.fromEnvironment("ENABLE_APP_INSTALL", defaultValue: true);

  bool get enableExperiment =>
      const bool.fromEnvironment("ENABLE_EXPERIMENT", defaultValue: true);

  bool get showGlobalError =>
      const bool.fromEnvironment("SHOW_ERROR_TOAST", defaultValue: false);

  bool get isTestFlight =>
      const bool.fromEnvironment("IS_TESTFLIGHT", defaultValue: false) &&
      Platform.isIOS;

  String get androidPlatform =>
      const String.fromEnvironment("ANDROID_PLATFORM", defaultValue: "play");

  int get orgChannel =>
      const int.fromEnvironment("ORG_CHANNEL", defaultValue: 1);
  int get video_http_server_port =>
      const int.fromEnvironment("VIDEO_HTTP_SERVER_PORT", defaultValue: 0);

  bool get isGameEnv => false;

  String get officialUrl =>
      const String.fromEnvironment("OFFICIAL_URL", defaultValue: "");

  String get email => const String.fromEnvironment("EMAIL", defaultValue: "");

  String get colorJson =>
      const String.fromEnvironment("COLOR_CODE", defaultValue: "{}");

  String get videoLicenseUrl => const String.fromEnvironment(
        "TENCENT_VIDEO_LICENSE_URL",
        defaultValue: "",
      );

  String get videoLicenseKey => const String.fromEnvironment(
        "TENCENT_VIDEO_LICENSE_KEY",
        defaultValue: "",
      );

  bool get enableSingleDevice =>
      const bool.fromEnvironment("ENABLE_SINGLE_DEVICE", defaultValue: true);
}
