class WalletTransferModel {
  String? txID;
  bool? phoneVcodeSend;
  bool? emailVcodeSend;

  WalletTransferModel({
    this.txID,
    this.phoneVcodeSend,
    this.emailVcodeSend,
  });

  static WalletTransferModel fromJson(dynamic data) {
    return WalletTransferModel(
      txID: data['txID'],
      phoneVcodeSend: data['phoneVcodeSend'],
      emailVcodeSend: data['emailVcodeSend'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['txID'] = txID;
    data['phoneVcodeSend'] = phoneVcodeSend;
    data['emailVcodeSend'] = emailVcodeSend;
    return data;
  }
}
