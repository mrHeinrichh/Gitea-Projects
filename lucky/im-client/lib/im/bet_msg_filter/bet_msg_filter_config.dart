import 'dart:convert';

/// showAllBettingMsgTime : {}
/// filterBetMsg : {}

BetMsgFilterConfig betMsgFilterConfigFromJson(String str) =>
    BetMsgFilterConfig.fromJson(json.decode(str));

String betMsgFilterConfigToJson(BetMsgFilterConfig data) =>
    json.encode(data.toJson());

class BetMsgFilterConfig {
  /// showAllBettingMsgTime: show showAllBettingMsgTime time
  ///
  /// filterBetMsg: filter bet message, key is bet message type, value is filter time
  BetMsgFilterConfig({
    int? showAllBettingMsgTime,
    Map<int, int>? filterBetMsg,
  }) {
    _showAllBettingMsgTime = showAllBettingMsgTime;
    _filterBetMsg = filterBetMsg;
  }

  BetMsgFilterConfig.fromJson(Map<String, dynamic> json) {
    _showAllBettingMsgTime = json['showAllBettingMsgTime'];
    final filterBetMsgMap = json['filterBetMsg'];
    if (filterBetMsgMap != null) {
      final filterBetMsg = <int, int>{};
      filterBetMsgMap.forEach((key, value) {
        filterBetMsg[int.parse(key)] = value;
      });
      _filterBetMsg = filterBetMsg;
    }
  }

  int? _showAllBettingMsgTime;

  Map<int, int>? _filterBetMsg;

  BetMsgFilterConfig copyWith({
    int? showAllBettingMsgTime,
    Map<int, int>? filterBetMsg,
  }) =>
      BetMsgFilterConfig(
        showAllBettingMsgTime: showAllBettingMsgTime ?? _showAllBettingMsgTime,
        filterBetMsg: filterBetMsg ?? _filterBetMsg,
      );

  int? get showAllBettingMsgTime => _showAllBettingMsgTime;

  Map<int, int>? get filterBetMsg => _filterBetMsg;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_showAllBettingMsgTime != null) {
      map['showAllBettingMsgTime'] = _showAllBettingMsgTime;
    }
    if (_filterBetMsg != null) {
      final filterBetMsgMap = {};
      _filterBetMsg?.forEach((key, value) {
        filterBetMsgMap[key.toString()] = value;
      });
      map['filterBetMsg'] = filterBetMsgMap;
    }
    return map;
  }
}
