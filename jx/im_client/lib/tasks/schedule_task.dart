import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jxim_client/utils/debug_info.dart';

abstract class ScheduleTask {
  // 心跳间隔
  final Duration delay;
  late int finalDelay;
  // 是否为永久性心跳
  final bool always;
  int _delayCount = 0;
  final minDelay = const Duration(milliseconds: 200);

  ScheduleTask(this.delay, {this.always = false}) {
    // 最少100毫秒一次
    finalDelay = delay.inMilliseconds > minDelay.inMilliseconds
        ? delay.inMilliseconds
        : minDelay.inMilliseconds;
  }

  bool _running = false;

  // diff 两帧之间的时间间隔,单位毫秒
  @mustCallSuper
  update(int diff) async {
    if (_isFinished) return;
    if (_isPause) {
      // 如果只是暂停那么差值继续减
      if (_delayCount > 0) _delayCount -= diff;
      return;
    }
    if (_delayCount <= 0) {
      if (_running) {
        pdebug('execute always running');
        return;
      }
      _running = true;
      // final stopwatch = Stopwatch()..start();
      try {
        await execute();
      } catch (e) {
        pdebug('runtimeType: $runtimeType, run execute error: $e');
      } finally {
        // if (stopwatch.elapsedMilliseconds > 0) {
        //   pdebug(
        //       '{"execute":"$runtimeType" , "execution_time": ${stopwatch.elapsedMilliseconds} ms}');
        // }
        // stopwatch.stop();
        _running = false;
        _delayCount = finalDelay;
      }
    } else {
      _delayCount -= diff;
    }
  }

  @protected
  Future<void> execute() {
    throw UnimplementedError();
  }

  bool _isPause = false;

  @mustCallSuper
  pause() {
    if (always) return;
    _isPause = true;
  }

  @mustCallSuper
  resumed() {
    if (always) return;
    _isPause = false;
  }

  bool get isFinished => _isFinished;
  bool _isFinished = false;

  @mustCallSuper
  finish() {
    _isFinished = true;
  }

  @mustCallSuper
  restart() {
    _isFinished = false;
  }

  // bool fource 心跳是否需要立即执行
  @mustCallSuper
  resetDelayCount({fource = false}) {
    if (fource) {
      _delayCount = 0;
      return;
    }
    if (_delayCount < finalDelay ~/ 4) {
      _delayCount = 0;
    } else {
      _delayCount = max(finalDelay ~/ 4, minDelay.inMilliseconds);
    }
  }
}
