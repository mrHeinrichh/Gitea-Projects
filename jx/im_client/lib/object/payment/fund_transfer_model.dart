class FundTransferModel {
  String? txID;

  FundTransferModel({
    this.txID,
  });

  static FundTransferModel fromJson(dynamic data) {
    return FundTransferModel(
      txID: data['txID'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['txID'] = txID;
    return data;
  }
}
