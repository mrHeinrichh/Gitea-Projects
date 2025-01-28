import 'package:events_widget/event_dispatcher.dart';

///小红点数据
class RedDotData extends EventDispatcher {
  static const eventUpdateShow = 'eventUpdateShow'; //小红点显示更新
  bool _isShow = false;
  bool get isShow => _isShow;
  set isShow(bool value) {
    if (_isShow == value) return;
    _isShow = value;
    event(this, eventUpdateShow);
  }

  RedDotData([bool isShow = false]) {
    _isShow = isShow;
  }
}
