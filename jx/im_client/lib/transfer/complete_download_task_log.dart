import 'package:jxim_client/transfer/download_task.dart';

class CompleteDownloadTaskLog {
  String downloadLogType = "COMPLETE";
  late String taskID;
  late String downloadType;
  late int taskSeq;
  late String channelName;
  late int fileLen;
  int createTime;
  int completeTime;
  int latency;
  int waitCost;
  int downloadCost;
  int queueLen;
  int retries;
  bool hasRedirect;
  String? lastErr;
  List<int> tryCosts;
  String? reason;

  CompleteDownloadTaskLog.fromDownloadTask(
      DownloadTask task, this.queueLen, int nowTs, this.reason)
      : taskID = task.simpleID,
        downloadType = task.downloadType.name,
        taskSeq = task.seq,
        channelName = task.channelName!,
        fileLen = task.fileLen,
        createTime = task.createTime,
        completeTime = nowTs,
        latency = nowTs - task.createTime,
        waitCost = task.downloadStartTimes[0] - task.createTime,
        downloadCost = nowTs - task.downloadStartTimes.last,
        retries = task.retries,
        hasRedirect = task.hasRedirect,
        lastErr = task.lastErr,
        tryCosts = task.tryCosts;

  Map<String, dynamic> toJson() {
    return {
      'downloadLogType': downloadLogType,
      'taskID': taskID,
      'downloadType': downloadType,
      'taskSeq': taskSeq,
      'channelName': channelName,
      'fileLen': fileLen,
      'createTime': createTime,
      'completeTime': completeTime,
      'latency': latency,
      'waitCost': waitCost,
      'downloadCost': downloadCost,
      'queueLen': queueLen,
      'retries': retries,
      'hasRedirect': hasRedirect,
      "lastErr": lastErr,
      "tryCosts": tryCosts,
      "reason": reason,
    };
  }

  @override
  String toString() {
    return 'CompleteDownloadTaskLog{downloadLogType: $downloadLogType, taskID: $taskID, '
        'downloadType: $downloadType, taskSeq: $taskSeq, channelName: $channelName, fileLen: $fileLen, '
        'createTime: $createTime, completeTime: $completeTime, latency: $latency, waitCost: $waitCost, '
        'downloadCost: $downloadCost, queueLen: $queueLen, retries: $retries, hasRedirect: $hasRedirect, '
        'lastErr: $lastErr, reason: $reason}';
  }
}
