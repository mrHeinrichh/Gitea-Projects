import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/encryption/aes_encryption.dart';
import 'package:jxim_client/utils/encryption/rsa_encryption.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';

class EncryptionPasswordController extends GetxController {
  int remainAttemptCount = 5;
  int unlockTime = 0;
  RxString unlockTimeError = ''.obs;
  String publicKey = '';
  String encPrivateKey = '';
  TextEditingController pwTextEditingController = TextEditingController();
  FocusNode pwFocusNode = FocusNode();
  RxString pwErrorText = "".obs;
  RxBool showPwClearButton = false.obs;
  RxBool isValidSubmit = false.obs;
  bool isFromChangePw = false;
  RxBool hidePw = true.obs;
  bool isClosing = false;
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

    if (isFromChangePw) {
      getAttemptCount();
    }

    pwFocusNode.addListener(() {
      if (pwFocusNode.hasFocus && pwTextEditingController.text.isNotEmpty) {
        showPwClearButton.value = true;
      } else {
        showPwClearButton.value = false;
      }
    });
  }

  @override
  void onClose() {
    pwTextEditingController.dispose();
    pwFocusNode.dispose();
    super.onClose();
  }

  Future<void> getCipherKeyByRemote() async {
    try {
      CipherKey data = await getCipherMyKey();
      if (data != null) {
        publicKey = data.public ?? '';
        encPrivateKey = data.encPrivate ?? '';
        objectMgr.encryptionMgr.hasEncryptedPrivateKey = data.encPrivate ?? '';
        objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.BE_ENCRYPTED_KEY, encPrivateKey);
      }
    } catch (e) {
      publicKey = objectMgr.encryptionMgr.encryptionPublicKey;
      String? bePrivateKey =
          objectMgr.localStorageMgr.read(LocalStorageMgr.BE_ENCRYPTED_KEY);
      if (notBlank(bePrivateKey)) {
        encPrivateKey = bePrivateKey!;
      } else {
        encPrivateKey = objectMgr.encryptionMgr.hasEncryptedPrivateKey;
      }
    }
  }

  Future<void> onClickNext() async {
    if (!isValidSubmit.value) {
      return;
    }

    if (pwTextEditingController.text.isEmpty) {
      isValidSubmit.value = false;
      return;
    }

    if (isFromChangePw && remainAttemptCount == 0) {
      isValidSubmit.value = false;
    }

    await getCipherKeyByRemote();

    pwErrorText.value = "";
    if (isFromChangePw) {
      handleChangePw();
    } else {
      handleSavePrivateKey();
    }
  }

  Future<void> getAttemptCount() async {
    try {
      UnlockCount data = await getUnlockCount();
      remainAttemptCount = data.remainCount ?? 5;
      unlockTime = data.resetIn ?? 0;
    } catch (_) {}
    if (remainAttemptCount < 5) {
      pwErrorText.value = localized(
        encPasswordErrorAttempt,
        params: [
          remainAttemptCount.toString(),
        ],
      );
    }
    calculateUnlockTime(unlockTime);
  }

  Future<void> updateAttemptCount(bool isUnlock) async {
    UnlockCount data = await updateUnlockCount(isUnlock);
    remainAttemptCount = data.remainCount ?? 5;
    unlockTime = data.resetIn ?? 0;

    if (remainAttemptCount == 0) {
      isValidSubmit.value = false;
    }

    if (!isUnlock) {
      pwErrorText.value = localized(
        encPasswordErrorAttempt,
        params: [
          remainAttemptCount.toString(),
        ],
      );
    }
    calculateUnlockTime(data.resetIn ?? 0);
  }

  String decryptPrivateKeyPassword() {
    try {
      String md52 = makeMD5(pwTextEditingController.text);
      var aesEncryption = AesEncryption(md52);
      var decryptedPrivateKey = aesEncryption.decrypt(encPrivateKey);
      return decryptedPrivateKey;
    } catch (e) {
      return '';
    }
  }

  Future<void> handleSavePrivateKey() async {
    if (isClosing) return;
    String decryptedPrivateKey = decryptPrivateKeyPassword();
    if (decryptedPrivateKey.isNotEmpty &&
        RSAEncryption.isValidPrivateKey(decryptedPrivateKey)) {
      isClosing = true;
      bool status = objectMgr.encryptionMgr
          .saveEncryptionKey(publicKey, decryptedPrivateKey);
      if (status) {
        objectMgr.encryptionMgr.decryptChat();
      }
      if (successCallback != null) {
        successCallback?.call();
      }

      if (pwFocusNode.hasFocus) {
        pwFocusNode.unfocus();
      }

      imBottomToast(
        Get.context!,
        title: localized(encryptionRecoverSuccess),
        icon: ImBottomNotifType.success,
      );
      Get.close(2);
    } else {
      pwErrorText.value = localized(passwordDoesNotMatch);
    }
  }

  void handleChangePw() {
    if (isClosing) return;
    String decryptedPrivateKey = decryptPrivateKeyPassword();
    if (decryptedPrivateKey.isNotEmpty &&
        RSAEncryption.isValidPrivateKey(decryptedPrivateKey)) {
      isClosing = true;
      updateAttemptCount(true);
      Get.close(1);
      Get.toNamed(
        RouteName.encryptionSetupPage,
        arguments: {
          'type': EncryptionPasswordType.changePassword,
        },
      );
    } else {
      updateAttemptCount(false);
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
    if (isFromChangePw && remainAttemptCount == 0) {
      isValidSubmit.value = false;
      return;
    }
    int textLength = value.length;
    String errorText = '';
    errorText = '';

    if (textLength > 0) {
    } else {
      errorText = localized(encPasswordErrorPleaseEnter);
    }

    pwErrorText.value = errorText;

    if (pwErrorText.isEmpty) {
      isValidSubmit.value = true;
    } else {
      isValidSubmit.value = false;
    }
  }

  void onHidePassword() {
    hidePw.value = !hidePw.value;
  }

  void calculateUnlockTime(int timestamp) {
    if (timestamp == 0) {
      unlockTimeError.value = '';
      return;
    }

    String unlockTime = '';

    DateTime timeToCheck =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    DateTime currentDateTime = DateTime.now();

    if (currentDateTime.isAfter(timeToCheck)) {
      unlockTimeError.value = '';
      return;
    } else {
      // Extract days, hours, minutes, and seconds from the difference
      Duration difference = timeToCheck.difference(currentDateTime);
      int hours = difference.inHours;
      int minutes = difference.inMinutes.remainder(60);
      int seconds = difference.inSeconds.remainder(60);

      if (hours > 0) {
        unlockTime = localized(hoursParam, params: [hours.toString()]);
      } else if (minutes > 0) {
        unlockTime = localized(minutesParam, params: [hours.toString()]);
      } else if (seconds > 0) {
        unlockTime = localized(secondsParam, params: [hours.toString()]);
      }

      unlockTimeError.value = localized(
        youCanTryAndResetAfter,
        params: [
          unlockTime,
        ],
      );
    }
  }
}
