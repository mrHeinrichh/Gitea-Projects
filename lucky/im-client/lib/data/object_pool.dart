import 'dart:collection';

abstract class Poolable {
  init(Map<String, dynamic> json);
  cleanup();
}

class JsonObjectPool<T extends Poolable> {
  Function ?_creator;
  final Queue<T> _pool = Queue<T>();

  JsonObjectPool(T Function() creator) {
    _creator = creator;
  }

  A fetch<A>() {
    // T obj = _pool.isNotEmpty ? _pool.removeLast() : _creator();
    // return obj;
    return _creator!() as A;
  }



  void discard(T obj) {
    // obj.cleanup();
    // _pool.addLast(obj);
  }

  int get length => _pool.length;
}
