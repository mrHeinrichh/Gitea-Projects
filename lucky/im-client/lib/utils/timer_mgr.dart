import 'dart:async';
import 'package:synchronized/synchronized.dart' as synchronized;

/// 支持心跳接口
class OnUpdateActor {
  /// 如果各子类要调整心跳的频率就变得可行了
  TickHolder ?tickHolder;
  // get tickHolder => _tickHolder;
  // set tickHolder(v) => _tickHolder = v;

  Future<void> updateTick(int diff) async {}
}

/// 自定义心跳记数器
class TickHolder {
  /// 当前心跳的时间ms数
  int _i = 0;

  /// 每次触发的毫秒数
  int _timer = 0;

  // ignore: unnecessary_getters_setters
  int get timer => _timer;

  /// 重新设置周期时间
  // ignore: unnecessary_getters_setters
  set timer(int v) => _timer = v;

  /// 周期
  int _period;

  /// 周期是不可更改的
  int get period => _period;

  TickHolder(this._period) {
    _timer = _period;
  }

  /// 增加超时时间
  void add(int v, {int? max}) {
    _timer += v;
    if (max != null && _timer > max) {
      _timer = max;
    }
  }

  /// 心跳自增加
  bool update(int diff) {

    _i = _i + diff;
    if (_i >= _timer) {
      // _i -= _timer;
      _i = 0; //还是从头开始吧,万一有脏数据就坏了
      return true;
    }
    return false;
  }

  /// 重置定时器值
  void reset({period}) {
    if (period != null) {
      _timer = period;
      _period = period;
    }
    _i = 0;
  }
}

/// 自定义心跳管理器
final TimerMgr timerMgr = TimerMgr();

/// 每帧变化的时间
// ignore: constant_identifier_names
const _UpdateMs = 100;

/// 本地时间管理
class TimerMgr {
  int _lastTime = 0;
  int _curTime = 0;

  /// 当前所有的待更新队列
  final Set<OnUpdateActor> _list = {};

  /// 待加入队列
  final Set<OnUpdateActor> _addList = {};

  /// 待删除队列
  final List<OnUpdateActor> _delList = [];

  TimerMgr() {
    _curTime = _now();
    _lastTime = _curTime;

    __createTimer();
  }

  int _now() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  void add(OnUpdateActor a, {int? ms}) {
    a.tickHolder = TickHolder(ms ?? _UpdateMs);
    _addList.add(a);
  }

  /// 增加可以心跳的东西
  void del(OnUpdateActor b) {
    _delList.add(b);
  }

  Timer ?_timer;
  __createTimer() {
    if (_timer == null) {
      synchronized.Lock lock = synchronized.Lock();
      bool isUpdating = false;
      _timer = Timer.periodic(const Duration(milliseconds: _UpdateMs), (timer) async {
        await lock.synchronized(() async {
          assert(!isUpdating);
          isUpdating = true;

          // ignore: todo
          //TODO:心跳定时器写法
          await updateTick(_UpdateMs);

          isUpdating = false;
        });
      });
    }
  }

  /// 心跳啊，心跳
  Future<void> updateTick(diff) async {
    int now = _now();
    int diff = now - _lastTime;
    if (diff > 0) {
      for (var item in _list) {
        try {
          // 每个管理器的心跳帧率可能不一致,使用定时器
          if (item.tickHolder != null && item.tickHolder!.update(diff)) {
            await item.updateTick(item.tickHolder!.timer);
          }
        } catch (e) {
          // mypdebug("心跳错误:$item 异常:$e");
        }
      }
    }
    _lastTime = now;

    // 待加入的队列
    _list.addAll(_addList);
    _addList.clear();

    for (var i = 0; i < _delList.length; i++) {
      var todel = _delList[i];
      _list.remove(todel);
    }
    _delList.clear();
  }
}
