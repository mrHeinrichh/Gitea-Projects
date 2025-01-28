import 'package:jxim_client/api/disturb_user.dart' as disturb_api;
import 'package:jxim_client/object/other_user.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:events_widget/event_dispatcher.dart';

class DisturbMgr extends EventDispatcher {
  static const String eventUpdateDisturb = 'updateDisturb';
  List<OtherUser> _userList = [];

  List<OtherUser> get userList => _userList;
  set userList(List<OtherUser> data) {
    _userList = data;
    event(this, eventUpdateDisturb);
  }

  //获取免打扰列表
  Future query(String? lastId, int pageCount) async {
    var res = await disturb_api.queryDisturbList(lastId, pageCount);
    if (res.success) {
      if (lastId == null) {
        _userList.clear();
      }
      if (res.data["datas"].isEmpty) return;
      for (var item in res.data["datas"]) {
        OtherUser user = OtherUser();
        user.applyJson(item);
        userList.add(user);
      }
      _userList = userList;
      event(this, eventUpdateDisturb);
      return res.data;
    } else {
      Toast.showToast(res.msg, code: res.code);
    }
  }

}
