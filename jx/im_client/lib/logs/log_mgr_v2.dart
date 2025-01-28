part of 'log_libs.dart';

enum LogModule { log, download, upload, message, api }

abstract class LogUtil {
  IOSink? _sink;
  File? _log_file;
  final Lock _logFileLock = Lock();
  bool _uploading = false;

  int get appLifeCycleState => switch (objectMgr.appLifecycleState) {
        AppLifecycleState.resumed => 1,
        AppLifecycleState.inactive => 2,
        AppLifecycleState.paused => 3,
        AppLifecycleState.detached => 4,
        AppLifecycleState.hidden => 5,
        _ => 0,
      };

  final LogModule _module;

  LogUtil.module(this._module) {
    _init();
  }

  void _init() async {
    await _createLogFile();
  }

  _createLogFile() async {
    String logFilePath =
        "${downloadMgr.appCacheRootPath}/log/${_module.toString()}.log";
    _log_file = await DownloadCommon().createFile(logFilePath);
    _sink = _log_file!.openWrite(mode: FileMode.append);
  }

  void debug(String message) {
    debugPrint("[${_formattedTime()}] [DEBUG] [${_module.name}] $message");
  }

  void info(String message) {
    debugPrint("[${_formattedTime()}] [INFO] [${_module.name}] $message");
  }

  void error(String message) {
    debugPrint("[${_formattedTime()}] [ERR] [${_module.name}] $message");
  }

  /// 添加日志使用这个入口
  Future<void> _addLog<T>(T message) async {
    final Map<String, dynamic> logMsg = processLog(message);

    if (_log_file != null && !(await _log_file!.exists())) {
      await _sink?.flush();
      await _sink?.close();
      await _createLogFile();
    }

    await _logFileLock.synchronized(() {
      try {
        _sink!.write('${jsonEncode(logMsg)}\n');
      } catch (e) {
        // ignore
      }
    });
  }

  /// 子类实现这个方法，返回需要记录的日志
  Map<String, dynamic> processLog<T>(T message);

  String _formattedTime() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.sss').format(DateTime.now());
  }

  Future<void> _report() async {
    if (_log_file != null && !(await _log_file!.exists())) {
      await _createLogFile();
    }

    if (await _log_file!.length() == 0 || _uploading) {
      return;
    }

    _uploading = true;
    String uploadLogFilePath =
        "${downloadMgr.appCacheRootPath}/log/${_module.toString()}.log.upload";
    await _logFileLock.synchronized(() async {
      await _sink!.flush();
      await _sink!.close();
      await _log_file!.rename(uploadLogFilePath);
      await _createLogFile();
    });

    File uploadFile = File(uploadLogFilePath);
    try {
      Stream lines = uploadFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      List<Map<String, dynamic>> curLines = [];
      await for (String line in lines) {
        Map<String, dynamic> map = jsonDecode(line);
        map["type"] = _module.name;
        curLines.add(map);
        if (curLines.length > 100) {
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
  }

  Future<void> _uploadLog(List<Map> metrics) async {
    Map<String, dynamic> map = {};
    map["log"] = metrics;
    map["app_version"] = await PlatformUtils.getAppVersion();

    try {
      final retryParameter = RetryParameter(
        expireTime: 86400,
        isReplaced: RetryReplace.NO_REPLACE,
        callbackFunctionName: RetryEndPointCallback.MESSAGE_LOG_UPLOAD_CALLBACK,
        apiPath: "/app/api/account/record-device-latency-log",
        methodType: CustomRequest.methodTypePost,
        data: map,
      );

      requestQueue.addRetry(retryParameter);

      // final res = await CustomRequest.doPost(
      //   "/app/api/account/record-device-latency-log",
      //   data: map,
      //   maxTry: 3,
      //   duration: const Duration(seconds: 5),
      // );
      // if (res.success()) {
      //   info("Upload download log success, lines: ${metrics.length}");
      // } else {
      //   info("Upload download log fail, lines: ${metrics.length}");
      // }
    } catch (e) {
      info("Upload download log fail, lines: ${metrics.length}, $e");
    }
  }
}
