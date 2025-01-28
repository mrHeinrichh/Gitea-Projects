import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/transfer/complete_download_task_log.dart';
import 'package:jxim_client/transfer/donwload_injected.dart';
import 'package:jxim_client/transfer/download_common.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class LogUtil {
  static const DOWNLOAD_LOG_TYPE = "DOWNLOAD_LOG_V2";
  static late IOSink _sink;
  static late File _log_file;
  static final Lock _logFileLock = Lock();
  static final _log = LogUtil.module(LogModule.log);
  static bool _uploading = false;

  final LogModule _module;

  LogUtil.module(this._module);

  static init() async {
    await _createLogFile();
    await _initUploadTask();
  }

  static onClearCache() async {
    await _createLogFile();
  }

  void debug(String message) {}

  void info(String message) {
    debugPrint("[${_formattedTime()}] [INFO] [${_module.name}] $message");
    // _logger.i("[${formattedTime()}] [${_module.name}] $message");
  }

  void error(String message) {
    debugPrint("[${_formattedTime()}] [ERR] [${_module.name}] $message");
    // _logger.e("[${formattedTime()}] [${_module.name}] $message");
  }

  Future<void> report<T>(T message) async {
    dynamic logObj;
    if (message is String) {
      info(message);
      logObj = {"message": message};
    } else if (message is CompleteDownloadTaskLog) {
      info("$message");
      if (!DownloadConfig().DOWNLOAD_COMPLETE_LOG_ENABLE) {
        return;
      }
      CompleteDownloadTaskLog log = message;
      if (log.latency <
              DownloadConfig().DOWNLOAD_COMPLETE_LOG_UPLOAD_MAX_LATENCY &&
          log.reason == null) {
        return;
      }
      logObj = message.toJson();
    } else {
      return;
    }

    await _logFileLock.synchronized(() {
      try {
        _sink.write('${jsonEncode(logObj)}\n');
      } catch (e) {
        // ignore
      }
    });
  }

  static _createLogFile() async {
    String logFilePath =
        "${(await getApplicationCacheDirectory()).path}/${DownloadConfig().DOWNLOAD_DIR_NAME}/app.log";
    _log_file = await DownloadCommon().createFile(logFilePath);
    _sink = _log_file.openWrite(mode: FileMode.append);
  }

  static _initUploadTask() {
    Timer.periodic(
        Duration(milliseconds: DownloadConfig().DOWNLOAD_LOG_UPLOAD_PERIOD),
        (timer) async {
      if (!await _log_file.exists()) {
        await _createLogFile();
      }

      if (await _log_file.length() == 0 ||
          _uploading ||
          !DownloadInjected().socketMgr.isConnect) {
        return;
      }

      _uploading = true;
      String uploadLogFilePath =
          "${(await getApplicationCacheDirectory()).path}/${DownloadConfig().DOWNLOAD_DIR_NAME}/app.log.upload";
      await _logFileLock.synchronized(() async {
        await _sink.flush();
        await _sink.close();
        await _log_file.rename(uploadLogFilePath);
        await _createLogFile();
      });

      File uploadFile = File(uploadLogFilePath);
      try {
        Stream lines = uploadFile
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        List<Map> curLines = [];
        await for (String line in lines) {
          Map map = jsonDecode(line);
          map["type"] = DOWNLOAD_LOG_TYPE;
          curLines.add(map);
          if (curLines.length >
              DownloadConfig().DOWNLOAD_LOG_BATCH_UPLOAD_SIZE) {
            await _uploadLog(curLines);
            curLines.clear();
          }
        }
        if (curLines.isNotEmpty) {
          await _uploadLog(curLines);
        }
      } catch (e, s) {
        pdebug('jsonDecode error', error: e, stackTrace: s);
      } finally {
        await uploadFile.delete();
        _uploading = false;
      }
    });
  }

  String _formattedTime() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.sss').format(DateTime.now());
  }

  static _uploadLog(List<Map> metrics) async {
    Map<String, dynamic> map = {};
    map["log"] = metrics;
    map["app_version"] = await PlatformUtils.getAppVersion();

    try {
      ResponseData res = await CustomRequest.doPost(
          "/app/api/account/record-device-latency-log",
          data: map,
          maxTry: 3,
          duration: const Duration(seconds: 5));
      if (res.success()) {
        _log.info("Upload download log success, lines: ${metrics.length}");
      } else {
        _log.info("Upload download log fail, lines: ${metrics.length}");
      }
    } catch (e) {
      _log.info("Upload download log fail, lines: ${metrics.length}, $e");
    }
  }
}

enum LogModule { download, log }

class LogcatOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      developer.log(line);
    }
  }
}
