import 'package:flutter/material.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/wallet/wallet_assets_bean.dart';
import 'package:jxim_client/utils/net/response_data.dart';

class TransferMoneyViewModel extends ChangeNotifier {
  final int chatId;

  TransferMoneyViewModel(this.chatId) {
    init();
  }

  WalletAssetsData _assetsData = WalletAssetsData(
    totalAmt: '-',
    totalAmtCurrencyType: '',
    cryptoCurrencyInfos: [],
    legalCurrencyInfos: [],
    updateTime: null,
  );

  WalletAssetsData get assetsData => _assetsData;

  double _amount = 0.0;

  String get amount => _amount.toString();

  String _error = '';

  String get error => _error;

  bool get isOverWalletAmount => _amount > double.parse(walletAmount);

  bool get isNextEnabled =>
      _amount > 0 && isOverWalletAmount == false && isLoading == false;

  String get walletAmount{
     if(_currency ==CurrencyALLType.currencyCNY){
       if(assetsData.legalCurrencyInfos.length>0)
     return  assetsData.legalCurrencyInfos[0].amount??"--";
     }else if(_currency ==CurrencyALLType.currencyUSDT){
       if(assetsData.cryptoCurrencyInfos.length>0)
       return assetsData.cryptoCurrencyInfos[0].amount??"--";
     }
    return  "--";
  }

  CurrencyALLType _currency = CurrencyALLType.currencyUSDT;

  CurrencyALLType get currency => _currency;

  String _remark = '';

  String get remark => _remark;

  bool _isKeyboardVisible = false;

  bool get isKeyboardVisible => _isKeyboardVisible;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void init() {
    requestWalletAssets();
  }

  void requestWalletAssets() async {
    ResponseData resData = await walletServices
        .getWalletAssets({"totalAmtCurrencyType": currency.type});
    if (resData.code == 0) {
      _assetsData = WalletAssetsData.fromJson(resData.data);
    } else {
      // showToast(resData.message);
    }

    notifyListeners();
  }

  void updateCurrency(CurrencyALLType type) {
    _currency = type;
    requestWalletAssets();
  }

  void clearError() {
    setError('');
  }

  void setError(String value) {
    _error = value;
    notifyListeners();
  }

  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void setRemark(String value) {
    _remark = value;
    notifyListeners();
  }

  void showKeyboard() {
    _isKeyboardVisible = true;
    notifyListeners();
  }

  void hideKeyboard() {
    _isKeyboardVisible = false;
    notifyListeners();
  }

  Future<ResponseData> sendTransferRequest({
    required String password,
    String? remark,
    Map<String,dynamic>? tokenMap,
  }) async {
    setLoading(true);

    try {
      ResponseData resData = await walletServices.postTransferChat({
        "chatID": chatId,
        "amount": amount,
        "currencyType": currency.type,
        "passcode": password,
        if (remark != null) "remark": remark,
        ...?tokenMap,
      });

      return resData;
    } catch (e) {
      return ResponseData(code: -1, message: e.toString());
    } finally {
      setLoading(false);
    }
  }
}
