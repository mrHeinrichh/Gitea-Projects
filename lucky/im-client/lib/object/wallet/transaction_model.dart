
import 'package:intl/intl.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../utils/lang_util.dart';

class TransactionModel {
  String? amount;
  String? currencyType;
  String? fee;
  String? desc;
  String? fromAddr;
  String? netType;
  String? remark;
  String? toAddr;
  TxFlag? txFlag;
  String? txID;
  String? rpID;
  String? txTime;
  String? txType;
  String? txStatus;
  String? recipientID;
  String? recipientName;
  String? sendUserID;
  String? senderName;
  String? groupName;

  TransactionModel({
    this.amount,
    this.currencyType,
    this.fee,
    this.desc,
    this.fromAddr,
    this.netType,
    this.remark,
    this.toAddr,
    this.txFlag,
    this.txID,
    this.txTime,
    this.txType,
    this.txStatus,
    this.recipientID,
    this.recipientName,
    this.sendUserID,
    this.senderName,
    this.groupName,
  });

  static TransactionModel fromJson(dynamic data) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(data['txTime'], isUtc: true)
            .toLocal();
    var d24 = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

    return TransactionModel(
      amount: data['amount'],
      currencyType: data['currencyType'],
      fee: data['fee'],
      desc: data['desc'],
      fromAddr: data['fromAddr'],
      netType: data['netType'],
      remark: data['remark'],
      toAddr: data['toAddr'],
      txFlag: data['txFlag'].toString().toTxFlag,
      txStatus: data['txStatus'],
      txID: data['txID'],
      txTime: d24,
      txType: data['txType'],
      recipientName: data['recipientName'],
      senderName: data['senderName'],
      groupName: data['groupName'],
    );
  }
}

enum TxFlag {
  CREDIT,
  DEBIT,
}

extension TxTypeUtils on TxFlag {
  String get toStatus {
    switch (this) {
      case TxFlag.CREDIT:
        return localized(walletOutgoing);
      case TxFlag.DEBIT:
        return localized(walletIncoming);
    }
  }
}

extension transactionStringUtils on String {
  TxFlag get toTxFlag {
    switch (this) {
      case 'CREDIT':
        return TxFlag.CREDIT;
      case 'DEBIT':
        return TxFlag.DEBIT;
      default:
        throw (localized(noSuitableTransactionType));
    }
  }

  String getWalletType({bool isFull = false}) {
    switch (this) {
      case 'SEND_EXT_ADDR_TRANSFER':
      case 'RCV_EXT_ADDR_TRANSFER':
        return localized(walletExternal);
      case 'SEND_INT_ADDR_TRANSFER':
      case 'RCV_INT_ADDR_TRANSFER':
        return localized(walletInternal);
      case 'SEND_STANDARD_RP':
      case 'RCV_STANDARD_RP':
        return localized(normalRedPacket);
      case 'SEND_LUCKY_RP':
      case 'RCV_LUCKY_RP':
        return localized(luckyRedPacket);
      case 'SEND_SPECIFIED_RP':
      case 'RCV_SPECIFIED_RP':
        return localized(exclusiveRedPacket);
      case 'REFUND_LK_RP':
        return '${localized(luckyRedPacket)} ${isFull ? 'Refund' : '(R)'}';
      case 'REFUND_SP_RP':
        return '${localized(exclusiveRedPacket)} ${isFull ? 'Refund' : '(R)'}';
      case 'REFUND_ST_RP':
        return '${localized(normalRedPacket)}  ${isFull ? 'Refund' : '(R)'}';
      default:
        return localized(walletWallet);
    }
  }
}

