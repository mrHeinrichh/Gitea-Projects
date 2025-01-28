// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:dio/dio.dart';

import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/debug_info.dart';

QueueTaskMgr queueUploadTaskMgr = QueueTaskMgr(maxTaskQueueCount: 10);
QueueTaskMgr queueDownloadTaskMgr = QueueTaskMgr();

class QueueTaskMgr extends ScheduleTask {
  QueueTaskMgr(
      {int delay = 1 * 200, bool isPeriodic = true, int maxTaskQueueCount = 40})
      : super(delay, isPeriodic) {
    _maxTaskQueueCount = _maxTaskQueueCount;
  }

  // 最大并行队列
  int _maxTaskQueueCount = 40;
  // 队列任务
  List<QueueTask> _taskList = <QueueTask>[];

  @override
  execute() async {
    await _update();
  }

  Future<void> _update() async {
    // 获取正在运行的任务
    final runningTasks = _taskList
        .where((task) => task.status == QueueTaskEnum.running)
        .toList();
    // pdebug("QUEUE runningTasks: ${runningTasks.length} total:${_taskList.length}");
    // 如果正在运行的任务数量小于最大并行队列数
    if (runningTasks.length < _maxTaskQueueCount) {
      // 获取等待中的任务
      final waitingTasks = _taskList
          .where((task) => task.status == QueueTaskEnum.wait)
          .toList()
        ..sort();

      // 启动新的任务
      for (var task
          in waitingTasks.take(_maxTaskQueueCount - runningTasks.length)) {
        _startTask(task);
      }
    }

    // 检查已完成和超时、失败、取消的任务
    _taskList.removeWhere((task) =>
        task.status == QueueTaskEnum.finished ||
        task.status == QueueTaskEnum.timeout ||
        task.status == QueueTaskEnum.canceled ||
        (task.status == QueueTaskEnum.failed && task.remainingRetries <= 0));
  }

  void _startTask(QueueTask task) async {
    task.status = QueueTaskEnum.running;
    await task.execute();
  }

  Future<void> addTask(QueueTask task) {
    final existingTask = _taskList.firstWhere(
      (existingTask) => existingTask.id == task.id,
      orElse: () => task,
    );

    if (existingTask == task) {
      _taskList.add(task);
    } else {
      pdebug("QUEUE Task with ID ${task.id} is already in the queue");
    }

    return existingTask.execute();
  }

  void cancelTask(String taskId) {
    final task = _taskList.firstWhere((task) => task.id == taskId);
    if (task != null) {
      task._cancel();
    }
  }
}

enum QueueTaskEnum {
  // 等待
  wait,
  // 进行中
  running,
  // 已完成
  finished,
  // 超时
  timeout,
  // 失败
  failed,
  // 重定向
  redirect,
  // 取消
  canceled,
}

class QueueTask implements Comparable<QueueTask> {
  final String id; // 唯一标识符
  QueueTaskEnum status = QueueTaskEnum.wait;
  final Duration timeout;
  final Future<TaskResult> Function(
      CancelToken cancelToken, bool shouldRedirect) task;
  final void Function(QueueTaskEnum status, String str)? onComplete;
  final void Function(String str)? onStart;
  // 重定向任务
  bool shouldRedirect;
  int remainingRetries;
  Completer<void>? _completer; // 用于返回任务结果的Completer
  CancelToken? cancelToken;
  int priority = 0; // 任务优先级
  final Duration initialRetryDelay; // 初始重试延迟
  final double retryBackoffFactor; // 退避因子
  final DateTime startTime = DateTime.now();

  QueueTask({
    required this.id, // 传入唯一标识符
    required this.task,
    required this.cancelToken,
    this.timeout = const Duration(seconds: 5),
    this.onComplete,
    this.onStart,
    this.shouldRedirect = false,
    this.remainingRetries = 3, // 默认重试3次
    this.priority = 0, // 默认优先级为0
    this.initialRetryDelay = const Duration(milliseconds: 300), // 默认初始重试延迟
    this.retryBackoffFactor = 1, // 退避因子
  }) {
    cancelToken ??= CancelToken();
    cancelToken?.whenCancel.then((e) => _cancel(e: e));
  }

