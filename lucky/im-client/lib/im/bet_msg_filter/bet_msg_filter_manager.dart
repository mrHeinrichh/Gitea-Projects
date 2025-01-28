import 'dart:convert';

import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/bet_msg_filter/bet_msg_filter_config.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

final betMsgFilterMgr = MsgFilterManager();

class MsgFilterManager {
  static final MsgFilterManager _instance = MsgFilterManager._internal();

  factory MsgFilterManager() => _instance;

  MsgFilterManager._internal() {
    validMsgByMsgId = (int groupId, int msgId) {
      return isValidMsgByMsgId(groupId: groupId, messageId: msgId);
    };
  }

  late final SharedPreferences _sp;
  late final Map<int, BetMsgFilterConfig> _groupConfigs;

  Future<void> init() async {
    _groupConfigs = {};
    _sp = await SharedPreferences.getInstance();
  }

  void clean() {
    _groupConfigs.clear();
    _sp.clear();
  }

  String _genKey(int groupId) => "key_msg_filter_gid_$groupId";

  BetMsgFilterConfig getGroupConfig({required int groupId}) {
    final config = _groupConfigs[groupId];

    if (config != null) return config;


    final configFromSp = _getGroupConfigFromSp(groupId: groupId);
    _groupConfigs[groupId] = configFromSp;

    return configFromSp;
  }

  BetMsgFilterConfig _getGroupConfigFromSp({required int groupId}) {
    final key = _genKey(groupId);
    final configString = _sp.getString(key);

    if (configString == null) return BetMsgFilterConfig();

    final config = betMsgFilterConfigFromJson(configString);
    return config;
  }

  Future<void> setGroupConfig({
    required int groupId,
    required BetMsgFilterConfig config,
  }) async {
    _groupConfigs[groupId] = config;
    await _setGroupConfigToSp(groupId: groupId, config: config);
  }

  Future<void> _setGroupConfigToSp({
    required int groupId,
    required BetMsgFilterConfig config,
  }) async {
    final key = _genKey(groupId);
    // final configJson = config.toJson();
    // print("TAG_BMFM, configJson: $configJson");
    // final configJsonEncode = json.encode(configJson);
    // print("TAG_BMFM, configJsonEncode: $configJsonEncode");
    final configString = betMsgFilterConfigToJson(config);
    await _sp.setString(key, configString);
  }

  bool isValidMsg({
    required int groupId,
    required Message msg,
  }) {
    final isBetMsg = messageBetTypes.contains(msg.typ);
    if (!isBetMsg) {
      return true;
    }

    final config = getGroupConfig(groupId: groupId);

    final isFilterBetMsg = _isFilterBetMsg(msg, config.filterBetMsg);
    if (isFilterBetMsg) return false;

    final showAllBettingMsgTime = config.showAllBettingMsgTime;
    if (showAllBettingMsgTime != null) {
      return true;
      final shouldShow = msg.create_time > showAllBettingMsgTime;

      if (shouldShow) return true;
    } else {
      final isPrimaryGameMsg = _isPrimaryGameMsg(msg);

      return isPrimaryGameMsg;
    }

    return true;
  }

  bool _isFilterBetMsg(Message msg, Map<int, int>? filterBetMsg) {
    if (filterBetMsg == null) return false;

    final filterTime = filterBetMsg[msg.typ];

    // 20001,自己发的消息不屏蔽
    bool isMe = objectMgr.userMgr.isMe(msg.send_id);
    if (msg.typ == 20001 && isMe) return false;

    if (filterTime == null) return false;
    return true;
    // print("TAG_BMFM, msg.create_time: ${msg.create_time}, filterTime: $filterTime");
    return msg.create_time > filterTime;
  }

  bool _isPrimaryGameMsg(Message msg) {
    final content = msg.content;
    Map<String, dynamic> map = {};
    try {
      map = jsonDecode(content);
    } catch (e) {
      return false;
    }
    final msgGameId = map[ImConstants.gameId];
    final defaultGameId = sharedDataManager.groupLocalData?.defaultGameId;

    if (defaultGameId == null) return false;

    final result = msgGameId == defaultGameId;
    // print("TAG_BMFM, _isPrimaryGameMsg, result: $result, message.typ: ${msg.typ}, msgGameId: $msgGameId, defaultGameId: $defaultGameId");
    bool isMe = objectMgr.userMgr.isMe(msg.send_id);
    if(isMe){
      return true;
    }
    return result;
  }

  bool isValidMsgByMsgId({
    required int groupId,
    required int messageId,
  }) {
    final isBetMsg = messageBetTypes.contains(messageId);
    // print("TAG_D_BMFM, isValidMsgByMsgId, groupId: $groupId, messageId: $messageId");
    // print("TAG_D_BMFM, isValidMsgByMsgId, messageBetTypes: $messageBetTypes");
    // print("TAG_D_BMFM, isValidMsgByMsgId, isBetMsg: $isBetMsg");

    if (!isBetMsg) {
      return true;
    }

    final config = getGroupConfig(groupId: groupId);
    // print("TAG_D_BMFM, isValidMsgByMsgId, config: ${config.toJson()}");

    final showAllBettingMsgTime = config.showAllBettingMsgTime;
    // print("TAG_D_BMFM, isValidMsgByMsgId, showAllBettingMsgTime: $showAllBettingMsgTime");

    if (showAllBettingMsgTime != null) {
      return true;
    } else {
      // print("TAG_D_BMFM, isValidMsgByMsgId, config.filterBetMsg: ${config.filterBetMsg}");
      final isFilterMsg = config.filterBetMsg?.keys.contains(messageId) ?? false;
      // print("TAG_D_BMFM, isValidMsgByMsgId, isFilterMsg: $isFilterMsg");

      return isFilterMsg == false;
    }
  }
}
