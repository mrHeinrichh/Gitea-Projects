import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

final PaymentServices paymentServices = PaymentServices();

class PaymentServices {
  final String _paymentUrl = '/payment';

  //錢包劃轉
  Future<ResponseData> fundTransfer({
    required String amount,
    required String currencyType,
    required String orderType,
    required String password,
  }) async {
    String url = "$_paymentUrl/own-transfer/create";

    final Map<String, dynamic> dataBody = {
      "amount": amount,
      "currencyType": currencyType,
      "orderType": orderType,
      "password": password,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(url, data: dataBody);

      return res;
    } on AppException catch (e) {
      return ResponseData(
          code: e.getPrefix(), message: e.getMessage(), data: e.getData());
    }
  }

  //取得交易紀錄
  Future<ResponseData> getRecordData({
    required String txID,
  }) async {
    String url = "$_paymentUrl/tx/get";

    final Map<String, dynamic> dataBody = {
      "txID": txID,
    };

    try {
      final ResponseData res = await CustomRequest.doPost(url, data: dataBody);

      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.getMessage());
    }
  }
}
