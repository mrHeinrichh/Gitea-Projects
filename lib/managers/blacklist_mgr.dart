import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:jxim_client/api/black_user.dart' as blacklist_api;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/object/other_user.dart';
import 'package:jxim_client/utils/toast.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

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
    var local = objectMgr.localStorageMgr.getLocalTable(localBlackList);
    if (local != null) {
      userList = local.map((e) => OtherUser()..applyJson(e)).toList();
    } else {}
  }

  int _controlTime = 0;

  Future remove(int blackId) async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_controlTime > nowTime) {
      Toast.showToast(localized(toastSystemBusy));
      return;
    }
    var body = await blacklist_api.removeNew(blackId);
    if (body != null) {
      List<OtherUser> blackList = _userList;
      blackList.removeWhere((element) => element.user.id == blackId);
      _controlTime = nowTime + 3;
      changeBlackState(false);
      objectMgr.localStorageMgr.putLocalTable(
        localBlackList,
        jsonEncode(blackList.map((e) => e.toJson()).toList()),
      );
      userList = blackList;
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
      List<OtherUser> blackList = _userList;
      blackList.add(user);
      objectMgr.localStorageMgr.putLocalTable(
        localBlackList,
        jsonEncode(blackList.map((e) => e.toJson()).toList()),
      );
      _controlTime = nowTime + 3;
      changeBlackState(true);
      userList = blackList;
    }
    return body;
  }

  bool isBlack(int userId) {
    for (var item in _userList) {
      if (item.user.id == userId) {
        return true;
      }
    }
    return false;
  }

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
    throw UnimplementedError();
  }
}
