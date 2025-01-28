
import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/object/account_contact.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/components/transaction_pwd_dialog.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/views/wallet/transfer_contact_bottom_sheet.dart';

import '../../api/account.dart';
import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/im_toast/im_gap.dart';
import '../../utils/im_toast/primary_button.dart';
import '../../utils/theme/text_styles.dart';
import '../component/new_appbar.dart';
import 'components/transfer_currency.dart';

class TransferView extends GetView<TransferController> {
  String? accountId;
  int? userId;
  String? nickName;
  String? phoneCode;
  String? phone;
  String? userName;

  TransferView(
      {super.key,
      this.accountId,
      this.userId,
      this.nickName,
      this.phoneCode,
      this.phone,
      this.userName}) {
    if (accountId != null) {
      getUserInfo();
    }
  }
  getUserInfo() async {
    String userId = accountId!;
    try {
      User user = await getUser(userId: userId);
      this.userId = user.uid;
      nickName = user.nickname;
      phoneCode = user.countryCode;
      phone = user.contact;
      userName = user.username;

      controller.setToUserText(
          this.userId!, nickName ?? "", phoneCode ?? "", phone ?? "",
          userName: userName ?? "");
    } catch (e) {
      String errorMessage = localized(unexpectedError);
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: errorMessage, icon: ImBottomNotifType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        title: '转账',
      ),
      body: common.KeyboardHideWidget(
        child: GestureDetector(
          onTap: () {
            controller.isShowMatchContact.value = false;
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getTitle('转给谁'),
                      getToWhomTextField(context),
                      getPhoneErrorHintWidget(),
                      ImGap.vGap(24),
                      getTitle('货币类型'),
                      getCurrentType(context),
                      ImGap.vGap(24),
                      getTitle('转账金额'),
                      getAmountTextField(),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 10),
                        child: Obx(
                          () => controller.currentWallet.value != null
                              ? Text(
                                  '账户可用余额: ${controller.currentWallet.value?.amount?.toStringAsFixed(2).cFormat()} '
                                  '${controller.currentWallet.value?.currencyType}',
                                  style: jxTextStyle.textStyle14(
                                      color: JXColors.orange),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      ImGap.vGap(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          getTitle('备注'),
                          Obx(() {
                            if (controller != null && controller.initialized) {
                              return Text(
                                '${controller.remainInputCount.value} 字剩余',
                                style: jxTextStyle.textStyle13(
                                    color: JXColors.black24),
                              );
                            } else {
                              return const SizedBox(); // 或者返回一個空的 widget
                            }
                          })
                        ],
                      ),
                      getMemoTextField(),
                      ImGap.vGap(24),
                      Obx(() => PrimaryButton(
                            title: '确认转账',
                            width: double.infinity,
                            disabled: !controller.isCanSend.value,
                            txtColor: Colors.white,
                            bgColor: accentColor,
                            disabledTxtColor: JXColors.black24,
                            disabledBgColor: JXColors.bgTertiaryColor,
                            onPressed: () {
                              //先關閉鍵盤
                              FocusScope.of(context).unfocus();
                              if (controller.toUserId.value == 0) {
                                return;
                              }
                              common.imShowBottomSheet(
                                  context,
                                  (context) => TransactionPwdDialog(
                                        amount: controller
                                            .amountTextController.text,
                                        currencyUnit: controller
                                            .currentWallet.value?.currencyType,
                                        onConfirmFunc: (password,
                                            {Function(String errorMsg)?
                                                showError,
                                            Function(bool isShow)?
                                                showDialog}) async {
                                          controller.handeData(context, password);
                                        },
                                      ));
                            },
                          )),
                    ],
                  ),
                  Obx(() {
                    return controller.isShowMatchContact.value &&
                            controller.accountContactList.isNotEmpty
                        ? Positioned(
                            top: MediaQuery.of(context).viewInsets.top + 82,
                            left: 0,
                            right: 0,
                            child: getToWhomList(controller.accountContactList),
                          )
                        : const SizedBox();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getToWhomList(List<AccountContact> contactList) {
    return Container(
      padding: EdgeInsets.only(left: 16),
      height: contactList.length > 1 ? 89 : 45,
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: contactList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                AccountContact data = contactList[index];
                controller.setToUserText(data.uid!, data.nickname!,
                    data.countryCode!, data.contact!);
                controller.isShowMatchContact.value = false;
              },
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 16),
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(contactList[index].nickname ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: jxTextStyle.textStyle16())),
                        Text(
                          "${contactList[index].countryCode}${contactList[index].contact}",
                          style: jxTextStyle.textStyle16(
                              color: JXColors.black48),
                        )
                      ],
                    ),
                  ),
                  if (contactList.length != index + 1)
                    Container(
                      height: 0.3,
                      width: double.infinity,
                      color: JXColors.black20,
                    )
                ],
              ),
            );
          }),
    );
  }

  getToWhomTextField(context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        right: 12.0,
      ),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      height: 44.w,
      alignment: Alignment.center,
      child: TextField(
        contextMenuBuilder: common.textMenuBar,
        textInputAction: TextInputAction.done,
        controller: controller.toWhomTextController,
        focusNode: controller.toWhomTextFocus,
        style: jxTextStyle.textStyle16(),
        maxLines: 1,
        keyboardType: TextInputType.phone,
        cursorColor: accentColor,
        onChanged: (txt) {
          controller.toWhomTextController.text.isEmpty
              ? controller.setShowClearBtn(false)
              : controller.setShowClearBtn(true);
        },
        readOnly: controller.isFromScanQRCode,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            // vertical: 9,
          ),
          hintText: '请输入手机号',
          hintStyle: const TextStyle(
            color: JXColors.supportingTextBlack,
          ),
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: !controller.isFromScanQRCode
              ? Container(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getClearBtn(type: 'showToWhom'),
                      ImGap.hGap(10),
                      GestureDetector(
                        onTap: () {
                          showTransferContactBottomSheet(context);
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/wallet/is_friend.svg',
                          width: 20,
                          height: 20,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
          border: InputBorder.none,
        ),
      ),

      // child: Container(
      //   alignment: Alignment.center,
      //   child: Obx(
      //     () {
      //       List<String> matchContact = [];
      //       for (var element in controller.accountContactList) {
      //         matchContact.add("${element.nickname} ${element.countryCode}${element.contact}");
      //       }
      //       return EasyAutocomplete(
      //         controller: controller.toWhomTextController,
      //         cursorColor: accentColor,
      //         suggestions: matchContact,
      //         keyboardType: TextInputType.phone,
      //         focusNode: controller.toWhomTextFocus,
      //         onChanged: (txt) {
      //           controller.toWhomTextController.text.isEmpty ?
      //           controller.setShowClearBtn(false) : controller.setShowClearBtn(true);
      //         },
      //         onSubmitted: (value) {
      //           //TODO:這邊有bug
      //           //找到該值得index
      //           int index = matchContact.indexWhere((element) => element == value);
      //           if (index != -1 && controller.accountContactList.length > index) {
      //             AccountContact data = controller.accountContactList[index];
      //             controller.setToUserText(data.uid!, data.nickname!, data.countryCode!, data.contact!);
      //           }
      //           pdebug('onSubmitted value: $value');
      //         },
      //         suggestionBuilder: (data) {
      //           return Container(
      //               margin: EdgeInsets.all(1),
      //               padding: EdgeInsets.all(5),
      //               child: Text(data, style: TextStyle(color: JXColors.black48)));
      //         },
      //         decoration: InputDecoration(
      //           isDense: true,
      //           contentPadding: const EdgeInsets.symmetric(
      //             horizontal: 16,
      //             vertical: 9,
      //           ),
      //           hintText: '请输入手机号',
      //           hintStyle: const TextStyle(
      //             color: JXColors.supportingTextBlack,
      //           ),
      //           suffixIconConstraints: const BoxConstraints(maxHeight: 44),
      //           suffixIcon: !controller.isFromScanQRCode ? Container(
      //             child: Row(
      //               mainAxisSize: MainAxisSize.min,
      //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //               children: [
      //                 getClearBtn(),
      //                 ImGap.hGap(10),
      //                 GestureDetector(
      //                   onTap: () {
      //                     showTransferContactBottomSheet(context);
      //                   },
      //                   child: SvgPicture.asset(
      //                     'assets/svgs/wallet/is_friend.svg',
      //                     width: 20,
      //                     height: 20,
      //                     color: Colors.black,
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ) : const SizedBox(),
      //           border: InputBorder.none,
      //         ),
      //       );
      //     }
      //   ),
      // ),
    );
  }

  getClearBtn({type}) {
    return Obx(() => Visibility(
          visible: type == 'showToWhom' ? controller.showToWhomTextClearBtn.value : controller.showAmountClearBtn.value,
          child: GestureDetector(
            onTap: () {
              if(type == 'showToWhom') {
                controller.toWhomTextController.text = '';
                controller.showToWhomTextClearBtn(false);
              } else {
                controller.amountTextController.text = '';
                controller.showAmountClearBtn(false);
              }
            },
            child: SvgPicture.asset(
              'assets/svgs/clear_icon.svg',
              color: JXColors.hintColor,
              width: 14,
              height: 14,
              fit: BoxFit.fitWidth,
            ),
          ),
        ));
  }

  Future showTransferContactBottomSheet(BuildContext context) {
    TransferController controller = Get.find<TransferController>();
    controller.getFriendList();
    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => const TransferContactBottomSheet(),
    ).then(
      (value) => controller.clearSearching(),
    );
  }

  getPhoneErrorHintWidget() {
    return Obx(() => Visibility(
          visible: controller.phoneErrorHint.isNotEmpty,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
            child: Text(
              controller.phoneErrorHint.value,
              style: jxTextStyle.textStyle14(
                color: JXColors.red,
              ),
            ),
          ),
        ));
  }

  getAmountTextField() {
    return Container(
      padding: const EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        right: 12.0,
      ),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      height: 44.w,
      alignment: Alignment.center,
      child: TextField(
        contextMenuBuilder: common.textMenuBar,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,
        focusNode: controller.memoTextFocus,
        controller: controller.amountTextController,
        style: jxTextStyle.textStyle16(),
        maxLines: 1,
        cursorColor: accentColor,
        onChanged: (value) {
          controller.amountTextController.text.isEmpty
              ? controller.setShowAmountClearBtn(false)
              : controller.setShowAmountClearBtn(true);
          if(value.isNotEmpty){
            dynamic amount = double.tryParse(value);
            if(amount==null){
              controller.amountTextController.text="";
              return;
            }
          }
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            // vertical: 9,
          ),
          hintText: '请输入金额',
          hintStyle: const TextStyle(
            color: JXColors.supportingTextBlack,
          ),
          border: InputBorder.none,
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: getClearBtn()
        ),
      ),
    );
  }

  getMemoTextField() {
    return Container(
      padding: const EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        right: 12.0,
      ),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      height: 44.w,
      alignment: Alignment.center,
      child: TextField(
        contextMenuBuilder: common.textMenuBar,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.multiline,
        focusNode: controller.amountTextFocus,
        controller: controller.memoTextController,
        style: jxTextStyle.textStyle16(),
        maxLines: null,
        maxLength: 30,
        buildCounter: (
          BuildContext context, {
          required int currentLength,
          required int? maxLength,
          required bool isFocused,
        }) {
          return null;
        },
        cursorColor: accentColor,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            // vertical: 9,
          ),
          hintText: '请输入（选填）',
          hintStyle: const TextStyle(
            color: JXColors.supportingTextBlack,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  getTitle(txt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        txt,
        style: jxTextStyle.textStyle14(
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }

  getCurrentType(context) {
    return GestureDetector(
      onTap: () {
        createTransferCurrencyBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 8.0,
          top: 4.0,
          bottom: 4.0,
        ),
        decoration: BoxDecoration(
          color: JXColors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        height: 44.w,
        alignment: Alignment.center,
        child: Row(
          children: [
            const Expanded(
                child: Text(
              '币种',
              style: const TextStyle(
                color: JXColors.black,
                fontSize: 16.0,
              ),
            )),
            Obx(
              () => Text(
                controller.currentWallet.value != null
                    ? controller.currentWallet.value!.currencyName ?? ""
                    : "",
                style: const TextStyle(
                  color: JXColors.secondaryTextBlack,
                  fontSize: 16.0,
                ),
              ),
            ),
            ImGap.hGap8,
            SvgPicture.asset(
              'assets/svgs/wallet/arrow_right.svg',
              width: 20,
              height: 20,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  createTransferCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (BuildContext context) {
          return TransferCurrency();
        });
  }
}
