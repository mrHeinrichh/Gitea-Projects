import 'package:jxim_client/utils/config.dart';

class WalletConfig {

  static String remainTransferCode = "remain";   //可用餘額的code
  static String safeTransferCode = "safe";   //保險櫃餘額的code
  static String bobiTransferCode = "bobi";   //波幣餘額的code

  /// 當前所有可用的劃轉類型
  static List<WalletTransferType> getWalletTransferList({String type = "CNY"}) {
    if (Config().isGameEnv && type == "CNY") {
      return WalletTransferType.values;
    } else {
      List<WalletTransferType> data = List.from(WalletTransferType.values);
      data.removeWhere((element) => element.code == WalletConfig.bobiTransferCode);
      return data;
    }
  }

  /// 根據code取得對應的劃轉類型
  static WalletTransferType getWalletTransferByCode(String code) {
    WalletTransferType walletTransferType = WalletTransferType.transferRemain;
    for (WalletTransferType type in getWalletTransferList()) {
      if (type.code == code) {
        walletTransferType = type;
        break;
      }
    }
    return walletTransferType;
  }
}

/// 全部錢包劃轉類型
enum WalletTransferType {
  transferRemain('remain', '可用余额'),

  transferSafe('safe', '保险柜余额'),

  transferBobi('bobi', '波币余额');

  const WalletTransferType(this.code, this.name);

  final String code;
  final String name;
}

/// 全部錢包劃轉api需要的類型
enum WalletTransferTypeAPI {
  BOB_WITHDRAW,   //用戶餘額轉到波幣
  BOB_WITHDRAW_FROM_USER_BOX,   //保險櫃轉到波幣
  USER_AVAIL_TO_BOX,   //用戶餘額轉到保險櫃
  USER_BOX_TO_AVAIL,   //保險櫃轉到用戶餘額
  BOB_RECHARGE,     //波幣轉到用戶餘額
  BOB_RECHARGE_TO_USER_BOX,    //波幣轉到保險櫃
}

/// api返回的全部錢包類型
enum WalletTypeAPI {
  USER_AVAIL,   //用戶可用餘額
  USER_BOX,   //保險櫃金額
}
