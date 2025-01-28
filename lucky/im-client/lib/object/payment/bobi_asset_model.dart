class BobiAssetModel {
  String? amount;
  int? updateTime;
  String? rechargeChannelID;
  String? bobNoticeUrl;

  BobiAssetModel({
    this.amount,
    this.updateTime,
    this.rechargeChannelID,
    this.bobNoticeUrl,
  });

  static BobiAssetModel fromJson(dynamic data) {
    return BobiAssetModel(
      amount: data['amount'],
      updateTime: data['updateTime'],
      rechargeChannelID: data['rechargeChannelID'],
      bobNoticeUrl: data['bobNoticeUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['updateTime'] = updateTime;
    data['rechargeChannelID'] = rechargeChannelID;
    data['bobNoticeUrl'] = bobNoticeUrl;
    return data;
  }
}
