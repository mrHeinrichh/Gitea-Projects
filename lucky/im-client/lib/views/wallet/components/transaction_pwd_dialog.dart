import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class TransactionPwdDialog extends StatefulWidget {
  final String amount;
  final String transactionTypeTxt;
  final String? currencyUnit; //貨幣單位
  final Function(String password,
      {Function(String errorMsg)? showError,
      Function(bool isShow)? showDialog}) onConfirmFunc;

  const TransactionPwdDialog({
    super.key,
    required this.amount,
    this.transactionTypeTxt = '官方认证',
    this.currencyUnit,
    required this.onConfirmFunc,
  });

  @override
  State<TransactionPwdDialog> createState() => _TransactionPwdDialogState();
}

class _TransactionPwdDialogState extends State<TransactionPwdDialog> {
  late TextEditingController _textController;
  //錯誤訊息的提示內容
  String errorMessage = "";
  int _numOfAttempts = 0;
  //是否顯示進度圈
  bool isShowLoading = false;

  @override
  void initState() {
    _textController = TextEditingController();

    _textController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImSheetOnBottom(
      title: '确认支付',
      withClose: true,
      middleChildPadding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 32,
      ).w,
      middleChild: Column(
        children: [
           ImText(
            '总金额',
            fontSize: ImFontSize.large,
          ),
          ImGap.vGap8,
          RichText(
            text: TextSpan(
              text: widget.amount.cFormat(),
              style: TextStyle(
                color: ImColor.black,
                fontSize: 40,
                fontWeight: MFontWeight.bold5.value,
                fontFamily: 'pingfang',
              ),
              children: [
                TextSpan(
                  text: widget.currencyUnit == null
                      ? ' USDT'
                      : ' ${widget.currencyUnit}',
                  style:  TextStyle(fontSize: ImFontSize.normal),
                ),
              ],
            ),
          ),
          ImGap.vGap32,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ImText(
                '交易类型',
                color: ImColor.grey30,
              ),
              ImText(
                widget.transactionTypeTxt,
                color: ImColor.black48,
              ),
            ],
          ),
          ImGap.vGap12,
          Container(
            color: ImColor.borderColor,
            height: 0.3,
          ),
          ImGap.vGap12,
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ImText(
                '扣款',
                color: ImColor.grey30,
              ),
              ImText(
                '将从可用余额中扣款',
                color: ImColor.black48,
              ),
            ],
          ),
          ImGap.vGap24,
          ImText(
            '输入您的密码',
            color: ImColor.grey30,
            fontSize: ImFontSize.large,
          ),
          ImGap.vGap16,
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int j = 1; j <= 4; j++)
                    Container(
                      height: 58.w,
                      width: 68.w,
                      decoration: BoxDecoration(
                        color: ImColor.bg,
                        borderRadius: ImBorderRadius.borderRadius12,
                        border: Border.all(
                          width: 1,
                          color: ImColor.black20,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _textController.text.length >= j
                          ? const Icon(
                        Icons.circle,
                        size: 12,
                        color: ImColor.black,
                      )
                          : const SizedBox(),
                    ),
                ],
              ),
              TextField(
                controller: _textController,
                obscureText: true,
                style: TextStyle(
                  color: Colors.transparent,
                  fontSize: 40,
                  fontWeight: MFontWeight.bold6.value,
                ),
                enabled: false,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
          if (_numOfAttempts > 0)
            ...[ImGap.vGap8,
              ImText(
                errorMessage,
                color: ImColor.red,
                fontSize: ImFontSize.small,
              )],
          ImGap.vGap(28),
        ],
      ),
      bottomChild: !isShowLoading
          ? KeyboardNumber(
        controller: _textController,
        onTap: (_) {
          String password = _textController.text;

          if (password.length == 4) {
            widget.onConfirmFunc(password, showError: (String msg) {
              //顯示api來的錯誤訊息
              if (msg.isNotEmpty) {
                setState(() {
                  errorMessage = msg;
                  _numOfAttempts++;
                });
              }

              if (_numOfAttempts == 4) {
                Navigator.pop(context);
              }
            }, showDialog: (bool isShow) {
              //是否顯示加載進度圈
              setState(() {
                isShowLoading = isShow;
              });
            });
          } else if (_textController.text.length > 4) {
            _textController.text = _textController.text
                .substring(0, _textController.text.length - 1);
          }
        },
      )
          : Container(
        height: 280.w,
        color: ImColor.bg,
        alignment: Alignment.center,
        child: getBallLoading(
          width: 60.w,
          height: 60.w,
        ),
      ),
    );
  }
}
