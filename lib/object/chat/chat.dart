// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';

// -- 会话类型
const chatTypeSingle = 1; // -- 单聊
const chatTypeGroup = 2; // -- 群聊
const chatTypeSaved = 3; // -- 收藏
const chatTypeSystem = 4; // -- 系统
const chatTypePostNotify = 5; // -- 动态通知

const chatTypeSmallSecretary = 9; // -- 小秘书

enum ChatEncryptionFlag {
  encrypted(1),
  previouslyEncrypted(2); //曾经加密,

  final int value;

  const ChatEncryptionFlag(this.value);
}


enum ChatStatus {
  MyChatFlagJoined(0),
  MyChatFlagAt(1),
  MyChatFlagFocus(2),
  MyChatFlagFollow(4),
  MyChatFlagMute(8),
  MyChatFlagKicked(16),
  MyChatFlagDisband(32),
  MyChatFlagHide(64),
  MyChatFlagDelete(128),
  MyChatFlagScreenshot(256);

  final int value;

  const ChatStatus(this.value);

  static String getEventName(int value) {
    switch (value) {
      case 0:
        return ChatMgr.eventChatJoined;
      case 16:
        return ChatMgr.eventChatKicked;
      case 64:
        return ChatMgr.eventChatHide;
      default:
        return ChatMgr.eventChatJoined;
    }
  }
}

/// 会话
class Chat extends RowObject with EventDispatcher {
  int get chat_id => getValue('chat_id', 0);

  set chat_id(int v) => setValue('chat_id', v);

  int get parent_id => getValue('parent_id', 0);

  int get typ => getValue('typ', 0);

  //其他人已读至哪条消息
  int get other_read_idx => getValue('other_read_idx', 0);

  set other_read_idx(int v) => setValue('other_read_idx', v);

  //最后更新chat的时间
  int get last_time => getValue('last_time', 0);

  set last_time(int v) => setValue('last_time', v);

  //最后信息类型
  int get last_typ => getValue('last_typ', 0);

  int get msg_idx => getValue('msg_idx', 0);

  set msg_idx(int v) => setValue('msg_idx', v);

  List<Message> get pin => getValue('pin', <Message>[]);

  set pin(List<Message> v) => setValue('pin', v);

  //是否有人@我 0无 1有
  int get at_flag => flag_my & 1;

  //特别关注发言 0无 1有
  int get focus_msg => flag_my & 2;

  //特别关注 0无 1有
  int get follow_flag => flag_my & 4;

  bool get isMute => checkIsMute(mute);

  //单聊->被删除好友
  //群聊->退出群组
  bool get isKick =>
      flag_my & ChatStatus.MyChatFlagKicked.value ==
      ChatStatus.MyChatFlagKicked.value;

  bool get isDisband =>
      flag_my & ChatStatus.MyChatFlagDisband.value ==
      ChatStatus.MyChatFlagDisband.value;

  bool get isCountUnread =>
      !isMute && isVisible && typ != chatTypePostNotify && !isDisband;

  // 查询拼接字段
  String get icon => getValue('icon', '');

  set icon(String v) => setValue('icon', v);

  String iconByAsset = '';

  String get name => getValue('name', '');

  set name(String v) => setValue('name', v);

  String get profile => getValue('profile', '');

  set profile(String v) => setValue('profile', v);

  int get userId => getValue('user_id', 0);

  set userId(int v) => setValue('user_id', v);

  //聊天置顶
  int get sort => getValue('sort', 0);

  //消息免打扰
  int get mute => getValue('mute', 0);

  set mute(int v) => setValue('mute', v);

  //特别关注
  int get follow => getValue('follow', 0);

  int get flag_my => getValue('flag_my', 0);

  set flag_my(int v) => setValue('flag_my', v);

  int get flag => getValue('flag', 0);

  set flag(int v) => setValue('flag', v);

  int get verified => getValue('verified', 0);

  set verified(int v) => setValue('verified', v);

  int get unread_num => getValue('unread_num', 0);

  set unread_num(int v) => setValue('unread_num', v);

  int get unread_count => getValue('unread_count', 0);

  set unread_count(int v) => setValue('unread_count', v);

  int get hide_chat_msg_idx => getValue('hide_chat_msg_idx', 0);

  int get read_chat_msg_idx => getValue('read_chat_msg_idx', 0);

  set read_chat_msg_idx(int v) => setValue('read_chat_msg_idx', v);

  int get delete_time => getValue('delete_time', 0);

  set delete_time(int v) => setValue('delete_time', v);

  int get friend_id => getValue('friend_id', 0);

