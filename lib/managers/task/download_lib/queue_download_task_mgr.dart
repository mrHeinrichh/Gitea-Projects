part of 'download_util.dart';

QueueDownloadTaskMgr queueDownloadTaskMgr = QueueDownloadTaskMgr();

class QueueDownloadTaskMgr extends ScheduleTask {
  QueueDownloadTaskMgr({
    Duration delay = const Duration(milliseconds: 500),
    int maxTaskQueueCount = 5,
  }) : super(delay) {
    _maxTaskQueueCount = maxTaskQueueCount;
  }

  // 最大并行队列
  int _maxTaskQueueCount = 1;

  int get len => _taskList.length;

  // 队列任务
  final List<QueueDownloadTask> _taskList = <QueueDownloadTask>[];

  @override
  execute() async {
    await _update();
  }

  Future<void> _update() async {
    if (_taskList.isEmpty) return;
    // 检查已完成和超时、失败、取消的任务
    _taskList.removeWhere(
      (task) =>
          task.status == QueueDownloadTaskEnum.finished ||
          task.status == QueueDownloadTaskEnum.canceled ||
          (task.status == QueueDownloadTaskEnum.failed &&
              task.remainingRetries <= 0),
    );
    // 获取正在运行的任务
    final runningTasks = _taskList
        .where((task) => task.status == QueueDownloadTaskEnum.running)
        .toList();
    // pdebug("QUEUE runningTasks: ${runningTasks.length} total:${_taskList.length}");
    // 如果正在运行的任务数量小于最大并行队列数
    if (runningTasks.length < _maxTaskQueueCount) {
      // 获取等待中的任务
      final waitingTasks = _taskList
          .where((task) => task.status == QueueDownloadTaskEnum.wait)
          .toList()
        ..sort();

      // 启动新的任务
      for (var task
          in waitingTasks.take(_maxTaskQueueCount - runningTasks.length)) {
        _startTask(task);
      }
    }
  }

  void _startTask(QueueDownloadTask task) async {
    task.status = QueueDownloadTaskEnum.running;
    await task.taskExecute();
  }

  Future<void> addTask(QueueDownloadTask task) {
    final existingTask = _taskList.firstWhere(
      (existingTask) => existingTask.id == task.id,
      orElse: () => task,
    );

    if (existingTask == task) {
      _taskList.add(task);
    } else {
      pdebug(
        "QUEUE QueueDownload Task with ID ${task.id} is already in the queue",
      );
    }
    return existingTask.completer.future;
  }

  clear() {
    for (QueueDownloadTask element in _taskList) {
      element.clear();
    }
    _taskList.length = 0;
  }
}

enum QueueDownloadTaskEnum {
  // 等待
  wait,
  // 进行中
  running,
  // 已完成
  finished,
  // 失败
  failed,
  // 取消
  canceled,
}

enum QueueDownloadResultEnum {
  // 已完成
  finished,
  // 失败
  failed,
  // 重定向
  redirect,
}

class QueueDownloadTask implements Comparable<QueueDownloadTask> {
  final String id; // 唯一标识符
  QueueDownloadTaskEnum status = QueueDownloadTaskEnum.wait;
  final Duration timeout;
  final Future<QueueDownloadResultEnum> Function(
      CancelToken cancelToken, bool shouldRedirect, Duration timeout) task;
  final void Function(QueueDownloadTaskEnum status, String str)? onComplete;
  final void Function(String str)? onStart;

  int remainingRetries;
  final Completer<void> completer = Completer<void>(); // 用于返回任务结果的Completer
  CancelToken cancelToken;
  int priority = 0; // 任务优先级
  bool redirect = false;

  QueueDownloadTask({
    required this.id, // 传入唯一标识符
    required this.task,
    required this.cancelToken,
    this.timeout = const Duration(seconds: 10),
    this.onComplete,
    this.onStart,
    this.remainingRetries = 3, // 默认重试3次
    this.priority = 100, // 默认优先级为0
  });

  // 执行任务并处理回调
  Future<void> taskExecute() async {
    if (onStart != null) {
      onStart!(toString());
    }
    Future.delayed(Duration(milliseconds: Random().nextInt(10)), () {
      _executeInternal();
    });
  }

  Future<void> _executeInternal() async {
    try {
      remainingRetries--;
      QueueDownloadResultEnum result = await _runWithTimeout();
      if (result == QueueDownloadResultEnum.finished) {
        status = QueueDownloadTaskEnum.finished;
      } else if (result == QueueDownloadResultEnum.redirect) {
        redirect = true;
      } else {
        pdebug(
          "QUEUE QueueDownloadTaskEnum.failed 其他失败 Task $id result: ${result.toString()}",
        );
        status = QueueDownloadTaskEnum.failed;
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        status = QueueDownloadTaskEnum.canceled;
      } else {
        pdebug("QUEUE QueueDownloadTaskEnum.failed 异常失败 Task $id");
        status = QueueDownloadTaskEnum.failed;
      }
    } finally {
      if (status == QueueDownloadTaskEnum.finished) {
        completer.complete();
      } else if (status == QueueDownloadTaskEnum.canceled) {
        completer.completeError(CompleteDownloadException(status));
      } else {
        if (remainingRetries > 0) {
          Future.delayed(Duration(milliseconds: Random().nextInt(10)), () {
            status = QueueDownloadTaskEnum.wait;
            priority = queueDownloadTaskMgr.len;
          });
        } else {
          completer.completeError(CompleteDownloadException(status));
        }
      }
      if (completer.isCompleted) {
        onComplete?.call(status, toString());
      }
    }
  }

  Future<QueueDownloadResultEnum> _runWithTimeout() {
    return Future.any([
      task(cancelToken, redirect, timeout),
      Future.delayed(timeout).then((_) =>
          throw TimeoutException('QueueDownloadTask _runWithTimeout 192')),
      cancelToken.whenCancel.then((e) => throw e),
    ]);
  }

  @override
  int compareTo(QueueDownloadTask other) {
    return other.priority.compareTo(priority);
  }

  @override
  String toString() {
    return "QueueDownloadTask(id: $id, isCancelled: ${cancelToken.isCancelled} remainingRetries: $remainingRetries, priority: $priority, timeout: ${timeout.inSeconds})";
  }

  clear() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('clear');
    }
  }
}

class CompleteDownloadException implements Exception {
  final QueueDownloadTaskEnum status;

  CompleteDownloadException(
    this.status,
  );

  @override
  String toString() => 'CompleteDownloadException(status: $status)';
}
