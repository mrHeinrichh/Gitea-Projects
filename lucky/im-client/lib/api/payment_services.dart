import 'package:jxim_client/object/payment/bobi_asset_model.dart';
import 'package:jxim_client/object/payment/bobi_shop_model.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

final PaymentServices paymentServices = PaymentServices();

class PaymentServices {
  String _paymentUrl = '/payment';

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
      final ResponseData res = await Request.doPost(url, data: dataBody);

      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.getMessage());
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
      final ResponseData res = await Request.doPost(url, data: dataBody);

      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.getMessage());
    }
  }

  //從波幣充值
  Future<ResponseData> bobiRecharge({
    required String amount,
    required String orderType,
  }) async {
    String url = "$_paymentUrl/recharge/create";

    final Map<String, dynamic> dataBody = {
      "amount": amount,
      "orderType": orderType,
    };

    final ResponseData res = await Request.doPost(url, data: dataBody);

    return res;
  }

  //取得波幣資產
  Future<BobiAssetModel?> bobiGetAsset() async {
    String url = "$_paymentUrl/asset/get";

    final Map<String, dynamic> dataBody = {};

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        BobiAssetModel bobiAssetModel =
        BobiAssetModel.fromJson(res.data);
        return bobiAssetModel;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      if (e.getPrefix() == 101) {
        return null;
      }
      print('AppException: ${e.toString()}');
      rethrow;
    }
  }

  //取得波幣商城連結
  Future<BobiShopModel?> bobiGetShop() async {
    String url = "$_paymentUrl/shop-url/get";

    final Map<String, dynamic> dataBody = {};

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        BobiShopModel bobiShopModel =
        BobiShopModel.fromJson(res.data);
        return bobiShopModel;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      if (e.getPrefix() == 101) {
        return null;
      }
      print('AppException: ${e.toString()}');
      rethrow;
    }
  }
}