  int get autoDeleteInterval => getValue('auto_delete_interval', 0);

  set autoDeleteInterval(int v) => setValue('auto_delete_interval', v);

  int get create_time => getValue('create_time', 0);

  set create_time(int v) => setValue('create_time', v);

  int get start_idx => getValue('start_idx', 0);

  set start_idx(int v) => setValue('start_idx', v);

  int get last_pos => getValue('last_pos', 0);

  set last_pos(int v) => setValue('last_pos', v);

  int get first_pos => getValue('first_pos', -1);

  set first_pos(int v) => setValue('first_pos', v);

  String get chat_key => getValue('chat_key', '');

  set chat_key(String v) => setValue('chat_key', v);

  /// 翻译相关
  /// {
  //       'currentLocale': 'EN',
  //       'isAuto': false,
  //       'visualType': 0,
  //  }
  String get translate_outgoing => getValue('translate_outgoing', '');

  set translate_outgoing(String v) => setValue('translate_outgoing', v);

  String get translate_incoming => getValue('translate_incoming', '');

  set translate_incoming(String v) => setValue('translate_incoming', v);

  int get outgoing_idx => getValue("outgoing_idx", 0);

  set outgoing_idx(int v) => setValue('outgoing_idx', v);

  int get incoming_idx => getValue("incoming_idx", 0);

  set incoming_idx(int v) => setValue('incoming_idx', v);

  int get incoming_sound_id => getValue('incoming_sound_id', 0);

  set incoming_sound_id(int v) => setValue('incoming_sound_id', v);

  int get outgoing_sound_id => getValue('outgoing_sound_id', 0);

  set outgoing_sound_id(int v) => setValue('outgoing_sound_id', v);

  int get notification_sound_id => getValue('notification_sound_id', 0);

  set notification_sound_id(int v) => setValue('notification_sound_id', v);

  bool get screenshotEnabled =>
      flag_my & ChatStatus.MyChatFlagScreenshot.value == 0 ? false : true;

  bool get autoDeleteEnabled => autoDeleteInterval > 0;

  /// 是否私聊
  bool get isSingle => typ == chatTypeSingle;

  /// 是否群聊
  bool get isGroup => typ == chatTypeGroup;

  /// 是否系统信息
  bool get isSystem => typ == chatTypeSystem;

  /// 是否动态通知
  bool get isPostNotify => typ == chatTypePostNotify;

  /// 是否收藏信息
  bool get isSaveMsg => typ == chatTypeSaved;

  /// 是否是小秘书
  bool get isSecretary => typ == chatTypeSmallSecretary;

  /// 是否是加密聊天室
  bool get isEncrypted => (flag & ChatEncryptionFlag.encrypted.value) == ChatEncryptionFlag.encrypted.value;

  /// 是否是特殊聊天室
  bool get isSpecialChat =>
      typ == chatTypeSmallSecretary ||
      typ == chatTypeSystem ||
      typ == chatTypeSaved;

  /// 是否能互动的
  bool get isValid =>
      (flag_my &
          (ChatStatus.MyChatFlagKicked.value |
              ChatStatus.MyChatFlagDisband.value)) ==
      0;

  /// 是否可见
  bool get isVisible =>
      delete_time <= last_time &&
      (typ != 0) &&
      (flag_my & ChatStatus.MyChatFlagHide.value) == 0;

  /// 是否可见
  bool get isDeleteAccount => isChatDeleteAccount(typ, friend_id);

  bool isChatDeleteAccount(int type, int uid) {
    if (type == chatTypeSingle) {
      User? user = objectMgr.userMgr.getUserById(friend_id);
      if (user != null && user.deletedAt > 0) {
        return true;
      }
    }
    return false;
  }

  /// 消息是否可见
  bool isMsgVisible(Message msg) {
    if (msg.message_id == 0 && msg.isHideShow) {
      return true; //清空后刚发的消息模拟是可见的
    }
    return msg.chat_idx > hide_chat_msg_idx;
  }

  /// 消息是否可见最后一条
  bool isLastVisibleMsg(Message msg) {
    return (msg.chat_idx == 1 || msg.chat_idx == hide_chat_msg_idx + 1);
  }

  final enableAudioChat = RxBool(false);

  Map<String, dynamic> get translateOutgoingMap =>
      translate_outgoing.isNotEmpty ? jsonDecode(translate_outgoing) : {};

  set translateOutgoingMap(Map<String, dynamic> newTranslation) {
    translate_outgoing = jsonEncode(newTranslation);
  }

  Map<String, dynamic> get translateIncomingMap =>
      translate_incoming.isNotEmpty ? jsonDecode(translate_incoming) : {};

