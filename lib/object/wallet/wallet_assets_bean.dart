///用戶資產 model
class WalletAssets {
  final String? amount;
  final String? convertAmt;
  final String? convertAmtCurrencyType;
  final String? currencyName;
  final String? currencyType;
  final bool? enableFlag;
  final num? _exRate;
  final String? iconPath;
  final List? netTypes;

  WalletAssets({
    this.amount,
    this.convertAmt,
    this.convertAmtCurrencyType,
    this.currencyName,
    this.currencyType,
    this.enableFlag,
    required num exRate,
    this.iconPath,
    this.netTypes,
  }) : _exRate = exRate;

  double? get exRate => _exRate?.toDouble();

  factory WalletAssets.fromJson(Map<String, dynamic> json) {
    return WalletAssets(
      amount: json['amount'] ?? "",
      convertAmt: json['convertAmt'] ?? "",
      convertAmtCurrencyType: json['convertAmtCurrencyType'] ?? "",
      currencyName: json['currencyName'] ?? "",
      currencyType: json['currencyType'] ?? "",
      enableFlag: json['enableFlag'] ?? false,
      exRate: json['exRate'] ?? 0.0,
      iconPath: json['iconPath'] ?? "",
      netTypes: json['netTypes'] ?? [],
    );
  }
}

class WalletAssetsData {
  final String? totalAmt;
  final String? totalAmtCurrencyType;
  final int? updateTime;
  final List<WalletAssets> cryptoCurrencyInfos;
  final List<WalletAssets> legalCurrencyInfos;

  WalletAssetsData({
    required this.totalAmt,
    required this.totalAmtCurrencyType,
    required this.updateTime,
    required this.cryptoCurrencyInfos,
    required this.legalCurrencyInfos,
  });

  factory WalletAssetsData.fromJson(Map<String, dynamic> json) {
    var cryptoList = <WalletAssets>[];
    var legalList = <WalletAssets>[];
    if (json['cryptoCurrencyInfos'] != null) {
      json['cryptoCurrencyInfos'].forEach((v) {
        cryptoList.add(WalletAssets.fromJson(v));
      });
    }
    if (json['legalCurrencyInfos'] != null) {
      json['legalCurrencyInfos'].forEach((v) {
        legalList.add(WalletAssets.fromJson(v));
      });
    }
    return WalletAssetsData(
      totalAmt: json['totalAmt'] ?? "",
      totalAmtCurrencyType: json['totalAmtCurrencyType'] ?? "",
      updateTime: json['updateTime'] ?? 0,
      cryptoCurrencyInfos: cryptoList,
      legalCurrencyInfos: legalList,
    );
  }
}
