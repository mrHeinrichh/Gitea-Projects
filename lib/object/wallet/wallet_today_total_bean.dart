/// 二次验证，已使用额度
class WalletTodayTotalSettingBean {
  String? amount;
  String? currencyType;

  WalletTodayTotalSettingBean({this.amount, this.currencyType});

  WalletTodayTotalSettingBean.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    currencyType = json['currencyType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['currencyType'] = currencyType;
    return data;
  }
}
