import 'dart:math';

import 'package:jxim_client/api/report.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/app_version_utils.dart';

class DataAnalyticsTask extends ScheduleTask {
  DataAnalyticsTask() : super(const Duration(minutes: 5));

  @override
  Future<void> execute() async {
    // 5分钟调用一次上报信息

    if (SumUploadAnalytics.sharedInstance.hasStatData ||
        SumDownloadAnalytics.sharedInstance.hasStatData) {
      reportFileStat(getFileStatParam());
    }

    if (SumApiAnalytics.sharedInstance._data.isNotEmpty) {
      reportApiStat(getApiStatParam());
    }

    SumUploadAnalytics.sharedInstance.reset();
    SumDownloadAnalytics.sharedInstance.reset();
    SumApiAnalytics.sharedInstance.resetAnalyticsInfo();
  }

  /// 汇总所有上传下载信息 [新接口]
  Map<String, dynamic> getFileStatParam() {
    final List<Map<String, dynamic>> statParam = <Map<String, dynamic>>[];
    SumUploadAnalytics.sharedInstance._sumAnalytics.forEach((k, v) {
      if (v.hasTaskCount) {
        final Map<String, dynamic> uParam = v._getUploadParam();
        uParam['size'] = k;
        statParam.add(uParam);
      }
    });

    SumDownloadAnalytics.sharedInstance._sumAnalytics.forEach((k, v) {
      if (v.hasTaskCount) {
        final Map<String, dynamic> uParam = v._getDownloadParam();
        uParam['size'] = k;
        statParam.add(uParam);
      }
    });

    return <String, dynamic>{
      'app_version': appVersionUtils.currentAppVersion,
      'platform': appVersionUtils.getDownloadPlatform(),
      'stats': statParam,
    };
  }

  /// 汇总所有上传下载信息 [新接口]
  Map<String, dynamic> getApiStatParam() {
    final List<Map<String, dynamic>> statParam = <Map<String, dynamic>>[];
    SumApiAnalytics.sharedInstance._data.forEach((k, v) {
      final Map<String, dynamic> uParam = v._getApiParam();
      uParam['path'] = k;
      statParam.add(uParam);
    });

    return <String, dynamic>{
      'app_version': appVersionUtils.currentAppVersion,
      'platform': appVersionUtils.getDownloadPlatform(),
      'stats': statParam,
    };
  }
}

abstract class _BaseFileAnalytics<T extends _BaseStat> {
  static const String smallFile = 'small';
  static const String mediumFile = 'medium';
  static const String largeFile = 'big';
  static const String xLargeFile = 'huge';

  late final Map<String, T> _sumAnalytics;

  _BaseFileAnalytics(T Function() factory) {
    _sumAnalytics = <String, T>{
      smallFile: factory(),
      mediumFile: factory(),
      largeFile: factory(),
      xLargeFile: factory(),
    };
  }

  bool get hasStatData {
    return _sumAnalytics.values.any((T e) => e.hasTaskCount);
  }

  void reset() {
    _sumAnalytics.clear();
  }
}

class AnalyticsHelper {
  static String getFileType(int? bytes) {
    if (bytes == null) return _BaseFileAnalytics.xLargeFile;

    switch (bytes) {
      case < 1000000:
        return _BaseFileAnalytics.smallFile;
      case < 5000000:
        return _BaseFileAnalytics.mediumFile;
      case < 20000000:
        return _BaseFileAnalytics.largeFile;
      default:
        return _BaseFileAnalytics.xLargeFile;
    }
  }
}

class SumUploadAnalytics extends _BaseFileAnalytics<UploadAnalytics> {
  factory SumUploadAnalytics() => _getInstance();

  static SumUploadAnalytics get sharedInstance => _getInstance();

  static SumUploadAnalytics? _instance;

  // Private constructor
  SumUploadAnalytics._internal() : super(() => UploadAnalytics());

  static SumUploadAnalytics _getInstance() {
    _instance ??= SumUploadAnalytics._internal();
    return _instance!;
  }

