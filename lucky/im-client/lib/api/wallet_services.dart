import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/object/wallet/wallet_assets_model.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/object/wallet/red_packet_model.dart';
import 'package:jxim_client/object/wallet/transaction_model.dart';
import 'package:jxim_client/object/wallet/withdraw_modal.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

final WalletServices walletServices = WalletServices();

class WalletServices {
  String _walletUrl = '/app/api/wallet';

  Future<WalletAssetsModel?> getUserAssets({String currency = 'USD', bool isShowBox = false}) async {
    String url = "$_walletUrl/assets";

    final Map<String, dynamic> dataBody = {
      "totalAmtCurrencyType": currency,
      "showUserBox": isShowBox,
    };

    try {
      final ResponseData res = await Request.doGet(url, data: dataBody);

      if (res.success()) {
        objectMgr.localStorageMgr.write(LocalStorageMgr.WALLET, res.data);
        WalletAssetsModel walletAssetsModel =
            WalletAssetsModel.fromJson(res.data);
        return walletAssetsModel;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      if (e.getPrefix() == 101) {
        return null;
      }
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<AddressModel>> getCryptoAddress({
    String? currencyType,
    String? netType,
    int page = 1,
    int offset = 200,
  }) async {
    final Map<String, dynamic> dataBody = {
      "page": page,
      "limit": offset,
      "currencyType": currencyType,
      "netType": netType
    };

    String url = '$_walletUrl/addresses';

    try {
      final ResponseData res = await Request.doGet(url, data: dataBody);

      if (res.success()) {
        if (res.data['list'] != null) {
          final List<AddressModel> data = res.data['list']
              .map<AddressModel>((e) => AddressModel.fromJson(e))
              .toList();
          return data;
        }
        return [];
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<AddressModel> generateAddress({
    required String currencyType,
    required String netType,
    required String addrName,
  }) async {
    String url = '$_walletUrl/addresses/add';
    final Map<String, dynamic> dataBody = {
      "currencyType": currencyType,
      "netType": netType,
      "addrName": addrName,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return AddressModel.fromJson(res.data);
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> editAddress({
    required String addrID,
    required String addrName,
  }) async {
    String url = '$_walletUrl/addresses/edit';
    final Map<String, dynamic> dataBody = {
      "addrID": addrID,
      "addrName": addrName,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return true;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteAddress({
    required String addrID,
  }) async {
    String url = '$_walletUrl/addresses/delete';
    final Map<String, dynamic> dataBody = {
      "addrID": addrID,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return true;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<String> calculateGasFee({
    required String currencyType,
    required String netType,
    required String amount,
    required String toAddr,
  }) async {
    String url = '$_walletUrl/calculate/withdrawal-fee';
    final Map<String, dynamic> dataBody = {
      "currencyType": currencyType,
      "netType": netType,
      "amount": amount,
      "toAddr": toAddr,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return res.data['fee'];
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<String> calculateExchangeCurrency({
    required double amount,
    required String fromCurrencyType,
    String? fromNetType,
    required String toCurrencyType,
  }) async {
    String url = '$_walletUrl/calculate/exchange-currency';
    final Map<String, dynamic> dataBody = {
      "amount": amount.toString(),
      "fromCurrencyType": fromCurrencyType,
      "fromNetType": fromNetType,
      "toCurrencyType": toCurrencyType,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return res.data['amount'];
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<ResponseData> withdrawToAddress(WithdrawModel withdrawModel) async {
    String url = '/payment/withdraw/address';

    final Map<String, dynamic> dataBody = {
      "amount": withdrawModel.amount.toString(),
      "currencyType": withdrawModel.selectedCurrency?.currencyType,
      "netType": withdrawModel.selectedCurrency?.netType,
      "toAddr": withdrawModel.toAddr,
      "remark": withdrawModel.remark ?? "",
      "passcode": withdrawModel.passcode,
      ...?withdrawModel.tokenMap
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      return res;
    } on AppException catch (_) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> getTransactionHistory({
    String? currencyType,
    int page = 1,
    int limit = 300,
    String txFlag = "",
    String txType = "",
    String txStatus = "",
  }) async {
    String url = '$_walletUrl/transactions';
    final Map<String, dynamic> dataBody = {
      if (currencyType != null) ...{
        "currencyType": currencyType,
      },
      "page": page,
      "limit": limit,
      "txFlag": txFlag,
      "txStatus": txStatus,
      // 'txType': txType
    };

    try {
      final ResponseData res = await Request.doGet(url, data: dataBody);

      if (res.success()) {
        if (res.data['list'] == null) return [];
        final List<TransactionModel> data = res.data['list']
            .map<TransactionModel>((e) => TransactionModel.fromJson(e))
            .toList();
        return data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<TransactionModel> getTransactionDetail({
    required String transactionID,
  }) async {
    String url = '$_walletUrl/transactions/detail';
    final Map<String, dynamic> dataBody = {
      "txID": transactionID,
    };

    try {
      final ResponseData res = await Request.doGet(url, data: dataBody);

      if (res.success()) {
        TransactionModel transactionModel = TransactionModel.fromJson(res.data);
        return transactionModel;
      } else {
        throw AppException(res.code, res.message, res.data);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<AddressModel>> getRecipientsAddress({
    String? currencyType,
    String? netType,
    int page = 1,
    int offset = 200,
  }) async {
    final Map<String, dynamic> dataBody = {
      "page": page,
      "limit": offset,
      if (currencyType != null) ...{
        "currencyType": currencyType,
      },
      if (netType != null) ...{
        "netType": netType,
      },
    };

    String url = '$_walletUrl/favourite-recipients';

    try {
      final ResponseData res = await Request.doGet(url, data: dataBody);

      if (res.success()) {
        if (res.data['list'] != null) {
          final List<AddressModel> data = res.data['list']
              .map<AddressModel>((e) => AddressModel.fromJson(e))
              .toList();
          return data;
        }
        return [];
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<ResponseData> addRecipientAddress({
    required String currencyType,
    required String netType,
    required String addrName,
    required String address,
    Map<String, String>? tokenMap,
  }) async {
    String url = '/payment/favourite-recipients/add';
    final Map<String, dynamic> dataBody = {
      "currencyType": currencyType,
      "netType": netType,
      "addrName": addrName,
      "address": address,
    };

    if (tokenMap != null) dataBody.addAll(tokenMap);

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return res;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> editRecipientAddress({
    required String addrID,
    required String addrName,
  }) async {
    String url = '$_walletUrl/favourite-recipients/edit';
    final Map<String, dynamic> dataBody = {
      "addrID": addrID,
      "addrName": addrName,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return true;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> deleteRecipientAddress({
    required String addrID,
  }) async {
    String url = '$_walletUrl/favourite-recipients/delete';
    final Map<String, dynamic> dataBody = {
      "addrID": addrID,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return true;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<RedPacketDetail> getRedPacket({
    required String rpID,
  }) async {
    String url = '$_walletUrl/rp/detail';

    Map<String, dynamic> params = {};
    params['rpID'] = rpID;

    try {
      final ResponseData res = await Request.doGet(url, data: params);

      if (res.success()) {
        return RedPacketDetail.fromJson(res.data);
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<RedPacketDetail>> getRedPacketMultiple({
    required List<String> rpID,
  }) async {
    String url = '$_walletUrl/rp/details';

    Map<String, dynamic> params = {};
    params['rpIDs'] = rpID;

    try {
      final ResponseData res = await Request.doPost(url, data: params);

      if (res.success()) {
        return res.data
            .map<RedPacketDetail>((e) => RedPacketDetail.fromJson(e))
            .toList();
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<ResponseData> sendRedPacket({
    required RedPacketModel redPacketModel,
  }) async {
    String url = '/payment/rp/send';
    try {
      final ResponseData res =
          await Request.doPost(url, data: redPacketModel.toJson());
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  Future<Map<String, dynamic>> receiveRedPacket({
    required String rpID,
    required int chatID,
    required String rpType,
  }) async {
    String url = '$_walletUrl/rp/receive';

    Map<String, dynamic> params = {};
    params['rpID'] = rpID;
    params['chatID'] = chatID;
    params['rpType'] = rpType;

    try {
      final ResponseData res = await Request.doPost(url, data: params);

      if (res.success()) {
        if (res.data['grab_flag']) {
          return {
            'status': rpReceived,
            'amount': res.data['amount'],
            'error': false,
          };
        } else {
          return {
            'status': rpFullyClaimed,
            'amount': res.data['amount'],
            'error': false,
          };
        }
      } else {
        switch (res.code) {
          case ErrorCodeConstant.EXPIRED_RP:
            return {
              'status': rpExpired,
              'amount': '0',
              'error': false,
            };
          case ErrorCodeConstant.BLOCKED_FROM_SPC_RP:
            return {
              'status': rpNotInExclusive,
              'amount': '0',
              'error': false,
            };
          case ErrorCodeConstant.UNKNOWN:
            return {
              'status': rpUnknownError,
              'amount': '0',
              'error': false,
            };
          case ErrorCodeConstant.RECEIVED_RP:
            return {
              'status': rpReceived,
              'amount': '0',
              'error': true,
            };
          default:
            throw CodeException(res.code, res.message, null);
        }
      }
    } on CodeException catch (e) {
      switch (e.getPrefix()) {
        case ErrorCodeConstant.EXPIRED_RP:
          return {
            'status': rpExpired,
            'amount': '0',
            'error': false,
          };
        case ErrorCodeConstant.BLOCKED_FROM_SPC_RP:
          return {
            'status': rpNotInExclusive,
            'amount': '0',
            'error': false,
          };
        case ErrorCodeConstant.UNKNOWN:
          return {
            'status': rpUnknownError,
            'amount': '0',
            'error': false,
          };
        case ErrorCodeConstant.RECEIVED_RP:
          return {
            'status': rpReceived,
            'amount': '0',
            'error': true,
          };
        default:
          throw CodeException(e.getPrefix(), e.getMessage(), null);
      }
    }
  }

  Future<Map> validateAddress({
    required String address,
    required String netType,
  }) async {
    String url = '$_walletUrl/validate-address';

    final Map<String, dynamic> dataBody = {
      "address": address,
      "netType": netType,
    };

    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      if (res.success()) {
        return res.data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      showWarningToast("无效的地址");
      rethrow;
    }
  }

  Future<Map> getRedPacketConfig() async {
    String url = '$_walletUrl/rp/configs';

    try {
      final ResponseData res = await Request.doGet(url);

      if (res.success()) {
        return res.data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map> getWithdrawConfig() async {
    String url = '$_walletUrl/transactions/configs';

    try {
      final ResponseData res = await Request.doGet(url);

      if (res.success()) {
        return res.data;
      } else {
        throw AppException(res.code, res.message);
      }
    } on AppException catch (e) {
      pdebug('AppException: ${e.toString()}');
      rethrow;
    }
  }

  //錢包轉帳
  Future<ResponseData> walletTransfer(int toUserID, String amount,
      String currencyType, String passcode, String remark,{
        Map<String,String> ? tokenMap,
      }) async {
    String url ="/payment/transfer/user";
    // String url = "$_walletUrl/transfer/user";

    final Map<String, dynamic> dataBody = {
      "toUserID": toUserID,
      "amount": amount,
      "currencyType": currencyType,
      "passcode": passcode,
      "remark": remark,
    };
    if(tokenMap!=null && tokenMap.isNotEmpty){
      dataBody.addAll(tokenMap);
    }
    try {
      final ResponseData res = await Request.doPost(url, data: dataBody);

      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.getMessage());
    }
  }

  ///取得用戶資產 WalletAssetsData 钱包主页
  Future<ResponseData> getWalletAssets(Map<String, dynamic> map) async {
    String url = '$_walletUrl/assets'; //取得用戶資產

    ResponseData res= await Request.doGet(url, data: map);
    return res;
  }

  ///单聊转账
  Future<ResponseData> postTransferChat(Map<String, dynamic> map) async {
    String url = '/payment/transfer/chat'; //单聊转账

    try {
      ResponseData res = await Request.doPost(url, data: map);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  ///收款说明
  Future<ResponseData> postRechargeExplain() async {
    String url = '/payment/recharge-explain/get';
    try {
      ResponseData res = await Request.doPost(url, data: {});
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  ///付款说明
  Future<ResponseData> postWithdrawExplain() async {
    String url = '/payment/withdraw-explain/get';
    try {
      ResponseData res = await Request.doPost(url, data: {});
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }


  ///获取支付安全设定
  Future<ResponseData> getSettings() async {
    String url = '$_walletUrl/settings';
    try {
      ResponseData res = await Request.doGet(url);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  ///获取当日交易额
  Future<ResponseData> postWalletTodayTotalSettings(Map<String, dynamic> map) async {
    String url = '/payment/today-tx-total/get';
    try {
      ResponseData res = await Request.doPost(url,data: map);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  ///设置区块链地址安全 白名单
  Future<ResponseData> updateBlockchainSettingsWithWhiteMode({
    required bool isWhiteMode,
    Map<String, String>? tokenMap,
  }) async {
    return await _updateBlockchainSettings(
      isWhiteMode: isWhiteMode,
      tokenMap: tokenMap,
    );
  }

  ///设置区块链地址安全 新地址
  Future<ResponseData> updateBlockchainSettingsWithNewAddressLock({
    required bool isNewAddressLock,
    Map<String, String>? tokenMap,
  }) async {
    return await _updateBlockchainSettings(
      isAddressLock: isNewAddressLock,
      tokenMap: tokenMap,
    );
  }

  ///设置区块链地址安全
  Future<ResponseData> _updateBlockchainSettings({
    bool? isWhiteMode,
    bool? isAddressLock,
    Map<String, String>? tokenMap,
  }) async {
    String url = '/payment/blockchain-settings/update';

    final Map<String, dynamic> data = {
      if (isWhiteMode != null)
        "blockchain_addr_white_mode": isWhiteMode ? 1 : 0,
      if (isAddressLock != null)
        "new_blockchain_addr_lock": isAddressLock ? 1 : 0,
    };

    if (tokenMap != null) data.addAll(tokenMap);

    try {
      ResponseData res = await Request.doPost(url, data: data);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }


  ///获取短信验证码
  Future<ResponseData>  postAuthVcode(Map<String, dynamic> data) async {
    String url = '/app/api/auth/vcode/get';
    try {
      ResponseData res = await Request.doPost(url, data: data);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }
///获取邮箱验证码
  Future<ResponseData>  postAuthEmailVcode(Map<String, dynamic> data) async {
    String url = '/app/api/auth/vcode/get-email';
    try {
      ResponseData res = await Request.doPost(url, data: data);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

///更新二次校验限额
  Future<ResponseData>  postDailyTransferUpdate(Map<String, dynamic> data) async {
    String url = '/payment/daily-transfer-out-quota/update';
    try {
      ResponseData res = await Request.doPost(url, data: data);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  ///更新二次校验配置
  Future<ResponseData>  postTwoFactorAuthSettingsUpdate(Map<String, dynamic> data) async {
    String url = '/payment/two-factor-auth-settings/update';
    try {
      ResponseData res = await Request.doPost(url, data: data);
      return res;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }
}
