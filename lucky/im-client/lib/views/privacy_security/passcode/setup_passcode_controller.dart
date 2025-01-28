import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class SetupPasscodeController extends GetxController {
  String walletPasscodeOptionType = "";
  String currentPasscode = "";
  String token = "";
  String? fromView;
  Chat? chat;
  var contentMap = Map<String, String>();
  late TextEditingController passcodeController;

  SetupPasscodeController();
  SetupPasscodeController.desktop({String? from_view, Chat? chat,String? walletPasscodeOptionType, String? currentPasscode, String? token}){
    if(walletPasscodeOptionType != null){
      this.walletPasscodeOptionType = walletPasscodeOptionType;
    }

    if(currentPasscode != null){
      this.currentPasscode = currentPasscode;
    }

    if(token != null){
      this.token = token;
    }

    if(from_view != null){
      this.fromView = from_view;
    }

    if(chat != null){
      this.chat = chat;
    }
  }

  @override
  void onInit() {
    if (Get.arguments != null) {
      if (Get.arguments['passcode_type'] != null) {
        walletPasscodeOptionType = Get.arguments['passcode_type'];
      }
      if (Get.arguments['current_passcode'] != null) {
        currentPasscode = Get.arguments['current_passcode'];
      }
      if (Get.arguments['token'] != null) {
        token = Get.arguments['token'];
      }
      if (Get.arguments['from_view'] != null) {
        fromView = Get.arguments['from_view'];
      }
      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }
    }

    setupView();
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void setupView() {
    passcodeController = TextEditingController();
    switch (walletPasscodeOptionType) {
      case 'setPasscode':
        contentMap["toolbarTitle"] = localized(setPasscodeText);
        contentMap["setupPasscodeText"] = localized(setYourPasscode);
        break;
      case 'changePasscode':
        contentMap["toolbarTitle"] = localized(changePasscodeText);
        contentMap["setupPasscodeText"] = localized(enterYourNewPasscode);
        break;
      case 'resetPasscode':
        contentMap["toolbarTitle"] = localized(resetPasscodeText);
        contentMap["setupPasscodeText"] = localized(enterYourNewPasscode);
        break;
      default:
        break;
    }
  }

  void toConfirmPasscodeView() {
    if (walletPasscodeOptionType == WalletPasscodeOption.setPasscode.type) {
      final Map<String, dynamic> arguments = {};
      arguments["passcode_type"] = WalletPasscodeOption.setPasscode.type;
      arguments["passcode"] = passcodeController.text;

      if (fromView != null) {
        arguments["from_view"] = fromView;
      }
      if (chat != null) {
        arguments["chat"] = chat;
      }
      if(objectMgr.loginMgr.isDesktop){
        Get.toNamed(
          RouteName.confirmPasscodeView,
          arguments: arguments,
          id: 3
        );
      }else{
        Get.toNamed(
          RouteName.confirmPasscodeView,
          arguments: arguments,
        );
      }
    } else if (walletPasscodeOptionType ==
        WalletPasscodeOption.changePasscode.type) {
      if(objectMgr.loginMgr.isDesktop) {
        Get.toNamed(
          RouteName.confirmPasscodeView,
          arguments: {
            'passcode_type': WalletPasscodeOption.changePasscode.type,
            'passcode': passcodeController.text,
            'current_passcode': currentPasscode,
          },
          id: 3
        );
      }else{
        if(objectMgr.loginMgr.isDesktop){
          Get.toNamed(
            RouteName.confirmPasscodeView,
            arguments: {
              'passcode_type': WalletPasscodeOption.changePasscode.type,
              'passcode': passcodeController.text,
              'current_passcode': currentPasscode,
            },
            id: 3,
          );
        }else{
          Get.toNamed(
            RouteName.confirmPasscodeView,
            arguments: {
              'passcode_type': WalletPasscodeOption.changePasscode.type,
              'passcode': passcodeController.text,
              'current_passcode': currentPasscode,
            },
          );
        }

      }

    } else if (walletPasscodeOptionType ==
        WalletPasscodeOption.resetPasscode.type) {
      if(objectMgr.loginMgr.isDesktop){
        Get.toNamed(
          RouteName.confirmPasscodeView,
          arguments: {
            'passcode_type': WalletPasscodeOption.resetPasscode.type,
            'passcode': passcodeController.text,
            'token': token,
          },
          id: 3,
        );
      }else{
        Get.toNamed(
          RouteName.confirmPasscodeView,
          arguments: {
            'passcode_type': WalletPasscodeOption.resetPasscode.type,
            'passcode': passcodeController.text,
            'token': token,
          },
        );
      }

    }
  }

  void clearPasscode() {
    passcodeController.clear();
  }
}