  void updateUploadStatistic(
    String analyticsKey, {
    bool? taskCount,
    bool? successCount,
    bool? failedCount,
    String? uploadSuccessKey,
    String? uploadFailedKey,
    int? uploadDuration,
    int? uploadBytes,
    int? apiPresignDuration,
    int? apiUploadingDuration,
    int? apiFinishDuration,
  }) {
    assert(
      analyticsKey == _BaseFileAnalytics.smallFile ||
          analyticsKey == _BaseFileAnalytics.mediumFile ||
          analyticsKey == _BaseFileAnalytics.largeFile ||
          analyticsKey == _BaseFileAnalytics.xLargeFile,
      "Key must be one of the file type. Either smallFile, mediumFile, largeFile or xLargeFile. Please look at the constant key in the class.",
    );

    UploadAnalytics? cache = _sumAnalytics[analyticsKey];
    if (cache == null) {
      cache ??= UploadAnalytics();
      _sumAnalytics[analyticsKey] = cache;
    }

    cache._updateUploadInfo(
      taskCount: taskCount,
      successCount: successCount,
      failedCount: failedCount,
      uploadSuccessKey: uploadSuccessKey,
      uploadFailedKey: uploadFailedKey,
      uploadDuration: uploadDuration,
      uploadBytes: uploadBytes,
      apiPresignDuration: apiPresignDuration,
      apiUploadingDuration: apiUploadingDuration,
      apiFinishDuration: apiFinishDuration,
    );
  }
}

class SumDownloadAnalytics extends _BaseFileAnalytics<DownloadAnalytics> {
  static const String smallFile = 'small';
  static const String mediumFile = 'medium';
  static const String largeFile = 'big';
  static const String xLargeFile = 'huge';

  factory SumDownloadAnalytics() => _getInstance();

  static SumDownloadAnalytics get sharedInstance => _getInstance();

  static SumDownloadAnalytics? _instance;

  SumDownloadAnalytics._internal() : super(() => DownloadAnalytics());

  static SumDownloadAnalytics _getInstance() {
    _instance ??= SumDownloadAnalytics._internal();
    return _instance!;
  }

  void updateDownloadStatistic(
    String analyticsKey, {
    bool? taskCount,
    bool? downloadSuccessKey,
    bool? downloadFailedKey,
    int? downloadDuration,
    int? downloadBytes,
  }) {
    assert(
      analyticsKey == _BaseFileAnalytics.smallFile ||
          analyticsKey == _BaseFileAnalytics.mediumFile ||
          analyticsKey == _BaseFileAnalytics.largeFile ||
          analyticsKey == _BaseFileAnalytics.xLargeFile,
      "Key must be one of the file type. Either smallFile, mediumFile, largeFile or xLargeFile. Please look at the constant key in the class.",
    );

    DownloadAnalytics? cache = _sumAnalytics[analyticsKey];
    if (cache == null) {
      cache ??= DownloadAnalytics();
      _sumAnalytics[analyticsKey] = cache;
    }

    cache._updateDownloadInfo(
      taskCount: taskCount,
      downloadSuccessKey: downloadSuccessKey,
      downloadFailedKey: downloadFailedKey,
      downloadDuration: downloadDuration,
      downloadBytes: downloadBytes,
    );
  }
}

abstract class _BaseStat {
  /// 总任务数量
  int _taskCount = 0;

  bool get hasTaskCount => _taskCount > 0;

  /// 上传成功数量
  int _success = 0;

  /// 上传失败数量
  int _failed = 0;

  /// 上传总用时 (毫秒)
  ///
  /// 平均值获取 公式: _totalDuration / _taskCount;
  int _totalDuration = 0;

  /// 上传总数据传输 (字节 Bytes)
  ///
  /// 平均值获取 公式 : _totalBytes / (_uploadSuccessCount[uploading] + _uploadFailedCount[uploading])
  int _totalBytes = 0;

  int get latencyAvg => _totalDuration ~/ max(_taskCount, 1);
}

class UploadAnalytics extends _BaseStat {
  static const String uploadPresign = 'UPLOAD_PRESIGN';
  static const String uploading = 'UPLOADING';
  static const String uploadFinish = 'UPLOAD_Finish';

  static const String _key = 'upload';

  /// 上传成功数量
  final Map<String, int> _uploadSuccessCount = <String, int>{};

  /// 上传失败数量
  final Map<String, int> _uploadFailedCount = <String, int>{};

