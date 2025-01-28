class RedPacketModel {
  String? amount;
  String? convertAmount;
  String? currencyType;
  int? chatID;
  String? rpType;
  int? rpNum;
  List<int>? recipientIDs;
  String? remark;
  String? passcode;
  Map<String,String>? tokenMap;

  static final RedPacketModel _redPacketModel = RedPacketModel._internal();

  factory RedPacketModel() {
    return _redPacketModel;
  }

  RedPacketModel._internal();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map ={
      'amount': amount,
      'currencyType': currencyType,
      'chatID': chatID,
      'rpType': rpType,
      'recipientIDs': recipientIDs,
      'rpNum': rpNum,
      'remark': remark,
      'passcode': passcode,
      ...?tokenMap,
    };
    return map;
  }
}