extension transactionUtils on TransactionModel {
  String get displayTitle {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
        return this.desc ?? localized(refundRedPacketUnknown);
      case 'RCV_INT_ADDR_TRANSFER':
        return this.senderName ?? localized(internalTransferUnknown);
      case 'SEND_EXT_ADDR_TRANSFER':
      case 'SEND_INT_ADDR_TRANSFER':
        return '${(this.toAddr?.substring(0, 5))} ... ${this.toAddr?.substring((this.toAddr!.length - 5))}' ??
            'External Transfer unknown';
      case 'RCV_EXT_ADDR_TRANSFER':
        return '${(this.fromAddr?.substring(0, 5))} ... ${this.fromAddr?.substring((this.fromAddr!.length - 5))}';
      case 'SEND_STANDARD_RP':
      case 'SEND_LUCKY_RP':
      case 'SEND_SPECIFIED_RP':
        return this.groupName ?? localized(redPacketGroupUnknown);
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
        return this.senderName ?? localized(unknownSender);
      default:
        return "Wallet";
    }
  }

  String get senderDetailTitle {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
      case 'SEND_STANDARD_RP':
      case 'SEND_LUCKY_RP':
      case 'SEND_SPECIFIED_RP':
      case 'RCV_INT_ADDR_TRANSFER':
      case 'SEND_INT_ADDR_TRANSFER':
      case 'RCV_EXT_ADDR_TRANSFER':
      case 'SEND_EXT_ADDR_TRANSFER':
        return localized(sender);
      default:
        return localized(walletWallet);
    }
  }

  String get senderDetail {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
        return 'System Refund';
      case 'RCV_INT_ADDR_TRANSFER':
      case 'SEND_INT_ADDR_TRANSFER':
        return this.senderName ?? localized(externalTransferUnknown);
      case 'RCV_EXT_ADDR_TRANSFER':
      case 'SEND_EXT_ADDR_TRANSFER':
        return this.fromAddr ?? localized(unknownAddress);
      case 'SEND_STANDARD_RP':
      case 'SEND_LUCKY_RP':
      case 'SEND_SPECIFIED_RP':
        return this.senderName ?? localized(redPacketGroupUnknown);
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
        return this.senderName ?? localized(unknownSender);
      default:
        return localized(walletWallet);
    }
  }

  String get recipientDetail {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
        return this.recipientName ?? localized(refundRedPacketUnknown);
      case 'RCV_INT_ADDR_TRANSFER':
      case 'RCV_EXT_ADDR_TRANSFER':
      case 'SEND_EXT_ADDR_TRANSFER':
      case 'SEND_INT_ADDR_TRANSFER':
        return this.toAddr ?? localized(externalTransferUnknown);
      case 'SEND_STANDARD_RP':
      case 'SEND_LUCKY_RP':
      case 'SEND_SPECIFIED_RP':
        return this.groupName ?? localized(redPacketGroupUnknown);
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
        return '${this.recipientName}';
      default:
        return localized(walletWallet);
    }
  }

  String get recipientDetailTitle {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
      case 'RCV_INT_ADDR_TRANSFER':
      case 'RCV_EXT_ADDR_TRANSFER':
      case 'SEND_EXT_ADDR_TRANSFER':
      case 'SEND_INT_ADDR_TRANSFER':
        return localized(recipient);
      case 'SEND_STANDARD_RP':
      case 'SEND_LUCKY_RP':
      case 'SEND_SPECIFIED_RP':
        return localized(groupName);
      default:
        return localized(walletWallet);
    }
  }

  bool get isShowGroupName {
    switch (this.txType) {
      case 'RCV_STANDARD_RP':
      case 'RCV_LUCKY_RP':
      case 'RCV_SPECIFIED_RP':
        return true;
      default:
        return false;
    }
  }

  bool get isRefund {
    switch (this.txType) {
      case 'REFUND_LK_RP':
      case 'REFUND_ST_RP':
      case 'REFUND_SP_RP':
        return true;
      default:
        return false;
    }
  }

  String get status {
    switch (this.txStatus) {
      case 'SUCCEEDED':
        return localized(walletTransactionsSuccessful);
      case 'PENDING':
        return localized(walletTransactionsPending);
      default:
        return localized(walletTransactionsSuccessful);
    }
  }
}
