import 'dart:convert';

import 'package:jxim_client/transfer/donwload_injected.dart';

class DownloadConfig {
  static const CONFIG_NAME = "DOWNLOAD_CONFIG";

  static final DownloadConfig _instance = DownloadConfig._internal();

  DownloadConfig._internal();

  Map<String, dynamic> _configMap = {};

  factory DownloadConfig() {
    return _instance;
  }

  int get MAX_SMALL_FILE_LEN => _config("max.small.file.len", 100 * 1024);
  int get GRAB_TASK_WAIT_RUN_TIMEOUT_MS => _config("grab.task.wait.run.timeout.ms", 500);
  int get DOWNLOAD_TASK_MAX_RETRIES => _config("download.task.max.retries", -1);
  int get DOWNLOAD_TASK_MULTI_RETRIES => _config("download.task.multi.retries", 5);
  int get WEAK_NET_SPEED_THRESHOLD_BYTES => _config("weak.net.speed.threshold.bytes", 100 * 1024);
  int get WEAK_NET_LATENCY_THRESHOLD_MS => _config("weak.net.latency.threshold.ms", 1000);
  int get WEAK_NET_LOW_SPEED_COUNT_THRESHOLD => _config("weak.net.low.speed.count.threshold", 3);

  int get SMALL_EXCLUSIVE_CHANNEL_COUNT => _config("small.exclusive.channel.count", 10);
  int get SMALL_EXCLUSIVE_CELLULAR_CHANNEL_COUNT => _config("small.exclusive.cellular.channel.count", 2);
  int get SHARED_CHANNEL_COUNT => _config("shared.channel.count", 2);
  int get SHARED_CELLULAR_CHANNEL_COUNT => _config("shared.cellular.channel.count", 1);
  int get LARGE_EXCLUSIVE_CHANNEL_COUNT => _config("large.exclusive.channel.count", 2);
  int get LARGE_EXCLUSIVE_CELLULAR_CHANNEL_COUNT => _config("large.exclusive.cellular.channel.count", 1);
  int get BACKGROUND_CHANNEL_COUNT => _config("background.channel.count", 5);
  int get BACKGROUND_CELLULAR_CHANNEL_COUNT => _config("background.cellular.channel.count", 2);
  int get RETRY_CHANNEL_COUNT => _config("retry.channel.count", 2);
  int get RETRY_CELLULAR_CHANNEL_COUNT => _config("retry.cellular.channel.count", 1);

  String get ENCRYPT_FILE_PATH_KEYWORD => _config("encrypt.file.path.keyword", "secret");
  bool get LARGE_FILE_RANGE_DOWNLOAD_ENABLE => _config("large.file.range.download.enable", true);
  bool get BACKGROUND_FILE_RANGE_DOWNLOAD_ENABLE => _config("background.file.range.download.enable", false);

  List get DOWNLOAD_RETRY_TIME_DELAYS => _config("download.retry.time.delays", [0, 500, 1000, 2000, 3000]);
  String get DOWNLOAD_DIR_NAME => _config("download.dir.name", "download");
  String get DOWNLOAD_LOG_DIR_NAME => _config("download.log.dir.name", "download_log");
  int get DOWNLOAD_LOG_UPLOAD_PERIOD => _config("download.log.upload.period", 2000);
  int get DOWNLOAD_LOG_BATCH_UPLOAD_SIZE => _config("download.log.batch.upload.size", 10);
  int get DOWNLOAD_COMPLETE_LOG_UPLOAD_MAX_LATENCY => _config("download.complete.log.upload.max.latency", 1000);
  bool get DOWNLOAD_COMPLETE_LOG_ENABLE => _config("download.complete.log.enable", true);
  int get DIO_SEND_TIMEOUT_MS => _config("dio.send.timeout.ms", 10000);
  int get DIO_RECEIVE_TIMEOUT_MS => _config("dio.receive.timeout.ms", 20000);
  int get SMALL_FILE_DIO_SEND_TIMEOUT_MS => _config("small.file.dio.send.timeout.ms", 2000);
  int get SMALL_FILE_DIO_RECEIVE_TIMEOUT_MS => _config("small.file.dio.receive.timeout.ms", 3000);
  int get LARGE_FILE_DIO_SEND_TIMEOUT_MS => _config("large.file.dio.send.timeout.ms", 2000);
  int get LARGE_FILE_DIO_RECEIVE_TIMEOUT_MS => _config("large.file.dio.receive.timeout.ms", 60000);
  int get BACKGROUND_FILE_DIO_SEND_TIMEOUT_MS => _config("background.file.dio.send.timeout.ms", 2000);
  int get BACKGROUND_FILE_DIO_RECEIVE_TIMEOUT_MS => _config("background.file.dio.receive.timeout.ms", 5000);
  int get RETRY_FILE_DIO_SEND_TIMEOUT_MS => _config("retry.file.dio.send.timeout.ms", 10000);
  int get RETRY_FILE_DIO_RECEIVE_TIMEOUT_MS => _config("background.file.dio.receive.timeout.ms", 60000);
  int get DOWNLOAD_TRY_COST_MAX_COUNT => _config("download.try.cost.max.count", 20);
  int get DOWNLOAD_QUEUE_MAX_LEN => _config("download.queue.max.len", 1000);
  int get RANGE_DOWNLOAD_LEN => _config("range.download.len", 5 * 1024 * 1024);


  void reloadConfig(String? configStr) {
    configStr ??= "{}";
    DownloadInjected().localStorageMgr.globalWrite(CONFIG_NAME, configStr);
    _configMap = jsonDecode(configStr);
  }

  void initConfig() {
    final config = DownloadInjected().localStorageMgr.globalRead(CONFIG_NAME);
    _configMap = jsonDecode(config ?? "{}");
  }

  void onClearCache() {
    String configStr = jsonEncode(_configMap);
    DownloadInjected().localStorageMgr.globalWrite(CONFIG_NAME, configStr);
  }

  T _config<T>(String configName, T defaultValue) {
    T? value = _configMap[configName];
    return value ?? defaultValue;
  }
}