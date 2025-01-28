import 'dart:io';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/share_user.dart';

class CustomerDispatcher extends EventDispatcher {
  static const String eventRecordIndex = 'record_index';
  static const String eventShowEnter = 'show_enter';

  static const String eventEditWithdraw = 'edit_withdraw'; //编辑撤回

  static const String eventShowGroupActivte = 'eventShowGroupActivte';

  static const String eventShowTranslation = 'eventShowTranslation';

  CustomerDispatcher.init() {}

  final TextEditingController textEditingController = TextEditingController();

  int textSession = 0;

  String emptyNoSeeStr = "\u200B";

  bool haveEmoji = false;

  int liveUpdateTime = 0;

  int _withdrawMessageId = 0;

  int get withdrawMessageId => _withdrawMessageId;

  set withdrawMessageId(int value) {
    _withdrawMessageId = value;
    event(this, eventEditWithdraw);
  }

  void updateWithdrawMessage() => event(this, eventEditWithdraw);

  Chat? mChat;

  List<ShareUser> chooseUsers = [];

  ShareUser? checkShareUser(int userId) {
    for (var item in chooseUsers) {
      if (item.userId == userId) {
        return item;
      }
    }
    return null;
  }

  bool canJoinUser(int userId) {
    for (var item in chooseUsers) {
      if (item.userId == userId) {
        return false;
      }
    }
    return true;
  }

  var userPage = 1;

  ///排行榜
  int weekRank = -1;
  int monthRank = -1;

  showActiveAlert() {
    event(this, eventShowGroupActivte);
  }

  double bodyHeight = 0.0;

  /// 更新翻译列表改动
  void updateTranslationId() =>
      objectMgr.chatMgr.event(this, eventShowTranslation);

  //============操作============

  onInputDelete() {
    String _str = textEditingController.text.substring(0, textSession);
    if (_str.isEmpty) {
      return;
    }
    String _lessStr = textEditingController.text
        .substring(textSession, textEditingController.text.length);
    String _newStr = '';
    int index = 0;
    int subCount = 1;
    bool _needBu = false;
    if (Platform.isIOS) {
      //如果最后一个字符是不可见字符
      int len = _str.length;
      String lastStr = _str.substring(len - 1, len);
      if (lastStr == emptyNoSeeStr)
        subCount = 2;
      else
        _needBu = _newStr.indexOf(emptyNoSeeStr) < 0;
    }
    _str.runes.forEach((element) {
      var _byte = String.fromCharCode(element);
      if (index < _str.runes.length - subCount) {
        _newStr += _byte;
      }
      index++;
    });
    if (Platform.isIOS && _needBu && _newStr.length > 0) {
      _newStr += emptyNoSeeStr;
    }
    textSession = _newStr.length;
    textEditingController.text = _newStr + _lessStr;
  }
}