  // 取消任务
  void _cancel({DioException? e}) {
    if (status == QueueTaskEnum.canceled) {
      return;
    }
    if (!cancelToken!.isCancelled) cancelToken!.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!
          .completeError(TaskCanceledException('QUEUE Task $id was canceled'));
    }
    status = QueueTaskEnum.canceled;
    if (onComplete != null) {
      onComplete!(status, toString());
    }
  }

  void _timeout() {
    if (status == QueueTaskEnum.timeout) {
      return;
    }
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(TimeoutException('QUEUE Task $id was timeout'));
    }
    status = QueueTaskEnum.timeout;
    if (onComplete != null) {
      onComplete!(status, toString());
    }
  }

  // 执行任务并处理回调
  Future<void> execute() {
    // 如果任务已经在执行中，返回同一个Completer的Future
    if (_completer != null) {
      return _completer!.future;
    }

    _completer = Completer<void>();
    _executeInternal().then((_) {
      if (!_completer!.isCompleted) {
        _completer!.complete();
      }
    }).catchError((e) {
      if (!_completer!.isCompleted) {
        _completer!.completeError(e);
      }
    });

    if (onStart != null) {
      onStart!(toString());
    }

    return _completer!.future;
  }

  Future<void> _executeInternal() async {
    if (cancelToken!.isCancelled) {
      _cancel();
      return;
    }

    if (DateTime.now().difference(startTime) > timeout) {
      _timeout();
      return;
    }

    try {
      TaskResult result = await _runWithTimeout();
      if (result.success) {
        status = QueueTaskEnum.finished;
      } else if (status == QueueTaskEnum.canceled ||
          status == QueueTaskEnum.timeout) {
        return;
      } else {
        pdebug("QUEUE QueueTaskEnum.failed 其他失败 Task $id");
        shouldRedirect = result.shouldRedirect;
        if (result.shouldRedirect && status != QueueTaskEnum.redirect) {
          status = QueueTaskEnum.redirect;
        } else {
          status = QueueTaskEnum.failed;
        }
        if (result.noRetry) {
          remainingRetries = 0;
        } else if ((remainingRetries > 0 || result.retryOnNetworkFailure) &&
            !cancelToken!.isCancelled) {
          remainingRetries--;
          if (result.retryOnNetworkFailure) {
            if (remainingRetries < 2) {
              remainingRetries = 3;
            }
          }

          final retryDelay =
              initialRetryDelay * (retryBackoffFactor * (3 - remainingRetries));
          pdebug(
              "QUEUE Retrying task in $retryDelay, remaining retries: $remainingRetries");
          await Future.delayed(retryDelay);
          await _executeInternal(); // 重试任务
        }
      }
    } catch (e) {
      if (e is TimeoutException) {
        status = QueueTaskEnum.timeout;
        throw e;
      } else if (e is TaskCanceledException) {
        status = QueueTaskEnum.canceled;
        throw e;
      } else if (e is DioException && e.type == DioExceptionType.cancel) {
        status = QueueTaskEnum.canceled;
        throw e;
      } else if (status == QueueTaskEnum.canceled ||
          status == QueueTaskEnum.timeout) {
        throw e;
      } else {
        pdebug("QUEUE QueueTaskEnum.failed 异常失败 Task $id");
        status = QueueTaskEnum.failed;
      }

      // 任务失败时进行重试
      if (status == QueueTaskEnum.failed &&
          (remainingRetries > 0 || !cancelToken!.isCancelled)) {
        remainingRetries--;
        final retryDelay =
            initialRetryDelay * (retryBackoffFactor * (3 - remainingRetries));
        pdebug(
            "QUEUE Retrying task in $retryDelay, remaining retries: $remainingRetries");
        await Future.delayed(retryDelay);
        await _executeInternal(); // 重试任务
      }
    } finally {
      if (onComplete != null && !cancelToken!.isCancelled) {
        onComplete!(status, toString());
      }
    }
  }

  Future<TaskResult> _runWithTimeout() {
    return Future.any([
      task(cancelToken!, shouldRedirect),
      Future.delayed(timeout).then((_) {
        throw TimeoutException("QUEUE Task timed out");
      }),
    ]);
  }

  @override
  int compareTo(QueueTask other) {
    return other.priority.compareTo(priority);
  }

  @override
  String toString() {
    return "QueueTask(id: $id, shouldRedirect: $shouldRedirect, remainingRetries: $remainingRetries, priority: $priority, timeout: ${timeout.inSeconds})";
  }
}

class TaskCanceledException implements Exception {
  final String message;
  TaskCanceledException(this.message);
}

class TaskResult {
  final bool success;
  final bool shouldRedirect;
  final bool noRetry;
  final bool retryOnNetworkFailure;
  String? message;

  TaskResult({
    required this.success,
    this.shouldRedirect = false,
    this.noRetry = false,
    this.retryOnNetworkFailure = false,
    this.message = '',
  });
}
