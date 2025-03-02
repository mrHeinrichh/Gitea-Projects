import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/open_install_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/register/components/themed_alert_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class NewProfileController extends GetxController {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  Rx<File> avatarFile = File('').obs;
  final isClear = false.obs;
  RxString username = "".obs;
  RxString name = "".obs;

  RxBool isValidated = false.obs;

  RxBool isValidName = false.obs;
  RxInt nameLength = 30.obs;

  RxBool isValidUsername = true.obs;
  RxInt usernameLength = 20.obs;
  RxBool usernameTaken = false.obs;
  RxBool usernameLengthError = false.obs;
  RxBool usernameFormat = false.obs;
  RxBool usernameUnderscore = false.obs;

  RxBool progressRegister = false.obs;
  RxBool checkingUsername = false.obs;
  RxBool registerComplete = false.obs;

  late CommonAlbumController commonAlbumController;

  bool get usernameValidFormat =>
      usernameUnderscore.value &&
      usernameFormat.value &&
      usernameLengthError.value;

  @override
  void onClose() {
    usernameController.removeListener(() {});
    nameController.removeListener(() {});
    usernameController.dispose();
    nameController.dispose();
    Get.findAndDelete<CommonAlbumController>(tag: commonAlbumTag);
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    commonAlbumController = Get.findOrPut<CommonAlbumController>(
        CommonAlbumController(),
        tag: commonAlbumTag);
    usernameController.addListener(() {
      username.value = usernameController.text;
    });
    nameController.addListener(() {
      name.value = nameController.text;
    });
    debounce(
      username,
      (_) => checkExistingUser(),
      time: const Duration(milliseconds: 500),
    );

    getInviterInfo();
  }

  getInviterInfo() async {
    if (Platform.isAndroid || Platform.isIOS) {
      openInstallMgr.init();
      openInstallMgr.handleInstallInviterInfo();
    }
  }

  handleInstallGroupLink() {
    if (Platform.isAndroid || Platform.isIOS) {
      final isInstalled =
          objectMgr.localStorageMgr.globalRead(LocalStorageMgr.INSTALL_DATE) !=
              null;
      if (!isInstalled) {
        // 新用户注册后，首次安装app
        // 从群组链接过来安装app后加群的逻辑
        openInstallMgr.handleInstallFriendAndGroupLink();
        objectMgr.localStorageMgr.globalWrite(
          LocalStorageMgr.INSTALL_DATE,
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }
      // 新用户注册后，已安装app
      // 从群组链接过来唤醒后加群的逻辑
      openInstallMgr.handleWakeupFriendAndGroupLink();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  processImage(AssetEntity asset) async {
    File? assetFile = await asset.file;
    if (assetFile != null) {
      File? croppedFile = await cropImage(assetFile);
      if (croppedFile != null) {
        File? compressedFile = await getThumbImageWithPath(
          croppedFile,
          asset.width,
          asset.height,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'head',
        );
        avatarFile.value = compressedFile;
      }
    } else {
      Toast.showToast(localized(photoGetFailed));
    }
  }

  Future<(String?, String?)> uploadPhoto(
      File imageFile, String uploadKey) async {
    String? gPath;
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      storageType: StorageType.avatar,
      cancelToken: CancelToken(),
      onGaussianComplete: (String gausPath) {
        gPath = gausPath;
      },
    );

    return (imageUrl, gPath);
  }

  usernameErrorDecider(String value) {
    final int wordsLength = getMessageLength(value);
    if (value[0] == '_') {
      usernameUnderscore.value = false;
    } else {
      usernameUnderscore.value = true;
    }
    if (RegExp(r'^(?=[\w]*$)(?=.*?^[a-zA-Z0-9])(?!.*_.*_)').hasMatch(value)) {
      usernameFormat.value = true;
    } else {
      usernameFormat.value = false;
    }
    if (wordsLength < 7 || wordsLength > 20) {
      usernameLengthError.value = false;
    } else {
      usernameLengthError.value = true;
    }
    if (!usernameValidFormat) finalValidation();
  }

  setUsernameValidity(bool value) {
    usernameUnderscore.value = value;
    usernameLengthError.value = value;
    usernameFormat.value = value;

    if (username.value.isEmpty) {
      finalValidation();
    }
  }

  setNameValidity(bool value) {
    isValidName(value);
    finalValidation();
  }

  finalValidation() async {
    if (username.isEmpty) {
      isValidUsername.value = true;
    } else {
      if (usernameValidFormat && !usernameTaken.value) {
        isValidUsername.value = true;
      } else {
        isValidUsername.value = false;
      }
    }

    if (isValidName.value && isValidUsername.value) {
      isValidated.value = true;
    } else {
      isValidated.value = false;
    }
  }

  checkExistingUser() async {
    if (username.value.length > 6 && usernameValidFormat) {
      checkingUsername.value = true;
      try {
        final res = await checkUser(usernameController.text);
        if (res) {
          usernameTaken.value = false;
        } else {
          usernameTaken.value = true;
        }
      } on AppException catch (e) {
        usernameTaken.value = true;
        pdebug('[ERROR-name_exist_check]: ${e.getMessage()}');
      }
      finalValidation();
      checkingUsername.value = false;
    } else {
      usernameTaken.value = false;
    }
  }

  contactAccessDialog(BuildContext context) async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      showCupertinoModalPopup(
        context: context,
        barrierDismissible: false,
        builder: (context) => ThemedAlertDialog(
          title: '"Jiang Xia" would like to Access Your Contacts',
          content: 'This will be used to manage your contacts',
          cancelButtonText: "Don't allow",
          cancelButtonCallback: () {
            Get.back();
          },
          confirmButtonText: "OK",
          confirmButtonCallback: () async {
            await Permission.contacts.request().isGranted;
            Get.back();
          },
        ),
      );
    }
  }

  register(BuildContext context) async {
    progressRegister.value = true;
    try {
      String profilePic = '';
      String gausPath = '';
      if (avatarFile.value.path != '') {
        String uploadKey = objectMgr.userMgr.mainUser.generateAvatarUrl();
        final (String? imgUrl, String? gPath) = await uploadPhoto(
          avatarFile.value,
          uploadKey,
        );
        gausPath = gPath ?? '';
        if (imgUrl != null) {
          profilePic = removeEndPoint(imgUrl);
        }
      }

      final user = await objectMgr.loginMgr.registerAccount(
        nickname: nameController.text.trim(),
        username: usernameController.text.trim(),
        profilePic: profilePic,
        gausPath: gausPath,
      );

      await objectMgr.init();
      if (objectMgr.loginMgr.isLogin) {
        await objectMgr.prepareDBData(user);
      }
      if (objectMgr.loginMgr.account != null) {
        objectMgr.loginMgr.account?.user = user;
        objectMgr.loginMgr.account?.user!.nickname = nameController.text;
        objectMgr.loginMgr.saveAccount(objectMgr.loginMgr.account!);
      }

      objectMgr.socketMgr.updateSocketTime =
          DateTime.now().millisecondsSinceEpoch;
      objectMgr.appInitState.value = AppInitState.idle;
      progressRegister.value = false;
      registerComplete.value = true;
      Get.offAllNamed(RouteName.home);
      handleInstallGroupLink();
    } on AppException catch (e) {
      progressRegister.value = false;
      Toast.showToast(e.getMessage());
    }
  }

  void clearPhoto() {
    avatarFile.value = File('');
  }

  String getUsernameErrorMessage() {
    if (username.value.isEmpty) {
      return localized(ifYouDidntProvideAnUsername);
    } else if (!usernameLengthError.value) {
      return localized(usernameMustBetween7to20Characters);
    } else if (!usernameUnderscore.value) {
      return localized(usernameMustStartWithLetterOrNumber);
    } else if (!usernameFormat.value) {
      return localized(usernameInputLettersNumbersAndUnderscoreOnly);
    } else if (usernameTaken.value) {
      return localized(userUsernameTaken);
    } else {
      return '';
    }
  }

  void showPickPhotoOption(BuildContext context) {
    FocusScope.of(context).unfocus();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext c) {
        return CupertinoActionSheet(
          actions: [
            Container(
              color: Colors.white,
              child: OverlayEffect(
                child: CupertinoActionSheetAction(
                  onPressed: () {
                    getCameraPhoto(c);
                    Navigator.pop(c);
                  },
                  child: Text(
                    localized(takeAPhoto),
                    style: jxTextStyle.textStyle20(color: themeColor),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: OverlayEffect(
                child: CupertinoActionSheetAction(
                  onPressed: () {
                    getGalleryPhoto(c);
                    Navigator.pop(c);
                  },
                  child: Text(
                    localized(chooseFromGalley),
                    style: jxTextStyle.textStyle20(color: themeColor),
                  ),
                ),
              ),
            ),
            if (avatarFile.value.path.isNotEmpty)
              Container(
                color: Colors.white,
                child: CupertinoActionSheetAction(
                  onPressed: () {
                    clearPhoto();
                    Navigator.pop(context);
                  },
                  child: Text(
                    localized(deletePhoto),
                    style: jxTextStyle.textStyle20(color: colorRed),
                  ),
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle20(color: themeColor),
            ),
          ),
        );
      },
    );
  }

  getGalleryPhoto(BuildContext context) async {
    if (!await commonAlbumController.onPrepareMediaPicker()) return;

    showModalBottomSheet(
      context: Get.context ?? context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePhotoPicker(
        provider: commonAlbumController.assetPickerProvider!,
        pickerConfig: commonAlbumController.pickerConfig!,
        ps: commonAlbumController.ps!,
        isUseCommonAlbum: true,
      ),
    ).then((asset) async {
      if (commonAlbumController
          .assetPickerProvider!.selectedAssets.isNotEmpty) {
        await processImage(
            commonAlbumController.assetPickerProvider!.selectedAssets.first);
        commonAlbumController.assetPickerProvider!.selectedAssets = [];
        commonAlbumController.assetPickerProvider!.removeListener(() {});
        commonAlbumController.pickerConfig = null;
        commonAlbumController.assetPickerProvider = null;
      }
    });
  }

  getCameraPhoto(BuildContext context) async {
    var isGranted = await checkCameraOrPhotoPermission(type: 1);
    if (!isGranted) return;
    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
          isMirrorFrontCamera: isMirrorFrontCamera);
    } else {
      final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const CamerawesomePage(),
        ),
      );
      if (res == null) {
        return;
      }
      entity = res["result"];
    }
    if (entity != null) {
      processImage(entity);
    }
  }
}