  /// 上传 请求预签地址 用时
  ///
  /// 平均值获取 公式 : _apiPresignDuration / (_uploadSuccessCount[uploadPresign] + _uploadFailedCount[uploadPresign])
  int _apiPresignDuration = 0;

  /// 上传 文件 用时
  ///
  /// 平均值获取 公式 : _apiUploadingDuration / (_uploadSuccessCount[uploading] + _uploadFailedCount[uploading])
  int _apiUploadingDuration = 0;

  /// 上传 请求Finish地址 用时
  ///
  /// 平均值获取 公式 : _apiFinishDuration / (_uploadSuccessCount[uploadFinish] + _uploadFailedCount[uploadFinish])
  int _apiFinishDuration = 0;

  void _updateUploadInfo({
    bool? taskCount,
    bool? successCount,
    bool? failedCount,
    String? uploadSuccessKey,
    String? uploadFailedKey,
    int? uploadDuration,
    int? uploadBytes,
    int? apiPresignDuration,
    int? apiUploadingDuration,
    int? apiFinishDuration,
  }) {
    if (taskCount ?? false) _taskCount += 1;
    if (successCount ?? false) _success += 1;
    if (failedCount ?? false) _failed += 1;

    if (uploadSuccessKey != null) {
      _uploadSuccessCount[uploadSuccessKey] =
          (_uploadSuccessCount[uploadSuccessKey] ?? 0) + 1;
    }

    if (uploadFailedKey != null) {
      _uploadFailedCount[uploadFailedKey] =
          (_uploadFailedCount[uploadFailedKey] ?? 0) + 1;
    }

    if (uploadDuration != null) _totalDuration += uploadDuration;

    if (uploadBytes != null) _totalBytes += uploadBytes;

    if (apiPresignDuration != null) _apiPresignDuration += apiPresignDuration;

    if (apiUploadingDuration != null) {
      _apiUploadingDuration += apiUploadingDuration;
    }

    if (apiFinishDuration != null) _apiFinishDuration += apiFinishDuration;
  }

  // void _resetUploadInfo() {
  //   _uploadSuccessCount.clear();
  //   _uploadFailedCount.clear();
  //   _taskCount = 0;
  //   _success = 0;
  //   _failed = 0;
  //   _apiPresignDuration = 0;
  //   _apiUploadingDuration = 0;
  //   _apiFinishDuration = 0;
  //   _totalDuration = 0;
  //   _totalBytes = 0;
  // }

  /// 时间取秒为单位
  double get speedAvg => _totalBytes / (max(_apiUploadingDuration ~/ 1000, 1));

  int get apiLatencyAvg =>
      (_apiPresignDuration + _apiFinishDuration) ~/
      max(
          ((_uploadSuccessCount[uploadPresign] ?? 0) +
              (_uploadFailedCount[uploadPresign] ?? 0) +
              (_uploadSuccessCount[uploadFinish] ?? 0) +
              (_uploadFailedCount[uploadFinish] ?? 0)),
          1);

  Map<String, dynamic> _getUploadParam() {
    return {
      'type': _key,
      'count': _taskCount,
      'success': _success,
      'failed': _failed,
      'latency_avg': latencyAvg,
      'speed_avg': speedAvg,
      'api_latency_avg': apiLatencyAvg,
      'presign_success': _uploadSuccessCount[uploadPresign],
      'part_success': _uploadSuccessCount[uploading],
      'finish_success': _uploadSuccessCount[uploadFinish],
      'presign_failed': _uploadFailedCount[uploadPresign],
      'part_failed': _uploadFailedCount[uploading],
      'finish_failed': _uploadFailedCount[uploadFinish],
    };
  }

  @override
  String toString() {
    return '''
\n      Total Request Count: $_taskCount
      Total Success Count: $_success
      Total Failed Count: $_failed
      
      Upload Success Count:
      $uploadPresign : ${_uploadSuccessCount[uploadPresign]}
      $uploading : ${_uploadSuccessCount[uploading]}
      $uploadFinish : ${_uploadSuccessCount[uploadFinish]}
      
      Upload Failed Count: 
      $uploadPresign : ${_uploadFailedCount[uploadPresign]}
      $uploading : ${_uploadFailedCount[uploading]}
      $uploadFinish : ${_uploadFailedCount[uploadFinish]}
      
      API latency Average: $apiLatencyAvg
      
      Total Upload Duration: $_totalDuration millisecond(s)
      
      Total Upload Bytes: $_totalBytes byte(s)
    ''';
  }
}

