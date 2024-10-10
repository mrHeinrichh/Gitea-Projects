part of 'upload_util.dart';

QueueUploadTaskMgr queueUploadTaskMgr =
    QueueUploadTaskMgr(maxTaskQueueCount: 1);

class QueueUploadTaskMgr extends ScheduleTask {
  QueueUploadTaskMgr({
    Duration delay = const Duration(milliseconds: 500),
    int maxTaskQueueCount = 1,
  }) : super(delay, always: true) {
    _maxTaskQueueCount = maxTaskQueueCount;
  }

  int get len => _taskList.length;

  // 最大并行队列
  int _maxTaskQueueCount = 40;

  // 队列任务
  final List<QueueUploadTask> _taskList = <QueueUploadTask>[];

  @override
  execute() async {
    _update();
  }

  Future<void> _update() async {
    if (_taskList.isEmpty) return;

    // 检查已完成和超时、失败、取消的任务
    _taskList.removeWhere((task) {
      bool b = task.status == QueueUploadTaskEnum.finished ||
          task.status == QueueUploadTaskEnum.canceled ||
          (task.status == QueueUploadTaskEnum.failed &&
              task.remainingRetries <= 0);
      if (b) {
        pdebug('QueueUploadTaskMgr 移除任务 ${task.id}');
      }
      return b;
    });
    // 获取正在运行的任务
    final runningTasks = _taskList
        .where((task) => task.status == QueueUploadTaskEnum.running)
        .toList();
    // pdebug("QUEUE runningTasks: ${runningTasks.length} total:${_taskList.length}");
    // 如果正在运行的任务数量小于最大并行队列数
    if (runningTasks.length < _maxTaskQueueCount) {
      // 获取等待中的任务
      final waitingTasks = _taskList
          .where((task) => task.status == QueueUploadTaskEnum.wait)
          .toList()
        ..sort();

      // 启动新的任务
      for (var task
          in waitingTasks.take(_maxTaskQueueCount - runningTasks.length)) {
        pdebug("QueueUploadTaskMgr 启动新任务");
        _startTask(task);
      }
    }
  }

  void _startTask(QueueUploadTask task) async {
    task.status = QueueUploadTaskEnum.running;
    task.taskExecute();
  }

  Future<void> addTask(QueueUploadTask task) {
    final existingTask = _taskList.firstWhere(
      (existingTask) => existingTask.id == task.id,
      orElse: () => task,
    );

    if (existingTask == task) {
      _taskList.add(task);
    } else {
      pdebug(
        "QUEUE QueueUpload Task with ID ${task.id} is already in the queue",
      );
    }
    return existingTask.completer.future;
  }

  clear() {
    for (QueueUploadTask element in _taskList) {
      element.clear();
    }
    _taskList.length = 0;
  }
}

enum QueueUploadTaskEnum {
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

class QueueUploadTask implements Comparable<QueueUploadTask> {
  final String id; // 唯一标识符
  QueueUploadTaskEnum status = QueueUploadTaskEnum.wait;
  final Duration timeout;
  final Future<bool> Function(CancelToken cancelToken) task;
  final void Function(QueueUploadTaskEnum status, String str)? onComplete;
  final void Function(String str)? onStart;

  int remainingRetries;
  final Completer<void> completer = Completer<void>(); // 用于返回任务结果的Completer
  CancelToken cancelToken;
  int priority = 0; // 任务优先级

  QueueUploadTask({
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
      bool result = await _runWithTimeout();
      if (result) {
        status = QueueUploadTaskEnum.finished;
      } else {
        pdebug(
          "QUEUE QueueUploadTaskEnum.failed 其他失败 Task $id result: ${result.toString()}",
        );
        status = QueueUploadTaskEnum.failed;
      }
    } catch (e, s) {
      logger.e(
        '"uploadHandleRequest":"Error in $runtimeType", "stackTrace": "$s","e":"$e"',
        e,
        s,
      );
      if (e is DioException && e.type == DioExceptionType.cancel) {
        status = QueueUploadTaskEnum.canceled;
      } else {
        pdebug("QUEUE QueueUploadTaskEnum.failed 异常失败 Task $id");
        status = QueueUploadTaskEnum.failed;
      }
    } finally {
      if (status == QueueUploadTaskEnum.finished) {
        completer.complete();
      } else if (status == QueueUploadTaskEnum.canceled) {
        completer.completeError(CompleteUploadException(status));
      } else {
        if (remainingRetries > 0) {
          Future.delayed(Duration(milliseconds: Random().nextInt(10)), () {
            status = QueueUploadTaskEnum.wait;
            priority = queueUploadTaskMgr.len;
          });
        } else {
          completer.completeError(CompleteUploadException(status));
        }
      }
      if (completer.isCompleted) {
        onComplete?.call(status, toString());
      }
    }
  }

  Future<bool> _runWithTimeout() {
    return Future.any([
      task(cancelToken),
      Future.delayed(timeout).then(
          (_) => throw TimeoutException('QueueUploadTask _runWithTimeout 192')),
      cancelToken.whenCancel.then((e) => throw e),
    ]);
  }

  @override
  int compareTo(QueueUploadTask other) {
    return other.priority.compareTo(priority);
  }

  @override
  String toString() {
    return "QueueUploadTask(id: $id,isCancelled: ${cancelToken.isCancelled} ,remainingRetries: $remainingRetries, priority: $priority, timeout: ${timeout.inSeconds})";
  }

  clear() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('clear');
    }
  }
}

class CompleteUploadException implements Exception {
  final QueueUploadTaskEnum status;

  CompleteUploadException(this.status);

  @override
  String toString() => 'CompleteUploadException(status: $status)';
}
