import 'package:jxim_client/object/wallet/currency_model.dart';

class WithdrawModel {
  double amount = 0.0;
  String addrID = '';
  String? toAddr = '';
  String? remark = '';
  String? passcode = '';
  double gasFee = 0.0;
  CurrencyModel? selectedCurrency = CurrencyModel();
  Map<String,String>? tokenMap;


  static final WithdrawModel _withdrawModel = WithdrawModel._internal();

  factory WithdrawModel() {
    return _withdrawModel;
  }

  WithdrawModel._internal();
}
