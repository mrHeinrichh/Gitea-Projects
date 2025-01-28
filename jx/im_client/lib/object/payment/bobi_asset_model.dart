class BobiAssetModel {
  String? amount;
  int? updateTime;
  String? rechargeChannelID;

  BobiAssetModel({
    this.amount,
    this.updateTime,
    this.rechargeChannelID,
  });

  static BobiAssetModel fromJson(dynamic data) {
    return BobiAssetModel(
      amount: data['amount'],
      updateTime: data['updateTime'],
      rechargeChannelID: data['rechargeChannelID'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['updateTime'] = updateTime;
    data['rechargeChannelID'] = rechargeChannelID;
    return data;
  }
}
