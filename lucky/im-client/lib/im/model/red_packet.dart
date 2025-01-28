import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

// 判断 红包状态 -> 1 未领取 2 已领取 3 已过期 4 红包已领取完毕 5 不在专属红包里 6 未知错误
const int rpYetReceive = 1;
const int rpReceived = 2;
const int rpExpired = 3;
const int rpFullyClaimed = 4;
const int rpNotInExclusive = 5;
const int rpUnknownError = 6;

class RedPacketDetail {
  String? id;
  String? conversionCurrency;
  String? convertedAmt;
  String? currencyType;
  String? receiveAmt;
  List<ReceiveInfo> receiveInfos = [];
  int? receiveNum;
  RedPacketType rpType = RedPacketType.none;
  String? totalAmt;
  int? totalNum;
  int? userID;

  RedPacketDetail();

  RedPacketDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    conversionCurrency = json['conversionCurrency'];
    convertedAmt = json['convertedAmt'];
    currencyType = json['currencyType'];
    receiveAmt = json['receiveAmt'];
    if (json.containsKey('receiveInfos') && json['receiveInfos'] != null) {
      receiveInfos = json['receiveInfos']
          .map<ReceiveInfo>((dynamic e) => ReceiveInfo.fromJson(e))
          .toList();
    }
    receiveNum = json['receiveNum'];
    if (json['rpType'] == 'LUCKY_RP') {
      rpType = RedPacketType.luckyRedPacket;
    } else if (json['rpType'] == 'STANDARD_RP') {
      rpType = RedPacketType.normalRedPacket;
    } else {
      rpType = RedPacketType.exclusiveRedPacket;
    }

    totalAmt = json['totalAmt'];
    totalNum = json['totalNum'];
    userID = json['userID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['conversionCurrency'] = conversionCurrency;
    data['convertedAmt'] = convertedAmt;
    data['currencyType'] = currencyType;
    data['receiveAmt'] = receiveAmt;
    data['receiveInfos'] = receiveInfos;
    data['receiveNum'] = receiveNum;
    data['rpType'] = rpType.value;
    data['totalAmt'] = totalAmt;
    data['totalNum'] = totalNum;
    data['userID'] = userID;
    return data;
  }
}

class ReceiveInfo {
  int? userId;
  String? uuid;
  String? amount;
  int? receiveTime;
  bool? receiveFlag;
  String? convertedAmount;

  ReceiveInfo();

  ReceiveInfo.fromJson(Map<String, dynamic> json) {
    userId = json['userID'];
    uuid = json['uuid'];
    amount = json['amount'];
    receiveTime = json['receiveTime'];
    receiveFlag = json['receiveFlag'];
    convertedAmount = json['convertedAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['uuid'] = uuid;
    data['amount'] = amount;
    data['receiveTime'] = receiveTime;
    data['receiveFlag'] = receiveFlag;
    data['convertedAmount'] = convertedAmount;
    return data;
  }
}

class RedPacketStatus {
  String? id;
  int? messageId;
  int? chatId;
  int? userId;
  int? status;

  RedPacketStatus();

  RedPacketStatus.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    messageId = json['message_id'];
    chatId = json['chat_id'];
    userId = json['user_id'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['message_id'] = messageId;
    data['chat_id'] = chatId;
    data['user_id'] = userId;
    data['status'] = status;
    return data;
  }
}

enum RedPacketType {
  luckyRedPacket(
      'LUCKY_RP',
      // 'Lucky Red Packet',
      'red_packet_lucky_detail_bg',
      const Color(0xFFFFDFAE),
      const Color(0xFF613200)),
  normalRedPacket(
    'STANDARD_RP',
    // 'Normal Red Packet',
    'red_packet_standard_detail_bg',
    const Color(0xFFEE4A4C),
    const Color(0xFFFFFFFF),
  ),
  exclusiveRedPacket(
    'SPECIFIED_RP',
    // 'Exclusive Red Packet',
    'red_packet_specified_detail_bg',
    const Color(0xFFFCD36B),
    const Color(0xFF613200),
  ),
  none(
    '',
    // 'None',
    '',
    const Color(0xFF000000),
    const Color(0xFF000000),
  );

  final String value;
  final String leaderboardBg;
  final Color bgColor;
  final Color titleColor;

  const RedPacketType(
    this.value,
    // this.name,
    this.leaderboardBg,
    this.bgColor,
    this.titleColor,
  );
}

extension RedPacketName on String {
  RedPacketType get toRpType {
    switch (this) {
      case 'LUCKY_RP':
        return RedPacketType.luckyRedPacket;
      case 'STANDARD_RP':
        return RedPacketType.normalRedPacket;
      case 'SPECIFIED_RP':
        return RedPacketType.exclusiveRedPacket;
      default:
        return RedPacketType.none;
    }
  }

  String get redPacketName {
    switch (this) {
      case 'luckyRedPacket':
        return localized(luckyRedPacket);
      case 'exclusiveRedPacket':
        return localized(exclusiveRedPacket);
      case 'normalRedPacket':
        return localized(normalRedPacket);
      default:
        return localized(none);
    }
  }
}

extension redPacketColorUtils on RedPacketType {
  Color get appBarColor {
    switch (this) {
      case RedPacketType.luckyRedPacket:
        return redPacketLuckyColor;
      case RedPacketType.normalRedPacket:
        return redPacketNormalColor;
      case RedPacketType.exclusiveRedPacket:
        return redPacketExclusiveColor;
      case RedPacketType.none:
        return JXColors.white;
      default:
        return JXColors.white;
    }
  }
}

class RedPacketTheme {
  final String redPacketCover;
  final String redPacketOpen;
  final Color topFoldBackground;
  final Color bottomFoldBackground;
  final List<Color> bodyBackground;
  final Color paperBackground;

  const RedPacketTheme(
    this.redPacketCover,
    this.redPacketOpen,
    this.topFoldBackground,
    this.bottomFoldBackground,
    this.bodyBackground,
    this.paperBackground,
  );
}
