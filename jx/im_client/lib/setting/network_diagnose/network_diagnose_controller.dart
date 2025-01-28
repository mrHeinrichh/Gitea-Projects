import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:path_provider/path_provider.dart';

class NetworkDiagnoseController extends GetxController
    with GetTickerProviderStateMixin {
  /// 0 = 初始状态
  /// 1 = 诊断中
  /// 2 = 诊断完成
  /// 3 = 网络异常
  /// 4 = 网络诊断中止
  final diagnoseStatus = 0.obs;

  final taskStatuses = <NetworkDiagnoseTask>[
    NetworkDiagnoseTask(type: ConnectionTask.connectNetwork),
    NetworkDiagnoseTask(type: ConnectionTask.shieldConnectNetwork),
    NetworkDiagnoseTask(type: ConnectionTask.connectServer),
    NetworkDiagnoseTask(type: ConnectionTask.uploadSpeed),
    NetworkDiagnoseTask(type: ConnectionTask.downloadSpeed),
  ].obs;

  late AnimationController successAnimationController;
  late AnimationController errorAnimationController;
  String? fileURL;

  CancelToken? uploadCancelToken;
  CancelToken? downloadCancelToken;
  CancelToken? connectivityCancelToken;

  Stopwatch taskStopwatch = Stopwatch();
  final isDiagnosing = false.obs;
  final networkWarningTitle = ''.obs;
  final networkWarningSubtitle = ''.obs;
  ConnectionTask? abnormalTask;
  Map<String, String> testResult = {};
  final currentCountry = localized(unknown).obs;
  final currentIP = localized(unknown).obs;
  int restartFlag = 0;

  @override
  void onInit() {
    successAnimationController = AnimationController(
      value: 0.0,
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    errorAnimationController = AnimationController(
      value: 0.0,
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (Get.arguments != null) {
      startDiagnose();
    }
    _fetchUserLocation();
    super.onInit();
  }

  @override
  void onClose() {
    clearResources();
    successAnimationController.dispose();
    errorAnimationController.dispose();
    super.onClose();
  }

  void startDiagnose() async {
    restartFlag++;
    _fetchUserLocation();
    testResult.clear();
    diagnoseStatus.value = 1;
    isDiagnosing.value = true;
    abnormalTask = null;
    await Future.delayed(const Duration(milliseconds: 500));

    // Run tasks sequentially
    final currentFlag = restartFlag;
    for (int i = 0; i < taskStatuses.length; i++) {
      if (!isDiagnosing.value || currentFlag != restartFlag) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      final taskResult = await _runTask(i, currentFlag);
      if (taskResult) {
        taskStatuses[i].status.value = ConnectionTaskStatus.success;
      } else {
        if (isDiagnosing.value) {
          // It's not pause by user
          if (taskStatuses[i].type != ConnectionTask.uploadSpeed &&
              taskStatuses[i].type != ConnectionTask.downloadSpeed) {
            abnormalTask = taskStatuses[i].type;
            taskStatuses[i].status.value = ConnectionTaskStatus.failure;
            diagnoseStatus.value = 3;
            isDiagnosing.value = false;
            _reportLog();
            return;
          }
        } else {
          return;
        }
      }
    }
    _reportLog();
    isDiagnosing.value = false;
    if (abnormalTask != null) {
      diagnoseStatus.value = 3;
    } else {
      diagnoseStatus.value = 2;
    }
    successAnimationController.forward(from: 0);
  }

  void restartDiagnose() {
    // reset value
    diagnoseStatus.value = 0;
    abnormalTask = null;
    for (var task in taskStatuses) {
      task.description = '';
      task.status.value = ConnectionTaskStatus.processing;
    }
    startDiagnose();
  }

  void stopDiagnose() {
    isDiagnosing.value = false;
    diagnoseStatus.value = 4;
    clearResources();
  }

  void clearResources() {
    // Cancel ongoing tasks
    _cancelToken(connectivityCancelToken);
    _cancelToken(uploadCancelToken);
    _cancelToken(downloadCancelToken);

    // Stop the stopwatch
    if (taskStopwatch.isRunning) {
      taskStopwatch.stop();
    }
  }

  void _cancelToken(CancelToken? token) {
    token?.cancel();
    token = null;
  }

  Future<bool> _runTask(int taskIndex, int currentFlag) async {
    if (!isDiagnosing.value) return false; // pause by user

    final task = taskStatuses[taskIndex];
    task.status.value = ConnectionTaskStatus.processing;

    switch (task.type) {
      case ConnectionTask.connectNetwork:
        return await _testConnectivity(task, currentFlag);
      case ConnectionTask.shieldConnectNetwork:
        return await _testShieldConnectNetwork(task, currentFlag);
      case ConnectionTask.connectServer:
        return await _testServerConnection(task, currentFlag);
      case ConnectionTask.uploadSpeed:
        return await _testUploadSpeed(task, currentFlag);
      case ConnectionTask.downloadSpeed:
        return await _testDownloadSpeed(task, currentFlag);
    }
  }

  Future<bool> _testConnectivity(
      NetworkDiagnoseTask task, int currentFlag) async {
    try {
      if (!isDiagnosing.value || currentFlag != restartFlag) return false;
      int duration = await testGetHeadTime(Config().officialUrl);
      task.description =
          localized(diagnoseSuccess1, params: [duration.toString()]);
      testResult['连接互联网'] = '成功，用时：$duration ms';
      return true;
    } catch (e) {
      task.description = localized(networkTaskError1);
      networkWarningTitle.value = localized(networkWarningTitle1);
      networkWarningSubtitle.value = localized(networkWarningSubtitle1);
      testResult['连接互联网'] = 'Catch Error: ${e.toString()}';
      return false;
    }
  }

  Future<bool> _testShieldConnectNetwork(
      NetworkDiagnoseTask task, int currentFlag) async {
    if (!isDiagnosing.value || currentFlag != restartFlag) return false;
    if (serversUriMgr.speed1Uri == null) {
      task.description = localized(networkTaskError2);
      networkWarningTitle.value = localized(networkWarningTitle2);
      networkWarningSubtitle.value = localized(networkWarningSubtitle2);
      testResult['连接互联网(加速)'] = 'speed1Uri为空';
      return false;
    }

    String uri = serversUriMgr.speed1Uri!.toString();
    try {
      int duration = await testGetHeadTime(uri);
      task.description =
          localized(diagnoseSuccess2, params: [duration.toString()]);
      testResult['连接互联网(加速)'] = '成功，用时：$duration ms';
      return true;
    } catch (e) {
      task.description = localized(networkTaskError2);
      networkWarningTitle.value = localized(networkWarningTitle2);
      networkWarningSubtitle.value = localized(networkWarningSubtitle2);
      testResult['连接互联网(加速)'] = "Catch Error: ${e.toString()}";
      return false;
    }
  }

  Future<bool> _testServerConnection(
      NetworkDiagnoseTask task, int currentFlag) async {
    if (!isDiagnosing.value || currentFlag != restartFlag) return false;

    final startTime = DateTime.now();
    try {
      final curTime = DateTime.now().millisecondsSinceEpoch;
      await heartbeat(curTime); // Trigger heartbeat
      if (isDiagnosing.value) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds / 2;
        task.description =
            localized(diagnoseSuccess3, params: [duration.toString()]);
        testResult['服务器'] = '成功，用时：$duration ms';
        return true;
      } else {
        return false;
      }
    } catch (e) {
      task.description = localized(networkTaskError3);
      networkWarningTitle.value = localized(networkWarningTitle3);
      networkWarningSubtitle.value = localized(networkWarningSubtitle3);
      testResult['服务器'] = "Catch error ${e.toString()}";
      return false;
    }
  }

  Future<bool> _testUploadSpeed(
      NetworkDiagnoseTask task, int currentFlag) async {
    if (!isDiagnosing.value || currentFlag != restartFlag) return false;

    fileURL = null;
    File tempFile = await _generateRandomFile();
    _startStopwatch();
    Timer? timeoutTimer;
    try {
      uploadCancelToken = CancelToken();
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        uploadCancelToken?.cancel();
        testResult['上传速度'] = '任务失败，60秒超时';
      });
      fileURL = await imageMgr.testUpload(uploadCancelToken!, tempFile);
      if (isDiagnosing.value) {
        if (fileURL != null) {
          task.description = _formatDuration(taskStopwatch.elapsedMilliseconds);
          return true;
        } else {
          task.description = localized(networkTaskError4);
          task.status.value = ConnectionTaskStatus.failure;
          networkWarningTitle.value = localized(networkWarningTitle4);
          networkWarningSubtitle.value = localized(networkWarningSubtitle4);
          abnormalTask = task.type;
          testResult['上传速度'] = '无法获取文件下载地址';
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      task.description = localized(networkTaskError5);
      task.status.value = ConnectionTaskStatus.failure;
      networkWarningTitle.value = localized(networkWarningTitle5);
      networkWarningSubtitle.value = localized(networkWarningSubtitle5);
      abnormalTask = task.type;
      testResult['上传速度'] = e.toString();
      return false;
    } finally {
      timeoutTimer?.cancel();
      taskStopwatch.stop();
      uploadCancelToken = null;
      tempFile.delete();
    }
  }

  Future<bool> _testDownloadSpeed(
      NetworkDiagnoseTask task, int currentFlag) async {
    if (!isDiagnosing.value || currentFlag != restartFlag) return false;

    fileURL ??= 'Document/speed/test.speed';
    _startStopwatch();
    downloadCancelToken = CancelToken();

    try {
      DownloadResult result = await downloadMgrV2.download(fileURL!,
          cancelToken: downloadCancelToken,
          timeout: const Duration(seconds: 60),
          grab: true,
          allowRangeDownload: false);
      String? path = result.localPath;
      if (isDiagnosing.value) {
        if (path == null) {
          task.description = localized(networkTaskError6);
          task.status.value = ConnectionTaskStatus.failure;
          networkWarningTitle.value = localized(networkWarningTitle6);
          networkWarningSubtitle.value = localized(networkWarningSubtitle6);
          abnormalTask = task.type;
          testResult['下载速度'] = result.reason ?? '超时';
          return false;
        } else {
          task.description = _formatDuration(taskStopwatch.elapsedMilliseconds,
              isUpload: false);
          File(path).delete();
          return true;
        }
      } else {
        return false;
      }
    } catch (e) {
      task.status.value = ConnectionTaskStatus.failure;
      task.description = localized(networkTaskError7);
      networkWarningTitle.value = localized(networkWarningTitle7);
      networkWarningSubtitle.value = localized(networkWarningSubtitle7);
      testResult['下载速度'] = "Catch error ${e.toString()}";
      abnormalTask = task.type;
      return false;
    } finally {
      taskStopwatch.stop();
      downloadCancelToken = null;
    }
  }

  void _startStopwatch() {
    if (taskStopwatch.isRunning) {
      taskStopwatch.stop();
    }

    taskStopwatch.reset();
    taskStopwatch.start();
  }

  Future<File> _generateRandomFile() async {
    final tempDir = await getTemporaryDirectory();
    final file =
        File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.speed');

    // Generate random content of 5 MB
    final random = Random();
    final content = List.generate(5 * 1024 * 1024, (_) => random.nextInt(256));
    await file.writeAsBytes(content);
    return file;
  }

  String _formatDuration(int milliseconds, {bool isUpload = true}) {
    const sizeInMegabits = (5242880 * 8) / 1000000;
    final timeInSeconds = milliseconds / 1000;
    final speedMbps = (sizeInMegabits / timeInSeconds);

    if (isUpload) {
      testResult['上传速度'] = "${speedMbps.toStringAsFixed(2)}Mbps";
      if (speedMbps >= 20) {
        return localized(diagnoseUploadSpeed1,
            params: [speedMbps.round().toString()]);
      } else if (speedMbps >= 5) {
        return localized(diagnoseUploadSpeed2,
            params: [speedMbps.round().toString()]);
      } else if (speedMbps >= 1) {
        return localized(diagnoseUploadSpeed3,
            params: [speedMbps.round().toString()]);
      } else {
        return localized(diagnoseUploadSpeed4,
            params: [speedMbps.toStringAsFixed(2)]);
      }
    } else {
      testResult['下载速度'] = "${speedMbps.toStringAsFixed(2)}Mbps";
      if (speedMbps >= 50) {
        return localized(diagnoseDownloadSpeed1,
            params: [speedMbps.round().toString()]);
      } else if (speedMbps >= 10) {
        return localized(diagnoseDownloadSpeed2,
            params: [speedMbps.round().toString()]);
      } else if (speedMbps >= 2) {
        return localized(diagnoseDownloadSpeed3,
            params: [speedMbps.round().toString()]);
      } else {
        return localized(diagnoseDownloadSpeed4,
            params: [speedMbps.toStringAsFixed(2)]);
      }
    }
  }

  Future<void> _reportLog() async {
    testResult['网络连接模式'] = connectivityMgr.preConnectType.toString();
    testResult['用户所在地'] = currentCountry.value;
    testResult['IP地址'] = currentIP.value;
    String formattedLog =
        testResult.entries.map((e) => "${e.key}: ${e.value}").join('\n');
    objectMgr.logMgr.logNetworkMgr.addMetrics(
      LogNetworkDiagnoseMsg(msg: formattedLog),
    );
  }

  Future<void> _fetchUserLocation() async {
    final result = await getUserIP();
    currentCountry.value = result['country'] ?? localized(unknown);
    currentIP.value = result['ip'] ?? localized(unknown);
    if (result.containsKey("error")) {
      testResult["IP info 报错"] = result["error"]!;
    }
  }
}

Future<Map<String, String>> getUserIP() async {
  const ipInfoUrl = "https://ipinfo.io";
  Map<String, String> result = {};
  try {
    final response = await Dio().get('$ipInfoUrl?token=${Config().ipInfoToken}',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ));
    if (response.statusCode == 200) {
      final data = response.data;
      result["country"] = data['region'] ?? localized(unknown);
      result["ip"] = data['ip'] ?? localized(unknown);
    } else {
      result["country"] = localized(unknown);
      result["ip"] = localized(unknown);
      result["error"] = "${response.statusCode}: ${response.statusMessage}";
    }
  } catch (e) {
    result["country"] = localized(unknown);
    result["ip"] = localized(unknown);
    result["error"] = "Catch Error: $e";
  }

  return result;
}

Future<int> testGetHeadTime(String url) async {
  Socket? socket;
  int port = 80;
  try {
    final uri = Uri.parse(url);
    if (uri.hasPort) {
      port = uri.port;
    }
    String domain = uri.host;
    socket =
        await Socket.connect(domain, port, timeout: const Duration(seconds: 5));

    String request = 'HEAD / HTTP/1.1\r\n'
        'Host: ${Uri.parse(Config().officialUrl).host}\r\n'
        'Accept: */*\r\n'
        'Connection: close\r\n\r\n';

    final startTime = DateTime.now();
    socket.write(request);
    StringBuffer responseBuffer = StringBuffer();
    await socket
        .listen((List<int> data) {
          responseBuffer.write(utf8.decode(data));
        })
        .asFuture()
        .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('Timeout while reading data from the socket');
        });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;

    return duration;
  } finally {
    socket?.destroy();
  }
}

class NetworkDiagnoseTask {
  String description;
  Rx<ConnectionTaskStatus> status;
  ConnectionTask type;

  NetworkDiagnoseTask({
    required this.type,
    this.description = '',
    ConnectionTaskStatus status = ConnectionTaskStatus.processing,
  }) : status = status.obs;

  // ConnectionTask 的名字
  String get name => type.name;
}
