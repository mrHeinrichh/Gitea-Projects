import 'package:get/get.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class FriendVerifyController extends GetxController {
  RxString code = ''.obs;
  RxInt verified = 0.obs;
  RxInt count = 0.obs;
  RxBool isValidToProceed = false.obs;

  @override
  void onInit() {
    super.onInit();
    getFriendAssistDetail();
  }

  void refreshCode() {
    getFriendAssistDetail();
  }

  Future<void> getFriendAssistDetail() async {
    String publicKey = objectMgr.encryptionMgr.encryptionPublicKey;
    int uid = objectMgr.userMgr.mainUser.uid;

    if (publicKey == '') {
      CipherKey data = await getCipherMyKey();
      if (data.public != '') {
        publicKey = data.public ?? '';
      }
    }

    if (publicKey != '') {
      FriendAssistData data = await getFriendAssist(publicKey,uid);
      code.value = data.code ?? '';
      verified.value = data.verified ?? 0;
      count.value = data.count ?? 0;
    }

    validateAbleToProceedAction();
  }

  void validateAbleToProceedAction(){
    if (verified.value == count.value) {
      isValidToProceed.value = true;
    } else {
      isValidToProceed.value = false;
    }
  }

  void confirmResetPassword() {
    if (!isValidToProceed.value) return;

    showCustomBottomAlertDialog(
      Get.context!,
      subtitle: localized(youNeedToResetEnter),
      items: [
        CustomBottomAlertItem(
          text: localized(continueProcessing),
          onClick: () {
            Get.toNamed(RouteName.encryptionSetupPage, arguments: {
              'type': EncryptionPasswordType.forgetPassword,
            });
          },
        ),
      ],
    );
  }

  void skipFriendVerified(){
    Get.close(1);
  }
}
