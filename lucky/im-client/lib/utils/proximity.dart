import 'dart:async';
import 'dart:ui';
// import 'package:all_sensors/all_sensors.dart';

StreamSubscription<dynamic>? _proximity;

enum ProximityType {
  call, //  通话

}

List<ProximityType> _proximityEnables = [];

// 近距离传感器
gProximityEnable(ProximityType type, bool v) {
  if (v) {
    if (!_proximityEnables.contains(type)) {
      _proximityEnables.add(type);
    }
  } else {
    _proximityEnables.remove(type);
  }
  _proximityEnable(_proximityEnables.isNotEmpty);
}

gProximityEnableByAppLifecycleState(AppLifecycleState ?state) {
  if (state != AppLifecycleState.resumed) {
    _proximityEnable(false);
  } else {
    _proximityEnable(_proximityEnables.isNotEmpty);
  }
}

_proximityEnable(bool v) {
  if (v) {
    // _proximity ??= proximityEvents?.listen((ProximityEvent event) {
    //   if(_proximityEnables.isEmpty){
    //     // 尝试修复一下
    //     _proximityEnable(_proximityEnables.isNotEmpty);
    //   }
    // });
  } else {
    _proximity?.cancel();
    _proximity = null;
  }
}
