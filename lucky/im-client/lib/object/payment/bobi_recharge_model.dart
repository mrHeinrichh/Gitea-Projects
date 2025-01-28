class BobiRechargeModel {
  String? txID;
  String? payUrl;

  BobiRechargeModel({
    this.txID,
    this.payUrl,
  });

  static BobiRechargeModel fromJson(dynamic data) {
    return BobiRechargeModel(
      txID: data['txID'],
      payUrl: data['payUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['txID'] = txID;
    data['payUrl'] = payUrl;
    return data;
  }
}
