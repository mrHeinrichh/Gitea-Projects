import 'dart:convert';

import 'package:jxim_client/main.dart';

class QrCodeWalletTask {
  static const String taskName = 'QrCodeWalletTask';
  static const String qrCodeWalletTaskTypeAcceptMoney =
      'QrCodeWalletTaskTypeAcceptMoney';

  static String generateAcceptMoneyStr({String? address}) {
    Map<String, dynamic> data = {};
    data['profile'] = objectMgr.userMgr.mainUser.accountId;
    data[taskName] = qrCodeWalletTaskTypeAcceptMoney;
    if (address != null) {
      data['address'] = address;
    }
    String str = jsonEncode(data);
    return str;
  }

  String profile = '';
  String? address;
  QrCodeWalletTask(this.profile, this.address);
  QrCodeWalletTask.fromJson(Map<String, dynamic> json){
    profile = json['profile'];
    address = json['address'];
  }

  static QrCodeWalletTask? currentTask;
}
