import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

enum WalletTransferErrorType {
  undefined(-1),
  invalidParam(150001),
  invalidChannelType(150002),
  idNotExists(150003),
  pwdIncorrect(150004),
  invalidOrderType(150005),
  userNotExists(150006),
  chatNotExists(150007),
  sendRpNoPermission(150008),
  needOpenBlockchainAddrWhiteMode(150009),
  newAddr(150010),
  cannotTransferSelf(150011),
  invalidVCodeToken(150012),
  invalidBizType(150013),
  invalidCurrency(150014),
  paySvcExists(150015),
  paySvcNotExists(150016),
  insufficientBalance(150017),
  rpAmtInsufficient(150018),
  exceedMaxRpNum(150019),
  exceedMaxRPAmt(150020),
  belowMinRPAmt(150021),
  currencyDisable(150022),
  codeReqTooFrequent(150023),
  noWalletPasscode(150024),
  unknown(150099),
  errWalletPasscode(30403),
  errResetWalletPasscode(30405),
  errWalletPasscodeTooManyRetry(30409);

  final int code;

  const WalletTransferErrorType(this.code);

  static WalletTransferErrorType fromCode(int code) {
    return WalletTransferErrorType.values.firstWhere(
      (element) => element.code == code,
      orElse: () => WalletTransferErrorType.undefined,
    );
  }

  String get message => switch (this) {
        invalidParam => localized(walletTransErrorInvalidParam),
        invalidChannelType => localized(walletTransErrorInvalidChannelType),
        idNotExists => localized(walletTransErrorIDNotExists),
        pwdIncorrect => localized(walletTransErrorPwdIncorrect),
        invalidOrderType => localized(walletTransErrorInvalidOrderType),
        userNotExists => localized(walletTransErrorUserNotExists),
        chatNotExists => localized(walletTransErrorChatNotExists),
        sendRpNoPermission => localized(walletTransErrorSendRpNoPermission),
        needOpenBlockchainAddrWhiteMode =>
          localized(walletTransErrorNeedOpenBlockchainAddrWhiteMode),
        newAddr => localized(walletTransErrorNewAddr),
        cannotTransferSelf => localized(walletTransErrorCannotTransferSelf),
        invalidVCodeToken => localized(walletTransErrorInvalidVCodeToken),
        invalidBizType => localized(walletTransErrorInvalidBizType),
        invalidCurrency => localized(walletTransErrorInvalidCurrency),
        paySvcExists => localized(walletTransErrorPaySvcExists),
        paySvcNotExists => localized(walletTransErrorPaySvcNotExists),
        insufficientBalance => localized(walletTransErrorInsufficientBalance),
        rpAmtInsufficient => localized(walletTransErrorRpAmtInsufficient),
        exceedMaxRpNum => localized(walletTransErrorExceedMaxRpNum),
        exceedMaxRPAmt => localized(walletTransErrorExceedMaxRPAmt),
        belowMinRPAmt => localized(walletTransErrorBelowMinRPAmt),
        currencyDisable => localized(walletTransErrorCurrencyDisable),
        codeReqTooFrequent => localized(walletTransErrorCodeReqTooFrequent),
        noWalletPasscode => localized(walletTransErrorNoWalletPasscode),
        unknown => localized(walletTransErrorUnknown),
        errWalletPasscode => localized(walletTransErrorWalletPasscode),
        errResetWalletPasscode =>
          localized(walletTransErrorResetWalletPasscode),
        errWalletPasscodeTooManyRetry =>
          localized(walletTransErrorWalletPasscodeTooManyRetry),
        _ => localized(walletTransFailed),
      };

  static String getErrorMsg(AppException e) {
    final code = e.getPrefix();
    return WalletTransferErrorType.fromCode(code).message;
  }
}
