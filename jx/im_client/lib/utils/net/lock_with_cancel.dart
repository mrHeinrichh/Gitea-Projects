import 'package:jxim_client/utils/debug_info.dart';
import 'package:synchronized/synchronized.dart';

class LockWithCancel {
  final Lock _lock = Lock(); // 使用真正的 Lock
  bool _isCancelled = false; // 控制取消信号

  Future<void> synchronized(Future<void> Function() action) async {
    try {
      await _lock.synchronized(() async {
        _isCancelled = false;
        // 开始执行任务，支持外部取消
        await Future.any([
          action(),
          _waitForCancel(), // 等待取消信号
        ]);

        _isCancelled = true;
      });
    } catch (e) {
      pdebug("LockWithCancel - 执行中发生异常：$e");
    }
  }

  Future<void> _waitForCancel() async {
    while (!_isCancelled) {
      await Future.delayed(const Duration(milliseconds: 1000)); // 定期检查是否取消
    }
  }

  void cancel() {
    _isCancelled = true;
  }
}

// void main() async {
//   final lockWithCancel = LockWithCancel();
//
//   // 启动任务
//   lockWithCancel.synchronized(() async {
//     print("任务开始");
//     await Future.delayed(Duration(seconds: 10)); // 模拟长时间任务
//     print("任务完成");
//   });
//
//   // 模拟 3 秒后取消任务
//   Future.delayed(Duration(seconds: 3), () {
//     lockWithCancel.cancel();
//   });
// }
