import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';

class EditProfileController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode bioFocusNode = FocusNode();

  final ReelMyProfileController parentController;

  RxBool showNameClearBtn = false.obs;
  RxBool showBioClearBtn = false.obs;
  RxBool isCanSend = false.obs;
  RxInt nameTxtRemainCount = 0.obs;
  RxInt bioTxtRemainCount = 0.obs;
  RxInt nameTxtCount = 0.obs;
  RxInt bioTxtCount = 0.obs;

  int nameMaxLength = 30;
  int bioMaxLength = 242;

  ReelEditTypeEnum initialFocus = ReelEditTypeEnum.nickname;

  EditProfileController({required this.parentController});

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    nameController.text = parentController.reelProfile.value.name.value!;
    bioController.text = parentController.reelProfile.value.bio.value!;

    // nameTxtRemainCount.value = nameMaxLength - nameController.text.length;
    // bioTxtRemainCount.value = bioMaxLength - bioController.text.length;
    nameTxtCount.value = nameController.text.length > nameMaxLength
        ? nameMaxLength
        : nameController.text.length;
    bioTxtCount.value = bioController.text.length > bioMaxLength
        ? bioMaxLength
        : bioController.text.length;
    setIsCanSend(nameController.text, bioController.text); //一進入,未點擊輸入框就檢查

    nameController.addListener(() {
      setIsCanSend(nameController.text, bioController.text);
    });
    bioController.addListener(() {
      setIsCanSend(nameController.text, bioController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialFocus == ReelEditTypeEnum.nickname
          ? nameFocusNode.requestFocus()
          : bioFocusNode.requestFocus();
    });
  }

  //用於計算剩餘可輸入字數(後來需求改掉,以防萬一先留著)
  void setRemainTxtCount(String type) {
    if (type == 'name') {
      nameTxtRemainCount.value = nameMaxLength - nameController.text.length < 0
          ? 0
          : nameMaxLength - nameController.text.length;
    } else {
      bioTxtRemainCount.value = bioMaxLength - bioController.text.length < 0
          ? 0
          : bioMaxLength - bioController.text.length;
    }
  }

  void setTxtCount(String type) {
    if (type == 'name') {
      nameTxtCount.value = nameController.text.length > nameMaxLength
          ? nameMaxLength
          : nameController.text.length;
    } else {
      bioTxtCount.value = bioController.text.length > bioMaxLength
          ? bioMaxLength
          : bioController.text.length;
    }
  }

  void onTapSave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await parentController.updateProfileInfo(
      name: nameController.text,
      bio: bioController.text,
    );
    Get.back();
  }

  void setShowClearBtn(bool showBtn, {required String type}) {
    type == 'bio' ? showBioClearBtn(showBtn) : showNameClearBtn(showBtn);
  }

  void setIsCanSend(String nameInput, String bioInput) {
    if (nameInput.isNotEmpty) {
      //因為後端api還沒改好,所以現在先限制user需填寫名字按鈕才會高亮
      isCanSend.value = true;
    } else {
      isCanSend.value = false;
    }
  }
}
