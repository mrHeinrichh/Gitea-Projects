import 'package:flutter/scheduler.dart';

typedef EventCallBack = void Function(Object sender, Object type, Object? data);

class _ActionInfo {
  EventCallBack? action;
  int _count = 0;
  bool get valid {
    return _count == -1 || _count > 0;
  }

  set valid(bool bool) {
    _count = 0;
  }

  _ActionInfo(this.action, int count) {
    _count = count;
  }

  void event(Object sender, Object type, Object? data) {
    action?.call(sender, type, data);
    if (_count > 0) {
      _count--;
    }
  }
}

class EventDispatcher {
  final Map<Object, List<_ActionInfo>> _actions = <Object, List<_ActionInfo>>{};

  final List<_ActionInfo> _dels = [];

  void event(Object sender, Object type, {Object? data}) {
    if (!_actions.containsKey(type)) {
      return;
    }
    var list = _actions[type];
    if (list != null) {
      for (var item in list) {
        if (item.valid) {
          item.event(sender, type, data);
        }
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _check();
    });
  }

  void _addAction(Object type, EventCallBack action, {int count = -1}) {
    if (!_actions.containsKey(type)) {
      _actions[type] = [];
    }
    List<_ActionInfo>? list = _actions[type];
    if (list != null && list.any((info) => info.action?.hashCode == action.hashCode)) {
      return; // Already subscribed, do not add again
    }
    list?.add(_ActionInfo(action, count));
  }

  void once(Object type, EventCallBack action) {
    _addAction(type, action, count: 1);
  }

  bool hasListener(Object type) {
    return _actions.containsKey(type) && _actions[type]!.isNotEmpty;
  }

  void on(Object type, EventCallBack action) {
    _addAction(type, action);
  }

  void off(Object type, [EventCallBack? action]) {
    if (!_actions.containsKey(type)) {
      return;
    }
    List<_ActionInfo>? list = _actions[type];
    if (action == null) {
      list?.clear();
    } else {
      if (list != null) {
        for (var item in list) {
          if (item.action == action) {
            item.valid = false;
          }
        }
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _check();
    });
  }

  void _check() {
    _actions.forEach((key, list) {
      _dels.clear();
      for (var item in list) {
        if (!item.valid) {
          _dels.add(item);
        }
      }
      for (var item in _dels) {
        list.remove(item);
      }
      _dels.clear();
    });
  }

  void clear() {
    _actions.clear();
  }
}