  set translateIncomingMap(Map<String, dynamic> newTranslation) {
    translate_incoming = jsonEncode(newTranslation);
  }

  bool get isAutoTranslateOutgoing => translateOutgoingMap['isAuto'] ?? false;

  set isAutoTranslateOutgoing(bool value) {
    Map<String, dynamic> res = translateOutgoingMap;
    res['isAuto'] = value;
    translateOutgoingMap = res;
  }

  String get currentLocaleOutgoing =>
      translateOutgoingMap['currentLocale'] ?? LanguageOption.auto.value;

  set currentLocaleOutgoing(String locale) {
    Map<String, dynamic> res = translateOutgoingMap;
    res['currentLocale'] = locale;
    translateOutgoingMap = res;
  }

  bool get isAutoTranslateIncoming => translateIncomingMap['isAuto'] ?? false;

  set isAutoTranslateIncoming(bool value) {
    Map<String, dynamic> res = translateIncomingMap;
    res['isAuto'] = value;
    translateIncomingMap = res;
  }

  String get currentLocaleIncoming =>
      translateIncomingMap['currentLocale'] ?? LanguageOption.auto.value;

  set currentLocaleIncoming(String locale) {
    Map<String, dynamic> res = translateIncomingMap;
    res['currentLocale'] = locale;
    translateIncomingMap = res;
  }

  /// 0: 原文+译文, 1: 译文
  int get visualTypeOutgoing => translateOutgoingMap['visualType'] ?? 0;

  set visualTypeOutgoing(int value) {
    Map<String, dynamic> res = translateOutgoingMap;
    res['visualType'] = value;
    translateOutgoingMap = res;
  }

  /// 0: 原文+译文, 1: 译文
  int get visualTypeIncoming => translateIncomingMap['visualType'] ?? 0;

  set visualTypeIncoming(int value) {
    Map<String, dynamic> res = translateIncomingMap;
    res['visualType'] = value;
    translateIncomingMap = res;
  }

  bool get isTmpGroup => isGroup && verified == GroupType.TMP.num;

  bool get showMessageReadIcon => isSingle || isGroup || isTmpGroup;

  @override
  init(Map<String, dynamic> json) {
    // 合并模式: 将老对象不存在的key复制到json中,然后盖上
    for (int i = 0; i < json.length; i++) {
      final key = json.keys.toList()[i];
      final value = json[key];
      if (key == 'pin') {
        if (value is String) {
          final tempV = jsonDecode(value);
          if (tempV is! List<Message>) {
            setValue(
              key,
              tempV.map<Message>((e) => Message()..init(e)).toList(),
            );
          } else {
            setValue(key, tempV);
          }
        }
        continue;
      }

      if (value != null) {
        setValue(key, value);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "typ": typ,
      "msg_idx": msg_idx,
      "profile": profile,
      "pin": jsonEncode(pin).toString(),
      "name": name,
      "chat_key":chat_key,
      "user_id": userId,
      "chat_id": chat_id,
      "friend_id": friend_id,
      "delete_time": delete_time,
      "sort": sort,
      "unread_num": unread_num,
      "hide_chat_msg_idx": hide_chat_msg_idx,
      "read_chat_msg_idx": read_chat_msg_idx,
      "other_read_idx": other_read_idx,
      "flag_my": flag_my,
      "flag": flag,
      "verified": verified,
      "auto_delete_interval": autoDeleteInterval,
      "mute": mute,
      "translate_incoming": translate_incoming,
      "translate_outgoing": translate_outgoing,
    };
  }

  static Chat creator() {
    return Chat();
  }

  ///Desktop Version ====================================================
  bool isSelected = false;

  readMessage(int maxIdx) async {
    if (maxIdx <= read_chat_msg_idx) return;
    if (objectMgr.appLifecycleState == null ||
        objectMgr.appLifecycleState == AppLifecycleState.inactive ||
        objectMgr.appLifecycleState == AppLifecycleState.resumed) {
      if (objectMgr.loginMgr.isMobile) {
        String currentRoute = Get.currentRoute;
        if (currentRoute.contains(id.toString()) ||
            currentRoute == RouteName.home) {
          objectMgr.chatMgr.updateChatAfterSetRead(id, maxIdx);
        }
      } else if (objectMgr.loginMgr.isDesktop) {
        const MethodChannel methodChannel = MethodChannel('desktopAction');
        bool windowFocused =
            await methodChannel.invokeMethod('checkWindowFocus');
        if (windowFocused) {
          objectMgr.chatMgr.updateChatAfterSetRead(id, maxIdx);
        }
      }
    }
  }
}
