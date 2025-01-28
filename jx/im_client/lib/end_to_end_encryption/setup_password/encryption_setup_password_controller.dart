import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class EncryptionSetupPasswordController extends GetxController {
  static const int PASSWORD = 1;
  static const int CONFIRM_PASSWORD = 2;

  RxString title = ''.obs;

  TextEditingController pwTextEditingController = TextEditingController();
  TextEditingController confirmPwTextEditingController =
      TextEditingController();

  FocusNode pwFocusNode = FocusNode();
  FocusNode confirmPwFocusNode = FocusNode();

  RxString pwErrorText = "".obs;
  RxString confirmPwErrorText = "".obs;

  RxBool showPwClearButton = false.obs;
  RxBool showConfirmPwClearButton = false.obs;

  RxBool hidePw = true.obs;
  RxBool hideConfirmPw = true.obs;

  RxBool isValidSubmit = false.obs;

  late EncryptionPasswordType encryptionPasswordType;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      if (Get.arguments["type"] != null) {
        encryptionPasswordType = Get.arguments["type"];
        switch (encryptionPasswordType) {
          case EncryptionPasswordType.setup:
            title.value = localized(privateKeyPassword);
            break;
          case EncryptionPasswordType.changePassword:
            title.value = localized(privateKeyPassword);
            break;
          case EncryptionPasswordType.forgetPassword:
            title.value = localized(resetPasscodeText);
            break;
          default:
            title.value = localized(privateKeyPassword);
            break;
        }
      }
    }

    pwFocusNode.addListener(() {
      if (pwFocusNode.hasFocus && pwTextEditingController.text.isNotEmpty) {
        showPwClearButton.value = true;
      } else {
        showPwClearButton.value = false;
      }
    });

    confirmPwFocusNode.addListener(() {
      if (confirmPwFocusNode.hasFocus &&
          confirmPwTextEditingController.text.isNotEmpty) {
        showConfirmPwClearButton.value = true;
      } else {
        showConfirmPwClearButton.value = false;
      }
    });
  }

  @override
  void onClose() {
    pwTextEditingController.dispose();
    confirmPwTextEditingController.dispose();
    pwFocusNode.dispose();
    confirmPwFocusNode.dispose();
    super.onClose();
  }

  Future<void> onDoneClick() async {
    if (isValidSubmit.value) {
      pwErrorText.value = "";
      confirmPwErrorText.value = "";
      if (pwTextEditingController.text.isEmpty ||
          confirmPwTextEditingController.text.isEmpty) {
        if (pwTextEditingController.text.isEmpty) {
          pwErrorText.value = localized(encPasswordErrorPleaseEnter);
        }
        if (confirmPwTextEditingController.text.isEmpty) {
          confirmPwErrorText.value = localized(encPasswordErrorPleaseEnter);
        }
      } else {
        if (pwTextEditingController.text ==
            confirmPwTextEditingController.text) {
          bool status = false;

          objectMgr.encryptionMgr.showSending();
          String oriPublicKey = objectMgr.encryptionMgr.encryptionPublicKey;
          try {
            status = await objectMgr.encryptionMgr.updateEncryptionPrivateKey(
              oriPublicKey,
              confirmPwTextEditingController.text,
            );

            if (status) {
              if (encryptionPasswordType == EncryptionPasswordType.setup) {
                updateUnlockCount(true);
              }

              imBottomToast(
                Get.context!,
                title: localized(privateKeyPasswordSetSuccessfully),
                icon: ImBottomNotifType.success,
              );

              objectMgr.encryptionMgr.event(
                objectMgr.encryptionMgr,
                EncryptionMgr.eventResetPrivateKeyPW,
                data: objectMgr.encryptionMgr.hasEncryptedPrivateKey,
              );

              if (Get.arguments != null) {
                Map<dynamic, dynamic> cArgs = Get.arguments;
                if (cArgs['successCallback'] != null) {
                  cArgs['successCallback'].call();
                }
              }
              if (encryptionPasswordType ==
                  EncryptionPasswordType.createEncGroup) {
                Get.close(3);
              } else {
                Get.close(2);
              }
            } else {
              if (!notBlank(objectMgr.encryptionMgr.encryptionPrivateKey) ||
                  !notBlank(objectMgr.encryptionMgr.encryptionPublicKey)) {
                Get.close(3);
              } else {
                confirmPwErrorText.value = localized(twoPasswordDoNotMatch);
                dismissAllToast();
              }
            }
          } catch (e) {
            dismissAllToast();
          }
        }
      }
    }
  }

  void onChanged(int type, String value) {
    if (type == PASSWORD && value.isNotEmpty) {
      showPwClearButton.value = true;
    } else {
      showPwClearButton.value = false;
    }

    if (type == CONFIRM_PASSWORD && value.isNotEmpty) {
      showConfirmPwClearButton.value = true;
    } else {
      showConfirmPwClearButton.value = false;
    }

    passwordValidate(type, value);
  }

  void onClearTextField(int type) {
    isValidSubmit.value = false;
    if (type == PASSWORD) {
      pwTextEditingController.clear();
      showPwClearButton.value = false;
    } else if (type == CONFIRM_PASSWORD) {
      confirmPwTextEditingController.clear();
      showConfirmPwClearButton.value = false;
    }
  }

  void passwordValidate(int type, String value) {
    pwErrorText.value = '';
    confirmPwErrorText.value = '';

    int textLength = value.length;
    String errorText = '';
    errorText = '';
    if (textLength > 0) {
      if (value[0] == '_') {
        errorText = localized(encPasswordValidContent3);
      } else if (textLength < 7 || textLength > 20) {
        errorText = localized(encPasswordValidContent2);
      } else if ((pwTextEditingController.text.isNotEmpty &&
              confirmPwTextEditingController.text.isNotEmpty) &&
          (pwTextEditingController.text !=
              confirmPwTextEditingController.text)) {
        errorText = localized(twoPasswordDoNotMatch);
      }
    } else {
      errorText = localized(encPasswordErrorPleaseEnter);
    }

    if (type == PASSWORD) {
      pwErrorText.value = errorText;
    } else if (type == CONFIRM_PASSWORD) {
      confirmPwErrorText.value = errorText;
    }

    if ((pwErrorText.isEmpty && confirmPwErrorText.isEmpty) &&
        (pwTextEditingController.text == confirmPwTextEditingController.text)) {
      isValidSubmit.value = true;
    } else {
      isValidSubmit.value = false;
    }
  }

  void onHidePassword(int type) {
    switch (type) {
      case PASSWORD:
        hidePw.value = !hidePw.value;
        break;
      case CONFIRM_PASSWORD:
        hideConfirmPw.value = !hideConfirmPw.value;
        break;
    }
  }
}
