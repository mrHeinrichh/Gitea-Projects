class AddressModel {
  String addrName;
  String addrID;
  String address;
  String currencyType;
  String netType;
  String rechargeAmt;
  int rechargeNum;

  AddressModel({
    required this.addrName,
    required this.addrID,
    required this.address,
    required this.currencyType,
    required this.netType,
    required this.rechargeAmt,
    required this.rechargeNum,
  });

  AddressModel.create({
    this.address = '',
    this.addrName = '',
    this.currencyType = '',
    this.netType = '',
    this.rechargeNum = 0,
    this.rechargeAmt = '',
    this.addrID = '',
  });

  static AddressModel fromJson(dynamic data) {
    return AddressModel(
      addrName: data['addrName'],
      addrID: data['addrID'],
      address: data['address'],
      currencyType: data['currencyType'],
      netType: data['netType'],
      rechargeAmt: data['rechargeAmt'] ?? "",
      rechargeNum: data['rechargeNum'] ?? 0,
    );
  }
}
