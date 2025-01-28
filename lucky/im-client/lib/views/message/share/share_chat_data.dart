import 'package:jxim_client/object/chat/chat.dart';
import 'package:events_widget/event_dispatcher.dart';

class ShareChatData extends EventDispatcher {
  static const String eventSelectChat = 'select_chat';

  List<Chat> _selectChatList = [];

  List<Chat> get selectChatList => _selectChatList;

  set selectChatList(List<Chat> value) {
    _selectChatList = value;
    event(this, eventSelectChat);
  }

  bool judgeSelect(int chatId) {
    for (Chat item in _selectChatList) {
      if (item.id == chatId) {
        return true;
      }
    }
    return false;
  }
}
