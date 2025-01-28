import 'dart:async';

import 'package:jxim_client/transfer/download_channel_policy.dart';
import 'package:jxim_client/transfer/download_channel_state_policy.dart';
import 'package:jxim_client/transfer/download_queue.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/transfer/log_util.dart';
import 'package:synchronized/synchronized.dart';

class DownloadChannel {
  static final LogUtil _log = LogUtil.module(LogModule.download);

  static final Map<ChannelType, ChannelPolicy> _channelPullPolicyMap = {};
  static final List<DownloadChannelStatePolicy> _channelStatePolicies = [];
  static final StreamController _checkStateStreamController =
      StreamController();

  final int _index;
  final ChannelType _channelType;
  final bool _cellularEnable;

  final _DownloadChannelContext _context = _DownloadChannelContext();

  int get lastTaskRunTime => _context._lastTaskRunTime;

  ChannelType get channelType => _channelType;

  bool get cellularEnable => _cellularEnable;

  DownloadChannel(this._index, this._channelType, this._cellularEnable) {
    _context._channelPullPolicy =
        _channelPullPolicyMap[_channelType] ??= SmallFirstSharedChannelPolicy();
  }

  static registerPullPolicy(ChannelPolicy policy) {
    _channelPullPolicyMap[policy.channelType()] = policy;
  }

  void pullTaskAndRun(DownloadQueue downloadQueue) async {
    while (true) {
      DownloadTask? task;
      bool updated = false;
      while (task == null || !updated) {
        if (_context._grabTask == null) {
          task = await _context._channelPullPolicy.pull(downloadQueue);
        } else {
          task = _context._grabTask!;
        }

        await _waitEnable();

        updated = await task.updateStatues(TaskStatus.downloading);
        if (updated) {
          _context._curTask = task;
        } else {
          _log.info(
              "Channel($qualifiedName) get task but not not competition for updating status");
        }
      }

      _context._lastTaskRunTime = DateTime.now().millisecondsSinceEpoch;
      try {
        _log.info(
            "Channel($qualifiedName) run task start, taskID: ${task.simpleID}");
        task.channelName = qualifiedName;
        task.recordDownloadStartTime();
        await task.run(_context._channelPullPolicy.getDioSendTimeoutMs(),
            _context._channelPullPolicy.getDioReceiveTimeoutMs());
      } catch (e) {
        await task.handleErr(e);
      } finally {
        await task.clean();
        task.recordDownloadEndTime();
        _log.info(
            "Channel($qualifiedName) run task finished, taskID: ${task.simpleID}, status: ${task.status.name}");
      }
      _context._curTask = null;
      _checkStateStreamController.add(null);
      if (task.status == TaskStatus.waitingRetry) {
        await task.prepareRetry();
      } else {
        task.dequeue();
        continue;
      }
    }
  }

  bool canSoftKickOut() {
    return _context._curTask == null ? true : !_context._curTask!.grab;
  }

  bool grabTask(DownloadTask task, bool force) {
    if (!force && _context._curTask != null && _context._curTask!.grab) {
      return false;
    }
    _context._curTask?.cancel();
    _context._grabTask = task;
    return true;
  }

  void cancelTask() {
    DownloadTask? curTask = _context._curTask;
    if (curTask == null) {
      return;
    }

    if (curTask.grab) {
      return;
    }

    curTask.cancel();
  }

  bool isWeakNet() {
    return _context._curTask?.isWeakNet ?? false;
  }

  registerChanelStatePolicy(DownloadChannelStatePolicy policy) {
    _channelStatePolicies.add(policy);
  }

  String get qualifiedName =>
      "${channelType.name}${_cellularEnable ? "-cellular-" : "-"}$_index";

  bool _enableByPolicies() {
    if (_channelStatePolicies == null) {
      return true;
    }

    for (DownloadChannelStatePolicy policy in _channelStatePolicies) {
      if (!policy.enable(this)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _waitEnable() async {
    while (!_enableByPolicies()) {
      await _checkStateStreamController.stream.first;
    }
  }
}

class _DownloadChannelContext {
  DownloadTask? _curTask;
  DownloadTask? _grabTask;
  final getSetGrabTaskLock = Lock();
  int _lastTaskRunTime = 0;
  late final ChannelPolicy _channelPullPolicy;
}

enum ChannelType {
  smallExclusive,
  smallFirstShared,
  largeExclusive,
  background,
  retry
}
