// import 'dart:async';
//
// class TimerMgr {
//   final Map<String, Function()> taskMap = {};
//
//   TimerMgr.init() {
//     startTimer();
//   }
//
//   Timer? _timer;
//   void startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       taskMap.forEach((key, value) {
//         value();
//       });
//     });
//   }
//
//   void stopTimer() {
//     if (_timer != null) {
//       _timer?.cancel();
//       _timer = null;
//     }
//   }
//
//   void addTask(String key, Function() task) {
//     taskMap[key] = task;
//   }
//
//   void removeTask(String key) {
//     taskMap.remove(key);
//   }
// }