class DownloadAnalytics extends _BaseStat {
  // factory DownloadAnalytics() => _getInstance();
  //
  // static DownloadAnalytics get sharedInstance => _getInstance();
  //
  // static DownloadAnalytics? _instance;
  //
  // DownloadAnalytics._internal();
  //
  // static DownloadAnalytics _getInstance() {
  //   _instance ??= DownloadAnalytics._internal();
  //   return _instance!;
  // }

  static const String _key = 'download';

  void _updateDownloadInfo({
    bool? taskCount,
    bool? downloadSuccessKey,
    bool? downloadFailedKey,
    int? downloadDuration,
    int? downloadBytes,
  }) {
    if (taskCount ?? false) _taskCount += 1;

    if (downloadSuccessKey ?? false) _success = _success + 1;

    if (downloadFailedKey ?? false) _failed = _failed + 1;

    if (downloadDuration != null) _totalDuration += downloadDuration;

    if (downloadBytes != null) _totalBytes += downloadBytes;
  }

  // void _resetDownloadInfo() {
  //   _taskCount = 0;
  //   _success = 0;
  //   _failed = 0;
  //   _totalDuration = 0;
  //   _totalBytes = 0;
  // }

  /// 时间取秒为单位
  double get speedAvg => _totalBytes / (max(_totalDuration ~/ 1000, 1));

  Map<String, dynamic> _getDownloadParam() {
    return {
      'type': _key,
      'count': _taskCount,
      'success': _success,
      'failed': _failed,
      'latency_avg': latencyAvg,
      'speed_avg': speedAvg,
    };
  }

  @override
  String toString() {
    return '''
\n      Total Request Count: $_taskCount
      
      Download Success Count: $_success
      
      Download Failed Count: $_failed

      Total Download Duration: $_totalDuration millisecond(s)
      
      Total Download Bytes: $_totalBytes byte(s)
    ''';
  }
}

class SumApiAnalytics {
  final Map<String, ApiAnalytics> _data = <String, ApiAnalytics>{};

  factory SumApiAnalytics() => _getInstance();

  static SumApiAnalytics get sharedInstance => _getInstance();

  static SumApiAnalytics? _instance;

  SumApiAnalytics._internal();

  static SumApiAnalytics _getInstance() {
    _instance ??= SumApiAnalytics._internal();
    return _instance!;
  }

  void updateAnalyticsInfo(
    String path, {
    bool? count,
    bool? success,
    bool? failed,
    int? latencyDuration,
  }) {
    ApiAnalytics? info = _data[path];
    if (info == null) {
      info ??= ApiAnalytics();
      _data[path] = info;
    }

    info._updateInfo(
      count: count,
      success: success,
      failed: failed,
      latencyDuration: latencyDuration,
    );
  }

  void resetAnalyticsInfo() {
    _data.clear();
  }
}

class ApiAnalytics {
  /// 总调用次数
  int _count = 0;

  /// 成功次数
  int _success = 0;

  /// 失败次数
  int _failed = 0;

  /// 接口调用总用时 (ms)
  ///
  /// 计算公式 : [_totalLatencyDuration] / [_count]
  int _totalLatencyDuration = 0;

  int get latencyAvg => _totalLatencyDuration ~/ max(_count, 1);

  void _updateInfo({
    bool? count,
    bool? success,
    bool? failed,
    int? latencyDuration,
  }) {
    if (count != null) _count += 1;

    if (success != null) _success += 1;

    if (failed != null) _failed += 1;

    if (latencyDuration != null) _totalLatencyDuration += latencyDuration;
  }

  @override
  String toString() {
    return '''
\n      Total Request Count: $_count
      
      Success Count: $_success
      
      Failed Count: $_failed

      Total Request Duration: $_totalLatencyDuration millisecond(s)
    ''';
  }

  Map<String, dynamic> _getApiParam() {
    return <String, dynamic>{
      'count': _count,
      'success': _success,
      'failed': _failed,
      'latency_avg': latencyAvg,
    };
  }
}
