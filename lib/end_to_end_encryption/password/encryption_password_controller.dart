import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/encryption/aes_encryption.dart';
import 'package:jxim_client/utils/encryption/rsa_encryption.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';

class EncryptionPasswordController extends GetxController{
  int MAX_ATTEMPT_COUNT = 5;
  String publicKey = '';
  String encPrivateKey = '';
  TextEditingController pwTextEditingController = TextEditingController();
  FocusNode pwFocusNode = FocusNode();
  RxString pwErrorText = "".obs;
  RxBool showPwClearButton = false.obs;
  int attemptCount = 1;
  RxBool isValidSubmit = false.obs;
  bool isFromChangePw = false;
  RxBool hidePw = true.obs;
  Function()? successCallback;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      if (Get.arguments["isFromChangePw"] != null) {
        isFromChangePw = Get.arguments["isFromChangePw"];
      }

      successCallback = Get.arguments["successCallback"];
    }

    pwFocusNode.addListener(() {
      if (pwFocusNode.hasFocus && pwTextEditingController.text.isNotEmpty) {
        showPwClearButton.value = true;
      } else {
        showPwClearButton.value = false;
      }
    });

    getCipherKeyByRemote();
  }

  @override
  void onClose() {
    pwTextEditingController.dispose();
    pwFocusNode.dispose();
    super.onClose();
  }

  Future<void> getCipherKeyByRemote() async {
    CipherKey data = await getCipherMyKey();
    if (data != null) {
      publicKey = data.public ?? '';
      encPrivateKey = data.encPrivate ?? '';
    }
  }

  Future<void> onClickNext() async {
    pwErrorText.value = "";

    if (attemptCount >= MAX_ATTEMPT_COUNT ) {
      isValidSubmit.value = false;
    }
    if (!isValidSubmit.value) {
      pwErrorText.value = localized(encPasswordErrorAttempt,params: ['${MAX_ATTEMPT_COUNT - attemptCount}']);
      return;
    }

    String password = pwTextEditingController.text;
    if (password.isNotEmpty) {
      try {
        String md52 = makeMD5(password);
        var aesEncryption = AesEncryption(md52);
        var decryptedPrivateKey = aesEncryption.decrypt(encPrivateKey);

        if (decryptedPrivateKey.isNotEmpty && RSAEncryption.isValidPrivateKey(decryptedPrivateKey)) {
          if (isFromChangePw){
            Get.toNamed(RouteName.encryptionSetupPage, arguments: {
              'type': EncryptionPasswordType.changePassword,
            });
          } else {
            bool status = objectMgr.encryptionMgr.saveEncryptionKey(publicKey,decryptedPrivateKey);
            if (status){
              objectMgr.encryptionMgr.decryptChat();
            }
            if (successCallback != null) {
              successCallback?.call();
            }
            Get.close(2);
            imBottomToast(
              Get.context!,
              title: localized(encryptionRecoverSuccess),
              icon: ImBottomNotifType.success,
            );
          }
        }
      } catch (e) {
        pwErrorText.value = localized(encPasswordErrorAttempt,params: ['${MAX_ATTEMPT_COUNT - attemptCount}']);
        attemptCount+=1;
      }
    }
  }

  void onChanged(String value) {
    if (value.isNotEmpty) {
      showPwClearButton.value = true;
    } else {
      showPwClearButton.value = false;
    }
    passwordValidate(value);
  }

  void onClearTextField() {
    isValidSubmit.value = false;
    pwTextEditingController.clear();
    showPwClearButton.value = false;
  }

  void passwordValidate(String value) {
    int textLength = value.length;
    String errorText = '';
    errorText = '';

    if (textLength > 0) {
    } else {
      errorText = localized(encPasswordErrorPleaseEnter);
    }

    pwErrorText.value = errorText;

    if (pwErrorText.isEmpty){
      isValidSubmit.value = true;
    } else {
      isValidSubmit.value = false;
    }
  }

  void onHidePassword() {
    hidePw.value = !hidePw.value;
  }
}