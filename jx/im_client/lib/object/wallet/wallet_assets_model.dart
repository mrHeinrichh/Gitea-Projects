import 'package:jxim_client/object/wallet/currency_model.dart';

class WalletAssetsModel {
  double? totalAmt;
  String? totalAmtCurrencyType;
  List<CurrencyModel>? cryptoCurrencyInfo;
  List<CurrencyModel>? legalCurrencyInfo;
  DateTime? updateTime;

  WalletAssetsModel({
    this.totalAmt,
    this.totalAmtCurrencyType,
    this.cryptoCurrencyInfo,
    this.legalCurrencyInfo,
    this.updateTime,
  });

  static WalletAssetsModel fromJson(dynamic data) {
    return WalletAssetsModel(
      totalAmt: double.parse(data['totalAmt']),
      totalAmtCurrencyType: data['totalAmtCurrencyType'],
      cryptoCurrencyInfo: data['cryptoCurrencyInfos']
          .map<CurrencyModel>((e) => CurrencyModel.fromJson(e))
          .toList(),
      legalCurrencyInfo: data['legalCurrencyInfos']
          .map<CurrencyModel>((e) => CurrencyModel.fromJson(e))
          .toList(),
      updateTime: DateTime.fromMillisecondsSinceEpoch(data['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalAmt'] = totalAmt;
    data['totalAmtCurrencyType'] = totalAmtCurrencyType;
    data['cryptoCurrencyInfos'] =
        cryptoCurrencyInfo?.map((e) => e.toJson()).toList();
    data['legalCurrencyInfos'] =
        legalCurrencyInfo?.map((e) => e.toJson()).toList();
    data['updateTime'] = updateTime?.millisecondsSinceEpoch;
    return data;
  }
}
