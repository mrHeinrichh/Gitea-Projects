import 'dart:async';

StreamSubscription<dynamic>? _proximity;

enum ProximityType {
  call,
}

List<ProximityType> _proximityEnables = [];

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

_proximityEnable(bool v) {
  if (v) {
  } else {
    _proximity?.cancel();
    _proximity = null;
  }
}
