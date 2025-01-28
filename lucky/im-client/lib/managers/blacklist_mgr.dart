import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:jxim_client/api/black_user.dart' as blacklist_api;
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/object/other_user.dart';
import 'package:jxim_client/utils/toast.dart';

import '../utils/lang_util.dart';
import '../utils/localization/app_localizations.dart';

const String localBlackList = 'local_black_list';

class BlackListMgr extends EventDispatcher
    implements TemplateMgrInterface, MgrInterface {
  @override
  Future<void> register() async {
    registerModel();
  }

  @override
  Future<void> registerModel() async {}

  @override
  Future<void> init() async {
    getBlackListByLocal();
  }

  @override
  Future<void> logout() async {
    _userList.clear();
  }

  static const String eventUpdateBlackList = 'updateBlackList';

  List<OtherUser> _userList = [];

  List<OtherUser> get userList => _userList;

  set userList(List<OtherUser> data) {
    _userList = data;
    event(this, eventUpdateBlackList);
  }

  getBlackListByLocal() {
    var _local = objectMgr.localStorageMgr.getLocalTable(localBlackList);
    if (_local != null) {
      userList = _local.map((e) => OtherUser()..applyJson(e)).toList();
    } else {
      // query(0, 100000);
    }
  }

  // int _time = 0;
  //获取黑名单列表
  // Future query(int page, int pageCount) async {
  //   int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  //   if (_time > nowTime) {
  //     return;
  //   }
  //   var res = await blacklist_api.queryBlackListNew();
  //   if (res != null) {
  //     debugPrint("Successfully retrieved");
  //     // userList = res.users!.map((e) => OtherUser()..applyJson(e)).toList();
  //     userList = res.dummyData["datas"]!
  //         .map<OtherUser>((e) => OtherUser()..applyJson(e))
  //         .toList();
  //     objectMgr.localStorageMgr
  //         // .putLocalTable(localBlackList, jsonEncode(res.users), true);
  //         .putLocalTable(
  //             localBlackList, jsonEncode(res.dummyData["datas"]), true);
  //     _time = nowTime + 60;
  //     // return res.users!.length;
  //     return res.dummyData["datas"]!.length;
  //   } else {
  //     Toast.showToast("Retrieve black list failed");
  //   }
  // }

  int _controlTime = 0;

  //移除黑名单
  Future remove(int blackId) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_controlTime > nowTime) {
      Toast.showToast(localized(toastSystemBusy));
      return;
    }
    var body = await blacklist_api.removeNew(blackId);
    if (body != null) {
      List<OtherUser> _blackList = _userList;
      _blackList.removeWhere((element) => element.user.id == blackId);
      _controlTime = nowTime + 3;
      changeBlackState(false);
      objectMgr.localStorageMgr.putLocalTable(localBlackList,
          jsonEncode(_blackList.map((e) => e.toJson()).toList()));
      userList = _blackList;
    } else {
      Toast.showToast(localized(errorRemoveBlackListFailed));
    }
  }

  changeBlackState(bool state) {
    if (state) {
      Toast.showToast(localized(toastAddedBlackList));
    } else {
      Toast.showToast(localized(toastRemovedBlackList));
    }
  }

  //加入黑名单
  Future add(int blackId) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_controlTime > nowTime) {
      Toast.showToast(localized(toastSystemBusy));
      return;
    }
    var body = await blacklist_api.createNew(blackId);
    if (body != null) {
      debugPrint("User added to black list successfully");
      OtherUser user = OtherUser();
      user.applyJson(body.dummyData["data"]);
      List<OtherUser> _blackList = _userList;
      _blackList.add(user);
      objectMgr.localStorageMgr.putLocalTable(localBlackList,
          jsonEncode(_blackList.map((e) => e.toJson()).toList()));
      _controlTime = nowTime + 3;
      changeBlackState(true);
      userList = _blackList;
    }
    return body;
  }

  //判断是否被拉黑
  bool isBlack(int userId) {
    for (var item in _userList) {
      if (item.user.id == userId) {
        return true;
      }
    }
    return false;
  }

  //是否显示拉黑消息提醒
  bool isBlackMessage(int userId, int messageTime) {
    for (var item in _userList) {
      if (item.user.id == userId && messageTime > item.createTime) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> reloadData() {
    // TODO: implement reloadData
    throw UnimplementedError();
  }
}
