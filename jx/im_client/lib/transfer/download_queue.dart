import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/transfer/log_util.dart';
import 'package:synchronized/synchronized.dart';

class DownloadQueue {
  final LogUtil _log = LogUtil.module(LogModule.download);
  final DoubleLinkedQueue<DownloadTask> _queue = DoubleLinkedQueue();
  final Map<String, DownloadTask> _taskMap = {};
  final StreamController<DownloadTask> _streamController =
      StreamController.broadcast();
  final Lock addTaskLock = Lock();
  int _taskSeq = 0;

  Future<DownloadTask> addTask(DownloadTask task) async {
    DownloadTask? exists = _taskMap[task.id];
    if (exists != null) {
      _log.info(
          "Download task exists, taskID: ${exists.simpleID}, ${exists.downloadType.name}");
      if (exists.downloadType == DownloadType.background) {
        exists.downloadType = task.downloadType;
      }
      addTaskLock.synchronized(() {
        _queue.addFirst(exists!);
        removeTask(task, skip: 1);
        _ensureMaxLength();
        exists!.retries = 0;
        _streamController.add(exists!);
      });

      return exists;
    }

    await addTaskLock.synchronized(() {
      exists = _taskMap[task.id];
      if (exists != null) {
        _log.info("Download task exists, taskID: ${exists!.id}");
        return;
      }

      task.seq = _taskSeq++;
      _queue.addFirst(task);
      _ensureMaxLength();
      _taskMap[task.id] = task;
      _streamController.add(task);
    });

    return exists ?? task;
  }

  Future<DownloadTask> fetchFirstReadyTask(
      DownloadType downloadType, bool mustMultiRetryTask) {
    DownloadTask? task =
        tryFetchFirstReadyTask(downloadType, mustMultiRetryTask);
    if (task != null) {
      return Future.value(task);
    }
    return _streamController.stream
        .firstWhere(_getReadyTaskCondition(downloadType, mustMultiRetryTask));
  }

  DownloadTask? tryFetchFirstReadyTask(
      DownloadType downloadType, bool mustMultiRetryTask) {
    return _queue.firstWhereOrNull(
        _getReadyTaskCondition(downloadType, mustMultiRetryTask));
  }

  bool Function(DownloadTask) _getReadyTaskCondition(
      DownloadType downloadType, bool mustMultiRetryTask) {
    return (task) =>
        task.downloadType == downloadType &&
        task.isReady() &&
        (mustMultiRetryTask
            ? task.retries >= DownloadConfig().DOWNLOAD_TASK_MULTI_RETRIES
            : task.retries < DownloadConfig().DOWNLOAD_TASK_MULTI_RETRIES);
  }

  removeTask(DownloadTask task, {int skip = 0}) {
    int matchCount = 0;
    for (var entry = _queue.firstEntry();
        entry != null;
        entry = entry.nextEntry()) {
      if (entry.element.id == task.id) {
        matchCount++;
        if (matchCount <= skip) {
          continue;
        }

        entry.remove();
        // _queue.remove(entry.element);
      }
    }

    if (skip == 0) {
      _taskMap.remove(task.id);
    }
  }

  backoffTask(DownloadTask task) {
    _queue.remove(task);
    _queue.addLast(task);
  }

  broadcastTask(DownloadTask task) {
    _streamController.add(task);
  }

  _ensureMaxLength() {
    if (_queue.length > DownloadConfig().DOWNLOAD_QUEUE_MAX_LEN) {
      _queue.removeLast();
    }
  }

  int get length => _queue.length;
}
