///二次验证 bean
class WalletSettingsBean {
  int? secureInterval;
  int? payTwoFactorAuthEnable;
  DailyTransferOutQuota? dailyTransferOutQuota;
  int? phoneAuthEnable;
  String? phoneAuthCountryCode;
  String? phoneAuthContact;
  int? emailAuthEnable;
  String? emailAuthEmail;
  int? blockchainAddrWhiteMode;
  int? newBlockchainAddrLock;

  WalletSettingsBean({
    this.secureInterval,
    this.payTwoFactorAuthEnable,
    this.dailyTransferOutQuota,
    this.phoneAuthEnable,
    this.phoneAuthCountryCode,
    this.phoneAuthContact,
    this.emailAuthEnable,
    this.emailAuthEmail,
    this.blockchainAddrWhiteMode,
    this.newBlockchainAddrLock,
  });

  WalletSettingsBean.fromJson(Map<String, dynamic> json) {
    secureInterval = json['secure_interval'];
    payTwoFactorAuthEnable = json['pay_two_factor_auth_enable'];
    dailyTransferOutQuota = json['daily_transfer_out_quota'] != null
        ? DailyTransferOutQuota.fromJson(json['daily_transfer_out_quota'])
        : null;
    phoneAuthEnable = json['phone_auth_enable'];
    phoneAuthCountryCode = json['phone_auth_country_code'];
    phoneAuthContact = json['phone_auth_contact'];
    emailAuthEnable = json['email_auth_enable'];
    emailAuthEmail = json['email_auth_email'];
    blockchainAddrWhiteMode = json['blockchain_addr_white_mode'];
    newBlockchainAddrLock = json['new_blockchain_addr_lock'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['secure_interval'] = secureInterval;
    data['pay_two_factor_auth_enable'] = payTwoFactorAuthEnable;
    if (dailyTransferOutQuota != null) {
      data['daily_transfer_out_quota'] = dailyTransferOutQuota!.toJson();
    }
    data['phone_auth_enable'] = phoneAuthEnable;
    data['phone_auth_country_code'] = phoneAuthCountryCode;
    data['phone_auth_contact'] = phoneAuthContact;
    data['email_auth_enable'] = emailAuthEnable;
    data['email_auth_email'] = emailAuthEmail;
    data['blockchain_addr_white_mode'] = blockchainAddrWhiteMode;
    data['new_blockchain_addr_lock'] = newBlockchainAddrLock;
    return data;
  }

  ///1 开启认证，0，不需要认证
  bool get isPayTwoFactorAuthEnable {
    return payTwoFactorAuthEnable == 1;
  }

  ///'-1:未设置钱包密码\\\\n0:每次输入钱包密码\\\\n1:每个session输入密码\\\\n2:每天输入密码
  ///现在只有-1和0的值
  bool get isSecureInterval => secureInterval == -1;
}

class DailyTransferOutQuota {
  // String? cNY;
  String? uSDT;

  DailyTransferOutQuota({
    // this.cNY,
    this.uSDT,
  });

  DailyTransferOutQuota.fromJson(Map<String, dynamic> json) {
    // cNY = json['CNY'];
    uSDT = json['USDT'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // data['CNY'] = this.cNY;
    data['USDT'] = uSDT;
    return data;
  }
}
