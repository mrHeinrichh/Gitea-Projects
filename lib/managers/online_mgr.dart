import 'package:events_widget/event_dispatcher.dart';

class OnlineMgr extends EventDispatcher {
  static const String eventLastSeenStatus = 'OnlineMgr.eventLastSeenStatus';

  // 长链接来的key
  static const String socketFriendOnline = "user_last_online";

  // 只能用于记录时间
  final friendOnlineTime = <int, int>{};

  // 所有展示使用这个
  final friendOnlineString = <int, String>{};
}
