import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/views/wallet/components/transaction_pwd_dialog.dart';
import 'package:provider/provider.dart';
import '../../utils/net/response_data.dart';
import '../../utils/second_verification_utils.dart';
import '../../utils/theme/text_styles.dart';
import 'currency_selection_dialog.dart';
import 'transfer_money_view_model.dart';

class TransferMoney extends StatefulWidget {
  final int chatId;

  const TransferMoney(this.chatId, {super.key});

  @override
  State<TransferMoney> createState() => _TransferMoneyState();
}

class _TransferMoneyState extends State<TransferMoney> {
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  int _remarkTextLength = 0;

  late final TransferMoneyViewModel model;

  @override
  void initState() {
    super.initState();
    model = TransferMoneyViewModel(widget.chatId);
  }

  Future<ResponseData> requestTransfer(String password,
      {Map<String, dynamic>? tokenMap}) async {
    final ret = await model.sendTransferRequest(
      password: password,
      remark: _remarkController.text,
      tokenMap: tokenMap,
    );

    return ret;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: model),
      ],
      child: Scaffold(
        backgroundColor: ImColor.systemBg,
        resizeToAvoidBottomInset: false,
        appBar: const ImAppBar(title: '转账'),
        body: Consumer<TransferMoneyViewModel>(
          builder: (context, model, child) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ).w,
                    children: [
                      ImRoundContainer(
                        title: '货币类型',
                        child: ImListItem(
                          title: '币种',
                          rightTitle: model.currency.title,
                          rightTitleColor: ImColor.black48,
                          rightTitleFontWeight:MFontWeight.bold4.value,
                          showArrow: true,
                          onClick: () {
                            imShowBottomSheet(
                              context,
                              (context) =>
                                  CurrencySelectionDialog(model.currency),
                            ).then((value) {
                              if (value is CurrencyALLType) {
                                model.updateCurrency(value);
                              }
                            });
                          },
                        ),
                      ),
                      ImGap.vGap24,
                      ImTextField(
                        title: '转账金额',
                        controller: _amountController,
                        hintText: '请输入金额',
                        errorText: model.error,
                        showClearButton: _amountController.text.isNotEmpty,
                        onTapClearButton: () {
                          _amountController.clear();
                          model.clearError();
                          model.setAmount(0.0);
                        },
                        onTapInput: model.showKeyboard,
                        descriptionWidget: ImText(
                          '账户可用余额：${model.walletAmount} ${model.currency.title}',
                          fontSize: 13,
                          color: ImColor.orange,
                        ),
                      ),
                      ImGap.vGap24,
                      ImTextField(
                        title: '备注',
                        rightTitleWidget: ImText(
                          '${30 - _remarkTextLength}字剩余',
                          fontSize: 13,
                          color: ImColor.black24,
                        ),
                        controller: _remarkController,
                        hintText: '恭喜发财，大吉大利',
                        textLength: 30,
                        keyboardType: TextInputType.text,
                        showClearButton: false,
                        onTapClearButton: () {},
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                        onTapInput: model.hideKeyboard,
                        onChanged: (value) {
                          setState(() {
                            _remarkTextLength = value.length;
                          });
                        },
                      ),
                      ImGap.vGap24,
                      PrimaryButton(
                        title: '转账',
                        block: true,
                        disabled: !model.isNextEnabled,
                        onPressed: () {
                          imShowBottomSheet(
                            context,
                            (context) => TransactionPwdDialog(
                              amount: model.amount,
                              transactionTypeTxt: '转账',
                              currencyUnit: model.currency.title,
                              onConfirmFunc: (
                                password, {
                                Function(String errorMsg)? showError,
                                Function(bool isShow)? showDialog,
                              }) async {
                                const bottomMargin =12.0;
                                ResponseData res =
                                    await requestTransfer(password);
                                bool needAuthPhone = res.needTwoFactorAuthPhone;
                                bool needAuthEmail = res.needTwoFactorAuthEmail;
                                if (res.success()) {
                                  if (needAuthPhone || needAuthEmail) {
                                    Map<String, String> tokenMap =
                                        await goSecondVerification(
                                            emailAuth: needAuthEmail,
                                            phoneAuth: needAuthPhone);
                                    if (tokenMap.isEmpty) {
                                      showErrorToast(
                                        '二次验证失败',
                                        bottomMargin: bottomMargin,
                                      );
                                      return;
                                    }
                                    ResponseData resAgain = await requestTransfer(
                                        password,
                                        tokenMap: tokenMap);
                                    Get.close(2);
                                    if (resAgain.success()) {
                                      showErrorToast(
                                        '好友转账发送成功',
                                        bottomMargin: bottomMargin+52,
                                      );
                                    } else {
                                      showErrorToast(
                                        '好友转账发送失败',
                                        bottomMargin: bottomMargin,
                                      );
                                    }
                                  } else {
                                    Get.close(2);
                                    showErrorToast(
                                      '好友转账发送成功',
                                      bottomMargin: bottomMargin+52,
                                    );
                                  }
                                } else {
                                  showErrorToast(
                                    '好友转账发送失败',
                                    bottomMargin: bottomMargin,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (model.isKeyboardVisible)
                  KeyboardNumber(
                    controller: _amountController,
                    showTopButtons: true,
                    onTap: (key) {
                      final double inputValue;

                      if (_amountController.text.isEmpty) {
                        inputValue = 0.0;
                        model.clearError();
                      } else {
                        inputValue = double.parse(_amountController.text);
                      }

                      model.setAmount(inputValue);

                      EasyDebounce.debounce(
                        'transferMoneyAmount',
                        const Duration(milliseconds: 500),
                        () {
                          if (model.isOverWalletAmount) {
                            model.setError('超过可转账可用余额');
                          } else {
                            model.clearError();
                          }
                        },
                      );
                    },
                    onTapCancel: model.hideKeyboard,
                    onTapConfirm: model.hideKeyboard,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
