import 'dart:async';
import 'dart:collection';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/net/custom_request.dart';

typedef FutureFunction = Future Function();

late final QueueTask queueTask;
Future queuePost(String url,
    {String data = '', bool front = false, bool reset = false}) async {
  Completer com = Completer();
  queueTask = QueueTask();
  // 登陆接口需要重头开始
  if (reset) queueTask.clear(null);
  if (queueTask.forbid) {
    com.completeError("token forbid");
    return com.future;
  }
  // 接口校验
  if (data.isEmpty) {
    com.completeError("check error");
    return com.future;
  }

  FutureFunction task = () async => await CustomRequest.doPost(url, data: data);
  queueTask.add(url, task, com.complete, com.completeError);
  return com.future;
}

class QueueTask {
  int _current = 0;
  int _queueCurrent = 0;
  bool forbid = false;
  String msg = '';
  final Queue<FutureFunction> _tasks = Queue<FutureFunction>();

  clear(dynamic err) {
    if (err == null) {
      forbid = false;
      return;
    }

    // 处理请求失败
    // int? statusCode = err['status'];
    // String? msg = err['msg'];
  }

  // task = () async => await CustomRequest.send(url, data: data);
  add(String url, FutureFunction task, Function(dynamic) resolve,
      Function(Object error, [StackTrace? stackTrace]) reject,
      {isFront = false}) async {
    final mainUserInfo = objectMgr.loginMgr.account?.user;
    bool pass = _current == 0 || mainUserInfo != null;

    if (pass) {
      _tasks.addFirst(task);
      _loadNext(url, resolve, reject);
      return;
    }

    _tasks.add(task);
    if (_queueCurrent > 0) return;
    _loadNext(url, resolve, reject);
  }

  _loadNext(String url, Function(dynamic) resolve,
      Function(Object error, [StackTrace? stackTrace]) reject) async {
    if (_tasks.isEmpty) return;
    _current++;
    _queueCurrent++;
    FutureFunction task = _tasks.first;
    _execute(task)
        .then((v) => resolve(v))
        .onError((e, _) => reject(e))
        .whenComplete(() => _onLoadFinally(url, resolve, reject));
  }

  _onLoadFinally(String url, Function(dynamic) resolve,
      Function(Object error, [StackTrace? stackTrace]) reject) {
    _current--;
    _queueCurrent--;
    _loadNext(url, resolve, reject);
  }

  _execute(FutureFunction task) async {
    var com = Completer();
    try {
      com.complete(await task());
    } catch (err, stack) {
      com.completeError(err, stack);
    }

    return com.future;
  }
}
