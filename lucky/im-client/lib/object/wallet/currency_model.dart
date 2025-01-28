class CurrencyModel {
  double? amount;
  double? convertAmt;
  String? convertAmtCurrencyType;
  String? currencyName;
  String? currencyType;
  double? exRate;
  String? iconPath;

  String? netType;
  List? supportNetType;

  bool enableFlag;
  String? assetType;
  String? lastDayIn;

  CurrencyModel({
    this.amount,
    this.convertAmt,
    this.convertAmtCurrencyType,
    this.currencyName,
    this.currencyType,
    this.iconPath,
    this.exRate,
    this.netType,
    this.supportNetType,
    this.enableFlag = true,
    this.assetType,
    this.lastDayIn,
  });

  static CurrencyModel fromJson(dynamic data) {
    return CurrencyModel(
      amount: double.parse(data['amount'].toString()),
      convertAmt: double.parse(data['convertAmt']),
      convertAmtCurrencyType: data['convertAmtCurrencyType'],
      currencyName: data['currencyName'],
      currencyType: data['currencyType'],
      iconPath: data['iconPath'] ?? 'https://picsum.photos/200',
      exRate: double.parse(data['exRate'].toString()),
      netType: null,
      supportNetType: data['netTypes'] ?? [],
      enableFlag: data['enableFlag'] ?? false,
      assetType: data['assetType'],
      lastDayIn: data['lastDayIn'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['convertAmt'] = convertAmt;
    data['convertAmtCurrencyType'] = convertAmtCurrencyType;
    data['currencyName'] = currencyName;
    data['currencyType'] = currencyType;
    data['iconPath'] = iconPath;
    data['exRate'] = exRate;
    data['exRate'] = exRate;
    data['netTypes'] = supportNetType;
    data['enableFlag'] = enableFlag;
    data['assetType'] = assetType;
    data['lastDayIn'] = lastDayIn;
    return data;
  }
}

extension CurrencyUtils on CurrencyModel {
  int get getDecimalPoint {
    switch (this.currencyType) {
      case 'USDT':
      case 'ETH':
      case 'BTC':
      case 'BNB':
      case 'BUSD':
      case 'MATIC':
        return 2;
      case 'USDC':
      case 'XRP':
      case 'ADA':
        return 4;
      case 'DOGE':
        return 5;
      case 'TRX':
        return 5;
      default:
        return 2;
    }
  }
}

extension doubleFloor on double {
  String toDoubleFloor([int length = 2]) {
    if (length < 0) {
      throw AssertionError('cannot negative value');
    }
    String formattedNumber = this.toString();
    int decimalIndex = formattedNumber.indexOf('.');
    if (decimalIndex != -1) {
      if (decimalIndex + length + 1 < formattedNumber.length) {
        formattedNumber =
            formattedNumber.substring(0, decimalIndex + length + 1);
      } else {
        formattedNumber =
            formattedNumber.padRight(decimalIndex + length + 1, '0');
      }
    } else {
      formattedNumber += '.' + '0' * length;
    }
    return formattedNumber;
  }
}

extension stringUtils on String {
  int get getDecimalPoint {
    switch (this) {
      case 'USDT':
      case 'ETH':
      case 'BTC':
      case 'BNB':
      case 'BUSD':
      case 'MATIC':
        return 2;
      case 'USDC':
      case 'XRP':
      case 'ADA':
        return 4;
      case 'DOGE':
        return 5;
      case 'TRX':
        return 3;
      default:
        return 2;
    }
  }
}
